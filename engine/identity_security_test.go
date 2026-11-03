// SPDX-License-Identifier: GPL-3.0-or-later
package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/hex"
	"strings"
	"testing"

	"github.com/tyler-smith/go-bip39"
)

// TestBIP39Mnemonic_Entropy tests that the mnemonic generation uses ~33 bits entropy
// (3 words from 2048-word BIP39 wordlist = 11 bits per word = 33 bits total)
func TestBIP39Mnemonic_Entropy(t *testing.T) {
	wordlist := bip39.GetWordList()
	if len(wordlist) != 2048 {
		t.Fatalf("expected 2048 words in BIP39 wordlist, got %d", len(wordlist))
	}

	// Each word provides 11 bits of entropy (2^11 = 2048)
	// 3 words = 33 bits of entropy
	entropyBits := 33
	expectedCombinations := uint64(1) << entropyBits

	// Total possible 3-word combinations
	totalCombinations := uint64(len(wordlist)) * uint64(len(wordlist)) * uint64(len(wordlist))
	if totalCombinations != expectedCombinations {
		t.Errorf("expected %d combinations (33 bits), got %d", expectedCombinations, totalCombinations)
	}

	// Verify the wordlist is the standard BIP39 English wordlist
	expectedFirstWords := []string{"abandon", "ability", "able", "about", "above"}
	for i, w := range expectedFirstWords {
		if wordlist[i] != w {
			t.Errorf("wordlist[%d] = %q, expected %q (non-standard wordlist?)", i, wordlist[i], w)
		}
	}
}

// TestBIP39Mnemonic_Deterministic tests that the same pubkey always produces the same mnemonic
func TestBIP39Mnemonic_Deterministic(t *testing.T) {
	pubKey := make([]byte, 32)
	if _, err := rand.Read(pubKey); err != nil {
		t.Fatal(err)
	}

	mnemonic1 := idFromPubkey(pubKey)
	mnemonic2 := idFromPubkey(pubKey)

	if mnemonic1 != mnemonic2 {
		t.Errorf("mnemonic not deterministic: %q != %q", mnemonic1, mnemonic2)
	}

	// Verify format: 3 words separated by hyphens
	parts := strings.Split(mnemonic1, "-")
	if len(parts) != 3 {
		t.Errorf("expected 3 words separated by hyphens, got %d parts: %q", len(parts), mnemonic1)
	}

	// Verify all words are from the BIP39 wordlist
	wordlist := bip39.GetWordList()
	wordSet := make(map[string]bool, len(wordlist))
	for _, w := range wordlist {
		wordSet[w] = true
	}

	for _, part := range parts {
		if !wordSet[part] {
			t.Errorf("word %q not in BIP39 wordlist", part)
		}
	}
}

// TestBIP39Mnemonic_CollisionResistance tests that different pubkeys produce different mnemonics
// (with high probability - 33 bits means ~50% collision chance after ~2^16.5 = 92681 samples)
func TestBIP39Mnemonic_CollisionResistance(t *testing.T) {
	const numSamples = 10000
	seen := make(map[string]bool, numSamples)
	collisions := 0

	for i := 0; i < numSamples; i++ {
		pubKey := make([]byte, 32)
		if _, err := rand.Read(pubKey); err != nil {
			t.Fatal(err)
		}

		mnemonic := idFromPubkey(pubKey)
		if seen[mnemonic] {
			collisions++
		}
		seen[mnemonic] = true
	}

	// With 33 bits entropy, expected collisions in 10000 samples:
	// p(collision) ≈ 1 - exp(-n²/2N) ≈ 1 - exp(-10000²/(2*2^33)) ≈ 0.058
	// Expected collisions ≈ 580
	// We'll just verify we don't have an unreasonable number (e.g., > 2000 would be suspicious)
	if collisions > 2000 {
		t.Errorf("too many collisions (%d) - possible entropy issue", collisions)
	}

	t.Logf("Samples: %d, Unique: %d, Collisions: %d", numSamples, len(seen), collisions)
}

// TestHandleSigning tests the handle signing functionality
func TestHandleSigning(t *testing.T) {
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
	}

	for _, h := range handles {
		sig, pub, err := handleSign(h)
		if err != nil {
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

		// Verify the public key matches our test identity
		expectedPub := hex.EncodeToString(testPriv.Public().(ed25519.PublicKey))
		if pub != expectedPub {
			t.Errorf("handleSign returned wrong pubkey for %q", h)
		}
	}
}

// TestHandleSigning_NoIdentity tests handleSign fails when no identity is set
func TestHandleSigning_NoIdentity(t *testing.T) {
	mu.Lock()
	oldEdPriv := myEdPriv
	myEdPriv = nil
	mu.Unlock()
	defer func() {
		mu.Lock()
		myEdPriv = oldEdPriv
		mu.Unlock()
	}()

	_, _, err := handleSign("alice")
	if err == nil {
		t.Error("expected error when no identity set, got nil")
	}
	if !strings.Contains(err.Error(), "no identity") {
		t.Errorf("expected 'no identity' error, got %q", err.Error())
	}
}

// TestHandleClaimRelease_SignatureFormat tests that claim/release use correct signature format
func TestHandleClaimRelease_SignatureFormat(t *testing.T) {
	// This test verifies the signature format used in claim/release
	// Since we can't easily mock the HTTP calls, we test the signing logic directly

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

	handle := "testuser"
	sig, pub, err := handleSign(handle)
	if err != nil {
		t.Fatal(err)
	}

	// Verify the signature is over "kryfo-handle-v1:" + handle
	msg := "kryfo-handle-v1:" + handle
	pubBytes, _ := hex.DecodeString(pub)
	sigBytes, _ := hex.DecodeString(sig)

	if !ed25519.Verify(pubBytes, []byte(msg), sigBytes) {
		t.Error("claim signature verification failed")
	}

	// Verify signature is NOT over just the handle (would be a security issue)
	if ed25519.Verify(pubBytes, []byte(handle), sigBytes) {
		t.Error("signature incorrectly verifies over bare handle (should be prefixed)")
	}
}

// TestHandleClaimRelease_OnlyClaimerCanRelease tests that only the original claimer can release
// This is a logical test - the actual enforcement is server-side, but we verify the client signs correctly
func TestHandleClaimRelease_OnlyClaimerCanRelease(t *testing.T) {
	// Two different identities
	priv1 := make([]byte, ed25519.PrivateKeySize)
	priv2 := make([]byte, ed25519.PrivateKeySize)
	rand.Read(priv1)
	rand.Read(priv2)

	handle := "testuser"

	// Identity 1 signs
	mu.Lock()
	myEdPriv = ed25519.PrivateKey(priv1)
	mu.Unlock()
	sig1, pub1, _ := handleSign(handle)

	// Identity 2 signs
	mu.Lock()
	myEdPriv = ed25519.PrivateKey(priv2)
	mu.Unlock()
	sig2, pub2, _ := handleSign(handle)

	// Signatures should be different
	if sig1 == sig2 {
		t.Error("different identities produced same signature")
	}
	if pub1 == pub2 {
		t.Error("different identities have same public key")
	}

	// Each signature should only verify with its own public key
	msg := "kryfo-handle-v1:" + handle
	pub1Bytes, _ := hex.DecodeString(pub1)
	pub2Bytes, _ := hex.DecodeString(pub2)
	sig1Bytes, _ := hex.DecodeString(sig1)
	sig2Bytes, _ := hex.DecodeString(sig2)

	if !ed25519.Verify(pub1Bytes, []byte(msg), sig1Bytes) {
		t.Error("sig1 doesn't verify with pub1")
	}
	if !ed25519.Verify(pub2Bytes, []byte(msg), sig2Bytes) {
		t.Error("sig2 doesn't verify with pub2")
	}

	// Cross-verification should fail
	if ed25519.Verify(pub1Bytes, []byte(msg), sig2Bytes) {
		t.Error("sig2 incorrectly verifies with pub1")
	}
	if ed25519.Verify(pub2Bytes, []byte(msg), sig1Bytes) {
		t.Error("sig1 incorrectly verifies with pub2")
	}
}

// TestIdFromPubkey_Format tests the exact format of idFromPubkey output
func TestIdFromPubkey_Format(t *testing.T) {
	// Test with a known input to verify exact format
	pubKey := make([]byte, 32)
	for i := range pubKey {
		pubKey[i] = byte(i)
	}

	result := idFromPubkey(pubKey)

	// Should be exactly 3 words separated by single hyphens
	parts := strings.Split(result, "-")
	if len(parts) != 3 {
		t.Errorf("expected 3 parts, got %d: %q", len(parts), result)
	}

	// No leading/trailing hyphens
	if strings.HasPrefix(result, "-") || strings.HasSuffix(result, "-") {
		t.Errorf("result has leading/trailing hyphen: %q", result)
	}

	// No double hyphens
	if strings.Contains(result, "--") {
		t.Errorf("result has double hyphen: %q", result)
	}

	// All words should be lowercase (BIP39 words are lowercase)
	for _, part := range parts {
		if part != strings.ToLower(part) {
			t.Errorf("word not lowercase: %q", part)
		}
	}
}

// TestIdFromPubkey_SHA256_Derivation tests that the ID is derived from SHA256 of pubkey
func TestIdFromPubkey_SHA256_Derivation(t *testing.T) {
	pubKey := make([]byte, 32)
	rand.Read(pubKey)

	// Compute SHA256
	hash := sha256.Sum256(pubKey)

	// The idFromPubkey uses first 5 bytes of SHA256 as 40-bit integer
	// bits = h[0]<<32 | h[1]<<24 | h[2]<<16 | h[3]<<8 | h[4]
	bits := uint64(hash[0])<<32 | uint64(hash[1])<<24 | uint64(hash[2])<<16 | uint64(hash[3])<<8 | uint64(hash[4])

	wordlist := bip39.GetWordList()
	w1 := wordlist[(bits>>22)&0x7FF]
	w2 := wordlist[(bits>>11)&0x7FF]
	w3 := wordlist[bits&0x7FF]
	expected := fmt.Sprintf("%s-%s-%s", w1, w2, w3)

	result := idFromPubkey(pubKey)
	if result != expected {
		t.Errorf("idFromPubkey doesn't match manual computation: got %q, expected %q", result, expected)
	}
}
