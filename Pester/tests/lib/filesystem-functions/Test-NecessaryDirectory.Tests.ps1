BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  $Script:logfile = "${workingFolder}/Test-NecessaryDirectory.Tests.log"
}



Describe 'Test-NecessaryDirectory' {
  Context 'Non-existent directory' {
    It 'Throws exception if specified directory does not exist.' {
      $nonexistent_dir = "${workingFolder}nonexistent_dir/"

      Mock LogAndShowMessage {}

      {
        Test-NecessaryDirectory 'Test' "${nonexistent_dir}" "${logfile}"
      } | Should -Throw
    }
  }

  Context 'Existing directory' {
    It 'Does not throw exception if specified directory exists.' {
      $existing_dir = "${workingFolder}existing_dir/"

      {
        Test-NecessaryDirectory 'Test' "${existing_dir}" "${logfile}"
      } | Should -Not -Throw
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty definition_name.' {
      {
        Test-NecessaryDirectory ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty path.' {
      {
        Test-NecessaryDirectory 'Test' ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty logfile.' {
      $existing_dir = "${workingFolder}existing_dir/"

      {
        Test-NecessaryDirectory 'Test' "${existing_dir}" ""
      } | Should -Throw
    }
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
