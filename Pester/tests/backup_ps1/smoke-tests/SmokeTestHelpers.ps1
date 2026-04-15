# Common helper functions for backup.ps1 smoke tests

function Get-ProjectRoot {
  <# Finds the project root by searching upwards from the current script directory
    for the "backup.ps1" file.
  #>
  $current = $PSScriptRoot
  $ProjectRoot = $null
  while ($current) {
    if (Test-Path (Join-Path $current "backup.ps1")) {
      $ProjectRoot = $current
      break
    }
    $current = Split-Path $current -Parent
  }

  if (-not $ProjectRoot) {
    throw "Could not find ProjectRoot (searching for backup.ps1 upwards from $PSScriptRoot)"
  }

  return $ProjectRoot
}

# Initialize-SmokeTestSandbox
function Initialize-SmokeTestSandbox {
  <# Sets up a clean sandbox for a smoke test by:
    1. Cleaning up previous artifacts.
    2. Copying the main script and its dependencies (lib/, templates/).
    3. Preparing the configuration files (backup.ini, dir-list.conf).
  #>
  [OutputType([hashtable])]
  [CmdletBinding(SupportsShouldProcess = $true)]
  param (
    [Parameter(Mandatory = $true)]
    [string]$SandboxRoot,
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [Parameter(Mandatory = $false)]
    [string]$IniSourceFileName = "test-backup.ini",
    [Parameter(Mandatory = $false)]
    [string]$DirListSourceFileName = "test-dir-list.conf",
    [Parameter(Mandatory = $false)]
    [string]$DirListDestinationPath = "destination\testuser\testcomputer\dir-list.conf"
  )

  if (-not $PSCmdlet.ShouldProcess($SandboxRoot, "Initialize smoke test sandbox")) {
    return
  }

  # --- CRITICAL SAFETY CHECK ---
  if ($SandboxRoot -eq "C:\" -or $SandboxRoot -eq "C:\Windows" -or -not $SandboxRoot.StartsWith($ProjectRoot)) {
    throw "SandboxRoot resolution failed or is outside ProjectRoot: $SandboxRoot"
  }

  Write-Host "Setting up sandbox: $SandboxRoot"

  $smokeTestPs1 = Join-Path $SandboxRoot "smoke-test.ps1"
  $smokeTestIni = Join-Path $SandboxRoot "backup.ini"
  $smokeTestConf = Join-Path $SandboxRoot $DirListDestinationPath

  # --- PRE-TEST CLEANUP ---
  $artifacts = @(
    $smokeTestPs1,
    $smokeTestIni,
    (Join-Path $SandboxRoot "source"),
    (Join-Path $SandboxRoot "destination"),
    (Join-Path $SandboxRoot "logdir"),
    (Join-Path $SandboxRoot "stdout.txt"),
    (Join-Path $SandboxRoot "stderr.txt")
  )
  foreach ($path in $artifacts) {
    if (Test-Path $path) {
      Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  # 1. Prepare the sandbox script
  Copy-Item (Join-Path $ProjectRoot "backup.ps1") -Destination $smokeTestPs1 -Force

  # 2. Prepare the sandbox ini file (optional, used in some tests)
  $iniSource = Join-Path $SandboxRoot $IniSourceFileName
  if (Test-Path $iniSource) {
    Copy-Item $iniSource -Destination $smokeTestIni -Force
  }

  # 3. Prepare the sandbox dir-list (optional, used in some tests)
  $dirListSource = Join-Path $SandboxRoot $DirListSourceFileName
  if (Test-Path $dirListSource) {
    $null = New-Item -ItemType Directory -Path (Split-Path $smokeTestConf -Parent) -Force
    Copy-Item $dirListSource -Destination $smokeTestConf -Force
  }

  # 4. Prepare the sandbox lib/ and templates/ folder.
  $libPath = Join-Path $SandboxRoot "lib\"
  $null = New-Item -ItemType Directory -Path $libPath -Force
  Get-ChildItem -Path (Join-Path $ProjectRoot "lib\") -Include "*.ps1", "*.psm1" -Recurse | Copy-Item -Destination $libPath -Force

  $templatesPath = Join-Path $SandboxRoot "templates\"
  $null = New-Item -ItemType Directory -Path $templatesPath -Force
  Get-ChildItem -Path (Join-Path $ProjectRoot "templates\*") -Include "*.RCJ", "dir-list-template.conf" | Copy-Item -Destination $templatesPath -Force

  return @{
    SmokeTestPs1  = $smokeTestPs1
    SmokeTestIni  = $smokeTestIni
    SmokeTestConf = $smokeTestConf
  }
}

# Invoke-SmokeTestProcess
function Invoke-SmokeTestProcess {
  <# Runs the smoke test script as a separate process and captures stdout/stderr.
  #>
  [OutputType([hashtable])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$PowerShellExecutable,
    [Parameter(Mandatory = $true)]
    [string]$SmokeTestPs1,
    [Parameter(Mandatory = $true)]
    [string]$WorkingDirectory
  )

  $stdoutFile = Join-Path $WorkingDirectory "stdout.txt"
  $stderrFile = Join-Path $WorkingDirectory "stderr.txt"

  $process = Start-Process -FilePath $PowerShellExecutable `
    -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$SmokeTestPs1`"", "-SkipExecution", "-NonInteractive" `
    -WorkingDirectory $WorkingDirectory `
    -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $stdoutFile `
    -RedirectStandardError $stderrFile

  return @{
    Process    = $process
    StdoutFile = $stdoutFile
    StderrFile = $stderrFile
  }
}

function Test-SmokeTestLogFormat {
  <# Validates that every line in stdout follows the [SEVERITY] log format or is empty.
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string[]]$StdoutLines
  )

  $validPrefixes = "\[(NOTICE |INFO   |DEBUG  )\]"
  $validLineRegex = "^($validPrefixes.*|)$"

  foreach ($line in $StdoutLines) {
    $line | Should -Match $validLineRegex -Because "Every line in stdout must follow the [SEVERITY] log format or be empty. Found unexpected line: '$line'"
  }
}
