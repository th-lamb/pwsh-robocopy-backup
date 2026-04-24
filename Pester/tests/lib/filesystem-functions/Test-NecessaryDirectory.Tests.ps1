using module '..\..\..\..\lib\config-classes.psm1'

# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\filesystem-functions.ps1"
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\logging-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\filesystem-functions.ps1"
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"

  # For logging in tested functions
  $workingFolder = "${ProjectRoot}\Pester\resources\lib\filesystem-functions\"
  $script:BACKUP_LOGFILE = "${workingFolder}Test-NecessaryDirectory.Tests.log"

  # For messages in tested functions
  $config = [ScriptConfig]::new()
  $config.General.__VERBOSE = 6
}



Describe 'Test-NecessaryDirectory' {
  Context 'Non-existent directory' {
    It 'Throws exception if specified directory does not exist.' {
      $nonexistent_dir = "${workingFolder}nonexistent_dir/"

      Mock LogAndShowMessage {}

      {
        Test-NecessaryDirectory 'Test' "${nonexistent_dir}" "${BACKUP_LOGFILE}"
      } | Should -Throw
    }
  }

  Context 'Existing directory' {
    It 'Does not throw exception if specified directory exists.' {
      $existing_dir = "${workingFolder}existing_dir/"

      {
        Test-NecessaryDirectory 'Test' "${existing_dir}" "${BACKUP_LOGFILE}"
      } | Should -Not -Throw
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty definition_name.' {
      {
        Test-NecessaryDirectory ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty path.' {
      {
        Test-NecessaryDirectory 'Test' ""
      } | Should -Throw
    }
  }
}



AfterAll {
  Remove-Item "${BACKUP_LOGFILE}" -ErrorAction SilentlyContinue
}
