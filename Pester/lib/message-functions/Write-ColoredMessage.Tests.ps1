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
      [SeverityKeyword]$test_severity,
      [Parameter()]
      [String]$message,
      [Parameter()]
      [String]$expected_backgroundColor
    )

    #TODO: Does not fail with multiple parameter checks (e.g. $BackgroundColor + $ForegroundColor) at the same time!
    #Mock Write-Host {} -Verifiable
    #
    #Write-ColoredMessage $test_severity "${message}"
    #
    #TODO: The error message just is "was called 0 times" - but not why!
    #Should -Invoke -CommandName "Write-Host" -Times 1 -Exactly -ParameterFilter {
    #  $BackgroundColor -eq "${expected_backgroundColor}"
    #}

    # We store the used BackgroundColor for a better error message.
    Mock Write-Host { $Script:used_backgroundColor = $BackgroundColor } -Verifiable

    Write-ColoredMessage $test_severity "${message}"

    $used_backgroundColor | Should -Be $expected_backgroundColor
  }

  function Test-SeverityExpectedForegroundColor {
    param (
      [Parameter()]
      [SeverityKeyword]$test_severity,
      [Parameter()]
      [String]$message,
      [Parameter()]
      [String]$expected_foregroundColor
    )

    # We store the used ForegroundColor for a better error message.
    Mock Write-Host { $Script:used_foregroundColor = $ForegroundColor } -Verifiable

    Write-ColoredMessage $test_severity "${message}"

    $used_foregroundColor | Should -Be $expected_foregroundColor
  }
}



Describe 'Write-ColoredMessage' {
  Context 'Legal severity levels' {
    It 'Uses correct BackgroundColor for severity: EMERG' {
      $test_severity            = [SeverityKeyword]::EMERG
      $expected_backgroundColor = "Red"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: EMERG' {
      $test_severity            = [SeverityKeyword]::EMERG
      $expected_foregroundColor = "White"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }

    It 'Uses correct BackgroundColor for severity: ALERT' {
      $test_severity            = [SeverityKeyword]::ALERT
      $expected_backgroundColor = "Red"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: ALERT' {
      $test_severity            = [SeverityKeyword]::ALERT
      $expected_foregroundColor = "Black"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }

    It 'Uses correct BackgroundColor for severity: CRIT' {
      $test_severity            = [SeverityKeyword]::CRIT
      $expected_backgroundColor = "Yellow"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: CRIT' {
      $test_severity            = [SeverityKeyword]::CRIT
      $expected_foregroundColor = "Black"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }

    It 'Uses correct BackgroundColor for severity: ERR' {
      $test_severity            = [SeverityKeyword]::ERR
      $expected_backgroundColor = "White"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: ERR' {
      $test_severity            = [SeverityKeyword]::ERR
      $expected_foregroundColor = "Red"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }

    It 'Uses correct BackgroundColor for severity: WARNING' {
      $test_severity            = [SeverityKeyword]::WARNING
      $expected_backgroundColor = "White"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: WARNING' {
      $test_severity            = [SeverityKeyword]::WARNING
      $expected_foregroundColor = "Black"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }

    It 'Uses correct BackgroundColor for severity: NOTICE' {
      $test_severity            = [SeverityKeyword]::NOTICE
      $expected_backgroundColor = "Blue"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: NOTICE' {
      $test_severity            = [SeverityKeyword]::NOTICE
      $expected_foregroundColor = "White"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }

    It 'Uses correct BackgroundColor for severity: INFO' {
      $test_severity            = [SeverityKeyword]::INFO
      $expected_backgroundColor = "Black"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: INFO' {
      $test_severity            = [SeverityKeyword]::INFO
      $expected_foregroundColor = "White"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }

    It 'Uses correct BackgroundColor for severity: DEBUG' {
      $test_severity            = [SeverityKeyword]::DEBUG
      $expected_backgroundColor = "Black"

      Test-SeverityExpectedBackgroundColor $test_severity "This message should be written." $expected_backgroundColor
    }

    It 'Uses correct ForegroundColor for severity: DEBUG' {
      $test_severity            = [SeverityKeyword]::DEBUG
      $expected_foregroundColor = "DarkGray"

      Test-SeverityExpectedForegroundColor $test_severity "This message should be written." $expected_foregroundColor
    }
  }

  Context 'Illegal severity levels' {
    BeforeAll {
      Mock Write-Host {}  # Omit output within the tested function.
    }

    It 'Does NOT write a message for severity: -1' {
      $test_severity    = -1
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage $test_severity "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: 0' {
      $test_severity    = 0
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage $test_severity "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: 1' {
      $test_severity    = 1
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage $test_severity "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: 8' {
      $test_severity    = 8
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage $test_severity "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }

    It 'Does NOT write a message for severity: foo' {
      $test_severity    = "foo"
      $expected_message = "Write-ColoredMessage(): Illegal severity level specified: *"   # Using wildcard

      {
        Write-ColoredMessage $test_severity "This message should NOT be written!"
      } | Should -Throw -ExpectedMessage "${expected_message}"
    }
  }

  #TODO: Redirects errors (emerg...warning) to stderr and other messages to stdout.

  #TODO: Use the enum in logging-functions for $severity?

}
