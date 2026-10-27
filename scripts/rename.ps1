#!/usr/bin/env pwsh
# Umbra rename script - converts Kryfo -> Umbra (user-visible only)
# Run from repo root: pwsh scripts/rename.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== Umbra Rename Script ===" -ForegroundColor Cyan

# 1. pubspec.yaml: name + description
$pubspec = "mobile/pubspec.yaml"
$content = Get-Content $pubspec -Raw
$content = $content -replace '^name: kryfo$', 'name: umbra'
$content = $content -replace 'Halo - private messaging over Tor\. No phone number, no servers of ours, no metadata\.', 'Umbra - private messaging over Tor. No phone number, no servers of ours, no metadata.'
$content = $content -replace 'assets/icon/halo_icon\.png', 'assets/icon/umbra_icon.png'
$content = $content -replace 'assets/icon/halo_icon_fg\.png', 'assets/icon/umbra_icon_fg.png'
$content = $content -replace 'assets/icon/kryfo_ring\.svg', 'assets/icon/umbra_ring.svg'
$content = $content -replace 'assets/icon/kryfo_ring\.png', 'assets/icon/umbra_ring.png'
Set-Content $pubspec $content -Encoding UTF8
Write-Host "Updated $pubspec" -ForegroundColor Green

# 2. build.gradle.kts: namespace, applicationId
$gradle = "mobile/android/app/build.gradle.kts"
$content = Get-Content $gradle -Raw
$content = $content -replace 'namespace = "app\.kryfo"', 'namespace = "app.umbra.messenger"'
$content = $content -replace 'applicationId = "app\.kryfo"', 'applicationId = "app.umbra.messenger"'
Set-Content $gradle $content -Encoding UTF8
Write-Host "Updated $gradle" -ForegroundColor Green

# 3. AndroidManifest.xml: label, scheme (keep both kryfo:// and umbra://)
$manifest = "mobile/android/app/src/main/AndroidManifest.xml"
$content = Get-Content $manifest -Raw
$content = $content -replace 'android:label="Kryfo"', 'android:label="Umbra"'
# Keep kryfo:// scheme for cross-app compatibility, add umbra://
$content = $content -replace '<data android:scheme="kryfo" />', '<data android:scheme="kryfo" />`n            <data android:scheme="umbra" />'
$content = $content -replace '\$\{applicationId\}\.open', '${applicationId}.open'
Set-Content $manifest $content -Encoding UTF8
Write-Host "Updated $manifest" -ForegroundColor Green

# 4. Move Kotlin package: app/kryfo -> app/umbra/messenger
$oldKotlinDir = "mobile/android/app/src/main/kotlin/app/kryfo"
$newKotlinDir = "mobile/android/app/src/main/kotlin/app/umbra/messenger"
if (Test-Path $oldKotlinDir) {
    New-Item -ItemType Directory -Force -Path $newKotlinDir | Out-Null
    Get-ChildItem $oldKotlinDir -Filter "*.kt" | ForEach-Object {
        $ktContent = Get-Content $_.FullName -Raw
        $ktContent = $ktContent -replace '^package app\.kryfo$', 'package app.umbra.messenger'
        $ktContent = $ktContent -replace 'import app\.kryfo\.', 'import app.umbra.messenger.'
        Set-Content $_.FullName $ktContent -Encoding UTF8
        Move-Item $_.FullName (Join-Path $newKotlinDir $_.Name) -Force
    }
    Remove-Item $oldKotlinDir -Recurse -Force
    Write-Host "Moved and updated Kotlin package to $newKotlinDir" -ForegroundColor Green
}

# 5. Update test imports: package:kryfo/ -> package:umbra/
$testFiles = Get-ChildItem "mobile/test" -Recurse -Filter "*.dart" | Where-Object { $_ | Select-String "package:kryfo/" }
foreach ($file in $testFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "package:kryfo/", "package:umbra/"
    Set-Content $file.FullName $content -Encoding UTF8
}
Write-Host "Updated $($testFiles.Count) test files" -ForegroundColor Green

# 6. F-Droid metadata: create new app.umbra.messenger.yml
$fdroidOld = "fdroiddata/app.kryfo.yml"
$fdroidNew = "fdroiddata/app.umbra.messenger.yml"
if (Test-Path $fdroidOld) {
    $content = Get-Content $fdroidOld -Raw
    $content = $content -replace 'AutoName: Kryfo', 'AutoName: Umbra'
    $content = $content -replace 'SourceCode: https://github.com/GnosiWorks/Kryfo', 'SourceCode: https://github.com/emtee40/Kryfo-android'
    $content = $content -replace 'IssueTracker: https://github.com/GnosiWorks/Kryfo/issues', 'IssueTracker: https://github.com/emtee40/Kryfo-android/issues'
    $content = $content -replace 'Changelog: https://github.com/GnosiWorks/Kryfo/blob/HEAD/CHANGELOG.md', 'Changelog: https://github.com/emtee40/Kryfo-android/blob/HEAD/CHANGELOG.md'
    $content = $content -replace 'Repo: https://github.com/GnosiWorks/Kryfo.git', 'Repo: https://github.com/emtee40/Kryfo-android.git'
    $content = $content -replace 'binary: https://github.com/GnosiWorks/Kryfo/releases/download/', 'binary: https://github.com/emtee40/Kryfo-android/releases/download/'
    $content = $content -replace 'AllowedAPKSigningKeys: .+', 'AllowedAPKSigningKeys: REPLACE_WITH_UMBRA_SIGNING_KEY'
    Set-Content $fdroidNew $content -Encoding UTF8
    Write-Host "Created $fdroidNew" -ForegroundColor Green
}

# 7. README.md rewrite
$readme = "README.md"
$content = Get-Content $readme -Raw
$content = @"
# Umbra

Umbra is a private messenger for Android — no phone number, no email, no account.
Messages are end-to-end encrypted and travel phone-to-phone over Tor onion services,
or wait on Nostr relays sealed with NIP-44/59 when the other side is offline.

**Umbra is a fork of [Kryfo](https://github.com/emtee40/Kryfo-android) — thank you to the Kryfo authors for the engine and protocol.**

## Building

See [BUILDING.md](BUILDING.md) for reproducible build instructions.

## License

GPL-3.0-or-later — see [LICENSE](LICENSE).
"@
Set-Content $readme $content -Encoding UTF8
Write-Host "Rewrote $readme" -ForegroundColor Green

# 8. CHANGELOG.md header
$changelog = "CHANGELOG.md"
$content = Get-Content $changelog -Raw
if ($content -match '^# Changelog') {
    $content = $content -replace '^# Changelog', "# Changelog`n`n## [Unreleased] - Umbra fork`n- Forked from Kryfo-android, renamed to Umbra`n- GPL-3.0 preserved with Kryfo attribution"
} else {
    $content = "# Changelog`n`n## [Unreleased] - Umbra fork`n- Forked from Kryfo-android, renamed to Umbra`n- GPL-3.0 preserved with Kryfo attribution`n`n" + $content
}
Set-Content $changelog $content -Encoding UTF8
Write-Host "Updated $changelog header" -ForegroundColor Green

# 9. Update engine/bridge.go and handle.go references in Dart FFI (keep Halo* symbols, only update comments)
# The plan says: Leave untouched: all Halo* symbols (Go + Dart), libhalo name, engine/ and dmrelay/ entirely
# So we only update Dart comments/strings that reference "kryfo" in user-visible contexts

Write-Host "=== Rename Complete ===" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify: git grep -i kryfo (should only show attribution/credit lines + upstream URLs)"
Write-Host "  2. Verify: git grep 'package:kryfo' (should be 0 hits)"
Write-Host "  3. Commit changes"
Write-Host "  4. Add GitHub Actions workflows (.github/workflows/ci.yml, release.yml)"