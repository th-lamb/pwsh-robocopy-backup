param(
  [ValidateSet("powershell.exe", "pwsh.exe")]
  [string]$PowerShellExecutable = "powershell.exe"
)

$script:PowerShellExecutableToUse = if ([string]::IsNullOrWhiteSpace($PowerShellExecutable)) {
  "powershell.exe"
}
else {
  $PowerShellExecutable
}

# Pester can execute test blocks in scopes where script parameters are not directly visible.
# Mirror the selected executable into an environment variable for robust access in test blocks.
$env:SINGLEFILE_TEST_ENGINE = $script:PowerShellExecutableToUse

try {
  Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
}
catch {
  throw "Pester v5.0+ is required to run this test file. Install with: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force"
}

Describe "backup.ps1 Smoke Test (Single File)" {
  . "${PSScriptRoot}\SmokeTestHelpers.ps1"
  $script:SandboxRoot = $null
  $script:smokeTestPs1 = $null
  $script:smokeTestIni = $null
  $script:smokeTestConf = $null

  BeforeAll {
    . "${PSScriptRoot}\SmokeTestHelpers.ps1"
    $ProjectRoot = Get-ProjectRoot
    $script:SandboxRoot = Join-Path $ProjectRoot "Pester\resources\backup_ps1\smoke-tests\SingleFile"

    $sandboxPaths = Initialize-SmokeTestSandbox -SandboxRoot $script:SandboxRoot -ProjectRoot $ProjectRoot
    $script:smokeTestPs1 = $sandboxPaths.SmokeTestPs1
    $script:smokeTestIni = $sandboxPaths.SmokeTestIni
    $script:smokeTestConf = $sandboxPaths.SmokeTestConf

    # Create the sandbox source/ folder and some dummy files.
    $sourcePath = Join-Path $script:SandboxRoot "source\"
    $sourceDir = New-Item -ItemType Directory -Path $sourcePath -Force
    Set-Content -Path (Join-Path $sourceDir.FullName "test1.txt") -Value "test content 1"
    Set-Content -Path (Join-Path $sourceDir.FullName "test2.txt") -Value "test content 2"
  }

  It "Runs successfully and creates a job file for a single file" {
    $result = Invoke-SmokeTestProcess -PowerShellExecutable $env:SINGLEFILE_TEST_ENGINE -SmokeTestPs1 $script:smokeTestPs1 -WorkingDirectory $script:SandboxRoot

    # Assert: Check for evidence of a successful (simulated) run
    $result.Process.ExitCode | Should -Be 0

    if (Test-Path $result.StderrFile) {
      $stderr = Get-Content $result.StderrFile -Raw
      $stderr | Should -BeNullOrEmpty -Because "Standard Error should be empty. Found unexpected output/errors: `n$stderr"
    }

    $stdoutLines = Get-Content $result.StdoutFile
    $stdout = $stdoutLines -join "`n"

    Test-SmokeTestLogFormat -StdoutLines $stdoutLines

    $stdout | Should -Match "INFO.*1 job file\(s\) created."

    # Verify the content of the generated job file
    $jobFilesDir = Join-Path $script:SandboxRoot "destination\testuser\robocopy-jobs"
    $jobFiles = Get-ChildItem -Path $jobFilesDir -Filter "testcomputer-Job*.RCJ"
    $jobFiles.Count | Should -Be 1

    $jobContent = Get-Content $jobFiles[0].FullName -Raw
    $jobContent | Should -Match "/IF :: Include the following Files\."
    $jobContent | Should -Match "  test1.txt"
    $jobContent | Should -Not -Match "  test2.txt"
  }

  AfterAll {
    # Cleanup is now handled in BeforeAll to allow inspection of artifacts after the test.
  }
}
