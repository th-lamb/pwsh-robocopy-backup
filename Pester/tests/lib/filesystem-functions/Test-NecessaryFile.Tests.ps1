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
  #FIXME: Check in all files whether variables like $workingFolder are only used once in the following line!
  $workingFolder = "${ProjectRoot}\Pester\resources\lib\filesystem-functions\"
  $script:BACKUP_LOGFILE = "${workingFolder}Test-NecessaryFile.Tests.log"

  # For messages in tested functions
  $config = [ScriptConfig]::new()
  $config.General.__VERBOSE = 6
}



Describe 'Test-NecessaryFile' {
  Context 'Non-existent file' {
    It 'Throws exception if specified file does not exist.' {
      $nonexistent_file = "${workingFolder}nonexistent_file"

      Mock LogAndShowMessage {}

      {
        Test-NecessaryFile 'Test' "${nonexistent_file}" "${BACKUP_LOGFILE}"
      } | Should -Throw
    }
  }

  Context 'Existing file' {
    It 'Does not throw exception if specified file exists.' {
      $existing_file = "${workingFolder}existing_file"

      {
        Test-NecessaryFile 'Test' "${existing_file}" "${BACKUP_LOGFILE}"
      } | Should -Not -Throw
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty definition_name.' {
      {
        Test-NecessaryFile ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty path.' {
      {
        Test-NecessaryFile 'Test' ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty logfile.' {
      $existing_file = "${workingFolder}existing_file"

      {
        Test-NecessaryFile 'Test' "${existing_file}" ""
      } | Should -Throw
    }
  }
}



AfterAll {
  Remove-Item "${BACKUP_LOGFILE}" -ErrorAction SilentlyContinue
}
