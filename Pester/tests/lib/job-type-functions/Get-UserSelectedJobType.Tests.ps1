BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-type-functions.ps1"

  # Simulate ini-values
  $Script:JOB_TYPE_SELECTION_MAX_WAITING_TIME_S = 3

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  #$Script:logfile = "${PSScriptRoot}/Get-UserSelectedJobType.Tests.log"
}



Describe 'Get-UserSelectedJobType' {
  Context 'Manual tests' {
    #TODO: Remove -Skip parameter if fully implemented.
    It 'User selects: Incremental' -Skip:$true {
      $default_job_type = "Incremental"
      $expected = "Incremental"

      Mock Add-LogMessage {}

      #TODO: Read the "I" from the console!
      #Mock Read-Host {return "I"}
      #Mock [Console]::KeyAvailable { return "I" }
      Mock ReadKey {return "I"}

      $result = Get-UserSelectedJobType "${default_job_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    #TODO:  [F]    Full backup                                  -> expected = Full
    #TODO:  [P]    Purge                                        -> expected = Purge
    #TODO:  [A]    Experimental: Files with Archive attribute   -> expected = Archive

    #TODO:  [S]    Start (use the default)                      -> expected = ?
    #TODO:  [ESC]  Cancel                                       -> expected = Cancel
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
