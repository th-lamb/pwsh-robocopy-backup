$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"
  . "${ProjectRoot}\lib\filesystem-functions.ps1"

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
        $Script:actualWarning = $message
      }

      $result = Read-Config -IniFile $IniFile

      $Script:actualWarning | Should -Be $ExpectedWarning
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

    <#TODO: Test missing backslash in the middle. Example:
      - The user defines `BACKUP_BASE_DIR=C:\Backups` (without trailing backslash) and
      - re-uses this variable in `BACKUP_USER_BASE_DIR=${BACKUP_BASE_DIR}%USERNAME%\`.
      - When `$Config.Normalize()` is called, the expanded paths are already assembled and
        the *missing "\" is in the middle* of the string!
    #>
    # It 'Normalizes combined paths with missing "\" in the middle' {
    #   $ResourcesDir = "${ProjectRoot}\Pester\resources\lib\inifile-functions\Read-Config"
    #   $IniFile = "${ResourcesDir}\INI-without-backslash-in-middle.ini"

    #   $ExpectedBackupUserBaseDir = "C:\Backups\testuser\"

    #   $Config = Read-Config -IniFile $IniFile
    #   $Config.Normalize()

    #   $Config.Directories.BACKUP_USER_BASE_DIR | Should -Be "${ExpectedBackupUserBaseDir}"
    # }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty String.' {
      {
        Read-Config -IniFile ""
      } | Should -Throw
    }
  }
}
