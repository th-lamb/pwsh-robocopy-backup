BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/network-functions.ps1"
}



Describe 'Get-ComputernameFromUncPath' {
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

  It 'Throws exception is path is not a UNC path.' {
    $unc_path = "\server"

    Mock Write-Error {}

    {
      Get-ComputernameFromUncPath "${unc_path}"
    } | Should -Throw
  }
}
