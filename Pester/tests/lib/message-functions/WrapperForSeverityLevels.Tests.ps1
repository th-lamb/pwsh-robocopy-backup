BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/message-functions.ps1"

  Mock Write-ColoredMessage {
    $Script:used_severity = $Severity
    $Script:used_message  = $Message
  } -Verifiable
}



Describe 'Write-EmergMsg' {
  It 'Calls Write-ColoredMessage with "emerg" and specified message.' {
    $test_severity    = "emerg"
    $test_message     = "Test message"
    $expected_message = "[EMERG  ] ${test_message}"

    Write-EmergMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

Describe 'Write-AlertMsg' {
  It 'Calls Write-ColoredMessage with "alert" and specified message.' {
    $test_severity    = "alert"
    $test_message     = "Test message"
    $expected_message = "[ALERT  ] ${test_message}"

    Write-AlertMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

Describe 'Write-CritMsg' {
  It 'Calls Write-ColoredMessage with "crit" and specified message.' {
    $test_severity    = "crit"
    $test_message     = "Test message"
    $expected_message = "[CRIT   ] ${test_message}"

    Write-CritMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

Describe 'Write-ErrMsg' {
  It 'Calls Write-ColoredMessage with "err" and specified message.' {
    $test_severity    = "err"
    $test_message     = "Test message"
    $expected_message = "[ERR    ] ${test_message}"

    Write-ErrMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }
}

Describe 'Write-WarningMsg' {
  It 'Calls Write-ColoredMessage with "warning" and specified message for $__VERBOSE >= 4.' {
    $test_severity    = "warning"
    $test_message     = "Test message"
    $expected_message = "[WARNING] ${test_message}"

    $Script:__VERBOSE = 4
    Write-WarningMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }

  It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 4.' {
    $Script:__VERBOSE = 3
    Write-WarningMsg -Message "Test message"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
  }

  It 'Throws an exception if $__VERBOSE is not defined.' {
    Mock Write-ErrMsg {}  # Omit output within the tested function.

    Clear-Variable __VERBOSE -Scope Script

    {
      Write-WarningMsg -Message "Test message"
    } | Should -Throw
  }
}

Describe 'Write-NoticeMsg' {
  It 'Calls Write-ColoredMessage with "notice" and specified message for $__VERBOSE >= 5.' {
    $test_severity    = "notice"
    $test_message     = "Test message"
    $expected_message = "[NOTICE ] ${test_message}"

    $Script:__VERBOSE = 5
    Write-NoticeMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }

  It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 5.' {
    $Script:__VERBOSE = 4
    Write-NoticeMsg -Message "Test message"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
  }

  It 'Throws an exception if $__VERBOSE is not defined.' {
    Mock Write-ErrMsg {}  # Omit output within the tested function.

    Clear-Variable __VERBOSE -Scope Script

    {
      Write-NoticeMsg -Message "Test message"
    } | Should -Throw
  }
}

Describe 'Write-InfoMsg' {
  It 'Calls Write-ColoredMessage with "info" and specified message for $__VERBOSE >= 6.' {
    $test_severity    = "info"
    $test_message     = "Test message"
    $expected_message = "[INFO   ] ${test_message}"

    $Script:__VERBOSE = 6
    Write-InfoMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }

  It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 6.' {
    $Script:__VERBOSE = 5
    Write-InfoMsg -Message "Test message"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
  }

  It 'Throws an exception if $__VERBOSE is not defined.' {
    Mock Write-ErrMsg {}  # Omit output within the tested function.

    Clear-Variable __VERBOSE -Scope Script

    {
      Write-InfoMsg -Message "Test message"
    } | Should -Throw
  }
}

Describe 'Write-DebugMsg' {
  It 'Calls Write-ColoredMessage with "debug" and specified message for $__VERBOSE >= 7.' {
    $test_severity    = "debug"
    $test_message     = "Test message"
    $expected_message = "[DEBUG  ] ${test_message}"

    $Script:__VERBOSE = 7
    Write-DebugMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }

  It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 7.' {
    $Script:__VERBOSE = 6
    Write-DebugMsg -Message "Test message"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
  }

  It 'Throws an exception if $__VERBOSE is not defined.' {
    Mock Write-ErrMsg {}  # Omit output within the tested function.

    Clear-Variable __VERBOSE -Scope Script

    {
      Write-DebugMsg -Message "Test message"
    } | Should -Throw
  }
}
