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
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/logging-functions.ps1"
  #$script:logfile = "${ProjectRoot}Pester/resources/logging-functions/LogAndShowMessage.Tests.log"

  . "${ProjectRoot}lib/message-functions.ps1"
  #$script:__VERBOSE = 6
}



Describe 'LogAndShowMessage' {
  Context 'Step 1: Add-LogMessage' {
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
        LogAndShowMessage "${logfile}" $test_severity "Test message"

        Should -Invoke -CommandName "Add-LogMessage" -Times 1 -Exactly -ParameterFilter {
          $severity -eq "${test_severity}"
        }
      }
    }

    It 'Calls Add-LogMessage with correct message.' {
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
        $test_message = "${test_severity} message"
        LogAndShowMessage "${logfile}" $test_severity "${test_message}"

        Should -Invoke -CommandName "Add-LogMessage" -Times 1 -Exactly -ParameterFilter {
          $message -eq "${test_message}"
        }
      }
    }
  }

  Context 'Step 2: Write-...Message functions' {
    It 'Calls correct Write-...Message function with specified message' {
      # Preparation
      Mock Add-LogMessage {}

      Mock Write-EmergMsg {} -Verifiable
      Mock Write-AlertMsg {} -Verifiable
      Mock Write-CritMsg {} -Verifiable
      Mock Write-ErrMsg {} -Verifiable
      Mock Write-WarningMsg {} -Verifiable
      Mock Write-NoticeMsg {} -Verifiable
      Mock Write-InfoMsg {} -Verifiable
      Mock Write-DebugMsg {} -Verifiable

      # Test(s)
      foreach( $test_severity in [SeverityKeyword].GetEnumNames() )
      {
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.Append("Write-")
        [void]$sb.Append( $test_severity.Substring(0,1) )
        [void]$sb.Append( $test_severity.Substring(1).ToLowerInvariant() )
        [void]$sb.Append("Msg")
        $command_name = $sb.ToString()

        LogAndShowMessage "${logfile}" $test_severity "Test message"

        Should -Invoke -CommandName "${command_name}" -Times 1 -Exactly -ParameterFilter {
          $message -eq "Test message"
        }
      }
    }
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
