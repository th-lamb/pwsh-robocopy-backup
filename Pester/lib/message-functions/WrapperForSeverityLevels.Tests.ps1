BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/message-functions.ps1"
}



Describe 'Write-EmergMsg' {
  It 'Calls Write-ColoredMessage with "emerg" and specified message.' {
    $test_severity    = "emerg"
    $test_message     = "Test message"
    $expected_message = "[EMERG  ] ${test_message}"

    Mock Write-ColoredMessage {
      $Script:used_severity = $Severity
      $Script:used_message  = $Message
    } -Verifiable

    Write-EmergMsg -Message "${test_message}"

    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

Describe 'Write-AlertMsg' {
  It 'Calls Write-ColoredMessage with "alert" and specified message.' {
    $test_severity    = "alert"
    $test_message     = "Test message"
    $expected_message = "[ALERT  ] ${test_message}"

    Mock Write-ColoredMessage {
      $Script:used_severity = $Severity
      $Script:used_message  = $Message
    } -Verifiable

    Write-AlertMsg -Message "${test_message}"

    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

Describe 'Write-CritMsg' {
  It 'Calls Write-ColoredMessage with "crit" and specified message.' {
    $test_severity    = "crit"
    $test_message     = "Test message"
    $expected_message = "[CRIT   ] ${test_message}"

    Mock Write-ColoredMessage {
      $Script:used_severity = $Severity
      $Script:used_message  = $Message
    } -Verifiable

    Write-CritMsg -Message "${test_message}"

    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

Describe 'Write-ErrMsg' {
  It 'Calls Write-ColoredMessage with "err" and specified message.' {
    $test_severity    = "err"
    $test_message     = "Test message"
    $expected_message = "[ERR    ] ${test_message}"

    Mock Write-ColoredMessage {
      $Script:used_severity = $Severity
      $Script:used_message  = $Message
    } -Verifiable

    Write-ErrMsg -Message "${test_message}"

    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

#TODO: rest incl. verbosity check!

Describe 'Write-WarningMsg' {
  It 'Calls Write-ColoredMessage with "warning" and specified message for $__VERBOSE `>= 4.' {
    $test_severity    = "warning"
    $test_message     = "Test message"
    $expected_message = "[WARNING] ${test_message}"

    Mock Write-ColoredMessage {
      $Script:used_severity = $Severity
      $Script:used_message  = $Message
    } -Verifiable

    $Script:__VERBOSE = 4
    Write-WarningMsg -Message "${test_message}"

    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }

  It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 4.' {
    $test_severity    = "warning"
    $test_message     = "Test message"
    $expected_message = "[WARNING] ${test_message}"

    Mock Write-ColoredMessage {
      $Script:used_severity = $Severity
      $Script:used_message  = $Message
    } -Verifiable

    $Script:__VERBOSE = 4
    Write-WarningMsg -Message "${test_message}"

    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }

  It 'Throws an exception if $__VERBOSE is not defined.' {
    $test_message     = "Test message"

    Mock Write-ErrMsg {}  # Omit output within the tested function.

    Clear-Variable __VERBOSE -Scope Script

    {
      Write-WarningMsg -Message "${test_message}"
    } | Should -Throw
  }
}
