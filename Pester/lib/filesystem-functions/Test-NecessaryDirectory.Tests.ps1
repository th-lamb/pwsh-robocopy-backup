BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
  $workingFolder = "${ProjectRoot}Pester/resources/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  $logfile = "${PSScriptRoot}/Test-NecessaryDirectory.Tests.log"
}



Describe 'Test-NecessaryDirectory' {
  It 'Throws exception if specified directory does not exist.' {
    $nonexistent_dir = "${workingFolder}nonexistent_dir/"

    # Omit output within the tested function.
    Mock LogAndShowMessage {}

    {
      Test-NecessaryDirectory 'Test' "${nonexistent_dir}" "${logfile}"
    } | Should -Throw
  }

  It 'Does not throw exception if specified directory exists.' {
    $nonexistent_dir = "${workingFolder}existing_dir/"

    $result = Test-NecessaryDirectory 'Test' "${nonexistent_dir}" "${logfile}"
    $result | Should -Be 0
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
