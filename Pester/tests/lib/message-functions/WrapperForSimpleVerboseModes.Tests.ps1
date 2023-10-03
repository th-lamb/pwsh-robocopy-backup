BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/message-functions.ps1"

  Mock Write-ColoredMessage {
    $Script:used_severity = $Severity
    $Script:used_message  = $Message
  } -Verifiable
}



Describe 'Write-QuietMessage' {
  It 'Calls Write-WarningMsg with the specified message.' {
    $test_message = "Test message"

    Mock Write-WarningMsg {} -Verifiable

    $Script:__VERBOSE = 4
    Write-QuietMessage -Message "${test_message}"

    Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
      $Message -eq "${test_message}"
    }
  }

  It 'Throws an exception when called with an empty message.' {
    {
      Write-QuietMessage ""
    } | Should -Throw
  }
}

Describe 'Write-NormalMessage' {
  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with an INFO if $__VERBOSE >= 5 (notice).' {
      $test_message     = "Test message"
      $test_severity    = "info"
      $expected_message = "[INFO   ] ${test_message}"

      $Script:__VERBOSE = 5
      Write-NormalMessage -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $Script:used_severity | Should -Be "${test_severity}"
      $Script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage if $__VERBOSE < 5 (notice).' {
      $Script:__VERBOSE = 4
      Write-NormalMessage -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-NormalMessage ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      Clear-Variable __VERBOSE -Scope Script

      {
        Write-NormalMessage -Message "Test message"
      } | Should -Throw
    }
  }
}

Describe 'Write-VerboseMessage' {
  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with an INFO only if $__VERBOSE = 7 (debug).' {
      $test_message     = "Test message"
      $test_severity    = "info"
      $expected_message = "[INFO   ] ${test_message}"

      $Script:__VERBOSE = 7
      Write-VerboseMessage -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $Script:used_severity | Should -Be "${test_severity}"
      $Script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage if $__VERBOSE < 7 (debug).' {
      $Script:__VERBOSE = 6
      Write-VerboseMessage -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-VerboseMessage ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      Clear-Variable __VERBOSE -Scope Script

      {
        Write-VerboseMessage -Message "Test message"
      } | Should -Throw
    }
  }
}
