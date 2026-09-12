# VE Cam Downloads

Official download website and release hub for **VE Cam**.

## Live website

https://sanchez1337r.github.io/ve-cam-downloads/

## Current releases

### Windows

**VE Cam for Windows v0.3.63**

Installer:

https://github.com/Sanchez1337R/ve-cam-downloads/releases/download/v0.3.63/VE-Cam-Setup-v0.3.63.exe

SHA-256:

```text
adeb4ac0091ce9a17b8bdcdfa8bb72dc726db1895666a8970b328f946dd8405a
```

The Windows installer is hosted through **GitHub Releases**, not inside the GitHub Pages repository.

### Android

**VE Cam Mobile v0.3.63**

Closed testing opt-in:

https://play.google.com/apps/testing/com.vecam.nvr

Current testing goal:

- At least 12 testers
- Testers remain enrolled for 14 days
- Each tester's Google account must first be added to the VE Cam tester list in Google Play Console
- Testers should use that same Google account in Google Play

### macOS

Planned.

### iPhone / iPad

Planned.

## Repository structure

```text
assets/
  ve-cam-logo.png

downloads/
  PUT-WINDOWS-INSTALLER-HERE.txt

index.html
styles.css
.gitignore
README.md
```

Windows `.exe` installers are intentionally excluded from the repository by `.gitignore` and are published as GitHub Release assets.

## Website publishing

GitHub Pages is configured to deploy from:

```text
Branch: main
Folder: / (root)
```

Pushing changes to `main` updates the live download site automatically.

## Updating a Windows release

For a future Windows release:

1. Build and validate the new VE Cam Windows installer.
2. Create a new GitHub Release and upload the installer.
3. Record the installer SHA-256.
4. Update `index.html` with:
   - version number
   - GitHub Release download URL
   - SHA-256
5. Commit and push the website update.

## Project

VE Cam provides access to VE Cam NVR systems on the local network and through Tailscale.

This repository is only for the public download website and release links.
