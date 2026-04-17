# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\job-functions.ps1"
. "${ProjectRoot}\lib\logging-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\job-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"
}



Describe 'Get-TargetDir' {
  Context 'Expected paths' {
    It 'Returns correct target-dir for folders.' {
      $base_dir     = "C:\Backup\"
      $folder_spec  = "C:\Test\"
      $expected     = "C:\Backup\C\Test\"

      $result = Get-TargetDir "${base_dir}" "${folder_spec}" "TestDrive:\test.log"
      $result | Should -Be "${expected}"
    }

    It 'Corrects missing path separators.' {
      $base_dir     = "C:\Backup"
      $folder_spec  = "C:\Test"
      $expected     = "C:\Backup\C\Test\"

      $result = Get-TargetDir "${base_dir}" "${folder_spec}" "TestDrive:\test.log"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Errors' {
    It 'Throws exception for empty specified folder path.' {
      $base_dir     = "C:\Backup\"
      $folder_spec  = ""

      Mock LogAndShowMessage {}

      {
        Get-TargetDir "${base_dir}" "${folder_spec}" "TestDrive:\test.log"
      } | Should -Throw
    }
  }
}
