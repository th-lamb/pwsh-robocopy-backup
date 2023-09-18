BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
}



Describe 'Test-FileExists' {
  It 'Returns $true for an existing file' {
    $path_spec  = "${ProjectRoot}/Pester/resources/test_files/filesystem-functions/Test1/test.ini"
    $expected   = $true

    $result = Test-FileExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for a non-existent file' {
    $path_spec  = "${PSScriptRoot}\test_files\Test1\test.xml"
    $expected   = $false

    $result = Test-FileExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for an existing directory' {
    $path_spec  = "${PSScriptRoot}\test_files\Test1\"
    $expected   = $false

    $result = Test-FileExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for a non-existent directory' {
    $path_spec  = "${PSScriptRoot}\test_files2\"
    $expected   = $false

    $result = Test-FileExists "${path_spec}"
    $result | Should -Be $expected
  }
}
