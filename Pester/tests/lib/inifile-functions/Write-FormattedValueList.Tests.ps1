BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/inifile-functions.ps1"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6
}



Describe 'Write-FormattedValueList' {
  Context 'Correctly used' {
#    It '' {
#    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called without var_names.' {
      #Write-FormattedValueList
      #Write-FormattedValueList @()

      Mock Write-Error {}   # Avoid messaged during the test.

      {
        Write-FormattedValueList
      } | Should -Throw
    }
  }
}
