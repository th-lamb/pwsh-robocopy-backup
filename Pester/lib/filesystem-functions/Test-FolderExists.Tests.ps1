BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
}



Describe 'Test-FolderExists' {
  It 'Returns $true for an existing directory' {
    $path_spec  = "${ProjectRoot}/Pester/resources/test_files/filesystem-functions/"
    $expected   = $true

    $result = Test-FolderExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for a non-existent directory' {
    $path_spec  = "${PSScriptRoot}/test_files2/"
    $expected   = $false

    $result = Test-FolderExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for an existing file' {
    $path_spec  = "${ProjectRoot}/Pester/resources/test_files/filesystem-functions/Test1/test.ini"
    $expected   = $false

    $result = Test-FolderExists "${path_spec}"
    $result | Should -Be $expected
  }

  It 'Returns $false for a non-existent file' {
    $path_spec  = "${ProjectRoot}/Pester/resources/test_files/filesystem-functions/Test1/test.xml"
    $expected   = $false

    $result = Test-FolderExists "${path_spec}"
    $result | Should -Be $expected
  }
}
