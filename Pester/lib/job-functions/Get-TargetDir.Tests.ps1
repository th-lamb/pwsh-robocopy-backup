BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-functions.ps1"

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  #$Script:logfile = "${PSScriptRoot}/Get-DirlistLineType.Tests.log"
}



Describe 'Get-TargetDir' {
  Context 'Expected paths' {
    It 'Returns correct target-dir for folders.' {
      $base_dir     = "C:\Backup\"
      $folder_spec  = "C:\Test\"
      $expected     = "C:\Backup\C\Test\"

      $result = Get-TargetDir "${base_dir}" "${folder_spec}"
      $result | Should -Be "${expected}"
    }

    It 'Corrects missing path separators.' {
      $base_dir     = "C:\Backup"
      $folder_spec  = "C:\Test"
      $expected     = "C:\Backup\C\Test\"

      $result = Get-TargetDir "${base_dir}" "${folder_spec}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Errors' {
    It 'Throws exception for empty specified folder path.' {
      $base_dir     = "C:\Backup\"
      $folder_spec  = ""

      Mock LogAndShowMessage {}

      {
        Get-TargetDir "${base_dir}" "${folder_spec}"
      } | Should -Throw
    }
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
