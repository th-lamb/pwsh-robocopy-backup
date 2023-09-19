BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
  $workingFolder = "${ProjectRoot}Pester/resources/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  #$logfile = "${PSScriptRoot}/Test-NecessaryFile.Tests.log"
}



Describe 'Test-NecessaryFile' {
  It 'Throws exception if specified file does not exist.' {
    $nonexistent_dir = "${workingFolder}nonexistent_file"

    Mock LogAndShowMessage {}

    {
      Test-NecessaryFile 'Test' "${nonexistent_dir}" "${logfile}"
    } | Should -Throw
  }

  It 'Does not throw exception if specified file exists.' {
    $nonexistent_dir = "${workingFolder}existing_file"

    $result = Test-NecessaryFile 'Test' "${nonexistent_dir}" "${logfile}"
    $result | Should -Be 0
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
