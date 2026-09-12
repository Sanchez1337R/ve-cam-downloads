# VE Cam download website

This is a static site designed for GitHub Pages or any simple web host.

## Windows installer

Place this file in the `downloads` folder:

`VE-Cam-Setup-v0.3.63.exe`

The page is already linked to that filename and already shows this SHA-256:

`adeb4ac0091ce9a17b8bdcdfa8bb72dc726db1895666a8970b328f946dd8405a`

## Android

Replace the disabled Google Play button in `index.html` with the public Play Store URL when ready.

## macOS / iOS

Those cards are intentionally marked Coming soon.

## Hosting recommendation

- Website: GitHub Pages
- Large installer binaries: GitHub Releases
- Optional custom domain later

For GitHub Releases, replace the local Windows link in `index.html` with the release asset URL.


## v2 cleanup

- Kept VE Cam logo and name at the top-left.
- Removed the redundant top-right Downloads link.
- Removed the three bottom informational cards.
- Main page now stays focused on platform installers.


## v3 cleanup

- Removed “Choose the app for your device.”
- Removed the “View downloads” button.
- Android copy now simply says “Install VE Cam from Google Play.”


## v4 Android closed testing

- Android now links directly to:
  https://play.google.com/apps/testing/com.vecam.nvr
- Shows that VE Cam needs at least 12 testers enrolled for 14 days.
- Tells testers their Google account must first be added to the VE Cam tester list.
