# build-test-package.ps1
# This script simulates the GitHub Actions release workflow locally.
# Use this to verify that your ZIP package has the correct folder structure.

$version = "v-local-test"
$packageName = "pwsh-robocopy-backup"
$stagingDir = "$packageName"
$zipName = "$packageName-$version.zip"

# Set the working directory to the parent folder (the project root)
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$PSScriptRoot\.."

Write-Host "--- Starting local build test for version $version ---" -ForegroundColor Cyan

# 0. Clean up previous test runs
if (Test-Path $stagingDir) {
    Write-Host "Cleaning up old staging directory..."
    Remove-Item -Path $stagingDir -Recurse -Force
}
if (Test-Path $zipName) {
    Write-Host "Removing old test ZIP..."
    Remove-Item -Path $zipName -Force
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

if (Test-Path "README.md") {
    Copy-Item "README.md" "$stagingDir\"
} else {
    Write-Warning "README.md not found in the root directory! The GitHub workflow will fail without it."
}

# 3. Copy ONLY .ps1 files into the lib folder
Write-Host "Copying library files (.ps1 only)..."
Copy-Item "lib\*.ps1" "$stagingDir\lib\"

# 4. Copy ONLY template files into the templates folder
Write-Host "Copying template files (.RCJ and .conf)..."
Copy-Item "templates\*.RCJ" "$stagingDir\templates\"
Copy-Item "templates\*.conf" "$stagingDir\templates\"

# 5. Create the ZIP archive
Write-Host "Creating ZIP archive: $zipName" -ForegroundColor Yellow
Compress-Archive -Path "$stagingDir\*" -DestinationPath "$zipName" -Force

# 6. Cleanup
Write-Host "Cleaning up staging directory..."
Remove-Item -Path $stagingDir -Recurse -Force

# 7. Final report
Write-Host "--- Build test finished! ---" -ForegroundColor Green
Write-Host "Test package created: " -NoNewLine; Write-Host "$(Get-Location)\$zipName" -ForegroundColor Green
Write-Host "You can open the ZIP file now to verify its contents."
