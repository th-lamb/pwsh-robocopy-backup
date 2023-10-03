BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/network-functions.ps1"
}



Describe 'Get-ComputernameFromUncPath' {
  Context 'Correctly used' {
    It 'Returns computername from UNC path.' {
      $unc_path = "\\server"
      $expected = "server"

      $result = Get-ComputernameFromUncPath "${unc_path}"
      "${result}" | Should -Be "${expected}"
    }

    It 'Returns computername from UNC path with share.' {
      $unc_path = "\\server\share"
      $expected = "server"

      $result = Get-ComputernameFromUncPath "${unc_path}"
      "${result}" | Should -Be "${expected}"
    }

    It 'Returns computername from UNC path with subfolders.' {
      $unc_path = "\\server\share\foo\bar"
      $expected = "server"

      $result = Get-ComputernameFromUncPath "${unc_path}"
      "${result}" | Should -Be "${expected}"
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Get-ComputernameFromUncPath ""
      } | Should -Throw
    }

    It 'Throws exception is path is not a UNC path.' {
      $invalid_path = "\server"

      Mock Write-Error {}

      {
        Get-ComputernameFromUncPath "${invalid_path}"
      } | Should -Throw
    }
  }
}
