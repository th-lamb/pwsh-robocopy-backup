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
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6

  function Test-SeverityExpectedBackgroundColor {
    param (
      [Parameter()]
      [SeverityKeyword]$Severity,
      [Parameter()]
      [String]$Message,
      [Parameter()]
      [String]$ExpectedBackgroundColor
    )

    #TODO: Does not fail with multiple parameter checks (e.g. $BackgroundColor + $ForegroundColor) at the same time!
    #Mock Write-Host {} -Verifiable
    #
    #Write-ColoredMessage $Severity "${Message}"
    #
    #TODO: The error message just is "was called 0 times" - but not why!
    #Should -Invoke -CommandName "Write-Host" -Times 1 -Exactly -ParameterFilter {
    #  $BackgroundColor -eq "${ExpectedBackgroundColor}"
    #}

    # We store the used BackgroundColor for a better error message.
    Mock Write-Host { $Script:used_backgroundColor = $BackgroundColor } -Verifiable

    Write-ColoredMessage $Severity "${Message}"

    $used_backgroundColor | Should -Be $ExpectedBackgroundColor
  }

  function Test-SeverityExpectedForegroundColor {
    param (
      [Parameter()]
      [SeverityKeyword]$Severity,
      [Parameter()]
      [String]$Message,
      [Parameter()]
      [String]$ExpectedForegroundColor
    )

    # We store the used ForegroundColor for a better error message.
    Mock Write-Host { $Script:used_foregroundColor = $ForegroundColor } -Verifiable

    Write-ColoredMessage $Severity "${Message}"

    $used_foregroundColor | Should -Be $ExpectedForegroundColor
  }
}



Describe 'Write-ColoredMessage' {
  Context 'Legal severity levels' {
    It 'Uses correct BackgroundColor for severity: EMERG' {
      $test_severity  = [SeverityKeyword]::EMERG
      $expected       = "Red"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: EMERG' {
      $test_severity  = [SeverityKeyword]::EMERG
      $expected       = "White"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity: ALERT' {
      $test_severity  = [SeverityKeyword]::ALERT
      $expected       = "Red"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: ALERT' {
      $test_severity  = [SeverityKeyword]::ALERT
      $expected       = "Black"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity: CRIT' {
      $test_severity  = [SeverityKeyword]::CRIT
      $expected       = "Yellow"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: CRIT' {
      $test_severity  = [SeverityKeyword]::CRIT
      $expected       = "Black"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity: ERR' {
      $test_severity  = [SeverityKeyword]::ERR
      $expected       = "White"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: ERR' {
      $test_severity  = [SeverityKeyword]::ERR
      $expected       = "Red"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity: WARNING' {
      $test_severity  = [SeverityKeyword]::WARNING
      $expected       = "White"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: WARNING' {
      $test_severity  = [SeverityKeyword]::WARNING
      $expected       = "Black"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity: NOTICE' {
      $test_severity  = [SeverityKeyword]::NOTICE
      $expected       = "Blue"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: NOTICE' {
      $test_severity  = [SeverityKeyword]::NOTICE
      $expected       = "White"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity: INFO' {
      $test_severity  = [SeverityKeyword]::INFO
      $expected       = "Black"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: INFO' {
      $test_severity  = [SeverityKeyword]::INFO
      $expected       = "White"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity: DEBUG' {
      $test_severity  = [SeverityKeyword]::DEBUG
      $expected       = "Black"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity: DEBUG' {
      $test_severity  = [SeverityKeyword]::DEBUG
      $expected       = "DarkGray"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }
  }

  Context 'Illegal severity levels' {
    BeforeAll {
      Mock Write-Host {}  # Omit output within the tested function.
    }

    It 'Does NOT write a message for severity: -1' {
      $test_severity = -1
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: 0' {
      $test_severity = 0
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: 1' {
      $test_severity = 1
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: 8' {
      $test_severity = 8
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: foo' {
      $test_severity = "foo"
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }
  }

  #TODO: Redirects errors (emerg...warning) to stderr and other messages to stdout.

  #TODO: Use the enum in logging-functions for $severity?

}
