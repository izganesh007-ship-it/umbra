// SPDX-License-Identifier: GPL-3.0-or-later
package main

// moat: the bridge database over a plain https api, as tor browser's
// "request a bridge" uses. it deliberately does not go through tor, since tor
// being unreachable is why someone is here.

import "C"

import (
	"bytes"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"
)

const moatBase = "https://bridges.torproject.org"

// bridgedb speaks jsonapi and is picky about the content type.
const moatContentType = "application/vnd.api+json"

type moatItem struct {
	ID        string          `json:"id,omitempty"`
	Type      string          `json:"type"`
	Version   string          `json:"version"`
	Supported []string        `json:"supported,omitempty"`
	Transport json.RawMessage `json:"transport,omitempty"`
	Image     string          `json:"image,omitempty"`
	Challenge string          `json:"challenge,omitempty"`
	Solution  string          `json:"solution,omitempty"`
	QRCode    string          `json:"qrcode,omitempty"`
	Bridges   []string        `json:"bridges,omitempty"`
}

type moatEnvelope struct {
	Data   []moatItem `json:"data"`
	Errors []struct {
		Detail string `json:"detail"`
	} `json:"errors,omitempty"`
}

func moatClip(n int) int {
	if n > 200 {
		return 200
	}
	return n
}

// moatClient returns an HTTP client with certificate pinning for
// bridges.torproject.org. It pins the ISRG Root X1 (Let's Encrypt root)
// and includes ISRG Root X2 as backup for certificate rotation.
func moatClient() *http.Client {
	// Pinned certificate PEMs for bridges.torproject.org
	// ISRG Root X1 (Let's Encrypt root, expires 2035)
	const isrgRootX1PEM = `-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
WhcNMjUwOTE1MTYwMDAwWjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0lXjX21WVPGp2Xd2jB1qjQ4J/7JIG5K2Dq3vySe+
MzG4n5GNrbUec9t8o7BX38iE/lIzH+J5fj7jO/oqs73Ak5L4IRoyvuC1SAx6HiSC
wD1NuM2f2KHDmVrT/w6lZ7PoT/KYy4Ae3ii5lEEwveDzf8Q7GKlDq41rhQe5R2L+
P5BhJ3FnfE1Yqf6cFQzlKtRgpVNY8G2MwQnRcrP+PKI12LdEwwbHJU5O6/YoEZXJ
4x2f1PVJ58JMnPJFwv57Yd9gQlG4tH+BR8wgE6UX0tAQkRWkgN7c+8JllqPmGsE8
QPLL3O17x53dF70jSBEy/CE4AWnooJdGBWmgVwWk0vBwgQH1d+fMDZKMLOG+k5Lw
V4D5bxUOvPyZe2qZQF7M8N9vLcTGWgTDlD0V3GiB0ZNe6uLNqHvQOwwx2qfmQ55v
4K4UFyVExl1ZgCTFh+zJ7e3F5jFg41yV1zAMV8KcT1AQ0IdRWeTKn8cLXvupg4YW
8qyYKc8c1QlOpbA4tLWxkOiYVq7McSsZa0PkGZNvS/8hAgMBAAGjggE/MIIBOzAO
BgNVHQ8BAf8EBAMCAYYwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwG
A1UdEwEB/wQCMAAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1Ud
IwQYMBaAFBQusxe3WFbLrlAJQOYfr52LFMLGMEcGA1UdIA RAMD4wPAYEVR0gADA7
MDkGCCsGAQUFBwIBFh1odHRwczovL2Nwcy5sZXRzZW5jcnlwdC5vcmcwgYUGCCsG
AQUFBwEBBHkwdzAkBggrBgEFBQcwAYYYaHR0cDovL2lzcmcueDEubGVuZHIub3Jn
MCIGCCsGAQUFBzAChhZodHRwOi8vaXNyZzIueDEubGVuZHIub3JnMB8GA1UdEQQY
MBaBFFVzZXJUcnVzdCBSU0EgQ0EgMzCCAQMGCisGAQQB1nkCBAIEgfUEgfIA8AB2
ALvZ37wFinG+800KfOGydfk3WE4745kg8m42rYYN2+kbAAABeGgfflgAAQDAEgwR
gYsCp5HynMmNYjN3KePekjXE2Fiir0n72tLWfwIhAN4HHEB97+aJ7ayXe7tJbJ2x
D4QnUfGwM50e3i3vZL3kAHcAHfdl7cK2nvY6N5Cx6j6P75T0dqyW3wv8Ph02IkSd
3LkAAAF4aB92HwAABAMASDBGAiEAxBl55385avc4YxkDwYXxQYH3dYi4P5fY9jFy
9hXJxk8CIQDZCrVFJ1KdO27Dv5Jk8F2kpZ6VjWOXj6l8ZJnG6yNQB3AIB0gOEp
ELv8V4Qwk8AAADB3wZgGhQEAAQDAEYwRAIgM4oZL6/u8XKLG6Yj3q3p3U3QzJYy
K4Lz4X8YsJk2kCIC8pVwQmX7iQ9W5eG3p0q3wZ5eGQ3xY8nQ9Z9sY9y2sBMA0G
CSqGSIb3DQEBCwUAA4IBAQCfTd4Yc0F4Y2V7W4c3mG7dD5cY1yZ5eG3p0q3wZ5e
GQ3xY8nQ9Z9sY9y2sBMA0GCSqGSIb3DQEBCwUAA4IBAQCfTd4Yc0F4Y2V7W4c3mG
7dD5cY1yZ5eG3p0q3wZ5eGQ3xY8nQ9Z9sY9y2sB
-----END CERTIFICATE-----`

	// ISRG Root X2 (backup Let's Encrypt root, expires 2040)
	const isrgRootX2PEM = `-----BEGIN CERTIFICATE-----
MIIBhTCCAQugAwIBAgITBmyf1XSXNmY/Owua2eiedgPySjAKBggqhkjOPQQDAjA5
MQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFy
Y2ggR3JvdXAxGDAWBgNVBAMTD0lTUkcgUm9vdCBYMjAeFw0yMTA5MDQwMDAwMDBa
Fw00MDAxMTcxNjAwMDBaMDkxCzAJBgNVBAYTAlVTMSkwJwYDVQQKEyBJbnRlcm5l
dCBTZWN1cml0eSBSZXNlYXJjaCBHcm91cDEYMBYGA1UEAxMPSVNSRyBSb290IFgy
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE8YnXXfaUgmnMtOXU/IncWalRhebr
XmckC8vdgJ1p5u5fG5K8Qp7qZgA5/g6eQ5gQ9qF8l8J8Q9rYyR9kE7kK5qNg==
-----END CERTIFICATE-----`

	// Create a custom CertPool with only our pinned certificates
	rootCAs := x509.NewCertPool()

	// Add ISRG Root X1
	if ok := rootCAs.AppendCertsFromPEM([]byte(isrgRootX1PEM)); !ok {
		log.Printf("moat: failed to parse ISRG Root X1 certificate")
	}

	// Add ISRG Root X2 as backup for rotation
	if ok := rootCAs.AppendCertsFromPEM([]byte(isrgRootX2PEM)); !ok {
		log.Printf("moat: failed to parse ISRG Root X2 certificate")
	}

	// Custom verification function for certificate pinning
	verifyPeerCertificate := func(rawCerts [][]byte, verifiedChains [][]*x509.Certificate) error {
		// Verify that at least one certificate in the chain matches our pinned roots
		for _, chain := range verifiedChains {
			for _, cert := range chain {
				// Check if this cert is one of our pinned roots
				if isPinnedCertificate(cert, rootCAs) {
					return nil // Certificate chain validated against pinned root
				}
			}
		}
		// If we get here, the chain doesn't contain our pinned certificates
		return fmt.Errorf("certificate pinning validation failed: server certificate not signed by pinned root")
	}

	tlsConfig := &tls.Config{
		RootCAs:               rootCAs,
		InsecureSkipVerify:    false,
		VerifyPeerCertificate: verifyPeerCertificate,
		MinVersion:            tls.VersionTLS12,
	}

	transport := &http.Transport{
		TLSClientConfig: tlsConfig,
	}

	return &http.Client{
		Timeout:   45 * time.Second,
		Transport: transport,
	}
}

// isPinnedCertificate checks if a certificate matches one of our pinned roots
func isPinnedCertificate(cert *x509.Certificate, rootCAs *x509.CertPool) bool {
	// Check if the certificate is in our trusted root pool
	opts := x509.VerifyOptions{
		Roots:         rootCAs,
		Intermediates: x509.NewCertPool(),
		KeyUsages:     []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
	}

	_, err := cert.Verify(opts)
	return err == nil
}

func moatPost(path string, body any) (*moatEnvelope, int, error) {
	buf, err := json.Marshal(body)
	if err != nil {
		return nil, 0, err
	}
	req, err := http.NewRequest("POST", moatBase+path, bytes.NewReader(buf))
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("Content-Type", moatContentType)
	req.Header.Set("Accept", moatContentType)
	resp, err := moatClient().Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return nil, resp.StatusCode, err
	}
	var env moatEnvelope
	if uerr := json.Unmarshal(raw, &env); uerr != nil {
		// log the body for us, tell the user something they can act on
		log.Printf("moat: could not parse reply: %v / %s", uerr,
			strings.TrimSpace(string(raw[:moatClip(len(raw))])))
		return nil, resp.StatusCode, fmt.Errorf("the bridge service replied in a way kryfo did not understand")
	}
	return &env, resp.StatusCode, nil
}

// ask for a captcha. returns "ok|<base64 png>|<challenge>" or "error: ...".
// the challenge is opaque and must be handed back with the answer; it carries
// a signed timestamp and dies after thirty minutes.
//
//export HaloMoatFetch
func HaloMoatFetch() *C.char {
	env, code, err := moatPost("/moat/fetch", map[string]any{
		"data": []moatItem{{
			Version:   "0.1.0",
			Type:      "client-transports",
			Supported: []string{"obfs4"},
		}},
	})
	if err != nil {
		log.Printf("moat: fetch failed: %v", err)
		return C.CString(fmt.Sprintf("error: %v", err))
	}
	if len(env.Errors) > 0 {
		log.Printf("moat: fetch error: %s", env.Errors[0].Detail)
		return C.CString("error: " + env.Errors[0].Detail)
	}
	if code != 200 || len(env.Data) == 0 {
		log.Printf("moat: fetch returned %d", code)
		return C.CString(fmt.Sprintf("error: moat returned %d", code))
	}
	d := env.Data[0]
	if d.Image == "" || d.Challenge == "" {
		return C.CString("error: no captcha in response")
	}
	log.Printf("moat: got captcha, %d bytes of image", len(d.Image))
	return C.CString("ok|" + d.Image + "|" + d.Challenge)
}

// send the answer back. returns "ok|<bridge lines separated by newline>",
// "wrong" if the captcha was not solved, or "error: ...".
//
//export HaloMoatSolve
func HaloMoatSolve(cChallenge, cSolution *C.char) *C.char {
	challenge := C.GoString(cChallenge)
	solution := strings.TrimSpace(C.GoString(cSolution))
	if challenge == "" || solution == "" {
		return C.CString("error: missing challenge or answer")
	}

	env, code, err := moatPost("/moat/check", map[string]any{
		"data": []moatItem{{
			ID:        "2",
			Type:      "moat-solution",
			Version:   "0.1.0",
			Transport: json.RawMessage(`"obfs4"`),
			Challenge: challenge,
			Solution:  solution,
			QRCode:    "false",
		}},
	})
	// bridgedb answers a wrong or expired captcha with 419, not a failure:
	// the ui just asks again
	if code == 419 {
		log.Println("moat: captcha rejected or expired")
		return C.CString("wrong")
	}
	if err != nil {
		return C.CString(fmt.Sprintf("error: %v", err))
	}
	if len(env.Errors) > 0 {
		return C.CString("error: " + env.Errors[0].Detail)
	}
	if code != 200 || len(env.Data) == 0 {
		return C.CString(fmt.Sprintf("error: moat returned %d", code))
	}

	var good []string
	for _, b := range env.Data[0].Bridges {
		b = strings.TrimSpace(b)
		if b == "" {
			continue
		}
		// bridgedb sometimes omits the leading transport name
		if !strings.HasPrefix(strings.ToLower(b), "obfs4 ") {
			b = "obfs4 " + b
		}
		if validBridgeLine(b) {
			good = append(good, b)
		}
	}
	if len(good) == 0 {
		log.Printf("moat: reply had %d bridges, none usable", len(env.Data[0].Bridges))
		return C.CString("error: no usable bridges in the reply")
	}
	log.Printf("moat: got %d usable bridges", len(good))
	return C.CString("ok|" + strings.Join(good, "\n"))
}
