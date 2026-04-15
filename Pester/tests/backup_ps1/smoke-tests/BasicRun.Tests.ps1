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
$env:BASICRUN_TEST_ENGINE = $script:PowerShellExecutableToUse

try {
  Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
}
catch {
  throw "Pester v5.0+ is required to run this test file. Install with: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force"
}

Describe "backup.ps1 Smoke Test" {
  . "${PSScriptRoot}\SmokeTestHelpers.ps1"
  $script:SandboxRoot = $null
  $script:smokeTestPs1 = $null
  $script:smokeTestIni = $null
  $script:smokeTestConf = $null

  BeforeAll {
    . "${PSScriptRoot}\SmokeTestHelpers.ps1"
    $ProjectRoot = Get-ProjectRoot
    $script:SandboxRoot = Join-Path $ProjectRoot "Pester\resources\backup_ps1\smoke-tests\BasicRun"

    $sandboxPaths = Initialize-SmokeTestSandbox -SandboxRoot $script:SandboxRoot -ProjectRoot $ProjectRoot
    $script:smokeTestPs1 = $sandboxPaths.SmokeTestPs1
    $script:smokeTestIni = $sandboxPaths.SmokeTestIni
    $script:smokeTestConf = $sandboxPaths.SmokeTestConf

    # Create the sandbox source/ folder and some dummy files.
    $sourcePath = Join-Path $script:SandboxRoot "source\"
    $sourceDir = New-Item -ItemType Directory -Path $sourcePath -Force
    Set-Content -Path (Join-Path $sourceDir.FullName "test1.txt") -Value "test content 1"
    Set-Content -Path (Join-Path $sourceDir.FullName "test2.txt") -Value "test content 2"
    Set-Content -Path (Join-Path $sourceDir.FullName "exclude_me.txt") -Value "I should be excluded"
    Set-Content -Path (Join-Path $sourceDir.FullName "test3.tmp") -Value "I should be excluded too"
  }

  It "Runs successfully with -SkipExecution and simulates the workflow" {
    $result = Invoke-SmokeTestProcess -PowerShellExecutable $env:BASICRUN_TEST_ENGINE -SmokeTestPs1 $script:smokeTestPs1 -WorkingDirectory $script:SandboxRoot

    # Assert: Check for evidence of a successful (simulated) run
    $result.Process.ExitCode | Should -Be 0

    if (Test-Path $result.StderrFile) {
      $stderr = Get-Content $result.StderrFile -Raw
      $stderr | Should -BeNullOrEmpty -Because "Standard Error should be empty. Found unexpected output/errors: `n$stderr"
    }

    $stdoutLines = Get-Content $result.StdoutFile
    $stdout = $stdoutLines -join "`n"

    Test-SmokeTestLogFormat -StdoutLines $stdoutLines

    $stdout | Should -Match "INFO.*Backup Script version .* started."
    $stdout | Should -Match "INFO.*Reading the settings file."
    $stdout | Should -Match "INFO.*Settings file read."
    $stdout | Should -Match "INFO.*Checking necessary directories and files..."
    $stdout | Should -Match "INFO.*Necessary directories and files checked."
    $stdout | Should -Match "INFO.*(selected|Using the default):.*Incremental"
    $stdout | Should -Match "INFO.*Archiving previous jobs..."
    $stdout | Should -Match "INFO.*Creating job files..."
    $stdout | Should -Match "INFO.*1 job file\(s\) created."
    $stdout | Should -Match "INFO.*Running 1 job\(s\)..."
    $stdout | Should -Match "INFO.*Skipping execution as requested \(-SkipExecution\)."
    $stdout | Should -Match "INFO.*Script finished in .*"
  }

  AfterAll {
    # Cleanup is now handled in BeforeAll to allow inspection of artifacts after the test.
  }
}
