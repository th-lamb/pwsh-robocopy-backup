$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\robocopy-functions.ps1"
. "${ProjectRoot}\lib\logging-functions.ps1"
. "${ProjectRoot}\lib\message-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\robocopy-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"
  . "${ProjectRoot}\lib\message-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}\Pester/resources/lib/robocopy-functions/"
  $Script:logfile = "${workingFolder}LogAndShowRobocopyError.Tests.log"
  $Script:__VERBOSE = 6

  function Format-RegexString {
    Param(
      [String]$message
    )

    $temp = "${message}".Replace("[", "\[")
    $temp = "${temp}".Replace("]", "\]")
    $temp = "${temp}".Replace("(", "\(")
    $temp = "${temp}".Replace(")", "\)")
    $result = ".*${temp}$"

    return "${result}"
  }
}



Describe 'LogAndShowRobocopyError' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatch

  Context 'Only information' {
    It 'Does NOT log exit codes 0..3 (NoChange, OKCopy, ExtraFiles)' {
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue

      $exit_code = 0
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $exit_code = 1
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $exit_code = 2
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $exit_code = 3
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $result = Test-Path -Path "${logfile}" -PathType Leaf
      $result | Should -Be $false   # No logfile created
    }

    It 'Does NOT call Write-InfoMsg for exit codes 0..3' {
      Mock Write-InfoMsg {} -Verifiable

      $exit_code = 0
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $exit_code = 1
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $exit_code = 2
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $exit_code = 3
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-InfoMsg" -Times 0      # 0 is interpreted as: 0 times exactly
    }
  }

  Context 'Notice' {
    It 'Correctly logs exit code 4 (MismatchedFilesFolders).' {
      $exit_code = 4
      $expected_log_entry = "[NOTICE ] Job1: MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      # Preparation
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-NoticeMsg {}

      # Test
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      # Check result
      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      # Cleanup
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-NoticeMsg exactly once.' {
      $exit_code = 4
      $expected_message = "Job1: MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      # Preparation
      Mock Write-NoticeMsg {} -Verifiable

      # Test
      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      # Check result
      Should -Invoke -CommandName "Write-NoticeMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      # Cleanup
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 5 (OKCopy, MismatchedFilesFolders).' {
      $exit_code = 5
      $expected_log_entry = "[NOTICE ] Job1: OKCopy, MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-NoticeMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-NoticeMsg exactly once.' {
      $exit_code = 5
      $expected_message = "Job1: OKCopy, MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      Mock Write-NoticeMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-NoticeMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 6 (ExtraFiles, MismatchedFilesFolders).' {
      $exit_code = 6
      $expected_log_entry = "[NOTICE ] Job1: ExtraFiles, MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-NoticeMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-NoticeMsg exactly once.' {
      $exit_code = 6
      $expected_message = "Job1: ExtraFiles, MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      Mock Write-NoticeMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-NoticeMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 7 (OKCopy, ExtraFiles, MismatchedFilesFolders).' {
      $exit_code = 7
      $expected_log_entry = "[NOTICE ] Job1: OKCopy, ExtraFiles, MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-NoticeMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-NoticeMsg exactly once.' {
      $exit_code = 7
      $expected_message = "Job1: OKCopy, ExtraFiles, MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      Mock Write-NoticeMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-NoticeMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }
  }

  Context 'Warning' {
    It 'Correctly logs exit code 8 (FailedCopyAttempts).' {
      $exit_code = 8
      $expected_log_entry = "[WARNING] Job1: FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 8
      $expected_message = "Job1: FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 9 (OKCopy, FailedCopyAttempts).' {
      $exit_code = 9
      $expected_log_entry = "[WARNING] Job1: OKCopy, FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 9
      $expected_message = "Job1: OKCopy, FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 10 (ExtraFiles, FailedCopyAttempts).' {
      $exit_code = 10
      $expected_log_entry = "[WARNING] Job1: ExtraFiles, FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 10
      $expected_message = "Job1: ExtraFiles, FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 11 (OKCopy, ExtraFiles, FailedCopyAttempts).' {
      $exit_code = 11
      $expected_log_entry = "[WARNING] Job1: OKCopy, ExtraFiles, FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 11
      $expected_message = "Job1: OKCopy, ExtraFiles, FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 12 (MismatchedFilesFolders, FailedCopyAttempts).' {
      $exit_code = 12
      $expected_log_entry = "[WARNING] Job1: MismatchedFilesFolders, FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 12
      $expected_message = "Job1: MismatchedFilesFolders, FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 13 (OKCopy, MismatchedFilesFolders, FailedCopyAttempts).' {
      $exit_code = 13
      $expected_log_entry = "[WARNING] Job1: OKCopy, MismatchedFilesFolders, FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 13
      $expected_message = "Job1: OKCopy, MismatchedFilesFolders, FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 14 (ExtraFiles, MismatchedFilesFolders, FailedCopyAttempts).' {
      $exit_code = 14
      $expected_log_entry = "[WARNING] Job1: ExtraFiles, MismatchedFilesFolders, FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 14
      $expected_message = "Job1: ExtraFiles, MismatchedFilesFolders, FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Correctly logs exit code 15 (OKCopy, ExtraFiles, MismatchedFilesFolders, FailedCopyAttempts).' {
      $exit_code = 15
      $expected_log_entry = "[WARNING] Job1: OKCopy, ExtraFiles, MismatchedFilesFolders, FailedCopyAttempts"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-WarningMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-WarningMsg exactly once.' {
      $exit_code = 15
      $expected_message = "Job1: OKCopy, ExtraFiles, MismatchedFilesFolders, FailedCopyAttempts"

      Mock Write-WarningMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }
  }

  Context 'Errors' {
    It 'Correctly logs exit code 16 (FatalError).' {
      $exit_code = 16
      $expected_log_entry = "[ERR    ] Job1: FatalError"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-ErrMsg {}

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It '...and calls Write-ErrMsg exactly once.' {
      $exit_code = 16
      $expected_message = "Job1: FatalError"

      Mock Write-ErrMsg {} -Verifiable

      LogAndShowRobocopyError "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-ErrMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }
  }

  #Context 'Invalid exit code' {
  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty logfile.' {
      {
        LogAndShowRobocopyError ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty job_name.' {
      {
        LogAndShowRobocopyError "${logfile}" ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an invalid exit code.' {
      {
        LogAndShowRobocopyError "${logfile}" 'Job1' -1
      } | Should -Throw

      {
        LogAndShowRobocopyError "${logfile}" 'Job1' 17
      } | Should -Throw

      {
        LogAndShowRobocopyError "${logfile}" 'Job1' "foo"
      } | Should -Throw
    }
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
