# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\filesystem-functions.ps1"

  # For logging in tested functions
  $workingFolder = "${ProjectRoot}\Pester\resources\lib\filesystem-functions\"
  $script:BACKUP_LOGFILE = "${workingFolder}Test-FileExists.Tests.log"
}



Describe 'Test-FileExists' {
  Context 'Existing file' {
    It 'Returns $true for an existing file' {
      $path_spec  = "${workingFolder}Test1/test.ini"
      $expected   = $true

      $result = Test-FileExists "${path_spec}"
      $result | Should -Be $expected
    }
  }

  Context 'Non-existent file' {
    It 'Returns $false for a non-existent file' {
      $path_spec  = "${workingFolder}Test1/nonexistent.xml"
      $expected   = $false

      $result = Test-FileExists "${path_spec}"
      $result | Should -Be $expected
    }

    It 'Returns $false for an existing directory' {
      $path_spec  = "${workingFolder}Test1/"
      $expected   = $false

      $result = Test-FileExists "${path_spec}"
      $result | Should -Be $expected
    }

    It 'Returns $false for a non-existent directory' {
      $path_spec  = "${workingFolder}nonexistent_dir/"
      $expected   = $false

      $result = Test-FileExists "${path_spec}"
      $result | Should -Be $expected
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty String.' {
      {
        Test-FileExists ""
      } | Should -Throw
    }
  }
}
