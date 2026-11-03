// SPDX-License-Identifier: GPL-3.0-or-later
package main

/*
#cgo CFLAGS: -I.
#include <stdlib.h>
*/
import "C"

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
	"testing"
	"unsafe"

	"github.com/tyler-smith/go-bip39"
)

// TestHaloGenerateIdentity_CGO tests the exported HaloGenerateIdentity function via CGO
func TestHaloGenerateIdentity_CGO(t *testing.T) {
	// Save state
	mu.Lock()
	oldEdPriv := myEdPriv
	oldEdPub := myEdPub
	oldXPriv := myXPriv
	oldXPub := myXPub
	oldId := myId
	mu.Unlock()

	// Call the exported function via CGO
	cResult := C.HaloGenerateIdentity()
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))

	if strings.HasPrefix(result, "error:") {
		t.Fatalf("HaloGenerateIdentity failed: %s", result)
	}

	// Verify the generated identity is a valid 3-word mnemonic
	parts := strings.Split(result, "-")
	if len(parts) != 3 {
		t.Errorf("generated identity not 3-word mnemonic: %q", result)
	}

	// Verify keys were set
	mu.Lock()
	edPriv := myEdPriv
	edPub := myEdPub
	xPriv := myXPriv
	xPub := myXPub
	mu.Unlock()

	if edPriv == nil {
		t.Error("Ed25519 private key not set after generation")
	}
	if edPub == nil {
		t.Error("Ed25519 public key not set after generation")
	}
	if len(edPriv) != ed25519.PrivateKeySize {
		t.Errorf("Ed25519 private key wrong size: %d, expected %d", len(edPriv), ed25519.PrivateKeySize)
	}
	if len(edPub) != ed25519.PublicKeySize {
		t.Errorf("Ed25519 public key wrong size: %d, expected %d", len(edPub), ed25519.PublicKeySize)
	}

	// Verify the private key corresponds to the public key
	if !ed25519.Verify(edPub, []byte("test"), ed25519.Sign(edPriv, []byte("test"))) {
		t.Error("generated Ed25519 keypair doesn't match")
	}

	// Verify X25519 keys
	var zeroKey [32]byte
	if xPriv == zeroKey {
		t.Error("X25519 private key not set (all zeros)")
	}
	if xPub == zeroKey {
		t.Error("X25519 public key not set (all zeros)")
	}

	// Verify the public key is correctly derived from private key
	var expectedXPub [32]byte
	curve25519.ScalarBaseMult(&expectedXPub, &xPriv)
	if xPub != expectedXPub {
		t.Error("X25519 public key doesn't match private key")
	}

	// Verify the halo ID matches the public key
	expectedID := idFromPubkey(edPub)
	if result != expectedID {
		t.Errorf("returned ID %q doesn't match computed ID %q", result, expectedID)
	}

	// Cleanup
	mu.Lock()
	myEdPriv = oldEdPriv
	myEdPub = oldEdPub
	myXPriv = oldXPriv
	myXPub = oldXPub
	myId = oldId
	mu.Unlock()
}

// TestHaloGenerateIdentity_Unique_CGO tests that multiple generations produce different identities
func TestHaloGenerateIdentity_Unique_CGO(t *testing.T) {
	const numGenerations = 100
	identities := make(map[string]bool, numGenerations)

	for i := 0; i < numGenerations; i++ {
		cResult := C.HaloGenerateIdentity()
		result := C.GoString(cResult)
		C.free(unsafe.Pointer(cResult))

		if strings.HasPrefix(result, "error:") {
			t.Fatalf("generation %d failed: %s", i, result)
		}
		identities[result] = true
	}

	// All should be unique (with very high probability)
	if len(identities) != numGenerations {
		t.Errorf("expected %d unique identities, got %d", numGenerations, len(identities))
	}
}

// TestHaloRestoreIdentity_CGO tests the exported HaloRestoreIdentity function via CGO
func TestHaloRestoreIdentity_CGO(t *testing.T) {
	// Generate a fresh identity first
	mu.Lock()
	oldEdPriv := myEdPriv
	oldEdPub := myEdPub
	oldXPriv := myXPriv
	oldXPub := myXPub
	oldId := myId
	mu.Unlock()

	cGenResult := C.HaloGenerateIdentity()
	genResult := C.GoString(cGenResult)
	C.free(unsafe.Pointer(cGenResult))

	if strings.HasPrefix(genResult, "error:") {
		t.Fatalf("generate failed: %s", genResult)
	}

	mu.Lock()
	edPrivHex := hex.EncodeToString(myEdPriv)
	xPrivHex := hex.EncodeToString(myXPriv[:])
	expectedId := myId
	mu.Unlock()

	// Now restore from the exported keys
	cEdPriv := C.CString(edPrivHex)
	cXPriv := C.CString(xPrivHex)
	cRestoreResult := C.HaloRestoreIdentity(cEdPriv, cXPriv)
	restoreResult := C.GoString(cRestoreResult)
	C.free(unsafe.Pointer(cRestoreResult))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if strings.HasPrefix(restoreResult, "error:") {
		t.Fatalf("HaloRestoreIdentity failed: %s", restoreResult)
	}

	if restoreResult != expectedId {
		t.Errorf("restored ID %q doesn't match original %q", restoreResult, expectedId)
	}

	// Verify keys match
	mu.Lock()
	if hex.EncodeToString(myEdPriv) != edPrivHex {
		t.Error("restored Ed25519 private key doesn't match")
	}
	if hex.EncodeToString(myXPriv[:]) != xPrivHex {
		t.Error("restored X25519 private key doesn't match")
	}
	// Verify public keys are correctly derived
	expectedEdPub := myEdPriv.Public().(ed25519.PublicKey)
	if !equalBytes(myEdPub, expectedEdPub) {
		t.Error("restored Ed25519 public key doesn't match private key")
	}
	var expectedXPub [32]byte
	curve25519.ScalarBaseMult(&expectedXPub, &myXPriv)
	if myXPub != expectedXPub {
		t.Error("restored X25519 public key doesn't match private key")
	}
	mu.Unlock()

	// Cleanup
	mu.Lock()
	myEdPriv = oldEdPriv
	myEdPub = oldEdPub
	myXPriv = oldXPriv
	myXPub = oldXPub
	myId = oldId
	mu.Unlock()
}

// TestHaloRestoreIdentity_InvalidKeys_CGO tests error handling for invalid keys
func TestHaloRestoreIdentity_InvalidKeys_CGO(t *testing.T) {
	// Invalid Ed25519 hex
	cEdPriv := C.CString("not-hex")
	cXPriv := C.CString(strings.Repeat("00", 32))
	cResult := C.HaloRestoreIdentity(cEdPriv, cXPriv)
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error for invalid ed priv hex, got %q", result)
	}

	// Wrong length Ed25519 (not 64 bytes = 128 hex chars)
	cEdPriv = C.CString("00")
	cXPriv = C.CString(strings.Repeat("00", 32))
	cResult = C.HaloRestoreIdentity(cEdPriv, cXPriv)
	result = C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error for short ed priv hex, got %q", result)
	}

	// Invalid X25519 hex
	edPrivHex := strings.Repeat("00", 128)
	cEdPriv = C.CString(edPrivHex)
	cXPriv = C.CString("not-hex")
	cResult = C.HaloRestoreIdentity(cEdPriv, cXPriv)
	result = C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error for invalid x priv hex, got %q", result)
	}

	// Wrong length X25519 (not 32 bytes = 64 hex chars)
	cEdPriv = C.CString(edPrivHex)
	cXPriv = C.CString("00")
	cResult = C.HaloRestoreIdentity(cEdPriv, cXPriv)
	result = C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error for short x priv hex, got %q", result)
	}
}

// TestHaloRestoreIdentity_RoundTrip_CGO tests generate -> export -> restore round trip via CGO
func TestHaloRestoreIdentity_RoundTrip_CGO(t *testing.T) {
	mu.Lock()
	oldEdPriv := myEdPriv
	oldEdPub := myEdPub
	oldXPriv := myXPriv
	oldXPub := myXPub
	oldId := myId
	mu.Unlock()

	// Generate
	cGenResult := C.HaloGenerateIdentity()
	genResult := C.GoString(cGenResult)
	C.free(unsafe.Pointer(cGenResult))

	if strings.HasPrefix(genResult, "error:") {
		t.Fatalf("generate failed: %s", genResult)
	}

	// Export
	cEdPrivResult := C.HaloMyEdPrivkey()
	edPrivHex := C.GoString(cEdPrivResult)
	C.free(unsafe.Pointer(cEdPrivResult))

	cXPrivResult := C.HaloMyXPrivkey()
	xPrivHex := C.GoString(cXPrivResult)
	C.free(unsafe.Pointer(cXPrivResult))

	if edPrivHex == "" {
		t.Fatal("Ed25519 private key export returned empty")
	}
	if xPrivHex == "" {
		t.Fatal("X25519 private key export returned empty")
	}

	// Clear identity
	mu.Lock()
	myEdPriv = nil
	myEdPub = nil
	myXPriv = [32]byte{}
	myXPub = [32]byte{}
	myId = ""
	mu.Unlock()

	// Restore
	cEdPriv := C.CString(edPrivHex)
	cXPriv := C.CString(xPrivHex)
	cRestoreResult := C.HaloRestoreIdentity(cEdPriv, cXPriv)
	restoreResult := C.GoString(cRestoreResult)
	C.free(unsafe.Pointer(cRestoreResult))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if strings.HasPrefix(restoreResult, "error:") {
		t.Fatalf("restore failed: %s", restoreResult)
	}

	if restoreResult != genResult {
		t.Errorf("round-trip failed: generated %q, restored %q", genResult, restoreResult)
	}

	// Verify keys match
	mu.Lock()
	if hex.EncodeToString(myEdPriv) != edPrivHex {
		t.Error("Ed25519 private key mismatch after round-trip")
	}
	if hex.EncodeToString(myXPriv[:]) != xPrivHex {
		t.Error("X25519 private key mismatch after round-trip")
	}
	mu.Unlock()

	// Cleanup
	mu.Lock()
	myEdPriv = oldEdPriv
	myEdPub = oldEdPub
	myXPriv = oldXPriv
	myXPub = oldXPub
	myId = oldId
	mu.Unlock()
}

// TestHaloMyEdPrivkey_CGO tests the exported HaloMyEdPrivkey function via CGO
func TestHaloMyEdPrivkey_CGO(t *testing.T) {
	mu.Lock()
	oldEdPriv := myEdPriv
	oldEdPub := myEdPub
	mu.Unlock()

	// Test empty when no identity
	mu.Lock()
	myEdPriv = nil
	mu.Unlock()

	cResult := C.HaloMyEdPrivkey()
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))

	if result != "" {
		t.Errorf("expected empty string for nil Ed25519 private key, got %q", result)
	}

	// Generate identity and test export
	cGenResult := C.HaloGenerateIdentity()
	genResult := C.GoString(cGenResult)
	C.free(unsafe.Pointer(cGenResult))

	if strings.HasPrefix(genResult, "error:") {
		t.Fatalf("generate failed: %s", genResult)
	}

	cResult = C.HaloMyEdPrivkey()
	result = C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))

	if result == "" {
		t.Error("Ed25519 private key export returned empty after generation")
	}

	// Verify it's valid hex
	_, err := hex.DecodeString(result)
	if err != nil {
		t.Errorf("exported Ed25519 private key not valid hex: %v", err)
	}

	// Verify length (64 bytes = 128 hex chars)
	if len(result) != ed25519.PrivateKeySize*2 {
		t.Errorf("exported Ed25519 private key wrong length: %d, expected %d", len(result), ed25519.PrivateKeySize*2)
	}

	// Verify it matches the internal key
	mu.Lock()
	expected := hex.EncodeToString(myEdPriv)
	mu.Unlock()
	if result != expected {
		t.Error("exported Ed25519 private key doesn't match internal key")
	}

	// Cleanup
	mu.Lock()
	myEdPriv = oldEdPriv
	myEdPub = oldEdPub
	mu.Unlock()
}

// TestHaloMyXPrivkey_CGO tests the exported HaloMyXPrivkey function via CGO
func TestHaloMyXPrivkey_CGO(t *testing.T) {
	mu.Lock()
	oldXPriv := myXPriv
	oldXPub := myXPub
	mu.Unlock()

	// Generate identity first
	cGenResult := C.HaloGenerateIdentity()
	genResult := C.GoString(cGenResult)
	C.free(unsafe.Pointer(cGenResult))

	if strings.HasPrefix(genResult, "error:") {
		t.Fatalf("generate failed: %s", genResult)
	}

	cResult := C.HaloMyXPrivkey()
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))

	if result == "" {
		t.Error("X25519 private key export returned empty")
	}

	// Verify it's valid hex
	_, err := hex.DecodeString(result)
	if err != nil {
		t.Errorf("exported X25519 private key not valid hex: %v", err)
	}

	// Verify length (32 bytes = 64 hex chars)
	if len(result) != 64 {
		t.Errorf("exported X25519 private key wrong length: %d, expected 64", len(result))
	}

	// Verify it matches the internal key
	mu.Lock()
	expected := hex.EncodeToString(myXPriv[:])
	mu.Unlock()
	if result != expected {
		t.Error("exported X25519 private key doesn't match internal key")
	}

	// Cleanup
	mu.Lock()
	myXPriv = oldXPriv
	myXPub = oldXPub
	mu.Unlock()
}

// TestHaloMyEdPrivkey_ExportedKeysWork_CGO tests that exported Ed25519 key works for crypto
func TestHaloMyEdPrivkey_ExportedKeysWork_CGO(t *testing.T) {
	mu.Lock()
	oldEdPriv := myEdPriv
	oldEdPub := myEdPub
	oldXPriv := myXPriv
	oldXPub := myXPub
	oldId := myId
	mu.Unlock()

	cGenResult := C.HaloGenerateIdentity()
	genResult := C.GoString(cGenResult)
	C.free(unsafe.Pointer(cGenResult))

	if strings.HasPrefix(genResult, "error:") {
		t.Fatalf("generate failed: %s", genResult)
	}

	cEdPrivResult := C.HaloMyEdPrivkey()
	edPrivHex := C.GoString(cEdPrivResult)
	C.free(unsafe.Pointer(cEdPrivResult))

	cXPrivResult := C.HaloMyXPrivkey()
	xPrivHex := C.GoString(cXPrivResult)
	C.free(unsafe.Pointer(cXPrivResult))

	// Restore into new variables
	edPrivBytes, _ := hex.DecodeString(edPrivHex)
	xPrivBytes, _ := hex.DecodeString(xPrivHex)

	// Test Ed25519 signing
	edPriv := ed25519.PrivateKey(edPrivBytes)
	msg := []byte("test message")
	sig := ed25519.Sign(edPriv, msg)
	if !ed25519.Verify(edPriv.Public().(ed25519.PublicKey), msg, sig) {
		t.Error("exported Ed25519 key fails sign/verify")
	}

	// Test X25519 key agreement
	var xPriv [32]byte
	copy(xPriv[:], xPrivBytes)
	var xPub [32]byte
	curve25519.ScalarBaseMult(&xPub, &xPriv)

	// Generate another keypair for ECDH
	var otherPriv, otherPub [32]byte
	_, _ = rand.Read(otherPriv[:])
	curve25519.ScalarBaseMult(&otherPub, &otherPriv)

	var shared1, shared2 [32]byte
	curve25519.ScalarMult(&shared1, &xPriv, &otherPub)
	curve25519.ScalarMult(&shared2, &otherPriv, &xPub)

	if shared1 != shared2 {
		t.Error("exported X25519 key fails ECDH")
	}

	// Cleanup
	mu.Lock()
	myEdPriv = oldEdPriv
	myEdPub = oldEdPub
	myXPriv = oldXPriv
	myXPub = oldXPub
	myId = oldId
	mu.Unlock()
}

// TestHaloIdFromPubkey_CGO tests the exported HaloIdFromPubkey function via CGO
func TestHaloIdFromPubkey_CGO(t *testing.T) {
	pubKey := make([]byte, 32)
	if _, err := rand.Read(pubKey); err != nil {
		t.Fatal(err)
	}

	pubHex := hex.EncodeToString(pubKey)
	cPubHex := C.CString(pubHex)
	cResult := C.HaloIdFromPubkey(cPubHex)
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cPubHex))

	if strings.HasPrefix(result, "error:") {
		t.Errorf("HaloIdFromPubkey returned error: %s", result)
	}

	parts := strings.Split(result, "-")
	if len(parts) != 3 {
		t.Errorf("expected 3-word mnemonic, got %d parts: %q", len(parts), result)
	}

	// Verify it matches direct call
	expected := idFromPubkey(pubKey)
	if result != expected {
		t.Errorf("HaloIdFromPubkey mismatch: got %q, expected %q", result, expected)
	}
}

// TestHaloIdFromPubkey_InvalidHex_CGO tests error handling for invalid hex input
func TestHaloIdFromPubkey_InvalidHex_CGO(t *testing.T) {
	cPubHex := C.CString("not-valid-hex")
	cResult := C.HaloIdFromPubkey(cPubHex)
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cPubHex))

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error for invalid hex, got %q", result)
	}

	// Wrong length (not 32 bytes = 64 hex chars)
	cPubHex = C.CString("00")
	cResult = C.HaloIdFromPubkey(cPubHex)
	result = C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cPubHex))

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error for short hex, got %q", result)
	}
}

// TestHaloIdFromEdPub_CGO tests the exported HaloIdFromEdPub function via CGO
func TestHaloIdFromEdPub_CGO(t *testing.T) {
	mu.Lock()
	oldEdPriv := myEdPriv
	oldEdPub := myEdPub
	mu.Unlock()

	// Generate identity
	cGenResult := C.HaloGenerateIdentity()
	genResult := C.GoString(cGenResult)
	C.free(unsafe.Pointer(cGenResult))

	if strings.HasPrefix(genResult, "error:") {
		t.Fatalf("generate failed: %s", genResult)
	}

	mu.Lock()
	edPubHex := hex.EncodeToString(myEdPub)
	expectedId := myId
	mu.Unlock()

	cEdPubHex := C.CString(edPubHex)
	cResult := C.HaloIdFromEdPub(cEdPubHex)
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cEdPubHex))

	if strings.HasPrefix(result, "error:") {
		t.Errorf("HaloIdFromEdPub returned error: %s", result)
	}

	if result != expectedId {
		t.Errorf("HaloIdFromEdPub mismatch: got %q, expected %q", result, expectedId)
	}

	// Test with invalid hex
	cEdPubHex = C.CString("not-hex")
	cResult = C.HaloIdFromEdPub(cEdPubHex)
	result = C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cEdPubHex))

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error for invalid hex, got %q", result)
	}

	// Cleanup
	mu.Lock()
	myEdPriv = oldEdPriv
	myEdPub = oldEdPub
	mu.Unlock()
}

// TestHaloHandleCheck_CGO tests the exported HaloHandleCheck function via CGO
func TestHaloHandleCheck_CGO(t *testing.T) {
	tests := []struct {
		handle     string
		shouldPass bool
	}{
		{"alice", true},
		{"bob_123", true},
		{"user_name_123", true},
		{"a1b2c3", true},
		{"very_long_handle_name_123", false}, // 23 chars - should fail (max 20)
		{"a", false},                         // too short (min 3)
		{"ab", false},                        // too short
		{"abc", true},                        // exactly 3
		{strings.Repeat("a", 20), true},      // exactly 20
		{strings.Repeat("a", 21), false},     // too long (21)
		{"Alice", false},                     // uppercase
		{"user-name", false},                 // hyphen not allowed
		{"user.name", false},                 // dot not allowed
		{"user@name", false},                 // @ not allowed
		{"user name", false},                 // space not allowed
		{"用户", false},                      // unicode not allowed
		{"", false},                          // empty
	}

	for _, tc := range tests {
		cHandle := C.CString(tc.handle)
		cResult := C.HaloHandleCheck(cHandle)
		result := C.GoString(cResult)
		C.free(unsafe.Pointer(cResult))
		C.free(unsafe.Pointer(cHandle))

		isFree := result == "free"
		isTaken := result == "taken"
		isError := strings.HasPrefix(result, "error:")

		if tc.shouldPass {
			if isError {
				t.Errorf("handle %q should be valid but got error: %s", tc.handle, result)
			}
		} else {
			if !isError {
				t.Errorf("handle %q should be invalid but got: %s", tc.handle, result)
			}
		}
	}
}

// TestHaloIdFromPubkey_BIP39_Entropy_CGO tests that HaloIdFromPubkey uses BIP39 with 33 bits entropy
func TestHaloIdFromPubkey_BIP39_Entropy_CGO(t *testing.T) {
	wordlist := bip39.GetWordList()
	if len(wordlist) != 2048 {
		t.Fatalf("expected 2048 words in BIP39 wordlist, got %d", len(wordlist))
	}

	// Test multiple random pubkeys to ensure all words come from wordlist
	for i := 0; i < 100; i++ {
		pubKey := make([]byte, 32)
		if _, err := rand.Read(pubKey); err != nil {
			t.Fatal(err)
		}

		pubHex := hex.EncodeToString(pubKey)
		cPubHex := C.CString(pubHex)
		cResult := C.HaloIdFromPubkey(cPubHex)
		result := C.GoString(cResult)
		C.free(unsafe.Pointer(cResult))
		C.free(unsafe.Pointer(cPubHex))

		if strings.HasPrefix(result, "error:") {
			t.Errorf("unexpected error: %s", result)
			continue
		}

		parts := strings.Split(result, "-")
		if len(parts) != 3 {
			t.Errorf("expected 3 words, got %d: %q", len(parts), result)
			continue
		}

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
}

// TestHaloIdFromPubkey_SHA256_Derivation_CGO tests that HaloIdFromPubkey derives ID from SHA256
func TestHaloIdFromPubkey_SHA256_Derivation_CGO(t *testing.T) {
	pubKey := make([]byte, 32)
	rand.Read(pubKey)

	// Compute SHA256
	hash := sha256.Sum256(pubKey)

	// The idFromPubkey uses first 5 bytes of SHA256 as 40-bit integer
	bits := uint64(hash[0])<<32 | uint64(hash[1])<<24 | uint64(hash[2])<<16 | uint64(hash[3])<<8 | uint64(hash[4])

	wordlist := bip39.GetWordList()
	w1 := wordlist[(bits>>22)&0x7FF]
	w2 := wordlist[(bits>>11)&0x7FF]
	w3 := wordlist[bits&0x7FF]
	expected := fmt.Sprintf("%s-%s-%s", w1, w2, w3)

	pubHex := hex.EncodeToString(pubKey)
	cPubHex := C.CString(pubHex)
	cResult := C.HaloIdFromPubkey(cPubHex)
	result := C.GoString(cResult)
	C.free(unsafe.Pointer(cResult))
	C.free(unsafe.Pointer(cPubHex))

	if result != expected {
		t.Errorf("HaloIdFromPubkey doesn't match manual computation: got %q, expected %q", result, expected)
	}
}

// TestIdentityIsolation_CGO tests that identities are properly isolated
func TestIdentityIsolation_CGO(t *testing.T) {
	mu.Lock()
	oldEdPriv := myEdPriv
	oldEdPub := myEdPub
	oldXPriv := myXPriv
	oldXPub := myXPub
	oldId := myId
	mu.Unlock()

	// Generate first identity
	cGen1 := C.HaloGenerateIdentity()
	id1 := C.GoString(cGen1)
	C.free(unsafe.Pointer(cGen1))

	cEdPriv1 := C.HaloMyEdPrivkey()
	edPriv1 := C.GoString(cEdPriv1)
	C.free(unsafe.Pointer(cEdPriv1))

	cXPriv1 := C.HaloMyXPrivkey()
	xPriv1 := C.GoString(cXPriv1)
	C.free(unsafe.Pointer(cXPriv1))

	// Generate second identity
	cGen2 := C.HaloGenerateIdentity()
	id2 := C.GoString(cGen2)
	C.free(unsafe.Pointer(cGen2))

	cEdPriv2 := C.HaloMyEdPrivkey()
	edPriv2 := C.GoString(cEdPriv2)
	C.free(unsafe.Pointer(cEdPriv2))

	cXPriv2 := C.HaloMyXPrivkey()
	xPriv2 := C.GoString(cXPriv2)
	C.free(unsafe.Pointer(cXPriv2))

	// They should be different
	if id1 == id2 {
		t.Error("two generated identities are the same")
	}
	if edPriv1 == edPriv2 {
		t.Error("two generated Ed25519 private keys are the same")
	}
	if xPriv1 == xPriv2 {
		t.Error("two generated X25519 private keys are the same")
	}

	// Restore first identity
	cEdPriv := C.CString(edPriv1)
	cXPriv := C.CString(xPriv1)
	cRestore := C.HaloRestoreIdentity(cEdPriv, cXPriv)
	restoreResult := C.GoString(cRestore)
	C.free(unsafe.Pointer(cRestore))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if restoreResult != id1 {
		t.Errorf("restore of first identity failed: got %q, expected %q", restoreResult, id1)
	}

	// Restore second identity
	cEdPriv = C.CString(edPriv2)
	cXPriv = C.CString(xPriv2)
	cRestore = C.HaloRestoreIdentity(cEdPriv, cXPriv)
	restoreResult = C.GoString(cRestore)
	C.free(unsafe.Pointer(cRestore))
	C.free(unsafe.Pointer(cEdPriv))
	C.free(unsafe.Pointer(cXPriv))

	if restoreResult != id2 {
		t.Errorf("restore of second identity failed: got %q, expected %q", restoreResult, id2)
	}

	// Cleanup
	mu.Lock()
	myEdPriv = oldEdPriv
	myEdPub = oldEdPub
	myXPriv = oldXPriv
	myXPub = oldXPub
	myId = oldId
	mu.Unlock()
}

func equalBytes(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
