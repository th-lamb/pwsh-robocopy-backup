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

      Read-Config -IniFile $IniFile

      $script:actualWarning | Should -Be $ExpectedWarning
    }

    It 'Returns a config with default values if INI file is missing.' {
      <# Note: the default initialization of ScriptConfig is tested in another test.
        - See: `Pester\tests\lib\config-classes\ScriptConfig.Tests.ps1`
        - Here, we just test whether Read-Config returns this Configuration Object.
      #>
      $IniFile = "NON_EXISTENT_FILE.ini"

      # Mock Write-WarningMsg to ignore the warning
      Mock Write-WarningMsg {}

      $result = Read-Config -IniFile $IniFile

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

  #TODO: find a better name for this context.
  Context 'Normal cases' {
    <# These tests create their own INI files in a temporary directory ($env:TEMP)
      for isolation and automatic cleanup, rather than using $script:workingFolder.
    #>
    BeforeAll {
      $script:tempDir = Join-Path $env:TEMP "Pester-Read-Config-NormalCases"
      if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
      New-Item $tempDir -ItemType Directory | Out-Null
    }

    AfterAll {
      if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }

    It 'should overwrite default values with settings from the INI file' {
      $Config = [ScriptConfig]::new()

      # Default values
      $Config.General.__VERBOSE | Should -Be 6
      $Config.Directories.BACKUP_BASE_DIR | Should -Be ".\Backup\"

      # INI file with different values
      $IniFile = Join-Path $tempDir "Overwrite.ini"
      @'
[General]
__VERBOSE=3
[Directories]
BACKUP_BASE_DIR=C:\MyBackup
'@ | Set-Content $IniFile

      $Config = Read-Config -IniFile $IniFile

      # Check the new values
      $Config.General.__VERBOSE | Should -Be 3
      $Config.Directories.BACKUP_BASE_DIR | Should -Be "C:\MyBackup\"
    }

    It 'correctly handles spaces around "=" in the INI file' {
      <#TODO: Ignore rule PSAvoidTrailingWhitespace for this test.
        Notes:
        - Disabling and enabling before and after the file does not work.
        - An inline comment "# psscriptanalyzer-disable PSAvoidTrailingWhitespace" behind the value
          with trailing whitespaces works and disables the rule - but also breaks the test!
        - Pragmas also don't work.

        Workaround:
        Use "   BACKUP_JOB_DIR   =   C:\Parent\UserDir\robocopy-jobs\" without trailing whitespace.
      #>

      $IniFile = Join-Path $tempDir "WithSpaces.ini"
      # psscriptanalyzer-disable PSAvoidTrailingWhitespace
      #pragma warning disable PSAvoidTrailingWhitespace
      @'
[Directories]
BACKUP_BASE_DIR = C:\Parent\
BACKUP_USER_BASE_DIR =C:\Parent\UserDir\
BACKUP_DIR= C:\Parent\<Username>\<Computername>\
   BACKUP_JOB_DIR   =   C:\Parent\UserDir\robocopy-jobs\
'@ | Set-Content $IniFile
      # psscriptanalyzer-enable PSAvoidTrailingWhitespace
      #pragma warning restore PSAvoidTrailingWhitespace

      $Config = Read-Config -IniFile $IniFile

      $Config.Directories.BACKUP_BASE_DIR       | Should -Be "C:\Parent\"
      $Config.Directories.BACKUP_USER_BASE_DIR  | Should -Be "C:\Parent\UserDir\"
      $Config.Directories.BACKUP_DIR            | Should -Be "C:\Parent\<Username>\<Computername>\"
      $Config.Directories.BACKUP_JOB_DIR        | Should -Be "C:\Parent\UserDir\robocopy-jobs\"
    }
  }

  Context 'Cross-references between properties' {
    <# These tests create their own INI files in a temporary directory ($env:TEMP)
      for isolation and automatic cleanup, rather than using $script:workingFolder.
    #>
    BeforeAll {
      $script:tempDir = Join-Path $env:TEMP "Pester-Read-Config-Crossref"
      if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
      New-Item $tempDir -ItemType Directory | Out-Null
    }

    AfterAll {
      if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }

    It 'Correctly handles cross-references and scope within the same container.' {
      # Note: For cross-references to work across different containers,
      # the variables must be set in the caller's scope (which Update-ConfigProperty does).
      $IniFile = Join-Path $tempDir "CrossrefSameContainer.ini"
      @'
[Directories]
BACKUP_BASE_DIR=C:\Parent
BACKUP_USER_BASE_DIR=${BACKUP_BASE_DIR}UserDir\
'@ | Set-Content $IniFile

      $Config = Read-Config -IniFile $IniFile

      $Config.Directories.BACKUP_BASE_DIR       | Should -Be "C:\Parent\"
      $Config.Directories.BACKUP_USER_BASE_DIR  | Should -Be "C:\Parent\UserDir\"
    }

    It 'Correctly handles cross-references and scope across two containers.' {
      # Note: For cross-references to work across different containers,
      # the variables must be set in the caller's scope (which Update-ConfigProperty does).
      $IniFile = Join-Path $tempDir "CrossrefDifferentContainers.ini"
      @'
[Directories]
BACKUP_BASE_DIR=C:\Parent
[Logging settings]
TRACE_LOG_LOCAL_DIR=${BACKUP_BASE_DIR}LogDir\
'@ | Set-Content $IniFile

      $Config = Read-Config -IniFile $IniFile

      $Config.Directories.BACKUP_BASE_DIR | Should -Be "C:\Parent\"
      $Config.Logging.TRACE_LOG_LOCAL_DIR | Should -Be "C:\Parent\LogDir\"
    }
  }

  Context 'Top-level settings' {
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
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty String.' {
      {
        Read-Config -IniFile ""
      } | Should -Throw
    }
  }
}
