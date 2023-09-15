BeforeAll {
  . "${PSScriptRoot}/../../../lib/filesystem-functions.ps1"

  # For messages in tested functions
  . "${PSScriptRoot}/../../../lib/message-functions.ps1"
  $__VERBOSE = 6

  # For logging in tested functions
  . "${PSScriptRoot}/../../../lib/logging-functions.ps1"
  $logfile = "${PSScriptRoot}/CheckNecessaryFile.Tests.log"
}



Describe 'CheckNecessaryFile' {
  It 'Throws exception if specified file does not exist.' {
    $nonexistent_dir = "${PSScriptRoot}/../../resources/test_files/nonexistent_file"

    {
      CheckNecessaryFile 'Test' "${nonexistent_dir}" "${logfile}"
    } | Should -Throw
  }

  It 'Does not throw exception if specified file exists.' {
    $nonexistent_dir = "${PSScriptRoot}/../../resources/test_files/existing_file"

    $result = CheckNecessaryFile 'Test' "${nonexistent_dir}" "${logfile}"
    $result | Should -Be 0
  }
}



AfterAll {
  Remove-Item "${logfile}"
}
