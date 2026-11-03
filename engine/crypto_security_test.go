// SPDX-License-Identifier: GPL-3.0-or-later
package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"io"
	"strings"
	"sync"
	"testing"

	"github.com/nbd-wtf/go-nostr/nip44"
	"github.com/nbd-wtf/go-nostr/nip59"
	"golang.org/x/crypto/curve25519"
	"golang.org/x/crypto/scrypt"
)

// TestX25519_ECDH_SharedSecret tests that deriveSharedKey produces consistent shared secrets
// and tests with known test vectors from RFC 7748.
func TestX25519_ECDH_SharedSecret(t *testing.T) {
	// Test with known test vectors from RFC 7748
	// Alice's private key: a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4
	// Alice's public key:  e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c
	// Bob's private key:   4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d
	// Bob's public key:    e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493
	// Shared secret:       c3da55379de9c6908e94ea4df28d084f32eccf03491c71f75b96e17093d1dc05

	alicePrivHex := "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4"
	bobPubHex := "e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493"
	expectedSharedHex := "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f75b96e17093d1dc05"

	// Test that deriveSharedKey produces the expected shared secret
	sharedKey, err := deriveSharedKey(bobPubHex)
	if err != nil {
		t.Fatalf("deriveSharedKey failed: %v", err)
	}

	expectedShared, err := hex.DecodeString(expectedSharedHex)
	if err != nil {
		t.Fatalf("hex decode expected: %v", err)
	}

	if hex.EncodeToString(sharedKey[:]) != expectedSharedHex {
		t.Errorf("shared secret mismatch: got %s, want %s", hex.EncodeToString(sharedKey[:]), expectedSharedHex)
	}

	// Test that shared secret is consistent (commutative property)
	// Set up Alice's identity
	alicePriv, err := hex.DecodeString(alicePrivHex)
	if err != nil {
		t.Fatalf("decode alice priv: %v", err)
	}
	var aliceXPriv [32]byte
	copy(aliceXPriv[:], alicePriv)

	// Compute Alice's public key
	var aliceXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPriv)
	alicePubHex := hex.EncodeToString(aliceXPub[:])

	// Now derive shared key from Alice's perspective (using Bob's public key)
	// This should produce the same shared secret
	sharedKey2, err := deriveSharedKey(alicePubHex)
	if err != nil {
		t.Fatalf("deriveSharedKey from Alice perspective failed: %v", err)
	}

	if hex.EncodeToString(sharedKey2[:]) != expectedSharedHex {
		t.Errorf("shared secret from Alice perspective mismatch: got %s, want %s", hex.EncodeToString(sharedKey2[:]), expectedSharedHex)
	}
}

// TestX25519_InvalidKeyRejection tests that invalid keys are rejected
func TestX25519_InvalidKeyRejection(t *testing.T) {
	// Test all-zeros key
	_, err := deriveSharedKey(strings.Repeat("0", 64))
	if err == nil {
		t.Error("expected error for all-zeros key, got nil")
	}

	// Test all-ones key (not a valid curve25519 point)
	_, err = deriveSharedKey(strings.Repeat("f", 64))
	if err == nil {
		t.Error("expected error for all-ones key, got nil")
	}

	// Test invalid hex string
	_, err = deriveSharedKey("not valid hex")
	if err == nil {
		t.Error("expected error for invalid hex, got nil")
	}

	// Test wrong length key (31 bytes = 62 hex chars)
	_, err = deriveSharedKey(strings.Repeat("0", 62))
	if err == nil {
		t.Error("expected error for 31-byte key, got nil")
	}

	// Test wrong length key (33 bytes = 66 hex chars)
	_, err = deriveSharedKey(strings.Repeat("0", 66))
	if err == nil {
		t.Error("expected error for 33-byte key, got nil")
	}
}

// TestX25519_RandomKeyConsistency tests that randomly generated keys produce consistent shared secrets
func TestX25519_RandomKeyConsistency(t *testing.T) {
	// Generate two random identities
	alicePriv := make([]byte, 32)
	bobPriv := make([]byte, 32)

	if _, err := rand.Read(alicePriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobPriv); err != nil {
		t.Fatal(err)
	}

	// Clamp private keys per RFC 7748
	alicePriv[0] &= 248
	alicePriv[31] &= 127
	alicePriv[31] |= 64
	bobPriv[0] &= 248
	bobPriv[31] &= 127
	bobPriv[31] |= 64

	var aliceXPriv, bobXPriv [32]byte
	copy(aliceXPriv[:], alicePriv)
	copy(bobXPriv[:], bobPriv)

	var aliceXPub, bobXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPriv)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPriv)

	alicePubHex := hex.EncodeToString(aliceXPub[:])
	bobPubHex := hex.EncodeToString(bobXPub[:])

	// Set global to Alice's private key for deriveSharedKey
	mu.Lock()
	oldXPriv := myXPriv
	myXPriv = aliceXPriv
	mu.Unlock()
	defer func() {
		mu.Lock()
		myXPriv = oldXPriv
		mu.Unlock()
	}()

	// Alice derives shared key using Bob's public key
	shared1, err := deriveSharedKey(bobPubHex)
	if err != nil {
		t.Fatalf("Alice derive failed: %v", err)
	}

	// Set global to Bob's private key
	mu.Lock()
	myXPriv = bobXPriv
	mu.Unlock()

	// Bob derives shared key using Alice's public key
	shared2, err := deriveSharedKey(alicePubHex)
	if err != nil {
		t.Fatalf("Bob derive failed: %v", err)
	}

	// Both should get the same shared secret
	if shared1 != shared2 {
		t.Errorf("shared secrets don't match: Alice=%s Bob=%s",
			hex.EncodeToString(shared1[:]), hex.EncodeToString(shared2[:]))
	}
}

// TestAESGCM_RoundTrip tests AES-GCM encryption/decryption round-trip via HaloEncryptFor/HaloDecryptFrom
func TestAESGCM_RoundTrip(t *testing.T) {
	// Generate two random X25519 identities
	alicePriv := make([]byte, 32)
	bobPriv := make([]byte, 32)
	if _, err := rand.Read(alicePriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobPriv); err != nil {
		t.Fatal(err)
	}

	// Clamp per RFC 7748
	alicePriv[0] &= 248
	alicePriv[31] &= 127
	alicePriv[31] |= 64
	bobPriv[0] &= 248
	bobPriv[31] &= 127
	bobPriv[31] |= 64

	var aliceXPriv, bobXPriv [32]byte
	copy(aliceXPriv[:], alicePriv)
	copy(bobXPriv[:], bobPriv)

	var aliceXPub, bobXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPriv)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPriv)

	alicePubHex := hex.EncodeToString(aliceXPub[:])
	bobPubHex := hex.EncodeToString(bobXPub[:])

	// Test data
	plaintext := "Hello, secure world! This is a test message for AES-GCM."

	// Set global to Alice's private key for encryption
	mu.Lock()
	oldXPriv := myXPriv
	myXPriv = aliceXPriv
	mu.Unlock()
	defer func() {
		mu.Lock()
		myXPriv = oldXPriv
		mu.Unlock()
	}()

	// Alice encrypts for Bob
	ciphertextB64 := HaloEncryptFor(bobPubHex, plaintext)
	if strings.HasPrefix(ciphertextB64, "error:") {
		t.Fatalf("HaloEncryptFor failed: %s", ciphertextB64)
	}

	// Set global to Bob's private key for decryption
	mu.Lock()
	myXPriv = bobXPriv
	mu.Unlock()

	// Bob decrypts from Alice
	decrypted := HaloDecryptFrom(alicePubHex, ciphertextB64)
	if strings.HasPrefix(decrypted, "error:") {
		t.Fatalf("HaloDecryptFrom failed: %s", decrypted)
	}

	if decrypted != plaintext {
		t.Errorf("decryption mismatch: got %q, want %q", decrypted, plaintext)
	}
}

// TestAESGCM_InvalidCiphertext tests that tampered ciphertext is rejected
func TestAESGCM_InvalidCiphertext(t *testing.T) {
	alicePriv := make([]byte, 32)
	bobPriv := make([]byte, 32)
	if _, err := rand.Read(alicePriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobPriv); err != nil {
		t.Fatal(err)
	}

	alicePriv[0] &= 248
	alicePriv[31] &= 127
	alicePriv[31] |= 64
	bobPriv[0] &= 248
	bobPriv[31] &= 127
	bobPriv[31] |= 64

	var aliceXPriv, bobXPriv [32]byte
	copy(aliceXPriv[:], alicePriv)
	copy(bobXPriv[:], bobPriv)

	var aliceXPub, bobXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPriv)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPriv)

	alicePubHex := hex.EncodeToString(aliceXPub[:])
	bobPubHex := hex.EncodeToString(bobXPub[:])

	plaintext := "Test message"

	mu.Lock()
	oldXPriv := myXPriv
	myXPriv = aliceXPriv
	mu.Unlock()
	defer func() {
		mu.Lock()
		myXPriv = oldXPriv
		mu.Unlock()
	}()
	ciphertextB64 := HaloEncryptFor(bobPubHex, plaintext)
	if strings.HasPrefix(ciphertextB64, "error:") {
		t.Fatalf("HaloEncryptFor failed: %s", ciphertextB64)
	}

	// Tamper with the ciphertext (flip a bit in the middle)
	ciphertextBytes := []byte(ciphertextB64)
	if len(ciphertextBytes) > 10 {
		ciphertextBytes[len(ciphertextBytes)/2] ^= 0x01
	}
	tamperedB64 := string(ciphertextBytes)

	mu.Lock()
	myXPriv = bobXPriv
	mu.Unlock()
	decrypted := HaloDecryptFrom(alicePubHex, tamperedB64)
	if !strings.HasPrefix(decrypted, "error:") {
		t.Error("expected decryption to fail with tampered ciphertext, but it succeeded")
	}
}

// TestAESGCM_WrongKeyRejection tests that decryption with wrong key fails
func TestAESGCM_WrongKeyRejection(t *testing.T) {
	// Three parties: Alice, Bob, Carol
	alicePriv := make([]byte, 32)
	bobPriv := make([]byte, 32)
	carolPriv := make([]byte, 32)
	if _, err := rand.Read(alicePriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(carolPriv); err != nil {
		t.Fatal(err)
	}

	for _, p := range [][]byte{alicePriv, bobPriv, carolPriv} {
		p[0] &= 248
		p[31] &= 127
		p[31] |= 64
	}

	var aliceXPriv, bobXPriv, carolXPriv [32]byte
	copy(aliceXPriv[:], alicePriv)
	copy(bobXPriv[:], bobPriv)
	copy(carolXPriv[:], carolPriv)

	var aliceXPub, bobXPub, carolXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPriv)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPriv)
	curve25519.ScalarBaseMult(&carolXPub, &carolXPriv)

	alicePubHex := hex.EncodeToString(aliceXPub[:])
	bobPubHex := hex.EncodeToString(bobXPub[:])
	carolPubHex := hex.EncodeToString(carolXPub[:])

	plaintext := "Secret for Bob only"

	mu.Lock()
	oldXPriv := myXPriv
	myXPriv = aliceXPriv
	mu.Unlock()
	defer func() {
		mu.Lock()
		myXPriv = oldXPriv
		mu.Unlock()
	}()
	ciphertextB64 := HaloEncryptFor(bobPubHex, plaintext)
	if strings.HasPrefix(ciphertextB64, "error:") {
		t.Fatalf("HaloEncryptFor failed: %s", ciphertextB64)
	}

	// Carol tries to decrypt (should fail)
	mu.Lock()
	myXPriv = carolXPriv
	mu.Unlock()
	decrypted := HaloDecryptFrom(alicePubHex, ciphertextB64)
	if !strings.HasPrefix(decrypted, "error:") {
		t.Error("expected decryption to fail with Carol's key, but it succeeded")
	}
}

// testNIP44Keys generates NIP-44 conversation keys for two X25519 identities.
// This helper encapsulates the NIP-17 key derivation logic so that NIP-44 tests
// don't depend directly on internal NIP-17 types and functions.
func testNIP44Keys(t *testing.T, aliceXPrivArr, bobXPrivArr [32]byte) (aliceSndSk, aliceSndPk, bobRcvSk, bobRcvPk string) {
	t.Helper()

	var aliceXPub, bobXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPrivArr)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPrivArr)

	aliceXID := xid{priv: aliceXPrivArr, pub: aliceXPub}
	bobXID := xid{priv: bobXPrivArr, pub: bobXPub}

	aliceSndSk, aliceSndPk, err := nip17DeriveRoleAs(aliceXID, bobXPub, nip17SndInfo, hex.EncodeToString(aliceXPub[:]))
	if err != nil {
		t.Fatalf("alice derive sender role: %v", err)
	}

	bobRcvSk, bobRcvPk, err := nip17DeriveRoleAs(bobXID, aliceXPub, nip17RcvInfo, hex.EncodeToString(bobXPub[:]))
	if err != nil {
		t.Fatalf("bob derive receiver role: %v", err)
	}

	return aliceSndSk, aliceSndPk, bobRcvSk, bobRcvPk
}

// TestNIP44_ConversationKey tests NIP-44 v2 conversation key generation
func TestNIP44_ConversationKey(t *testing.T) {
	// Generate X25519 identities
	aliceXPriv := make([]byte, 32)
	bobXPriv := make([]byte, 32)
	if _, err := rand.Read(aliceXPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobXPriv); err != nil {
		t.Fatal(err)
	}

	aliceXPriv[0] &= 248
	aliceXPriv[31] &= 127
	aliceXPriv[31] |= 64
	bobXPriv[0] &= 248
	bobXPriv[31] &= 127
	bobXPriv[31] |= 64

	var aliceXPrivArr, bobXPrivArr [32]byte
	copy(aliceXPrivArr[:], aliceXPriv)
	copy(bobXPrivArr[:], bobXPriv)

	// Derive NIP-44 conversation keys using helper
	aliceSndSk, aliceSndPk, bobRcvSk, bobRcvPk := testNIP44Keys(t, aliceXPrivArr, bobXPrivArr)

	// Alice generates conversation key for Bob
	ck1, err := nip44.GenerateConversationKey(bobRcvPk, aliceSndSk)
	if err != nil {
		t.Fatalf("alice generate conversation key: %v", err)
	}

	// Bob generates conversation key for Alice
	ck2, err := nip44.GenerateConversationKey(aliceSndPk, bobRcvSk)
	if err != nil {
		t.Fatalf("bob generate conversation key: %v", err)
	}

	// Both should get the same conversation key
	if ck1 != ck2 {
		t.Errorf("conversation keys don't match: alice=%s bob=%s", ck1, ck2)
	}
}

// TestNIP44_EncryptDecrypt tests NIP-44 v2 encryption/decryption round-trip
func TestNIP44_EncryptDecrypt(t *testing.T) {
	aliceXPriv := make([]byte, 32)
	bobXPriv := make([]byte, 32)
	if _, err := rand.Read(aliceXPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobXPriv); err != nil {
		t.Fatal(err)
	}

	aliceXPriv[0] &= 248
	aliceXPriv[31] &= 127
	aliceXPriv[31] |= 64
	bobXPriv[0] &= 248
	bobXPriv[31] &= 127
	bobXPriv[31] |= 64

	var aliceXPrivArr, bobXPrivArr [32]byte
	copy(aliceXPrivArr[:], aliceXPriv)
	copy(bobXPrivArr[:], bobXPriv)

	// Derive NIP-44 conversation keys using helper
	aliceSndSk, aliceSndPk, bobRcvSk, bobRcvPk := testNIP44Keys(t, aliceXPrivArr, bobXPrivArr)

	// Generate conversation keys
	ckAlice, err := nip44.GenerateConversationKey(bobRcvPk, aliceSndSk)
	if err != nil {
		t.Fatalf("alice conversation key: %v", err)
	}
	ckBob, err := nip44.GenerateConversationKey(aliceSndPk, bobRcvSk)
	if err != nil {
		t.Fatalf("bob conversation key: %v", err)
	}

	// Test messages
	messages := []string{
		"Hello, NIP-44!",
		"",
		"Special chars: \n\t\"'\\",
		"Unicode: 🎉 你好 мир",
		strings.Repeat("A", 10000), // Large message
	}

	for _, msg := range messages {
		// Alice encrypts
		ciphertext, err := nip44.Encrypt(msg, ckAlice)
		if err != nil {
			t.Fatalf("encrypt failed: %v", err)
		}

		// Bob decrypts
		plaintext, err := nip44.Decrypt(ciphertext, ckBob)
		if err != nil {
			t.Fatalf("decrypt failed: %v", err)
		}

		if plaintext != msg {
			t.Errorf("round-trip failed: got %q, want %q", plaintext, msg)
		}
	}
}

// TestNIP44_InvalidCiphertextRejection tests that tampered NIP-44 ciphertext is rejected
func TestNIP44_InvalidCiphertextRejection(t *testing.T) {
	aliceXPriv := make([]byte, 32)
	bobXPriv := make([]byte, 32)
	if _, err := rand.Read(aliceXPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobXPriv); err != nil {
		t.Fatal(err)
	}

	aliceXPriv[0] &= 248
	aliceXPriv[31] &= 127
	aliceXPriv[31] |= 64
	bobXPriv[0] &= 248
	bobXPriv[31] &= 127
	bobXPriv[31] |= 64

	var aliceXPrivArr, bobXPrivArr [32]byte
	copy(aliceXPrivArr[:], aliceXPriv)
	copy(bobXPrivArr[:], bobXPriv)

	// Derive NIP-44 conversation keys using helper
	aliceSndSk, aliceSndPk, bobRcvSk, bobRcvPk := testNIP44Keys(t, aliceXPrivArr, bobXPrivArr)

	ckAlice, err := nip44.GenerateConversationKey(bobRcvPk, aliceSndSk)
	if err != nil {
		t.Fatalf("alice conversation key: %v", err)
	}
	ckBob, err := nip44.GenerateConversationKey(aliceSndPk, bobRcvSk)
	if err != nil {
		t.Fatalf("bob conversation key: %v", err)
	}

	msg := "Test message for tampering"
	ciphertext, err := nip44.Encrypt(msg, ckAlice)
	if err != nil {
		t.Fatalf("encrypt: %v", err)
	}

	// Tamper with ciphertext
	if len(ciphertext) > 10 {
		ciphertext = ciphertext[:len(ciphertext)/2] + "X" + ciphertext[len(ciphertext)/2+1:]
	}

	_, err = nip44.Decrypt(ciphertext, ckBob)
	if err == nil {
		t.Error("expected decryption to fail with tampered ciphertext")
	}
}

// TestNIP59_GiftWrapUnwrap tests NIP-59 gift wrap/unwrap round-trip
func TestNIP59_GiftWrapUnwrap(t *testing.T) {
	aliceXPriv := make([]byte, 32)
	bobXPriv := make([]byte, 32)
	if _, err := rand.Read(aliceXPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobXPriv); err != nil {
		t.Fatal(err)
	}

	aliceXPriv[0] &= 248
	aliceXPriv[31] &= 127
	aliceXPriv[31] |= 64
	bobXPriv[0] &= 248
	bobXPriv[31] &= 127
	bobXPriv[31] |= 64

	var aliceXPrivArr, bobXPrivArr [32]byte
	copy(aliceXPrivArr[:], aliceXPriv)
	copy(bobXPrivArr[:], bobXPriv)

	var aliceXPub, bobXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPrivArr)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPrivArr)

	aliceXID := xid{priv: aliceXPrivArr, pub: aliceXPub}
	bobXID := xid{priv: bobXPrivArr, pub: bobXPub}

	// Test messages
	messages := []string{
		"Hello, NIP-59!",
		"",
		"Special chars: \n\t\"'\\",
		"Unicode: 🎉 你好 мир",
		strings.Repeat("B", 5000),
	}

	for _, msg := range messages {
		// Alice wraps for Bob
		wrapped, err := nip17WrapAs(aliceXID, bobXPub, msg)
		if err != nil {
			t.Fatalf("nip17WrapAs failed: %v", err)
		}

		// Bob unwraps from Alice
		unwrapped, err := nip17UnwrapAs(bobXID, aliceXPub, wrapped)
		if err != nil {
			t.Fatalf("nip17UnwrapAs failed: %v", err)
		}

		if unwrapped != msg {
			t.Errorf("gift wrap round-trip failed: got %q, want %q", unwrapped, msg)
		}

		// Verify the wrapped event structure
		if wrapped.Kind != 1059 { // Gift wrap kind
			t.Errorf("wrapped event kind should be 1059, got %d", wrapped.Kind)
		}
		if wrapped.PubKey == "" {
			t.Error("wrapped event should have a pubkey (ephemeral)")
		}
	}
}

// TestNIP59_WrongPeerRejection tests that gift wrap from wrong peer is rejected
func TestNIP59_WrongPeerRejection(t *testing.T) {
	aliceXPriv := make([]byte, 32)
	bobXPriv := make([]byte, 32)
	carolXPriv := make([]byte, 32)
	if _, err := rand.Read(aliceXPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobXPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(carolXPriv); err != nil {
		t.Fatal(err)
	}

	for _, p := range [][]byte{aliceXPriv, bobXPriv, carolXPriv} {
		p[0] &= 248
		p[31] &= 127
		p[31] |= 64
	}

	var aliceXPrivArr, bobXPrivArr, carolXPrivArr [32]byte
	copy(aliceXPrivArr[:], aliceXPriv)
	copy(bobXPrivArr[:], bobPriv)
	copy(carolXPrivArr[:], carolXPriv)

	var aliceXPub, bobXPub, carolXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPrivArr)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPrivArr)
	curve25519.ScalarBaseMult(&carolXPub, &carolXPrivArr)

	aliceXID := xid{priv: aliceXPrivArr, pub: aliceXPub}
	bobXID := xid{priv: bobXPrivArr, pub: bobXPub}
	carolXID := xid{priv: carolXPrivArr, pub: carolXPub}

	// Alice wraps for Bob
	wrapped, err := nip17WrapAs(aliceXID, bobXPub, "Secret for Bob")
	if err != nil {
		t.Fatalf("wrap: %v", err)
	}

	// Carol tries to unwrap (should fail)
	_, err = nip17UnwrapAs(carolXID, aliceXPub, wrapped)
	if err == nil {
		t.Error("expected unwrap to fail for Carol, but it succeeded")
	}

	// Bob can unwrap (should succeed)
	unwrapped, err := nip17UnwrapAs(bobXID, aliceXPub, wrapped)
	if err != nil {
		t.Fatalf("bob unwrap failed: %v", err)
	}
	if unwrapped != "Secret for Bob" {
		t.Errorf("bob unwrap wrong content: %q", unwrapped)
	}
}

// TestNIP59_TamperedGiftWrapRejection tests that tampered gift wrap is rejected
func TestNIP59_TamperedGiftWrapRejection(t *testing.T) {
	aliceXPriv := make([]byte, 32)
	bobXPriv := make([]byte, 32)
	if _, err := rand.Read(aliceXPriv); err != nil {
		t.Fatal(err)
	}
	if _, err := rand.Read(bobXPriv); err != nil {
		t.Fatal(err)
	}

	aliceXPriv[0] &= 248
	aliceXPriv[31] &= 127
	aliceXPriv[31] |= 64
	bobXPriv[0] &= 248
	bobXPriv[31] &= 127
	bobXPriv[31] |= 64

	var aliceXPrivArr, bobXPrivArr [32]byte
	copy(aliceXPrivArr[:], aliceXPriv)
	copy(bobXPrivArr[:], bobXPriv)

	var aliceXPub, bobXPub [32]byte
	curve25519.ScalarBaseMult(&aliceXPub, &aliceXPrivArr)
	curve25519.ScalarBaseMult(&bobXPub, &bobXPrivArr)

	aliceXID := xid{priv: aliceXPrivArr, pub: aliceXPub}
	bobXID := xid{priv: bobXPrivArr, pub: bobXPub}

	wrapped, err := nip17WrapAs(aliceXID, bobXPub, "Test")
	if err != nil {
		t.Fatalf("wrap: %v", err)
	}

	// Tamper with the gift wrap - modify the content
	wrapped.Content = "tampered"

	_, err = nip17UnwrapAs(bobXID, aliceXPub, wrapped)
	if err == nil {
		t.Error("expected unwrap to fail with tampered gift wrap")
	}
}

// TestScrypt_BackupEncryption tests scrypt KDF with N=32768, r=8, p=1 for backup encryption
func TestScrypt_BackupEncryption(t *testing.T) {
	passphrase := "correct horse battery staple"
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		t.Fatal(err)
	}

	// Test that scrypt produces the expected key length
	key, err := scrypt.Key([]byte(passphrase), salt, 32768, 8, 1, 32)
	if err != nil {
		t.Fatalf("scrypt.Key failed: %v", err)
	}
	if len(key) != 32 {
		t.Errorf("expected 32-byte key, got %d", len(key))
	}

	// Test deterministic output with same parameters
	key2, err := scrypt.Key([]byte(passphrase), salt, 32768, 8, 1, 32)
	if err != nil {
		t.Fatalf("scrypt.Key second call failed: %v", err)
	}
	if string(key) != string(key2) {
		t.Error("scrypt output not deterministic with same inputs")
	}

	// Test different salt produces different key
	salt2 := make([]byte, 16)
	if _, err := rand.Read(salt2); err != nil {
		t.Fatal(err)
	}
	key3, err := scrypt.Key([]byte(passphrase), salt2, 32768, 8, 1, 32)
	if err != nil {
		t.Fatalf("scrypt.Key with different salt failed: %v", err)
	}
	if string(key) == string(key3) {
		t.Error("different salts produced same key")
	}

	// Test different passphrase produces different key
	key4, err := scrypt.Key([]byte("wrong passphrase"), salt, 32768, 8, 1, 32)
	if err != nil {
		t.Fatalf("scrypt.Key with different passphrase failed: %v", err)
	}
	if string(key) == string(key4) {
		t.Error("different passphrases produced same key")
	}

	// Test wrong parameters (lower N) produces different key
	key5, err := scrypt.Key([]byte(passphrase), salt, 16384, 8, 1, 32)
	if err != nil {
		t.Fatalf("scrypt.Key with N=16384 failed: %v", err)
	}
	if string(key) == string(key5) {
		t.Error("different N parameter produced same key")
	}
}

// TestScrypt_BackupRoundTrip tests full backup encryption/decryption round-trip
func TestScrypt_BackupRoundTrip(t *testing.T) {
	plaintext := []byte("This is my secret backup data that should be encrypted!")
	passphrase := "my-secure-passphrase-123"

	// Encrypt
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		t.Fatal(err)
	}
	key, err := scrypt.Key([]byte(passphrase), salt, 32768, 8, 1, 32)
	if err != nil {
		t.Fatalf("scrypt key derivation failed: %v", err)
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		t.Fatalf("aes.NewCipher failed: %v", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		t.Fatalf("cipher.NewGCM failed: %v", err)
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		t.Fatalf("nonce generation failed: %v", err)
	}
	ct := gcm.Seal(nil, nonce, plaintext, nil)
	blob := append(append(salt, nonce...), ct...)

	// Decrypt
	if len(blob) < 16+12+16 {
		t.Fatal("blob too short")
	}
	saltDec := blob[:16]
	rest := blob[16:]
	keyDec, err := scrypt.Key([]byte(passphrase), saltDec, 32768, 8, 1, 32)
	if err != nil {
		t.Fatalf("scrypt key derivation (decrypt) failed: %v", err)
	}
	blockDec, err := aes.NewCipher(keyDec)
	if err != nil {
		t.Fatalf("aes.NewCipher (decrypt) failed: %v", err)
	}
	gcmDec, err := cipher.NewGCM(blockDec)
	if err != nil {
		t.Fatalf("cipher.NewGCM (decrypt) failed: %v", err)
	}
	nonceSize := gcmDec.NonceSize()
	nonceDec := rest[:nonceSize]
	ctDec := rest[nonceSize:]
	decrypted, err := gcmDec.Open(nil, nonceDec, ctDec, nil)
	if err != nil {
		t.Fatalf("gcm.Open failed: %v", err)
	}

	if string(decrypted) != string(plaintext) {
		t.Errorf("backup round-trip failed: got %q, want %q", string(decrypted), string(plaintext))
	}
}

// TestScrypt_WrongPassphraseRejection tests that wrong passphrase fails to decrypt
func TestScrypt_WrongPassphraseRejection(t *testing.T) {
	plaintext := []byte("Secret data")
	passphrase := "correct-passphrase"
	wrongPassphrase := "wrong-passphrase"

	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		t.Fatal(err)
	}

	key, err := scrypt.Key([]byte(passphrase), salt, 32768, 8, 1, 32)
	if err != nil {
		t.Fatal(err)
	}
	block, _ := aes.NewCipher(key)
	gcm, _ := cipher.NewGCM(block)
	nonce := make([]byte, gcm.NonceSize())
	rand.Read(nonce)
	ct := gcm.Seal(nil, nonce, plaintext, nil)
	blob := append(append(salt, nonce...), ct...)

	// Try to decrypt with wrong passphrase
	saltDec := blob[:16]
	rest := blob[16:]
	keyDec, err := scrypt.Key([]byte(wrongPassphrase), saltDec, 32768, 8, 1, 32)
	if err != nil {
		t.Fatal(err)
	}
	blockDec, _ := aes.NewCipher(keyDec)
	gcmDec, _ := cipher.NewGCM(blockDec)
	nonceSize := gcmDec.NonceSize()
	nonceDec := rest[:nonceSize]
	ctDec := rest[nonceSize:]
	_, err = gcmDec.Open(nil, nonceDec, ctDec, nil)
	if err == nil {
		t.Error("expected decryption to fail with wrong passphrase")
	}
}

// TestHaloEncryptBackupDecryptBackup tests the exported FFI functions for backup encryption
func TestHaloEncryptBackupDecryptBackup(t *testing.T) {
	plaintext := "This is my secret backup data that should be encrypted via FFI!"
	passphrase := "my-secure-backup-passphrase-123"

	// Encrypt using the exported FFI function
	ciphertext := HaloEncryptBackup(plaintext, passphrase)
	if strings.HasPrefix(ciphertext, "error:") {
		t.Fatalf("HaloEncryptBackup failed: %s", ciphertext)
	}

	// Verify the format
	prefix := "halo-backup:v1:"
	if !strings.HasPrefix(ciphertext, prefix) {
		t.Errorf("expected ciphertext to start with %q, got %q", prefix, ciphertext[:min(len(ciphertext), 20)])
	}

	// Decrypt using the exported FFI function
	decrypted := HaloDecryptBackup(ciphertext, passphrase)
	if strings.HasPrefix(decrypted, "error:") {
		t.Fatalf("HaloDecryptBackup failed: %s", decrypted)
	}

	if decrypted != plaintext {
		t.Errorf("backup round-trip failed: got %q, want %q", decrypted, plaintext)
	}
}

// TestHaloDecryptBackup_WrongPassphrase tests that wrong passphrase fails to decrypt backup
func TestHaloDecryptBackup_WrongPassphrase(t *testing.T) {
	plaintext := "Secret backup data"
	passphrase := "correct-passphrase"
	wrongPassphrase := "wrong-passphrase"

	ciphertext := HaloEncryptBackup(plaintext, passphrase)
	if strings.HasPrefix(ciphertext, "error:") {
		t.Fatalf("HaloEncryptBackup failed: %s", ciphertext)
	}

	// Try to decrypt with wrong passphrase
	decrypted := HaloDecryptBackup(ciphertext, wrongPassphrase)
	if !strings.HasPrefix(decrypted, "error:") {
		t.Error("expected decryption to fail with wrong passphrase")
	}
}

// TestHaloDecryptBackup_CorruptData tests that corrupt backup data is rejected
func TestHaloDecryptBackup_CorruptData(t *testing.T) {
	plaintext := "Test data"
	passphrase := "passphrase"

	ciphertext := HaloEncryptBackup(plaintext, passphrase)
	if strings.HasPrefix(ciphertext, "error:") {
		t.Fatalf("HaloEncryptBackup failed: %s", ciphertext)
	}

	// Corrupt the base64 data
	corrupted := ciphertext[:len(ciphertext)/2] + "X" + ciphertext[len(ciphertext)/2+1:]

	decrypted := HaloDecryptBackup(corrupted, passphrase)
	if !strings.HasPrefix(decrypted, "error:") {
		t.Error("expected decryption to fail with corrupted data")
	}
}

// TestHaloDecryptBackup_InvalidFormat tests that non-backup data is rejected
func TestHaloDecryptBackup_InvalidFormat(t *testing.T) {
	// Try to decrypt something that's not a halo backup
	decrypted := HaloDecryptBackup("not-a-backup-blob", "passphrase")
	if !strings.HasPrefix(decrypted, "error:") {
		t.Error("expected decryption to fail for non-backup data")
	}

	// Try with wrong prefix
	decrypted = HaloDecryptBackup("halo-backup:v2:invalid", "passphrase")
	if !strings.HasPrefix(decrypted, "error:") {
		t.Error("expected decryption to fail for wrong version")
	}
}

// TestEd25519_SignVerify tests Ed25519 signing and verification for handle claims
func TestEd25519_SignVerify(t *testing.T) {
	// Generate Ed25519 keypair
	pubKey, privKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatalf("ed25519.GenerateKey failed: %v", err)
	}

	// Test messages
	messages := []string{
		"kryfo-handle-v1:alice",
		"kryfo-handle-v1:bob_123",
		"kryfo-handle-v1:",
		strings.Repeat("kryfo-handle-v1:a", 100),
	}

	for _, msg := range messages {
		// Sign
		sig := ed25519.Sign(privKey, []byte(msg))

		// Verify
		if !ed25519.Verify(pubKey, []byte(msg), sig) {
			t.Errorf("verification failed for message %q", msg)
		}

		// Verify with wrong message fails
		if ed25519.Verify(pubKey, []byte(msg+"tampered"), sig) {
			t.Errorf("verification should fail for tampered message %q", msg)
		}

		// Verify with wrong key fails
		otherPub, _, _ := ed25519.GenerateKey(rand.Reader)
		if ed25519.Verify(otherPub, []byte(msg), sig) {
			t.Errorf("verification should fail with different public key")
		}

		// Verify with tampered signature fails
		tamperedSig := make([]byte, len(sig))
		copy(tamperedSig, sig)
		if len(tamperedSig) > 0 {
			tamperedSig[0] ^= 0x01
		}
		if ed25519.Verify(pubKey, []byte(msg), tamperedSig) {
			t.Errorf("verification should fail with tampered signature")
		}
	}
}

// TestEd25519_HandleSign tests the handleSign function used for handle claims
func TestEd25519_HandleSign(t *testing.T) {
	// Set up a test identity
	testPriv := make([]byte, ed25519.PrivateKeySize)
	if _, err := rand.Read(testPriv); err != nil {
		t.Fatal(err)
	}
	mu.Lock()
	oldEdPriv := myEdPriv
	myEdPriv = ed25519.PrivateKey(testPriv)
	mu.Unlock()
	defer func() {
		mu.Lock()
		myEdPriv = oldEdPriv
		mu.Unlock()
	}()

	handles := []string{
		"alice",
		"bob_123",
		"very_long_handle_name_123",
		"a", // Will be rejected by handleOK regex
	}

	for _, h := range handles {
		sig, pub, err := handleSign(h)
		if err != nil {
			if h == "a" {
				// Expected to fail due to handle validation
				continue
			}
			t.Fatalf("handleSign(%q) failed: %v", h, err)
		}

		// Verify the signature
		pubBytes, err := hex.DecodeString(pub)
		if err != nil {
			t.Fatalf("decode pubkey: %v", err)
		}
		sigBytes, err := hex.DecodeString(sig)
		if err != nil {
			t.Fatalf("decode sig: %v", err)
		}

		msg := "kryfo-handle-v1:" + h
		if !ed25519.Verify(pubBytes, []byte(msg), sigBytes) {
			t.Errorf("handleSign verification failed for %q", h)
		}
	}
}

// TestEd25519_DeterministicSignatures tests that Ed25519 signatures are deterministic
func TestEd25519_DeterministicSignatures(t *testing.T) {
	pubKey, privKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}

	msg := []byte("kryfo-handle-v1:testuser")

	sig1 := ed25519.Sign(privKey, msg)
	sig2 := ed25519.Sign(privKey, msg)

	// Ed25519 signatures are deterministic (per RFC 8032)
	if string(sig1) != string(sig2) {
		t.Error("Ed25519 signatures are not deterministic")
	}

	// Both should verify
	if !ed25519.Verify(pubKey, msg, sig1) {
		t.Error("sig1 verification failed")
	}
	if !ed25519.Verify(pubKey, msg, sig2) {
		t.Error("sig2 verification failed")
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
