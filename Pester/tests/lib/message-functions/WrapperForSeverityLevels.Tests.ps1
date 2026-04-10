using module '..\..\..\..\lib\config-classes.psm1'

# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"
  . "${ProjectRoot}\lib\filesystem-functions.ps1"

  $script:config = [ScriptConfig]::new()
}



Describe 'Write-EmergMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  It 'Calls Write-ColoredMessage with "emerg" and specified message.' {
    $test_severity    = "emerg"
    $test_message     = "Test message"
    $expected_message = "[EMERG  ] ${test_message}"

    Write-EmergMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $script:used_severity | Should -Be "${test_severity}"
    $script:used_message | Should -Be "${expected_message}"
  }

  It 'Throws an exception when called with an empty message.' {
    {
      Write-EmergMsg ""
    } | Should -Throw
  }
}

Describe 'Write-AlertMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  It 'Calls Write-ColoredMessage with "alert" and specified message.' {
    $test_severity    = "alert"
    $test_message     = "Test message"
    $expected_message = "[ALERT  ] ${test_message}"

    Write-AlertMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $script:used_severity | Should -Be "${test_severity}"
    $script:used_message | Should -Be "${expected_message}"
  }

  It 'Throws an exception when called with an empty message.' {
    {
      Write-AlertMsg ""
    } | Should -Throw
  }
}

Describe 'Write-CritMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  It 'Calls Write-ColoredMessage with "crit" and specified message.' {
    $test_severity    = "crit"
    $test_message     = "Test message"
    $expected_message = "[CRIT   ] ${test_message}"

    Write-CritMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $script:used_severity | Should -Be "${test_severity}"
    $script:used_message | Should -Be "${expected_message}"
  }

  It 'Throws an exception when called with an empty message.' {
    {
      Write-CritMsg ""
    } | Should -Throw
  }
}

Describe 'Write-ErrMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  It 'Calls Write-ColoredMessage with "err" and specified message.' {
    $test_severity    = "err"
    $test_message     = "Test message"
    $expected_message = "[ERR    ] ${test_message}"

    Write-ErrMsg -Message "${test_message}"

    Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
    $script:used_severity | Should -Be "${test_severity}"
    $script:used_message | Should -Be "${expected_message}"
  }

  It 'Throws an exception when called with an empty message.' {
    {
      Write-ErrMsg ""
    } | Should -Throw
  }
}

Describe 'Write-WarningMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with "warning" and specified message for $__VERBOSE >= 4.' {
      $test_severity    = "warning"
      $test_message     = "Test message"
      $expected_message = "[WARNING] ${test_message}"

      $config.General.__VERBOSE = 4
      Write-WarningMsg -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $script:used_severity | Should -Be "${test_severity}"
      $script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 4.' {
      $config.General.__VERBOSE = 3
      Write-WarningMsg -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-WarningMsg ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      $oldConfig = $script:config
      $script:config = $null

      {
        Write-WarningMsg -Message "Test message"
      } | Should -Throw

      $script:config = $oldConfig
    }
  }
}

Describe 'Write-NoticeMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with "notice" and specified message for $__VERBOSE >= 5.' {
      $test_severity    = "notice"
      $test_message     = "Test message"
      $expected_message = "[NOTICE ] ${test_message}"

      $config.General.__VERBOSE = 5
      Write-NoticeMsg -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $script:used_severity | Should -Be "${test_severity}"
      $script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 5.' {
      $config.General.__VERBOSE = 4
      Write-NoticeMsg -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-NoticeMsg ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      $oldConfig = $script:config
      $script:config = $null

      {
        Write-NoticeMsg -Message "Test message"
      } | Should -Throw

      $script:config = $oldConfig
    }
  }
}

Describe 'Write-InfoMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with "info" and specified message for $__VERBOSE >= 6.' {
      $test_severity    = "info"
      $test_message     = "Test message"
      $expected_message = "[INFO   ] ${test_message}"

      $config.General.__VERBOSE = 6
      Write-InfoMsg -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $script:used_severity | Should -Be "${test_severity}"
      $script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 6.' {
      $config.General.__VERBOSE = 5
      Write-InfoMsg -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-InfoMsg ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      $oldConfig = $script:config
      $script:config = $null

      {
        Write-InfoMsg -Message "Test message"
      } | Should -Throw

      $script:config = $oldConfig
    }
  }
}

Describe 'Write-DebugMsg' {
  BeforeAll {
    Mock Write-ColoredMessage {
      $script:used_severity = $Severity
      $script:used_message = $Message
    } -Verifiable
  }

  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with "debug" and specified message for $__VERBOSE >= 7.' {
      $test_severity    = "debug"
      $test_message     = "Test message"
      $expected_message = "[DEBUG  ] ${test_message}"

      $config.General.__VERBOSE = 7
      Write-DebugMsg -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $script:used_severity | Should -Be "${test_severity}"
      $script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage for $__VERBOSE < 7.' {
      $config.General.__VERBOSE = 6
      Write-DebugMsg -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-DebugMsg ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      $oldConfig = $script:config
      $script:config = $null

      {
        Write-DebugMsg -Message "Test message"
      } | Should -Throw

      $script:config = $oldConfig
    }
  }
}
