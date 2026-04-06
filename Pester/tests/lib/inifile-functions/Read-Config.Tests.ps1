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
    It 'Writes a warning if the settings file is missing.' {
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
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty String.' {
      {
        Read-Config -IniFile ""
      } | Should -Throw
    }
  }
}
