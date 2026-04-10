using module '..\..\..\..\lib\config-classes.psm1'

# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"
  . "${ProjectRoot}\lib\filesystem-functions.ps1"

  $script:workingFolder = "${ProjectRoot}\Pester\resources\lib\inifile-functions\"

  $script:IniFile = "${workingFolder}Read-Config.Tests.ini"

  # For messages in tested functions
  $script:config = [ScriptConfig]::new()
  $config.General.__VERBOSE = 6
}



Describe 'Read-Config' {
  Context 'Error Handling' {
    It 'Writes a warning if the INI file is missing.' {
      $IniFile = "NON_EXISTENT_FILE.ini"
      $ExpectedWarning = "Settings file not found: [$IniFile]. Using default values."

      # Mock Write-WarningMsg to capture the message
      Mock Write-WarningMsg {
        param($message)
        $script:actualWarning = $message
      }

      $result = Read-Config -IniFile $IniFile

      $script:actualWarning | Should -Be $ExpectedWarning
      $result.GetType().Name | Should -Be "ScriptConfig"
      $result.General.__VERBOSE | Should -Be 6
    }

    It 'Normalizes directories with missing trailing backslash' {
      $ResourcesDir = "${ProjectRoot}\Pester\resources\lib\inifile-functions\Read-Config"
      $IniFile = "${ResourcesDir}\INI-without-backslash-in-middle.ini"

      $ExpectedBackupBaseDir = "C:\Backups\"

      $Config = Read-Config -IniFile $IniFile
      $Config.Normalize()

      $Config.Directories.BACKUP_BASE_DIR | Should -Be "${ExpectedBackupBaseDir}"
    }

    It 'Normalizes combined paths with missing backslash in the middle' {
      <# Tests missing backslash in the middle. Example:
        - The user defines `BACKUP_BASE_DIR=C:\Backups` (without trailing backslash) and
        - re-uses this variable in `BACKUP_USER_BASE_DIR=${BACKUP_BASE_DIR}%USERNAME%\`.
      #>
      $ResourcesDir = "${ProjectRoot}\Pester\resources\lib\inifile-functions\Read-Config"
      $IniFile = "${ResourcesDir}\INI-without-backslash-in-middle.ini"

      $ExpectedBackupUserBaseDir = "C:\Backups\testuser\"

      $Config = Read-Config -IniFile $IniFile
      $Config.Normalize()

      $Config.Directories.BACKUP_USER_BASE_DIR | Should -Be "${ExpectedBackupUserBaseDir}"
    }
  }

  Context 'Top-level settings (Finding 5)' {
    <# These tests create their own INI files in a temporary directory ($env:TEMP)
      for isolation and automatic cleanup, rather than using $script:workingFolder.
    #>
    BeforeAll {
      $script:tempDir = Join-Path $env:TEMP "Pester-Read-Config-TopLevel"
      if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
      New-Item $tempDir -ItemType Directory | Out-Null
    }

    AfterAll {
      if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }

    It 'Assigns settings before any section header to the General container.' {
      $IniFile = Join-Path $tempDir "TopLevel.ini"
      @'
__VERBOSE=3
[Directories]
BACKUP_BASE_DIR=C:\MyBackup
'@ | Set-Content $IniFile

      $Config = Read-Config -IniFile $IniFile

      $Config.General.__VERBOSE | Should -Be 3
      $Config.Directories.BACKUP_BASE_DIR | Should -Be "C:\MyBackup\"
    }

    It 'Correctly handles cross-references and scope.' {
      # Note: For cross-references to work across different containers,
      # the variables must be set in the caller's scope (which Update-ConfigProperty does).
      $IniFile = Join-Path $tempDir "TopLevelCrossref.ini"
      @'
__VERBOSE=1
[Directories]
BACKUP_BASE_DIR=C:\TopLevel
BACKUP_USER_BASE_DIR=${BACKUP_BASE_DIR}User\
'@ | Set-Content $IniFile

      $Config = Read-Config -IniFile $IniFile

      $Config.General.__VERBOSE | Should -Be 1
      $Config.Directories.BACKUP_BASE_DIR | Should -Be "C:\TopLevel\"
      $Config.Directories.BACKUP_USER_BASE_DIR | Should -Be "C:\TopLevel\User\"
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty String.' {
      {
        Read-Config -IniFile ""
      } | Should -Throw
    }
  }
}
