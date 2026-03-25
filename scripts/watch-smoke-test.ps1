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

Write-Host "--- Smoke Test Watcher ---" -ForegroundColor Cyan
Write-Host "Watching: $($WatchPatterns -join ', ')"
Write-Host "Running:  $($TestFullPath.Path)"
Write-Host "Press Ctrl+C to stop.`n"

$lastWriteTimes = @{}

function Get-WatchedFileCollection {
    param($Patterns)
    $files = @()
    foreach ($p in $Patterns) {
        $files += Get-ChildItem -Path $p -ErrorAction SilentlyContinue
    }
    return $files
}

# Initialize state
Get-WatchedFileCollection -Patterns $WatchPatterns | ForEach-Object {
    $lastWriteTimes[$_.FullName] = $_.LastWriteTime
}

# Initial run
Write-Host "Initial run..." -ForegroundColor Gray
Invoke-Pester -Path $TestFullPath.Path -Output Detailed

while ($true) {
    $changed = $false
    $currentFiles = Get-WatchedFileCollection -Patterns $WatchPatterns

    foreach ($f in $currentFiles) {
        if (-not $lastWriteTimes.ContainsKey($f.FullName) -or $lastWriteTimes[$f.FullName] -ne $f.LastWriteTime) {
            $lastWriteTimes[$f.FullName] = $f.LastWriteTime
            $changed = $true
            Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Change detected: $($f.Name)" -ForegroundColor Yellow
        }
    }

    if ($changed) {
        Write-Host "Running smoke test..." -ForegroundColor Cyan
        Invoke-Pester -Path $TestFullPath.Path -Output Detailed
    }

    Start-Sleep -Seconds 1
}
