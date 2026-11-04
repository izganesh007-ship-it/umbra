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
	cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
	WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
	ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
	MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
	h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
	0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
	A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
	T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
	B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
	B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
	KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
	OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
	jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
	qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
	rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
	HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
	hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
	ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
	3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
	NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
	ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
	TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
	jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
	yi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
	4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
	mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
	emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
	-----END CERTIFICATE-----`

	// ISRG Root X2 (backup Let's Encrypt root, expires 2040)
	const isrgRootX2PEM = `-----BEGIN CERTIFICATE-----
	MIICGzCCAaGgAwIBAgIQQdKd0XLq7qeAwSxs6S+HUjAKBggqhkjOPQQDAzBPMQsw
	CQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFyY2gg
	R3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBYMjAeFw0yMDA5MDQwMDAwMDBaFw00
	MDA5MTcxNjAwMDBaME8xCzAJBgNVBAYTAlVTMSkwJwYDVQQKEyBJbnRlcm5ldCBT
	ZWN1cml0eSBSZXNlYXJjaCBHcm91cDEVMBMGA1UEAxMMSVNSRyBSb290IFgyMHYw
	EAYHKoZIzj0CAQYFK4EEACIDYgAEzZvVn4CDCuwJSvMWSj5cz3es3mcFDR0HttwW
	+1qLFNvicWDEukWVEYmO6gbf9yoWHKS5xcUy4APgHoIYOIvXRdgKam7mAHf7AlF9
	ItgKbppbd9/w+kHsOdx1ymgHDB/qo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0T
	AQH/BAUwAwEB/zAdBgNVHQ4EFgQUfEKWrt5LSDv6kviejM9ti6lyN5UwCgYIKoZI
	zj0EAwMDaAAwZQIwe3lORlCEwkSHRhtFcP9Ymd70/aTSVaYgLXTWNLxBo1BfASdW
	tL4ndQavEi51mI38AjEAi/V3bNTIZargCyzuFJ0nN6T5U6VR5CmD1/iQMVtCnwr1
	/q4AaOeMSQ+2b1tbFfLn
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
