# Phase 4: End-to-End Testing & Release Preparation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete end-to-end testing of the Umbra Flutter app with the new design system, verify all user flows work correctly, and prepare signed release artifacts for distribution.

**Architecture:** The app uses Material 3 with custom Umbra design system tokens. All screens now use the new design system (ChatListScreen, ChatScreen_new, SettingsScreen_new, ToolsScreen_new, OnboardingScreen_new, NewGroupScreen_new, GroupChatScreen_new, GroupInfoScreen_new). Theme switching between Sol (light) and Umbra (dark) uses a 600ms radial eclipse wipe animation. CI runs on GitHub Actions with Flutter 3.41.7.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, Material 3, libsignal-protocol-dart, Tor (via native library), 15 locales including RTL.

## Global Constraints

- Flutter version: 3.41.7 (stable)
- Dart SDK: ^3.11.5
- GPL-3.0 license with Kryfo attribution preserved
- 15 locales including RTL (fa, ar) via existing l10n
- Material 3 adaptive; custom only where Umbra identity requires
- Reduced motion: all durations -> 0ms, springs -> linear
- Design tokens MUST match tokens.css exactly:
  - Sol accent: #4C2F9E (Indigo) | Umbra accent: #F59E0B (Corona Amber)
  - Bubble radius: 18px, tail: 20x18px, max-width: 75%
  - Input bar: 56px frosted, backdrop-filter saturate(180%) blur(20px)
  - Nav large: 96px, title 28px Fraunces 700 | collapsed: 56px, title 20px Inter 600
  - Motion: 150/200/300ms, spring cubic-bezier(0.34, 1.56, 0.64, 1)
- No local toolchain - CI builds in GitHub Actions only (500MB disk space limit)

---

### Task 1: Verify CI Pipeline Passes

**Files:**
- Check: `.github/workflows/ci.yml`
- Test: `test/tokens_test.dart`

**Interfaces:**
- Consumes: All previous Phase 2-3 fixes
- Produces: Green CI badge

- [ ] **Step 1: Check GitHub Actions CI status**

```bash
# Check CI status at:
# https://github.com/izganesh007-ship-it/umbra/actions
```

Expected: All jobs (analyze, test, build-android, build-ios) should pass

- [ ] **Step 2: If CI fails, analyze failure logs and fix**

Common failures to check:
- `flutter analyze` - static analysis errors
- `flutter test` - token test failures
- `flutter build apk` - Android build errors
- `flutter build ios` - iOS build errors (macOS runner)

- [ ] **Step 3: Commit any CI fixes**

```bash
git add .github/workflows/ci.yml lib/ test/
git commit -m "ci: fix CI pipeline for Phase 4 release"
git push origin fresh-start
```

---

### Task 2: End-to-End User Flow Testing (via CI)

**Files:**
- Test: Integration test file (to be created)
- Verify: All screen navigation flows

**Interfaces:**
- Consumes: All implemented screens
- Produces: Verified user flows

- [ ] **Step 1: Create integration test for core user flows**

Create `integration_test/app_flow_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:umbra/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Core User Flows', () {
    testWidgets('App launches and shows onboarding', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      // Verify onboarding screen appears
      expect(find.text('Umbra'), findsOneWidget);
    });

    testWidgets('Theme toggle works', (tester) async {
      // Test theme switching
    });

    testWidgets('Navigate to settings', (tester) async {
      // Test settings navigation
    });

    testWidgets('Navigate to tools', (tester) async {
      // Test tools navigation
    });

    testWidgets('Create new group', (tester) async {
      // Test group creation flow
    });
  });
}
```

- [ ] **Step 2: Add integration_test dependency to pubspec.yaml**

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

- [ ] **Step 3: Configure CI to run integration tests**

Update `.github/workflows/ci.yml` to add integration test job:

```yaml
integration-test:
  name: Integration Test
  runs-on: ubuntu-latest
  needs: [analyze, test]
  steps:
    - uses: actions/checkout@v4
    - uses: flutter-actions/setup-flutter@v4
      with:
        channel: stable
        flutter-version: 3.41.7
        cache: true
    - name: Get dependencies
      run: flutter pub get
      working-directory: ./umbra/mobile
    - name: Run integration tests
      run: flutter test integration_test/app_flow_test.dart
      working-directory: ./umbra/mobile
```

- [ ] **Step 4: Run CI and verify integration tests pass**

```bash
git push origin fresh-start
# Check GitHub Actions
```

---

### Task 3: Android Release Build Verification

**Files:**
- Check: `android/app/build.gradle.kts` (or build.gradle)
- Check: `pubspec.yaml` (version)
- Build: `flutter build apk --release` / `flutter build appbundle --release`

**Interfaces:**
- Consumes: Complete app with all screens
- Produces: Signed APK/AAB for Play Store

- [ ] **Step 1: Verify version in pubspec.yaml**

```bash
# Check current version
grep "version:" pubspec.yaml
# Should be something like: version: 0.3.2+18
```

- [ ] **Step 2: Bump version for release**

```bash
# Update pubspec.yaml version (e.g., 0.3.3+19)
sed -i 's/version: 0.3.2+18/version: 0.3.3+19/' pubspec.yaml
```

- [ ] **Step 3: Verify Android signing config**

Check `android/app/build.gradle.kts` has signing config for release.

- [ ] **Step 4: Run Android release build in CI**

```yaml
build-android-release:
  name: Build Android Release
  runs-on: ubuntu-latest
  needs: [analyze, test, integration-test]
  steps:
    - uses: actions/checkout@v4
    - uses: flutter-actions/setup-flutter@v4
      with:
        channel: stable
        flutter-version: 3.41.7
        cache: true
    - name: Get dependencies
      run: flutter pub get
      working-directory: ./umbra/mobile
    - name: Build APK (release)
      run: flutter build apk --release
      working-directory: ./umbra/mobile
    - name: Build App Bundle (release)
      run: flutter build appbundle --release
      working-directory: ./umbra/mobile
    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: android-release
        path: |
          umbra/mobile/build/app/outputs/flutter-apk/app-release.apk
          umbra/mobile/build/app/outputs/bundle/release/app-release.aab
```

- [ ] **Step 5: Commit version bump and CI update**

```bash
git add pubspec.yaml .github/workflows/ci.yml
git commit -m "chore: bump version to 0.3.3+19 for release"
git push origin fresh-start
```

---

### Task 4: iOS Release Build Verification (if macOS runner available)

**Files:**
- Check: `ios/Runner.xcodeproj` / `Runner.xcworkspace`
- Check: `pubspec.yaml` (version)
- Build: `flutter build ios --release --no-codesign`

**Interfaces:**
- Consumes: Complete app with all screens
- Produces: iOS release archive for App Store

- [ ] **Step 1: Verify iOS build config**

Check `ios/Runner.xcodeproj/project.pbxproj` for release config.

- [ ] **Step 2: Add iOS release build to CI**

```yaml
build-ios-release:
  name: Build iOS Release
  runs-on: macos-latest
  needs: [analyze, test, integration-test]
  steps:
    - uses: actions/checkout@v4
    - uses: flutter-actions/setup-flutter@v4
      with:
        channel: stable
        flutter-version: 3.41.7
        cache: true
    - name: Get dependencies
      run: flutter pub get
      working-directory: ./umbra/mobile
    - name: Build iOS (release)
      run: flutter build ios --release --no-codesign
      working-directory: ./umbra/mobile
    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: ios-release
        path: umbra/mobile/build/ios/iphoneos/Runner.app
```

- [ ] **Step 3: Run CI and verify iOS build passes**

```bash
git push origin fresh-start
```

---

### Task 5: Visual Regression Testing (Design Token Ve
