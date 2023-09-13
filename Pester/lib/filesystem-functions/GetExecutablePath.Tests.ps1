BeforeAll {
  . "${PSScriptRoot}/../../lib/filesystem-functions.ps1"

  # For messages in tested functions
  . $PSScriptRoot/../../lib/message-functions.ps1
  $__VERBOSE = 6

  # For logging in tested functions
  . $PSScriptRoot/../../lib/logging-functions.ps1
  $logfile = "${PSScriptRoot}/GetExecutablePath.Tests.Tests.log"
}



Describe 'GetExecutablePath' {
  Context 'File exists' {
    It 'Returns the specified file if it exists' {
      $path_spec  = "C:\TOOLS\CMD\robocopy\Win10_engl\Robocopy.exe"
      $expected   = "C:\TOOLS\CMD\robocopy\Win10_engl\Robocopy.exe"

      $result = GetExecutablePath 'ROBOCOPY' "${path_spec}" "${logfile}"
      "${result}" | Should -eq "${expected}"
    }

    It 'Returns the file from the Windows PATH if it exists' {
      $path_spec  = "robocopy"
      $expected   = "C:\Windows\system32\Robocopy.exe"

      $result = GetExecutablePath 'ROBOCOPY' "${path_spec}" "${logfile}"
      "${result}" | Should -eq "${expected}"
    }

    It 'Returns the file from the Windows PATH if it exists' {
      $path_spec  = "robocopy.exe"
      $expected   = "C:\Windows\system32\Robocopy.exe"

      $result = GetExecutablePath 'ROBOCOPY' "${path_spec}" "${logfile}"
      "${result}" | Should -eq "${expected}"
    }
  }

  Context 'File does not exist' {
    #TODO: Exits the script with exit-code 2 if the specified file doesn't exist.
  }

}
