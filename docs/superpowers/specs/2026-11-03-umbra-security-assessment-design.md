# Umbra Security Assessment Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Comprehensive security assessment of Umbra messenger from a hacker's perspective - find vulnerabilities across all layers, create PoC exploits, apply fixes, and add regression tests with CI integration.

**Architecture:** Layer-by-layer deep dive (Approach 1) targeting 7 architectural layers: Crypto, Identity, Network, Pairing, Storage, FFI Boundary, DoS/Resilience. Each layer produces: attack vector analysis, PoC test, fix/patch, regression test, CI verification. Followed by cross-layer attack path validation and CI/CD security hardening.

**Tech Stack:** Go 1.23+ engine (bridge.go, nostr.go, moat.go, paircode.go, handle.go, route.go, nip17.go), Flutter/Dart mobile app, GitHub Actions CI, Tor + Nostr transport, Signal double ratchet + NIP-44/59 crypto, SQLCipher storage.

## Global Constraints

- No local toolchain - CI only (GitHub Actions ubuntu-latest)
- GPL-3.0 with Kryfo attribution preserved
- 15 locales including RTL (fa, ar) via existing l10n
- Material 3 adaptive; custom only where Umbra identity requires
- Reduced motion: all durations to 0ms, springs to linear
- Engine FFI is C ABI - symbols in bridge.go are frozen
- Pre-alpha, unaudited - THREAT_MODEL.md explicitly warns

---

## Layer 1: Crypto Layer Assessment

### Attack Vectors

| Vector | Location | Risk | Test Approach |
|--------|----------|------|---------------|
| **X25519 key derivation** | `bridge.go:deriveSharedKey` | Key compromise if nonce reused | Test constant-time, input validation |
| **AES-GCM nonce reuse** | `bridge.go:HaloEncryptFor/DecryptFrom` | Plaintext recovery | Fuzz nonce generation, test 96-bit IV |
| **NIP-44 conversation key** | `nip17.go:nip44.GenerateConversationKey` | Key derivation flaw | Test with known vectors, edge cases |
| **NIP-59 gift wrap/unwrap** | `nip17.go:nip59.GiftWrap/Unwrap` | Parsing vulnerabilities | Fuzz malformed events |
| **scrypt parameters** | `bridge.go:HaloEncryptBackup` | Weak KDF (32768/8/1) | Verify parameters, test timing |
| **Ed25519 key generation** | `bridge.go:HaloGenerateIdentity` | Entropy quality | Test randomness, seed uniqueness |

### Files to Create/Modify
- **Test:** `engine/crypto_security_test.go` (new)
- **Fix:** `engine/bridge.go`, `engine/nip17.go` (if needed)
- **CI:** Add to `.github/workflows/ci.yml` test step

---

## Layer 2: Identity Layer Assessment

### Attack Vectors

| Vector | Location | Risk | Test Approach |
|--------|----------|------|---------------|
| **3-word BIP39 entropy** | `bridge.go:idFromPubkey` | ~33 bits entropy | Brute-force test, collision test |
| **Identity restoration** | `bridge.go:HaloRestoreIdentity` | Key injection | Test malformed hex, length validation |
| **Private key export** | `bridge.go:HaloMyEdPrivkey/XPrivkey` | Memory exposure | Test zeroization, access control |
| **Handle registration** | `handle.go:HaloHandleClaim` | Impersonation | Test signature verification, replay |

### Files to Create/Modify
- **Test:** `engine/identity_security_test.go` (new)
- **Fix:** `engine/bridge.go`, `engine/handle.go` (if needed)

---

## Layer 3: Network Layer Assessment

### Attack Vectors

| Vector | Location | Risk | Test Approach |
|--------|----------|------|---------------|
| **Bridge fetching (cleartext HTTPS!)** | `moat.go:moatPost` | MITM, bridge injection | Test TLS cert pinning, MITM simulation |
| **Tor HS descriptor enumeration** | `bridge.go:watchHSDirUpload` | Service discovery | Test descriptor privacy |
| **Nostr relay metadata** | `nostr.go:nostrSubscribeRunnerFn` | Traffic analysis | Test padding, timing |
| **Onion key generation** | `bridge.go:startListener` | Key reuse | Test persistence, rotation |

### Files to Create/Modify
- **Test:** `engine/network_security_test.go` (new)
- **Fix:** `engine/moat.go` (add cert pinning), `engine/bridge.go`

---

## Layer 4: Pairing Layer Assessment

### Attack Vectors

| Vector | Location | Risk | Test Approach |
|--------|----------|------|---------------|
| **6-digit pair code (1M space)** | `paircode.go:pairCodeKeys` | Online brute force | Rate limiting test, enum simulation |
| **NIP-44 key derivation from code** | `paircode.go:pairCodeKeys` | Weak entropy | Test HKDF expansion, collision |
| **Invite encryption** | `paircode.go:HaloPairCodePublish` | Payload exposure | Test encryption, expiration |

### Files to Create/Modify
- **Test:** `engine/pairing_security_test.go` (new)
- **Fix:** `engine/paircode.go` (add rate limiting, proof-of-work)

---

## Layer 5: Storage Layer Assessment

### Attack Vectors

| Vector | Location | Risk | Test Approach |
|--------|----------|------|---------------|
| **SQLCipher key derivation** | Dart side (not in engine) | Weak passphrase | Verify KDF, test brute force |
| **Flutter Secure Storage** | Dart side | Key extraction | Test platform security |
| **Backup encryption (scrypt)** | `bridge.go:HaloEncryptBackup` | Passphrase cracking | Test scrypt params, timing |
| **Streamed backup (v2)** | `bridge.go:HaloSealChunk/OpenChunk` | Chunk manipulation | Test nonce reuse, AEAD |

### Files to Create/Modify
- **Test:** `engine/storage_security_test.go` (new), Dart tests
- **Fix:** `engine/bridge.go` (if needed)

---

## Layer 6: FFI Boundary Assessment

### Attack Vectors

| Vector | Location | Risk | Test Approach |
|--------|----------|------|---------------|
| **C string handling** | All `Halo*` exports | Buffer overflow, UAF | Fuzz string inputs, test lengths |
| **Error string propagation** | All exports return `*C.char` | Info leak, format string | Test error paths, sanitize |
| **Memory ownership** | `bridge.go`, `nostr.go` | Leaks, double-free | Test with ASAN, valgrind |
| **Concurrent FFI calls** | Global mutex `mu` in bridge.go | Race conditions | Stress test concurrent access |

### Files to Create/Modify
- **Test:** `engine/ffi_security_test.go` (new), run with `-race`
- **Fix:** `engine/bridge.go`, `engine/nostr.go` (if needed)

---

## Layer 7: DoS/Resilience Assessment

### Attack Vectors

| Vector | Location | Risk | Test Approach |
|--------|----------|------|---------------|
| **Tor bootstrap stall** | `route.go:routeNeedsRescue` | Permanent stall | Test bootstrap timeout, rescue logic |
| **Relay connection exhaustion** | `nostr.go:relayFailed/Backoff` | Resource exhaustion | Test max connections, backoff |
| **Proof-of-work bypass** | Dart side (not in engine) | Spam | Verify PoW verification |
| **Inbox flooding** | `bridge.go:inboxPut/ShapeOK` | Memory exhaustion | Test limits, cleanup |

### Files to Create/Modify
- **Test:** `engine/dos_security_test.go` (new)
- **Fix:** `engine/route.go`, `engine/nostr.go`, `engine/bridge.go` (if needed)

---

## Cross-Layer Attack Path Validation

After all layers pass, validate chained exploits:
1. **Bridge MITM to Malicious relay to Traffic correlation**
2. **Pair code enum to First contact to Identity binding**
3. **FFI overflow to Memory corruption to Key extraction**

---

## CI/CD Security Hardening

| Hardening | Implementation |
|-----------|----------------|
| **govulncheck** | Add to CI `analyze` job |
| **gosec** | Add static analysis |
| **Fuzzing** | `go-fuzz` for parsers |
| **Race detector** | `go test -race` in CI |
| **Dependency pinning** | Verify `go.sum`, add `govulncheck` |

---

## Deliverables and Verification

### Final Deliverables
1. **Attack plan spec** - `docs/superpowers/specs/2026-11-03-umbra-security-assessment-design.md`
2. **7 test files** - One per layer in `engine/*_security_test.go`
3. **Fixes** - Commits per vulnerability found
4. **CI integration** - Updated `.github/workflows/ci.yml`
5. **Verification report** - CI run logs showing all tests pass

---

## Spec Self-Review Checklist

- [x] **Placeholder scan:** No TBD, TODO, incomplete sections
- [x] **Internal consistency:** Architecture matches l
