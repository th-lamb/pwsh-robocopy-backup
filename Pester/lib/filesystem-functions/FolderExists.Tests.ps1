BeforeAll {
  . "${PSScriptRoot}/../../../lib/filesystem-functions.ps1"
}



Describe 'FolderExists' {
  It 'Returns $true for an existing directory' {
    $path_spec  = "${PSScriptRoot}/../../resources/test_files/"
    $expected   = $true

    $result = FolderExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for a non-existent directory' {
    $path_spec  = "${PSScriptRoot}\test_files2\"
    $expected   = $false

    $result = FolderExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for an existing file' {
    $path_spec  = "${PSScriptRoot}\test_files\Test1\test.ini"
    $expected   = $false

    $result = FolderExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for a non-existent file' {
    $path_spec  = "${PSScriptRoot}\test_files\Test1\test.xml"
    $expected   = $false

    $result = FolderExists "${path_spec}"
    $result | Should -Be $expected
  }
}
