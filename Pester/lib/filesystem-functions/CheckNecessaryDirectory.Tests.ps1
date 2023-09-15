BeforeAll {
  . "${PSScriptRoot}/../../../lib/filesystem-functions.ps1"

  # For messages in tested functions
  . "${PSScriptRoot}/../../../lib/message-functions.ps1"
  $__VERBOSE = 6

  # For logging in tested functions
  . "${PSScriptRoot}/../../../lib/logging-functions.ps1"
  $logfile = "${PSScriptRoot}/CheckNecessaryDirectory.Tests.log"
}



Describe 'CheckNecessaryDirectory' {
  It 'Throws exception if specified directory does not exist.' {
    $nonexistent_dir = "${PSScriptRoot}/../../resources/test_files/nonexistent_dir"

    {
      CheckNecessaryDirectory 'Test' "${nonexistent_dir}" "${logfile}"
    } | Should -Throw
  }

  It 'Does not throw exception if specified directory exists.' {
    $nonexistent_dir = "${PSScriptRoot}/../../resources/test_files/existing_dir"

    $result = CheckNecessaryDirectory 'Test' "${nonexistent_dir}" "${logfile}"
    $result | Should -Be 0
  }
}



AfterAll {
  Remove-Item "${logfile}"
}
