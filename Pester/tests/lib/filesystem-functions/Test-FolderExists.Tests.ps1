BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/filesystem-functions/"
  $Script:logfile = "${workingFolder}/Test-FolderExists.Tests.log"
}



Describe 'Test-FolderExists' {
  Context 'Existing directory' {
    It 'Returns $true for an existing directory' {
      $path_spec  = "${workingFolder}Test1/"
      $expected   = $true

      $result = Test-FolderExists "${path_spec}"
      $result | Should -Be $expected
    }
  }

  Context 'Non-existent directory' {
    It 'Returns $false for a non-existent directory' {
      $path_spec  = "${workingFolder}Test0/"
      $expected   = $false

      $result = Test-FolderExists "${path_spec}"
      $result | Should -Be $expected
    }

    It 'Returns $false for an existing file' {
      $path_spec  = "${workingFolder}Test1/test.ini"
      $expected   = $false

      $result = Test-FolderExists "${path_spec}"
      $result | Should -Be $expected
    }

    It 'Returns $false for a non-existent file' {
      $path_spec  = "${workingFolder}Test1/test.xml"
      $expected   = $false

      $result = Test-FolderExists "${path_spec}"
      $result | Should -Be $expected
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Test-FolderExists ""
      } | Should -Throw
    }
  }
}
