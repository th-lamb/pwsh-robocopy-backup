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

$env:FIRSTRUN_TEST_ENGINE = $script:PowerShellExecutableToUse

try {
  Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
}
catch {
  throw "Pester v5.0+ is required to run this test file. Install with: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force"
}

Describe "backup.ps1 New User Experience Smoke Test" {
  . "${PSScriptRoot}\SmokeTestHelpers.ps1"
  $script:SandboxRoot = $null
  $script:smokeTestPs1 = $null

  BeforeAll {
    . "${PSScriptRoot}\SmokeTestHelpers.ps1"
    $script:ProjectRoot = Get-ProjectRoot
    $script:SandboxRoot = Join-Path $script:ProjectRoot "Pester\resources\backup_ps1\smoke-tests\FirstRun"

    # Custom sandbox setup for FirstRun: we don't want to pre-copy backup.ini or dir-list.conf
    function Initialize-CleanFirstRunSandbox {
      if (Test-Path $script:SandboxRoot) {
        Get-ChildItem -Path $script:SandboxRoot -Exclude ".gitignore" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
      }
      $null = New-Item -ItemType Directory -Path $script:SandboxRoot -Force

      $script:smokeTestPs1 = Join-Path $script:SandboxRoot "smoke-test.ps1"
      Copy-Item (Join-Path $script:ProjectRoot "backup.ps1") -Destination $script:smokeTestPs1 -Force
      Copy-Item (Join-Path $script:ProjectRoot "example-backup.ini") -Destination $script:SandboxRoot -Force

      $libPath = Join-Path $script:SandboxRoot "lib\"
      $null = New-Item -ItemType Directory -Path $libPath -Force
      Get-ChildItem -Path (Join-Path $script:ProjectRoot "lib\") -Include "*.ps1", "*.psm1" -Recurse | Copy-Item -Destination $libPath -Force

      $templatesPath = Join-Path $script:SandboxRoot "templates\"
      $null = New-Item -ItemType Directory -Path $templatesPath -Force
      Get-ChildItem -Path (Join-Path $script:ProjectRoot "templates\*") -Include "*.RCJ", "dir-list-template.conf" | Copy-Item -Destination $templatesPath -Force
    }
  }

  Context "Fresh Run (Zero Local Configuration, Template exists)" {
    BeforeAll {
      Initialize-CleanFirstRunSandbox
    }

    It "Copies example-backup.ini to backup.ini, creates dir-list.conf in BACKUP_DIR, and runs successfully" {
      $result = Invoke-SmokeTestProcess -PowerShellExecutable $env:FIRSTRUN_TEST_ENGINE -SmokeTestPs1 $script:smokeTestPs1 -WorkingDirectory $script:SandboxRoot

      $result.Process.ExitCode | Should -Be 0

      $stdoutLines = Get-Content $result.StdoutFile
      $stdout = $stdoutLines -join "`n"

      $stdout | Should -Match "INFO.*Settings file \[backup.ini\] not found\. Creating from \[example-backup\.ini\]\.\.\."
      $stdout | Should -Match "INFO.*Settings file \[backup.ini\] successfully created\."
      $stdout | Should -Match "INFO.*File created from template\."

      # ASSERT: Filesystem checks
      $expectedIni = Join-Path $script:SandboxRoot "backup.ini"
      Test-Path $expectedIni | Should -Be $true -Because "backup.ini should be created from the example."

      # Default BACKUP_DIR is .\Backup\%Username%\%Computername%\
      $userName = [System.Environment]::UserName
      $computerName = [System.Environment]::MachineName
      $expectedBackupDir = Join-Path $script:SandboxRoot "Backup\$userName\$computerName"
      $expectedDirList = Join-Path $expectedBackupDir "dir-list.conf"

      Test-Path $expectedBackupDir | Should -Be $true -Because "The directory structure $expectedBackupDir should be created."
      Test-Path $expectedDirList | Should -Be $true -Because "The dir-list.conf should be created in the BACKUP_DIR."
    }
  }

  Context "Fresh Run (No ini files at all)" {
    BeforeAll {
      Initialize-CleanFirstRunSandbox
      Remove-Item (Join-Path $script:SandboxRoot "example-backup.ini") -Force
    }

    It "Warns about missing configuration and uses defaults" {
      $result = Invoke-SmokeTestProcess -PowerShellExecutable $env:FIRSTRUN_TEST_ENGINE -SmokeTestPs1 $script:smokeTestPs1 -WorkingDirectory $script:SandboxRoot

      $result.Process.ExitCode | Should -Be 0

      $stdout = Get-Content $result.StdoutFile -Raw
      $stdout | Should -Match "WARNING.*No settings file found\. Using default values\."
    }
  }

  Context "Execution from a different directory (Relative Pathing)" {
    BeforeAll {
      Initialize-CleanFirstRunSandbox
      $script:WorkDir = Join-Path $script:SandboxRoot "MyDataFolder"
      if (Test-Path $script:WorkDir) {
        Remove-Item -Path $script:WorkDir -Recurse -Force -ErrorAction SilentlyContinue
      }
      $null = New-Item -ItemType Directory -Path $script:WorkDir -Force
    }

    It "Creates configuration and backups relative to the caller''s directory" {
      $result = Invoke-SmokeTestProcess -PowerShellExecutable $env:FIRSTRUN_TEST_ENGINE -SmokeTestPs1 $script:smokeTestPs1 -WorkingDirectory $script:WorkDir

      $result.Process.ExitCode | Should -Be 0

      # ASSERT: Files should appear in MyDataFolder, not the sandbox root (where the script is)
      $userName = [System.Environment]::UserName
      $computerName = [System.Environment]::MachineName
      $expectedBackupDir = Join-Path $script:WorkDir "Backup\$userName\$computerName"
      $expectedDirList = Join-Path $expectedBackupDir "dir-list.conf"

      Test-Path $expectedBackupDir | Should -Be $true -Because "Backup folder structure should be relative to current working directory."
      Test-Path $expectedDirList | Should -Be $true -Because "dir-list.conf should be created in the BACKUP_DIR relative to the working directory."

      # Crucially check that it DID NOT create it in the script dir
      $scriptDirBackup = Join-Path $script:SandboxRoot "Backup"
      Test-Path $scriptDirBackup | Should -Be $false -Because "Backup folder should NOT be created in the script directory."
    }
  }
}
