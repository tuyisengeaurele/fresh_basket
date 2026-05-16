# Testing FreshBasket on iPhone from Windows

## What You Need
- iPhone (any model, iOS 16+)
- Windows PC with iTunes or iCloud installed
- Apple ID (free — no developer account needed)
- AltStore (free sideloading tool)

## Step 1 — Install iCloud
Download the **direct installer** (not Microsoft Store version):
https://support.apple.com/en-us/111896

## Step 2 — Install AltServer
1. Download AltInstaller.zip from https://altstore.io
2. Extract and run `AltInstaller.exe`
3. AltServer icon appears in system tray (bottom-right)

## Step 3 — Install AltStore on iPhone
1. Connect iPhone via USB
2. Tap **Trust** on iPhone when prompted
3. Click AltServer tray icon → **Install AltStore** → select your iPhone
4. Enter Apple ID when prompted

## Step 4 — Trust AltStore
Settings → General → VPN & Device Management → your Apple ID → Trust

## Step 5 — Build IPA via Codemagic
1. Push code to GitHub
2. Sign up at https://codemagic.io with GitHub
3. Add fresh_basket repo → trigger `ios-debug` workflow
4. Download the `.app` artifact when done

## Step 6 — Sideload via AltServer
1. Connect iPhone via USB (or same Wi-Fi with AltServer running)
2. AltServer tray icon → **Sideload .ipa** → select your IPA
3. Open AltStore on iPhone → My Apps → the app is installed

## Refreshing (every 7 days)
Open AltStore → My Apps → Refresh All
(Keep AltServer running on PC and on same Wi-Fi for auto-refresh)
