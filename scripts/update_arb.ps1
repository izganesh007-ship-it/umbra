#!/usr/bin/env pwsh
# Update ARB file: kryfo -> Umbra in user-visible strings
# Run from repo root: pwsh scripts/update_arb.ps1

$arb = "mobile/lib/l10n/app_en.arb"
$content = Get-Content $arb -Raw

# User-visible string replacements (case-sensitive, whole phrase replacements)
$replacements = @(
    @{Old = '"Unlock kryfo"'; New = '"Unlock Umbra"'}
    @{Old = '"A kryfo link, a room link or @wren"'; New = '"An Umbra link, a room link or @wren"'}
    @{Old = '"Your kryfo"'; New = '"Your Umbra"'}
    @{Old = '"Add a kryfo"'; New = '"Add an Umbra"'}
    @{Old = '"Your kryfo:"'; New = '"Your Umbra:"'}
    @{Old = '"Let kryfo run in the background"'; New = '"Let Umbra run in the background"'}
    @{Old = '"Kryfo backup"'; New = '"Umbra backup"'}
    @{Old = '"Your encrypted kryfo backup. Keep both this file AND your passphrase safe - you need both to restore."'; New = '"Your encrypted Umbra backup. Keep both this file AND your passphrase safe - you need both to restore."'}
    @{Old = '"Back up kryfo"'; New = '"Back up Umbra"'}
    @{Old = '"Kryfo can.t clean this kind of file yet."'; New = '"Umbra can.t clean this kind of file yet."'}
    @{Old = '"Kryfo could not make this one clean."'; New = '"Umbra could not make this one clean."'}
    @{Old = '"Kryfo could not open that file."'; New = '"Umbra could not open that file."'}
    @{Old = '"Kryfo could not read it to the end, so it won.t call it clean. No copy was made."'; New = '"Umbra could not read it to the end, so it won.t call it clean. No copy was made."'}
    @{Old = '"Keep kryfo *independent*"'; New = '"Keep Umbra *independent*"'}
    @{Old = '"Kryfo looks for messages every 15 minutes. Easy on battery, but messages can be late."'; New = '"Umbra looks for messages every 15 minutes. Easy on battery, but messages can be late."'}
    @{Old = '"Kryfo is offline"'; New = '"Umbra is offline"'}
    @{Old = '"Kryfo will check in every 15 minutes"'; New = '"Umbra will check in every 15 minutes"'}
    @{Old = '"It has closed kryfo three times today, so messages were late or waited. Check-ins survive that: kryfo wakes every 15 minutes instead of staying connected."'; New = '"It has closed Umbra three times today, so messages were late or waited. Check-ins survive that: Umbra wakes every 15 minutes instead of staying connected."'}
    @{Old = '"No kryfos yet."'; New = '"No Umbras yet."'}
    @{Old = '"Kryfo could not read or write the file."'; New = '"Umbra could not read or write the file."'}
    @{Old = '"Kryfo opens files locked with age. Those usually end in .age."'; New = '"Umbra opens files locked with age. Those usually end in .age."'}
    @{Old = '"No Kryfo on the other side? On a computer:"'; New = '"No Umbra on the other side? On a computer:"'}
    @{Old = '"Everything kryfo holds here goes: the messages, the contacts, the keys. The other device keeps all of it. This cannot be undone."'; New = '"Everything Umbra holds here goes: the messages, the contacts, the keys. The other device keeps all of it. This cannot be undone."'}
    @{Old = '"Kryfo will close now. Tap the icon to reopen as {myId}."'; New = '"Umbra will close now. Tap the icon to reopen as {myId}."'}
    @{Old = '"Reopen kryfo"'; New = '"Reopen Umbra"'}
    @{Old = '"This kryfo has moved"'; New = '"This Umbra has moved"'}
    # contact card
    @{Old = '"Message me on kryfo · {haloId}"'; New = '"Message me on Umbra · {haloId}"'}
)

$updated = 0
foreach ($r in $replacements) {
    if ($content -match [regex]::Escape($r.Old)) {
        $content = $content -replace [regex]::Escape($r.Old), $r.New
        $updated++
        Write-Host "Updated: $($r.Old) -> $($r.New)" -ForegroundColor Green
    } else {
        Write-Host "NOT FOUND: $($r.Old)" -ForegroundColor Yellow
    }
}

Set-Content $arb $content -Encoding UTF8
Write-Host "=== Updated $updated strings in ARB file ===" -ForegroundColor Cyan