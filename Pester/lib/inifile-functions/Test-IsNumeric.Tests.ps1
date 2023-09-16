BeforeAll {
  . "${PSScriptRoot}/../../../lib/inifile-functions.ps1"
}



Describe 'Test-IsNumeric' {
  Context 'Numeric values' {
    It 'A number is numeric' {
      $value = 10
      $expected = $true

      $result = Test-IsNumeric $value
      $result | Should -Be $expected
    }

    It 'A string containing a number is numeric' {
      [string]$value = "10"
      $expected = $true

      $result = Test-IsNumeric $value
      $result | Should -Be $expected
    }
  }

  Context 'Non-numeric values' {
    It 'A string with other chars is NOT a number' {
      $value = "A 10"
      $expected = $false

      $result = Test-IsNumeric $value
      $result | Should -Be $expected
    }
  }
}
