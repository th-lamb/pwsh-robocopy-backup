$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"
  . "${ProjectRoot}\lib\filesystem-functions.ps1"

  $script:config = [ScriptConfig]::new()

  Mock Write-ColoredMessage {
    $Script:used_severity = $Severity
    $Script:used_message = $Message
  } -Verifiable
}



Describe 'Write-QuietMessage' {
  Context 'Correctly used' {
    It 'Calls Write-WarningMsg with the specified message.' {
      $test_message = "Test message"

      Mock Write-WarningMsg {} -Verifiable

      $config.General.__VERBOSE = 4
      Write-QuietMessage -Message "${test_message}"

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $Message -eq "${test_message}"
      }
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-QuietMessage ""
      } | Should -Throw
    }
  }
}

Describe 'Write-NormalMessage' {
  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with an INFO if $__VERBOSE >= 5 (notice).' {
      $test_message = "Test message"
      $test_severity = "info"
      $expected_message = "[INFO   ] ${test_message}"

      $config.General.__VERBOSE = 5
      Write-NormalMessage -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $Script:used_severity | Should -Be "${test_severity}"
      $Script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage if $__VERBOSE < 5 (notice).' {
      $config.General.__VERBOSE = 4
      Write-NormalMessage -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-NormalMessage ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      $oldConfig = $script:config
      $script:config = $null

      {
        Write-NormalMessage -Message "Test message"
      } | Should -Throw

      $script:config = $oldConfig
    }
  }
}

Describe 'Write-VerboseMessage' {
  Context 'Correctly used' {
    It 'Calls Write-ColoredMessage with an INFO only if $__VERBOSE = 7 (debug).' {
      $test_message = "Test message"
      $test_severity = "info"
      $expected_message = "[INFO   ] ${test_message}"

      $config.General.__VERBOSE = 7
      Write-VerboseMessage -Message "${test_message}"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 1 -Exactly
      $Script:used_severity | Should -Be "${test_severity}"
      $Script:used_message | Should -Be "${expected_message}"
    }

    It 'Does NOT call Write-ColoredMessage if $__VERBOSE < 7 (debug).' {
      $config.General.__VERBOSE = 6
      Write-VerboseMessage -Message "Test message"

      Should -Invoke -CommandName "Write-ColoredMessage" -Times 0
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty message.' {
      {
        Write-VerboseMessage ""
      } | Should -Throw
    }

    It 'Throws an exception if $__VERBOSE is not defined.' {
      Mock Write-ErrMsg {}  # Omit output within the tested function.

      $oldConfig = $script:config
      $script:config = $null

      {
        Write-VerboseMessage -Message "Test message"
      } | Should -Throw

      $script:config = $oldConfig
    }
  }
}
