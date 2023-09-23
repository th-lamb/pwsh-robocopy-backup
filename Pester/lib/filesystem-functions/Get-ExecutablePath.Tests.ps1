BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $script:__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
#  $script:logfile = "${PSScriptRoot}/Get-ExecutablePath.Tests.log"
}



Describe 'Get-ExecutablePath' {
  Context 'File exists' {
    It 'Returns the specified file if it exists' {
      $path_spec  = "C:\TOOLS\CMD\robocopy\Win10_engl\Robocopy.exe"
      $expected   = "C:\TOOLS\CMD\robocopy\Win10_engl\Robocopy.exe"

      $result = Get-ExecutablePath 'ROBOCOPY' "${path_spec}" "${logfile}"
      "${result}" | Should -Be "${expected}"
    }

    It 'Returns the file from the Windows PATH if it exists' {
      $path_spec  = "robocopy.exe"
      $expected   = "C:\Windows\system32\Robocopy.exe"

      $result = Get-ExecutablePath 'ROBOCOPY' "${path_spec}" "${logfile}"
      "${result}" | Should -Be "${expected}"
    }

    It 'Returns the file from the Windows PATH if called without the suffix (.exe)' {
      $path_spec  = "robocopy"
      $expected   = "C:\Windows\system32\Robocopy.exe"

      $result = Get-ExecutablePath 'ROBOCOPY' "${path_spec}" "${logfile}"
      "${result}" | Should -Be "${expected}"
    }
  }

  Context 'File does not exist' {
    It 'Throws exception if the specified file does not exist.' {
      $path_spec  = "robocopy2.exe"

      Mock LogAndShowMessage {}

      {
        Get-ExecutablePath 'ROBOCOPY' "${path_spec}" "${logfile}" | Out-Null
      } | Should -Throw
    }
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
