param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$InstallerPath,

    [string]$WebsitePath = "C:\Users\Enmanuel\develop\ve_cam_website",

    [string]$GitHubRepo = "Sanchez1337R/ve-cam-downloads",

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "============================================================"
    Write-Host " $Text"
    Write-Host "============================================================"
}

function Assert-Command([string]$Name, [string]$HelpText) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name was not found. $HelpText"
    }
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Get-UpdatedWebsiteContent(
    [string]$IndexText,
    [string]$ReadmeText,
    [string]$Version,
    [string]$DownloadUrl,
    [string]$Hash,
    [string]$GitHubRepo
) {
    $windowsVersionPattern = '(?<=<div class="version">VE Cam for Windows &bull; v)\d+\.\d+\.\d+(?=</div>)'
    if ([regex]::Matches($IndexText, $windowsVersionPattern).Count -ne 1) {
        throw "Could not uniquely locate the Windows version line in index.html."
    }
    $IndexText = [regex]::Replace($IndexText, $windowsVersionPattern, $Version, 1)

    $windowsHrefPattern = 'href="https://github\.com/[^"]+/releases/download/v\d+\.\d+\.\d+/VE-Cam-Setup-v\d+\.\d+\.\d+\.exe"'
    if ([regex]::Matches($IndexText, $windowsHrefPattern).Count -ne 1) {
        throw "Could not uniquely locate the Windows GitHub Release URL in index.html."
    }
    $IndexText = [regex]::Replace(
        $IndexText,
        $windowsHrefPattern,
        ('href="' + $DownloadUrl + '"'),
        1
    )

    $shaPattern = '(?s)(<div class="checksum">\s*<span>SHA-256</span>\s*<code>)[0-9a-fA-F]{64}(</code>)'
    if ([regex]::Matches($IndexText, $shaPattern).Count -ne 1) {
        throw "Could not uniquely locate the Windows SHA-256 in index.html."
    }
    $IndexText = [regex]::Replace($IndexText, $shaPattern, ('$1' + $Hash + '$2'), 1)

    $ReadmeText = [regex]::Replace(
        $ReadmeText,
        '(?m)^\*\*VE Cam for Windows v\d+\.\d+\.\d+\*\*$',
        "**VE Cam for Windows v$Version**",
        1
    )

    $ReadmeText = [regex]::Replace(
        $ReadmeText,
        '(?m)^https://github\.com/' + [regex]::Escape($GitHubRepo) + '/releases/download/v\d+\.\d+\.\d+/VE-Cam-Setup-v\d+\.\d+\.\d+\.exe$',
        $DownloadUrl,
        1
    )

    $windowsSectionPattern = '(?s)(### Windows.*?SHA-256:\s*```text\s*)[0-9a-fA-F]{64}(\s*```)'
    if ([regex]::Matches($ReadmeText, $windowsSectionPattern).Count -ne 1) {
        throw "Could not uniquely locate the Windows SHA-256 in README.md."
    }
    $ReadmeText = [regex]::Replace(
        $ReadmeText,
        $windowsSectionPattern,
        ('$1' + $Hash + '$2'),
        1
    )

    return @{
        Index  = $IndexText
        Readme = $ReadmeText
    }
}

Write-Step "VE Cam Windows Release Automation"

if ($DryRun) {
    Write-Host "MODE: DRY RUN"
    Write-Host "No GitHub release will be created."
    Write-Host "No website files will be changed."
    Write-Host "Nothing will be committed or pushed."
    Write-Host ""
}

$InstallerPath = (Resolve-Path -LiteralPath $InstallerPath).Path
$WebsitePath = (Resolve-Path -LiteralPath $WebsitePath).Path

$expectedFileName = "VE-Cam-Setup-v$Version.exe"
$actualFileName = [System.IO.Path]::GetFileName($InstallerPath)

if ($actualFileName -ne $expectedFileName) {
    throw "Installer filename must be exactly '$expectedFileName'. Found '$actualFileName'."
}

$indexPath = Join-Path $WebsitePath "index.html"
$readmePath = Join-Path $WebsitePath "README.md"

if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "index.html not found at $indexPath"
}

if (-not (Test-Path -LiteralPath $readmePath)) {
    throw "README.md not found at $readmePath"
}

Assert-Command "git" "Install Git for Windows before running this release script."
Assert-Command "gh" "Install GitHub CLI first with: winget install --id GitHub.cli -e"

Push-Location $WebsitePath
try {
    Write-Step "Preflight checks"

    $insideRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $insideRepo.Trim() -ne "true") {
        throw "$WebsitePath is not a Git repository."
    }

    $branch = (git branch --show-current).Trim()
    if ($branch -ne "main") {
        throw "Expected Git branch 'main', but current branch is '$branch'."
    }

    $status = git status --porcelain
    if ($status) {
        Write-Host "Uncommitted changes detected:"
        $status | ForEach-Object { Write-Host "  $_" }
        throw "Commit or discard existing website changes before publishing a release."
    }

    gh auth status | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub CLI is not authenticated. Run: gh auth login"
    }

    git fetch origin main
    if ($LASTEXITCODE -ne 0) {
        throw "Could not fetch origin/main."
    }

    $localHead = (git rev-parse HEAD).Trim()
    $remoteHead = (git rev-parse origin/main).Trim()
    if ($localHead -ne $remoteHead) {
        throw "Local main is not exactly synchronized with origin/main. Run: git pull --ff-only"
    }

    $tag = "v$Version"
    gh release view $tag --repo $GitHubRepo *> $null
    $releaseExists = ($LASTEXITCODE -eq 0)

    if ($releaseExists -and -not $DryRun) {
        throw "GitHub Release '$tag' already exists."
    }

    if ($releaseExists -and $DryRun) {
        Write-Host "[INFO] Release '$tag' already exists. Allowed because this is a dry run."
    } else {
        Write-Host "[PASS] Release tag '$tag' is available."
    }

    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $InstallerPath).Hash.ToLowerInvariant()
    $downloadUrl = "https://github.com/$GitHubRepo/releases/download/$tag/$expectedFileName"

    Write-Host "[PASS] Version:     $Version"
    Write-Host "[PASS] Installer:   $InstallerPath"
    Write-Host "[PASS] SHA-256:     $hash"
    Write-Host "[PASS] Download URL:"
    Write-Host "       $downloadUrl"

    Write-Step "Validate website update"

    $indexOriginal = [System.IO.File]::ReadAllText($indexPath)
    $readmeOriginal = [System.IO.File]::ReadAllText($readmePath)

    $updated = Get-UpdatedWebsiteContent `
        -IndexText $indexOriginal `
        -ReadmeText $readmeOriginal `
        -Version $Version `
        -DownloadUrl $downloadUrl `
        -Hash $hash `
        -GitHubRepo $GitHubRepo

    Write-Host "[PASS] Windows version replacement validated"
    Write-Host "[PASS] Windows release URL replacement validated"
    Write-Host "[PASS] Windows SHA-256 replacement validated"
    Write-Host "[PASS] README replacement validated"

    if ($DryRun) {
        Write-Step "Dry-run result"

        $indexChanged = ($updated.Index -ne $indexOriginal)
        $readmeChanged = ($updated.Readme -ne $readmeOriginal)

        Write-Host "Would change index.html: $indexChanged"
        Write-Host "Would change README.md:  $readmeChanged"
        Write-Host ""
        Write-Host "Planned release:"
        Write-Host "  Tag:       $tag"
        Write-Host "  Title:     VE Cam for Windows $tag"
        Write-Host "  Installer: $expectedFileName"
        Write-Host "  SHA-256:   $hash"
        Write-Host "  URL:       $downloadUrl"
        Write-Host ""
        Write-Host "DRY RUN PASSED"
        Write-Host "No files changed. No release created. Nothing pushed."
        exit 0
    }

    Write-Step "Create rollback backup"

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $env:USERPROFILE "Downloads\VE-Cam-Website-Release-Backup-$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item -LiteralPath $indexPath -Destination (Join-Path $backupDir "index.html") -Force
    Copy-Item -LiteralPath $readmePath -Destination (Join-Path $backupDir "README.md") -Force

    Write-Host "[PASS] Backup:"
    Write-Host "       $backupDir"

    Write-Step "Update website"

    Write-Utf8NoBom $indexPath $updated.Index
    Write-Utf8NoBom $readmePath $updated.Readme

    Write-Host "[PASS] index.html updated"
    Write-Host "[PASS] README.md updated"

    Write-Step "Review release plan"

    Write-Host "GitHub Release:"
    Write-Host "  Tag:   $tag"
    Write-Host "  Title: VE Cam for Windows $tag"
    Write-Host ""
    Write-Host "Installer:"
    Write-Host "  $expectedFileName"
    Write-Host ""
    Write-Host "SHA-256:"
    Write-Host "  $hash"
    Write-Host ""
    git diff -- index.html README.md | Out-Host

    $answer = Read-Host "Publish this GitHub Release and push the website update? Type YES to continue"
    if ($answer -cne "YES") {
        Copy-Item -LiteralPath (Join-Path $backupDir "index.html") -Destination $indexPath -Force
        Copy-Item -LiteralPath (Join-Path $backupDir "README.md") -Destination $readmePath -Force
        Write-Host ""
        Write-Host "Cancelled. Website files were restored from backup."
        exit 0
    }

    Write-Step "Publish GitHub Release"

    $notesPath = Join-Path $env:TEMP "VE-Cam-Windows-$tag-release-notes.md"
    $notes = @"
VE Cam for Windows $tag

Windows release of VE Cam.

Includes:
- VE Cam NVR discovery
- App Trust
- Tailscale support
- WebView2 camera viewing
- Windows installer and uninstall support
- VE Cam NVR branding

SHA-256:
$hash
"@
    Write-Utf8NoBom $notesPath $notes

    gh release create $tag `
        $InstallerPath `
        --repo $GitHubRepo `
        --target main `
        --title "VE Cam for Windows $tag" `
        --notes-file $notesPath `
        --latest

    if ($LASTEXITCODE -ne 0) {
        throw "GitHub Release creation failed. Website changes have NOT been committed."
    }

    Write-Host "[PASS] GitHub Release published"

    Write-Step "Commit and deploy website"

    git add index.html README.md

    git commit -m "Update Windows download to $tag"
    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed after the release was published. Fix locally, then push manually."
    }

    git push
    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed. The GitHub Release exists, but the website update still needs to be pushed."
    }

    Write-Step "Release complete"

    Write-Host "Version:"
    Write-Host "  $tag"
    Write-Host ""
    Write-Host "Installer:"
    Write-Host "  $downloadUrl"
    Write-Host ""
    Write-Host "SHA-256:"
    Write-Host "  $hash"
    Write-Host ""
    Write-Host "Website:"
    Write-Host "  https://sanchez1337r.github.io/ve-cam-downloads/"
    Write-Host ""
    Write-Host "GitHub Pages will redeploy automatically from main."
}
finally {
    Pop-Location
}
