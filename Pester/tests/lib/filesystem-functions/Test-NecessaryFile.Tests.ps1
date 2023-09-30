BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  $Script:logfile = "${workingFolder}/Test-NecessaryFile.Tests.log"
}



Describe 'Test-NecessaryFile' {
  Context 'Non-existent file' {
    It 'Throws exception if specified file does not exist.' {
      $nonexistent_file = "${workingFolder}nonexistent_file"

      Mock LogAndShowMessage {}

      {
        Test-NecessaryFile 'Test' "${nonexistent_file}" "${logfile}"
      } | Should -Throw
    }
  }

  Context 'Existing file' {
    It 'Does not throw exception if specified file exists.' {
      $existing_file = "${workingFolder}existing_file"

      {
        Test-NecessaryFile 'Test' "${existing_file}" "${logfile}"
      } | Should -Not -Throw
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty definition_name.' {
      {
        Test-NecessaryFile ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty path.' {
      {
        Test-NecessaryFile 'Test' ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty logfile.' {
      $existing_file = "${workingFolder}existing_file"

      {
        Test-NecessaryFile 'Test' "${existing_file}" ""
      } | Should -Throw
    }
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
