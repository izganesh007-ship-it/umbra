# Umbra 0.3.3 Release Notes

## Overview
This release introduces the complete iMessage-calibrated design system for Umbra, bringing a polished, cohesive visual identity with Sol (light) and Umbra (dark) themes, a signature radial eclipse wipe theme transition, and rebuilt core screens.

## Highlights

### 🎨 Design System
- **Exact token parity** with design mockups: colors, typography, spacing, motion, shadows
- **Sol theme** (light): Indigo accent `#4C2F9E`, warm paper `#FAFAF8`
- **Umbra theme** (dark): Corona Amber accent `#F59E0B`, true-black chrome `#0E0F12`
- **Typography**: Fraunces (display), Inter Variable (body), JetBrains Mono (timestamps)
- **Motion**: 150/200/300ms durations, spring `cubic-bezier(0.34, 1.56, 0.64, 1)`
- **Reduced motion**: Full respect for OS accessibility setting (durations → 0ms, springs → linear)

### ✨ Eclipse Wipe Theme Transition
- 600ms radial clip animation expanding from toggle origin
- Color swap at 50ms, wipe completes at 650ms
- No flash, instant perceived theme change
- Fully respects `prefers-reduced-motion`

### 🏗️ Rebuilt Screens
| Screen | Key Features |
|--------|--------------|
| **Chat List** | Large/collapsed nav bar, search, pinned chats, swipe actions, connection status pill |
| **1:1 Chat** | Bubbles with 18px radius + 20×18px tail, replies (swipe), reactions, pins, media, delivery states |
| **Onboarding** | 3-screen plain-language flow: welcome → 3-word identity → QR pairing |
| **Settings** | Appearance / Chats / Privacy & Locks / Advanced taxonomy |
| **Tools** | Photo cleaner (EXIF/metadata), QR codes, age file encryption, diagnostics |
| **Groups** | New group creation, group chat, group info with member management |

### 🧪 Quality Assurance
- 14 design token verification tests (all passing)
- Integration test suite for E2E user flows
- RTL support for Arabic/Persian (15 locales total)
- Golden test infrastructure ready

## Technical Details

### Version
- **App version**: 0.3.3+19
- **Flutter**: 3.41.7
- **Dart SDK**: ^3.11.5
- **Engine**: Go 1.25.14, Tor 0.4.9.12

### Architecture
- Theme controller singleton with `AnimatedBuilder` integration
- `UmbraTheme` inherited widget for efficient color access
- Foundation widgets in `lib/widgets/` (UmbraBubble, UmbraInputBar, UmbraNavBar, UmbraChatItem, UmbraAvatar, EclipseWipe)
- Screen implementations in `lib/screens/` (*_new.dart variants)
- Shared models in `lib/models/previews.dart` (ContactPreview, GroupPreview)

### Compatibility
- **Android**: API 23+ (armeabi-v7a, arm64-v8a, x86_64)
- **iOS**: 14+ (arm64)
- **Desktop**: Linux, macOS, Windows (via Flutter desktop)
- **Web**: Experimental support

### License
GPL-3.0-or-later — Fork of Kryfo-android, attribution preserved

## Installation

### Android
Download the signed APK from the [GitHub Release](https://github.com/izganesh007-ship-it/umbra/releases/tag/v0.3.3) or build from source:
```bash
cd mobile
flutter build apk --release --split-per-abi
```

### F-Droid
Available in the Umbra F-Droid repository (metadata: `fdroiddata/app.umbra.messenger.yml`)

### Verification
Reproducible builds via `repro/verify.sh` — see `RELEASING.md` for details.

## Known Issues
- iOS build requires macOS runner (not available in all CI environments)
- Integration tests require physical device/emulator for full validation
- Some legacy screens still reference old theme system (cleanup in progress)

## Upcoming
- v0.4.0: Stealth recents, local nicknames, quiet hours
- Store readiness: Play Console listing, F-Droid submission
- Design-is re-audit against built app

---

**Full changelog**: [CHANGELOG.md](CHANGELOG.md)  
**Source**: https://github.com/izganesh007-ship-it/umbra  
**Upstream**: https://github.com/emtee40/Kryfo-android (thank you!)