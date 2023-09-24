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

  function Test-SeverityWithExpectedColors {
    param (
      [SeverityKeyword]$test_severity,
      [String]$message,
      [String]$expected_backgroundColor,
      [String]$expected_foregroundColor
    )

    #Mock Write-Host {} -Verifiable
    Mock Write-Host {
      $Script:used_backgroundColor = "${BackgroundColor}"
      $Script:used_foregroundColor = "${ForegroundColor}"
    } -Verifiable

    Write-ColoredMessage $test_severity "${message}"

    Should -Invoke -CommandName "Write-Host" -Times 1 -Exactly

    #TODO: Does not fail with wrong colors, but it works in "LogAndShowMessage.Tests.ps1"!
    #Should -Invoke -CommandName "Write-Host" -ParameterFilter {
    #  $BackgroundColor -eq "${expected_backgroundColor}"
    #  $ForegroundColor -eq "${expected_foregroundColor}"
    #}

    $used_backgroundColor | Should -Be $expected_backgroundColor
    $used_foregroundColor | Should -Be $expected_foregroundColor
  }
}



Describe 'Write-ColoredMessage' {
  Context 'Legal severity levels' {
    It 'Writes a message for severity: EMERG' {
      $test_severity            = [SeverityKeyword]::EMERG
      $expected_backgroundColor = "Red"
      $expected_foregroundColor = "White"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
    }

    It 'Writes a message for severity: ALERT' {
      $test_severity            = [SeverityKeyword]::ALERT
      $expected_backgroundColor = "Red"
      $expected_foregroundColor = "Black"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
    }

    It 'Writes a message for severity: CRIT' {
      $test_severity            = [SeverityKeyword]::CRIT
      $expected_backgroundColor = "Yellow"
      $expected_foregroundColor = "Black"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
    }

    It 'Writes a message for severity: ERR' {
      $test_severity            = [SeverityKeyword]::ERR
      $expected_backgroundColor = "White"
      $expected_foregroundColor = "Red"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
    }

    It 'Writes a message for severity: WARNING' {
      $test_severity            = [SeverityKeyword]::WARNING
      $expected_backgroundColor = "White"
      $expected_foregroundColor = "Black"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
    }

    It 'Writes a message for severity: NOTICE' {
      $test_severity            = [SeverityKeyword]::NOTICE
      $expected_backgroundColor = "Blue"
      $expected_foregroundColor = "White"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
    }

    It 'Writes a message for severity: INFO' {
      $test_severity            = [SeverityKeyword]::INFO
      $expected_backgroundColor = "Black"
      $expected_foregroundColor = "White"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
    }

    It 'Writes a message for severity: DEBUG' {
      $test_severity            = [SeverityKeyword]::DEBUG
      $expected_backgroundColor = "Black"
      $expected_foregroundColor = "DarkGray"

      Test-SeverityWithExpectedColors $test_severity "This message should be written." $expected_backgroundColor $expected_foregroundColor
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
