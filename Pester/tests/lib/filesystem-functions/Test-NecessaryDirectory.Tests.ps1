BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
  $Script:workingFolder = "${ProjectRoot}Pester/resources/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  #$Script:logfile = "${PSScriptRoot}/Test-NecessaryDirectory.Tests.log"
}



Describe 'Test-NecessaryDirectory' {
  It 'Throws exception if specified directory does not exist.' {
    $nonexistent_dir = "${workingFolder}nonexistent_dir/"

    Mock LogAndShowMessage {}

    {
      Test-NecessaryDirectory 'Test' "${nonexistent_dir}" "${logfile}"
    } | Should -Throw
  }

  It 'Does not throw exception if specified directory exists.' {
    $nonexistent_dir = "${workingFolder}existing_dir/"

    {
      Test-NecessaryDirectory 'Test' "${nonexistent_dir}" "${logfile}"
    } | Should -Not -Throw
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
