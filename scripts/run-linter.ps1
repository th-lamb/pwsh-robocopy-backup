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

Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan

try {
    $results = Invoke-ScriptAnalyzer -Path $ProjectRoot -Settings $ConfigPath -Recurse -ErrorAction Stop
} catch {
    Write-Error "Failed to run PSScriptAnalyzer: $_"
    exit 1
}

if ($results) {
    $results | Select-Object Severity, RuleName, @{Name='File'; Expression={ $_.ScriptPath.Replace($ProjectRoot.Path + "\", "") }}, Line, Message | Format-Table -AutoSize -Wrap
    $count = ($results | Measure-Object).Count
    Write-Host "`nLinter found $count issues. Please fix them." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "No issues found!" -ForegroundColor Green
    exit 0
}
