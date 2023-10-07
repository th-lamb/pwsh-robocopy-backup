BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/inifile-functions.ps1"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6
}



Describe 'Write-FormattedValueList' {
  #TODO: Context 'Correctly used'
#  Context 'Correctly used' {
#    It '' {
#    }
#  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with missing parameters.' {
      <# Note: the function must not specify
        - [Parameter(Mandatory=$true)] and
        - [AllowEmptyCollection()]
      #>
      Mock Write-Error {}       # Avoid messaged during the test.
      Mock Write-WarningMsg {}  # Avoid messaged during the test.

      {
        Write-FormattedValueList
      } | Should -Throw "Wrong number of parameters provided!"

      {
        Write-FormattedValueList @()
      } | Should -Throw "Wrong number of parameters provided!"

      {
        Write-FormattedValueList @() @()
      } | Should -Not -Throw "Wrong number of parameters provided!"
    }

    It 'Writes only a warning when called with a null value.' {
      Mock Write-WarningMsg {} -Verifiable
      Mock Write-DebugMsg {} -Verifiable

      Write-FormattedValueList $null @()
      Write-FormattedValueList @() $null
      Write-FormattedValueList $null $null

      Should -Invoke -CommandName "Write-WarningMsg" -Times 3 -Exactly
      Should -Invoke -CommandName "Write-DebugMsg" -Times 0
    }

    It 'Writes only a warning when called with an empty collection.' {
      Mock Write-WarningMsg {} -Verifiable
      Mock Write-DebugMsg {} -Verifiable

      Write-FormattedValueList @() @("foo")
      Write-FormattedValueList @("foo") @()
      Write-FormattedValueList @() @()

      Should -Invoke -CommandName "Write-WarningMsg" -Times 3 -Exactly
      Should -Invoke -CommandName "Write-DebugMsg" -Times 0
    }

    It 'Writes only a warning when called with an empty String.' {
      Mock Write-WarningMsg {} -Verifiable
      Mock Write-DebugMsg {} -Verifiable

      Write-FormattedValueList "" @("foo")
      Write-FormattedValueList @("foo") ""
      Write-FormattedValueList "" ""

      Should -Invoke -CommandName "Write-WarningMsg" -Times 3 -Exactly
      Should -Invoke -CommandName "Write-DebugMsg" -Times 0
    }
  }
}
