BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/robocopy-functions.ps1"

  . "${ProjectRoot}lib/logging-functions.ps1"
  $logfile = "${ProjectRoot}Pester/resources/robocopy-functions/LogAndShowRobocopyErrors.Tests.log"

  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6

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



Describe 'LogAndShowRobocopyErrors' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatch
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatchmultiline

  Context 'Only information' {
    It 'Does NOT log exit codes 0..3 (NoChange, OKCopy, ExtraFiles)' {
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue

      $exit_code = 0
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      $exit_code = 1
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      $exit_code = 2
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      $exit_code = 3
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      $result = Test-Path -Path "${logfile}" -PathType Leaf
      $result | Should -Be $false   # No logfile created
    }

    It 'Does NOT call Write-InfoMsg for exit codes 0..3' {
      Mock Write-InfoMsg {} -Verifiable

      $exit_code = 0
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      $exit_code = 1
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      $exit_code = 2
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      $exit_code = 3
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      Should -Invoke -CommandName "Write-InfoMsg" -Times 0      # 0 is interpreted as: 0 times exactly
    }
  }

  Context 'Notice' {
    It 'Logs exit code 4 (MismatchedFilesFolders)' {
      $exit_code = 4
      $expected_log_entry = "[NOTICE ] Job1: MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      # Preparation
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Mock Write-NoticeMsg {}

      # Test
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      # Check result
      $expected_regex = Format-RegexString "${expected_log_entry}"
      "${logfile}" | Should -FileContentMatch "${expected_regex}"

      # Cleanup
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

    It 'Calls Write-NoticeMsg for exit code 4' {
      $exit_code = 4
      $expected_message = "Job1: MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

      # Preparation
      Mock Write-NoticeMsg {} -Verifiable

      # Test
      LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

      # Check result
      Should -Invoke -CommandName "Write-NoticeMsg" -Times 1 -Exactly -ParameterFilter {
        $message -eq "${expected_message}"
      }

      # Cleanup
      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    }

  }

}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
