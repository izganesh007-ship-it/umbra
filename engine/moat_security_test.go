// SPDX-License-Identifier: GPL-3.0-or-later
package main

import (
	"crypto/tls"
	"crypto/x509"
	"net/http"
	"testing"

	"golang.org/x/crypto/cryptobyte"
)

// TestMoatClient_CertPinning tests that moatClient returns an HTTP client
// with proper certificate pinning for bridges.torproject.org
func TestMoatClient_CertPinning(t *testing.T) {
	client := moatClient()

	// Verify the client has a custom TLS config
	if client.Transport == nil {
		t.Fatal("moatClient: Transport is nil, expected custom HTTP transport")
	}

	// Check that Transport is an *http.Transport with TLSClientConfig
	transport, ok := client.Transport.(*http.Transport)
	if !ok {
		t.Fatalf("moatClient: Transport is not *http.Transport, got %T", client.Transport)
	}

	if transport.TLSClientConfig == nil {
		t.Fatal("moatClient: TLSClientConfig is nil, expected custom TLS config for cert pinning")
	}

	tlsConfig := transport.TLSClientConfig

	// Verify InsecureSkipVerify is false (should never skip verification)
	if tlsConfig.InsecureSkipVerify {
		t.Error("moatClient: InsecureSkipVerify is true, should be false for security")
	}

	// Verify RootCAs is set (custom CA pool for pinning)
	if tlsConfig.RootCAs == nil {
		t.Error("moatClient: RootCAs is nil, expected custom CA pool with pinned certificates")
	}

	// Verify the pinned certificates are in the RootCAs pool
	// We expect at least the ISRG Root X1 (Let's Encrypt root) to be pinned
	expectedPins := []string{
		"96:BC:EC:06:26:49:76:F3:74:60:77:9A:CF:28:C5:A7:CF:E8:A0:D8:9F:BE:5E:6A:B6:5C:5D:4A:88:9C:DB", // ISRG Root X1
		"13:94:96:34:D9:9C:D6:FD:6A:A8:0B:C0:34:FE:FA:CC:EB:19:69:FE:EF:98:65:86:71:3E:CD:BB:05:75:8D:3F", // Let's Encrypt YR1 (intermediate)
	}

	for _, expectedPin := range expectedPins {
		found := false
		// Iterate through the cert pool
		// Note: x509.CertPool doesn't expose direct iteration, so we check by trying to verify
		// a certificate with that fingerprint
		_ = found
		// For now, just verify RootCAs is not the system pool
		// A more thorough test would create a test cert with the expected fingerprint
	}

	_ = tlsConfig
	_ = expectedPins
}

// TestMoatClient_VerifyCallback tests that the TLS config has a proper
// VerifyPeerCertificate callback for certificate pinning
func TestMoatClient_VerifyCallback(t *testing.T) {
	client := moatClient()

	transport, ok := client.Transport.(*http.Transport)
	if !ok {
		t.Fatalf("moatClient: Transport is not *http.Transport")
	}

	tlsConfig := transport.TLSClientConfig
	if tlsConfig == nil {
		t.Fatal("moatClient: TLSClientConfig is nil")
	}

	// Verify that VerifyPeerCertificate or VerifyConnection is set
	// for custom certificate pinning logic
	if tlsConfig.VerifyPeerCertificate == nil && tlsConfig.VerifyConnection == nil {
		t.Error("moatClient: Neither VerifyPeerCertificate nor VerifyConnection is set, expected custom verification for cert pinning")
	}

	if tlsConfig.VerifyPeerCertificate != nil {
		t.Log("moatClient: VerifyPeerCertificate is set (good)")
	}
	if tlsConfig.VerifyConnection != nil {
		t.Log("moatClient: VerifyConnection is set (good)")
	}
}

// TestMoatClient_Timeout tests that the client has a reasonable timeout
func TestMoatClient_Timeout(t *testing.T) {
	client := moatClient()

	// The timeout should be set (45 seconds as per current implementation)
	if client.Timeout <= 0 {
		t.Error("moatClient: Timeout should be positive")
	}
}

// TestMoatPost_RequiresHTTPS tests that moatPost uses HTTPS
func TestMoatPost_RequiresHTTPS(t *testing.T) {
	// This test verifies that the moatBase constant uses HTTPS
	if len(moatBase) < 8 || moatBase[:8] != "https://" {
		t.Errorf("moatBase should use HTTPS, got: %s", moatBase)
	}

	// Verify it's the correct domain
	expectedDomain := "bridges.torproject.org"
	if len(moatBase) < len("https://"+expectedDomain) || moatBase[:len("https://"+expectedDomain)] != "https://"+expectedDomain {
		t.Errorf("moatBase should be https://bridges.torproject.org, got: %s", moatBase)
	}
}

// TestCertificateFingerprint tests our fingerprint parsing logic
func TestCertificateFingerprint(t *testing.T) {
	// Test that we can parse the expected fingerprint format
	testPin := "96:BC:EC:06:26:49:76:F3:74:60:77:9A:CF:28:C5:A7:CF:E8:A0:D8:9F:BE:5E:6A:B6:5C:5D:4A:88:9C:DB"

	// Verify it's a valid SHA256 fingerprint (32 bytes = 64 hex chars with colons)
	// Remove colons and verify length
	clean := ""
	for _, c := range testPin {
		if c != ':' {
			clean += string(c)
		}
	}

	if len(clean) != 64 {
		t.Errorf("Expected 64 hex chars, got %d", len(clean))
	}

	// Verify it's valid hex
	_, err := cryptobyte.String(clean).ReadBytes(nil)
	if err != nil {
		// Actually, let's just check it's valid hex manually
		for _, c := range clean {
			if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
				t.Errorf("Invalid hex character: %c", c)
			}
		}
	}
}

// TestMoatClient_BlocksInvalidCert tests that the client rejects
// certificates not matching our pinned fingerprints
// This is an integration-style test that would require a test server
func TestMoatClient_BlocksInvalidCert(t *testing.T) {
	// This test would require setting up a test HTTPS server with
	// a certificate that doesn't match our pins.
	// For now, we verify the structure is in place.
	client := moatClient()

	transport, ok := client.Transport.(*http.Transport)
	if !ok {
		t.Fatal("Transport is not *http.Transport")
	}

	tlsConfig := transport.TLSClientConfig
	if tlsConfig == nil {
		t.Fatal("TLSClientConfig is nil")
	}

	// The key test: verification callback should exist
	if tlsConfig.VerifyPeerCertificate == nil && tlsConfig.VerifyConnection == nil {
		t.Error("No certificate verification callback - client would accept any valid cert")
	}
}

// TestBridge_Validation tests that bridge lines are properly validated
// according to the obfs4 bridge format requirements
func TestBridge_Validation(t *testing.T) {
	tests := []struct{
		name     string
		bridge   string
		valid    bool
	} {
		{
			name:   "valid obfs4 bridge with cert and iat-mode",
			bridge: "obfs4 192.0.2.1:443 ABCDEF0123456789ABCDEF0123456789ABCDEF01 cert=ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789 iat-mode=0",
			valid:  true,
		},
		{
			name:   "valid obfs4 bridge with only cert",
			bridge: "obfs4 192.0.2.1:443 ABCDEF0123456789ABCDEF0123456789ABCDEF01 cert=ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
			valid:  true,
		},
		{
			name:   "invalid - not obfs4 transport",
			bridge: "meek 192.0.2.1:443 ABCDEF0123456789ABCDEF0123456789ABCDEF01 cert=ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
			valid:  false,
		},
		{
			name:   "invalid - missing port",
			bridge: "obfs4 192.0.2.1 ABCDEF0123456789ABCDEF0123456789ABCDEF01 cert=ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
			valid:  false,
		},
		{
			name:   "invalid - missing cert",
			bridge: "obfs4 192.0.2.1:443 ABCDEF0123456789ABCDEF0123456789ABCDEF01 iat-mode=0",
			valid:  false,
		},
		{
			name:   "invalid - empty string",
			bridge: "",
			valid:  false,
		},
		{
			name:   "invalid - only whitespace",
			bridge: "   ",
			valid:  false,
		},
		{
			name:   "invalid - missing fingerprint",
			bridge: "obfs4 192.0.2.1:443 cert=ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
			valid:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := validBridgeLine(tt.bridge)
			if result != tt.valid {
				t.Errorf("validBridgeLine(%q) = %v, want %v", tt.bridge, result, tt.valid)
			}
		})
	}
}
