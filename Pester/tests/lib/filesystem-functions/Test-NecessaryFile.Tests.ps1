BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  #$Script:logfile = "${PSScriptRoot}/Test-NecessaryFile.Tests.log"
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

    {
      Test-NecessaryFile 'Test' "${nonexistent_dir}" "${logfile}"
    } | Should -Not -Throw
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
