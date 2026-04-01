# build-test-package.ps1
# This script simulates the GitHub Actions release workflow locally.
# Use this to verify that your ZIP package has the correct folder structure.

# Hardening: Ensure build process is not interrupted by an inherited confirmation state.
# (Prevents inherited -Confirm prompts from nested/suspended shells).
$ConfirmPreference = 'High'

# --- Variables ---
$packageName = "pwsh-robocopy-backup"
$lastTag = (git describe --tags --abbrev=0 2>$null)   # Last Git tag (e.g., v0.1.00)
# $version = "v-local-test"
$version = "$lastTag"
$stagingDir = "$packageName"
$distDir = "dist"
$zipName = "$packageName-$version.zip"
$zipPath = "$distDir\$zipName"

# Set the working directory to the parent folder (the project root)
$CurrentScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$CurrentScriptDir\.."

# --- Version Check ---
if ($lastTag) {
    # Extract the version from backup.ps1
    # Example: "SCRIPT_VERSION" -Option ReadOnly -Value "0.2.00"
    # $versionLine = Get-Content "backup.ps1" | Select-String "SCRIPT_VERSION.*Value\s`"([0-9\.]+)`""
    $versionLine = Get-Content "backup.ps1" | Select-String "Set-Variable -Name `"SCRIPT_VERSION`""

    if ($versionLine -match "Value\s`"([0-9\.]+)`"") {
        $actualVersion = $Matches[1]
        $expectedTag = "v$actualVersion"

        if ($lastTag -eq $expectedTag) {
            Write-Host "WARNING: The version in 'backup.ps1' ($actualVersion) is the same as the last Git tag ($lastTag)." -ForegroundColor Yellow
            Write-Host "         Have you forgotten to bump the version for the next release?" -ForegroundColor Yellow
        } else {
            Write-Host "Version check: Script version ($actualVersion) is different from last tag ($lastTag)." -ForegroundColor Cyan
        }
    }
}
# ---------------------

# Create the dist folder if it doesn't exist
if (!(Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

Write-Host "--- Starting local build test for version $version ---" -ForegroundColor Cyan

# Clean up previous test runs
if (Test-Path $stagingDir) {
    Write-Host "Cleaning up old staging directory..."
    Remove-Item -Path $stagingDir -Recurse -Force
}
if (Test-Path $zipPath) {
    Write-Host "Removing old test ZIP..."
    Remove-Item -Path $zipPath -Force
}

# 1. Create temporary folder structure
Write-Host "Creating folder structure..."
New-Item -ItemType Directory -Path "$stagingDir\lib" -Force | Out-Null
New-Item -ItemType Directory -Path "$stagingDir\templates" -Force | Out-Null

# 2. Copy main script, templates, and README
Write-Host "Copying root files..."
Copy-Item "backup.ps1" "$stagingDir\"
Copy-Item "example-backup.ini" "$stagingDir\"
Copy-Item "example-dir-list.conf" "$stagingDir\"
Copy-Item "README.md" "$stagingDir\"

# 3. Copy ONLY .ps1 files into the lib folder
Write-Host "Copying library files (.ps1 only)..."
Copy-Item "lib\*.ps1" "$stagingDir\lib\"

# 4. Copy ONLY template files into the templates folder
Write-Host "Copying template files (.RCJ and .conf)..."
Copy-Item "templates\*.RCJ" "$stagingDir\templates\"
Copy-Item "templates\*.conf" "$stagingDir\templates\"

# 5. Create the ZIP archive
Write-Host "Creating ZIP archive: $zipPath" -ForegroundColor Yellow
Compress-Archive -Path "$stagingDir\*" -DestinationPath "$zipPath" -Force

# 6. Cleanup
Write-Host "Cleaning up staging directory..."
Remove-Item -Path $stagingDir -Recurse -Force

# 7. Final report
Write-Host "--- Build test finished! ---" -ForegroundColor Green
Write-Host "Test package created: " -NoNewLine; Write-Host "$(Get-Location)\$zipPath" -ForegroundColor Green
Write-Host "You can open the ZIP file now to verify its contents."
