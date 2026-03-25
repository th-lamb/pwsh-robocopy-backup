[CmdletBinding()]
param(
    [string]$TestPath = "Pester/tests/backup_ps1/smoke-tests/BasicRun.Tests.ps1",
    [string[]]$WatchPatterns = @("backup.ps1", "lib/*.ps1", "Pester/tests/backup_ps1/smoke-tests/BasicRun.Tests.ps1")
)

$TestFullPath = Resolve-Path $TestPath -ErrorAction SilentlyContinue
if (-not $TestFullPath) {
    Write-Error "Test file not found: $TestPath"
    return
}

# Ensure Pester v5 is loaded (presents New-PesterConfiguration)
try {
    Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
}
catch {
    Write-Error "Pester v5.0+ is required but was not found. Please install it with: Install-Module Pester -MinimumVersion 5.0 -Force"
    return
}

Write-Host "--- Smoke Test Watcher ---" -ForegroundColor Cyan
Write-Host "Watching: $($WatchPatterns -join ', ')"
Write-Host "Running:  $($TestFullPath.Path)"
Write-Host "Press Ctrl+C to stop.`n"

$lastWriteTimes = @{}

function Get-WatchedFiles {
    param($Patterns)
    $files = @()
    foreach ($p in $Patterns) {
        $files += Get-ChildItem -Path $p -ErrorAction SilentlyContinue
    }
    return $files
}

# Initialize state
Get-WatchedFiles -Patterns $WatchPatterns | ForEach-Object {
    $lastWriteTimes[$_.FullName] = $_.LastWriteTime
}

# Helper to run Pester v5 style
function Start-SmokeTest {
    param($Path)
    $config = New-PesterConfiguration
    $config.Run.Path = $Path
    $config.Output.Verbosity = 'Detailed'
    Invoke-Pester -Configuration $config
}

# Initial run
Write-Host "Initial run..." -ForegroundColor Gray
Start-SmokeTest -Path $TestFullPath.Path

while ($true) {
    $changed = $false
    $currentFiles = Get-WatchedFiles -Patterns $WatchPatterns

    foreach ($f in $currentFiles) {
        if (-not $lastWriteTimes.ContainsKey($f.FullName) -or $lastWriteTimes[$f.FullName] -ne $f.LastWriteTime) {
            $lastWriteTimes[$f.FullName] = $f.LastWriteTime
            $changed = $true
            Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Change detected: $($f.Name)" -ForegroundColor Yellow
        }
    }

    if ($changed) {
        Write-Host "Running smoke test..." -ForegroundColor Cyan
        Start-SmokeTest -Path $TestFullPath.Path
    }

    Start-Sleep -Seconds 1
}
