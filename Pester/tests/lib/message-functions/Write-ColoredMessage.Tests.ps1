$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  $Script:__VERBOSE = 6

  function Test-SeverityExpectedBackgroundColor {
    param (
      [SeverityKeyword]$Severity,
      [String]$Message,
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
      [SeverityKeyword]$Severity,
      [String]$Message,
      [String]$ExpectedForegroundColor
    )

    # We store the used ForegroundColor for a better error message.
    Mock Write-Host { $Script:used_foregroundColor = $ForegroundColor } -Verifiable

    Write-ColoredMessage $Severity "${Message}"

    $used_foregroundColor | Should -Be $ExpectedForegroundColor
  }
}



# Test the Enum definition
Describe 'SeverityKeyword Enum' {
  It 'EMERG should be 0' {
    [int][SeverityKeyword]::EMERG | Should -Be 0
  }
  It 'ALERT should be 1' {
    [int][SeverityKeyword]::ALERT | Should -Be 1
  }
  It 'CRIT should be 2' {
    [int][SeverityKeyword]::CRIT | Should -Be 2
  }
  It 'ERR should be 3' {
    [int][SeverityKeyword]::ERR | Should -Be 3
  }
  It 'WARNING should be 4' {
    [int][SeverityKeyword]::WARNING | Should -Be 4
  }
  It 'NOTICE should be 5' {
    [int][SeverityKeyword]::NOTICE | Should -Be 5
  }
  It 'INFO should be 6' {
    [int][SeverityKeyword]::INFO | Should -Be 6
  }
  It 'DEBUG should be 6' {
    [int][SeverityKeyword]::DEBUG | Should -Be 7
  }
}



<# Test Write-ColoredMessage with integer values: Function accepts
  integers (which PowerShell casts to the enum) and actually triggers
  the correct behavio, for example 0 -> EMERG?
#>
Describe 'Write-ColoredMessage' {
  Context 'Legal severity levels' {
    It 'Uses correct BackgroundColor for severity 0 = EMERG' {
      $test_severity = 0
      $expected = "Red"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 0 = EMERG' {
      $test_severity = 0
      $expected = "White"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity 1 = ALERT' {
      $test_severity = 1
      $expected = "Red"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 1 = ALERT' {
      $test_severity = 1
      $expected = "Black"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity 2 = CRIT' {
      $test_severity = 2
      $expected = "Yellow"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 2 = CRIT' {
      $test_severity = 2
      $expected = "Black"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity 3 = ERR' {
      $test_severity = 3
      $expected = "White"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 3 = ERR' {
      $test_severity = 3
      $expected = "Red"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity 4 = WARNING' {
      $test_severity = 4
      $expected = "White"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 4 = WARNING' {
      $test_severity = 4
      $expected = "Black"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity 5 = NOTICE' {
      $test_severity = 5
      $expected = "Blue"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 5 = NOTICE' {
      $test_severity = 5
      $expected = "White"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity 6 = INFO' {
      $test_severity = 6
      $expected = "Black"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 6 = INFO' {
      $test_severity = 6
      $expected = "White"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }

    It 'Uses correct BackgroundColor for severity 7 = DEBUG' {
      $test_severity = 7
      $expected = "Black"

      Test-SeverityExpectedBackgroundColor -Severity $test_severity -Message "This message should be written." -ExpectedBackgroundColor $expected
    }

    It 'Uses correct ForegroundColor for severity 7 = DEBUG' {
      $test_severity = 7
      $expected = "DarkGray"

      Test-SeverityExpectedForegroundColor -Severity $test_severity -Message "This message should be written." -ExpectedForegroundColor $expected
    }
  }

  Context 'Illegal severity levels' {
    BeforeAll {
      Mock Write-Host {}  # Omit output within the tested function.
    }

    It 'Does NOT write a message for severity: -1' {
      $test_severity = -1

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw
    }

    It 'Does NOT write a message for severity: 8' {
      $test_severity = 8

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw
    }

    It 'Does NOT write a message for severity: foo' {
      $test_severity = "foo"

      {
        Write-ColoredMessage -Severity $test_severity -Message "This message should NOT be written!"
      } | Should -Throw
    }
  }

  #TODO: Redirects errors (emerg...warning) to stderr and other messages to stdout.
  <#
    Since Write-ColoredMessage currently uses Write-Host for both error and non-error
    messages, there's no observable difference between them for a Pester test.
    Once the stderr redirection is implemented, we'll be able to test it by checking
    if a message was written to the error stream.
  #>

  Context 'Wrong Usage' {
    It 'Throws an exception when called without severity.' {
      {
        Write-ColoredMessage ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty message.' {
      {
        Write-ColoredMessage [SeverityKeyword]::INFO ""
      } | Should -Throw
    }
  }
}
