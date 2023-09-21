enum SeverityKeyword {
  EMERG
  ALERT
  CRIT
  ERR
  WARNING
  NOTICE
  INFO
  DEBUG
}

BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/logging-functions.ps1"
  $logfile = "${ProjectRoot}Pester/resources/logging-functions/LogAndShowMessage.Tests.log"

  . "${ProjectRoot}lib/message-functions.ps1"
#  $__VERBOSE = 6

#  function Format-RegexString {
#    Param(
#      [String]$message
#    )
#
#    $temp = "${message}".Replace("[", "\[")
#    $temp = "${temp}".Replace("]", "\]")
#    $result = ".*${temp}$"
#
#    return "${result}"
#  }
}



Describe 'LogAndShowMessage' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatch

  #TODO: Calls Add-LogMessage with correct message?
  #TODO: Calls correct Write-*Message function?
  Context 'Add-LogMessage' {
    It 'Calls Add-LogMessage with correct severity.' {
      # Preparation
      Mock Add-LogMessage {} -Verifiable

      Mock Write-EmergMsg {}
      Mock Write-AlertMsg {}
      Mock Write-CritMsg {}
      Mock Write-ErrMsg {}
      Mock Write-WarningMsg {}
      Mock Write-NoticeMsg {}
      Mock Write-InfoMsg {}
      Mock Write-DebugMsg {}

      # Test(s)
      foreach( $test_severity in [SeverityKeyword].GetEnumNames() )
      {
        #Write-Host $test_severity -ForegroundColor Yellow
        LogAndShowMessage "${logfile}" $test_severity "Test message"

        Should -Invoke -CommandName "Add-LogMessage" -Times 1 -Exactly -ParameterFilter {
          $severity -eq "${test_severity}"
        }
      }

      # Cleanup
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

  }

}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
