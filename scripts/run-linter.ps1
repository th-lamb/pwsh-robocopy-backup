<#
.SYNOPSIS
    Runs PSScriptAnalyzer on the codebase using the project's configuration.

.DESCRIPTION
    This script identifies potential issues in PowerShell code by checking it against
    best practices and the specific rules defined in .github/linters/powershell-psscriptanalyzer.psd1.

.EXAMPLE
    ./scripts/run-linter.ps1
#>

[CmdletBinding()]
param()

$ProjectRoot = Resolve-Path "${PSScriptRoot}/.."
$ConfigPath = Join-Path $ProjectRoot ".github/linters/powershell-psscriptanalyzer.psd1"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Linter configuration not found at: $ConfigPath"
    exit 1
}

if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
    if ($Host.UI.RawUI) {
        Write-Host "PSScriptAnalyzer module not found. Installing..." -ForegroundColor Cyan
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck
    } else {
        Write-Error "PSScriptAnalyzer module is required but not installed. Please install it with 'Install-Module -Name PSScriptAnalyzer'."
        exit 1
    }
}

$ResultsDir = Join-Path $ProjectRoot "test-results"
if (-not (Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}
$OutputFile = Join-Path $ResultsDir "linterResults.txt"

Write-Host "Gathering PowerShell files to analyze (respecting .gitignore)..." -ForegroundColor Cyan

$FilesToAnalyze = @()
try {
    # Get all tracked files and untracked (but not ignored) files that are PowerShell scripts
    # Using -C to ensure git runs from the project root
    $trackedFiles = git -C "$($ProjectRoot.Path)" ls-files --cached --others --exclude-standard | Where-Object { $_ -match '\.(ps1|psm1|psd1)$' }
    foreach ($f in $trackedFiles) {
        $FilesToAnalyze += Join-Path "$($ProjectRoot.Path)" $f
    }
} catch {
    Write-Warning "Failed to use git to find files. Falling back to recursive scan (ignoring .git)..."
    $FilesToAnalyze = Get-ChildItem -Path "$($ProjectRoot.Path)" -Filter "*.ps1" -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' }
    $FilesToAnalyze += Get-ChildItem -Path "$($ProjectRoot.Path)" -Filter "*.psm1" -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' }
    $FilesToAnalyze += Get-ChildItem -Path "$($ProjectRoot.Path)" -Filter "*.psd1" -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' }
}

if ($FilesToAnalyze.Count -eq 0) {
    Write-Host "No PowerShell files found to analyze." -ForegroundColor Green
    exit 0
}

Write-Host "Running PSScriptAnalyzer on $($FilesToAnalyze.Count) files..." -ForegroundColor Cyan

$results = @()
foreach ($file in $FilesToAnalyze) {
    try {
        $fileResults = Invoke-ScriptAnalyzer -Path $file -Settings $ConfigPath -ErrorAction Stop
        if ($fileResults) {
            $results += $fileResults
        }
    } catch {
        Write-Warning "Failed to analyze file: $file. Error: $_"
    }
}

if ($results) {
    $resultsToSelect = $results | Select-Object Severity, RuleName, @{Name='File'; Expression={ $_.ScriptPath.Replace($ProjectRoot.Path + "\", "") }}, Line, Message

    # Save to file with a fixed wide width to avoid truncation
    $resultsToSelect | Format-Table -AutoSize -Wrap | Out-String -Width 300 | Out-File -FilePath $OutputFile -Encoding utf8

    # Show in console (will still adapt to window size)
    $resultsToSelect | Format-Table -AutoSize -Wrap | Out-Host

    $count = ($results | Measure-Object).Count
    Write-Host "`nLinter found $count issues. Please fix them. (Full results saved to $OutputFile)" -ForegroundColor Yellow
    exit 1
} else {
    "No issues found." | Out-File -FilePath $OutputFile -Encoding utf8
    Write-Host "No issues found." -ForegroundColor Green
    exit 0
}
