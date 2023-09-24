BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/message-functions.ps1"
}



<# Returns false if ${__VERBOSE} is not defined or 
  if ${__VERBOSE} is not between 0..7.
#>

Describe 'Test-VerbosityIsDefined' {
  Context 'Legal values' {
    It 'Returns $true for 0..7.' {
      $values = @(0, 1, 2, 3, 4, 5, 6, 7)

      for ($i=0; $i -lt $values.Length; $i++) {
        $Script:__VERBOSE = $values[$i]

        Test-VerbosityIsDefined | Should -Be $true
      }
    }
  }

  Context 'Illegal values' {
    It 'Returns $false for values `< 0 or `> 7.' {
      $values = @(-2, -1, 8, 9)

      for ($i=0; $i -lt $values.Length; $i++) {
        $Script:__VERBOSE = $values[$i]

        Test-VerbosityIsDefined | Should -Be $false
      }
    }

    It 'Returns $false for non-numeric values.' {
      $Script:__VERBOSE = "foo"

      Test-VerbosityIsDefined | Should -Be $false
    }
  }
}
