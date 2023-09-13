BeforeAll {
  . "${PSScriptRoot}/../../../lib/filesystem-functions.ps1"
}



Describe 'FileExists' {
  It 'Returns $true for an existing file' {
    $path_spec  = "${PSScriptRoot}/../../resources/test_files/Test1/test.ini"
    $expected   = $true

    $result = FileExists "${path_spec}"
    $result | Should -be $expected
  }

  It 'Returns $false for a non-existent file' {
    $path_spec  = "${PSScriptRoot}\test_files\Test1\test.xml"
    $expected   = $false

    $result = FileExists "${path_spec}"
    $result | Should -be $expected
  }

  It 'Returns $false for an existing directory' {
    $path_spec  = "${PSScriptRoot}\test_files\Test1\"
    $expected   = $false

    $result = FileExists "${path_spec}"
    $result | Should -be $expected
  }

  It 'Returns $false for a non-existent directory' {
    $path_spec  = "${PSScriptRoot}\test_files2\"
    $expected   = $false

    $result = FileExists "${path_spec}"
    $result | Should -be $expected
  }
}
