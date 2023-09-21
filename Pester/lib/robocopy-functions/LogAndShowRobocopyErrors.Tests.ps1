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



#Enum RoboCopyExitCodes {
#  NoChange = 0
#  OKCopy = 1
#  ExtraFiles = 2
#  MismatchedFilesFolders = 4
#  FailedCopyAttempts = 8
#  FatalError = 16
#}

Describe 'LogAndShowRobocopyErrors' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatch
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatchmultiline

  It 'Does not log exit codes 0..3 (NoChange, OKCopy, ExtraFiles)' {
    Remove-Item "${logfile}" -ErrorAction SilentlyContinue

    $exit_code  = 0
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $exit_code  = 1
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $exit_code  = 2
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $exit_code  = 3
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $result = Test-Path -Path "${logfile}" -PathType Leaf
    $result | Should -Be $false   # No logfile created
  }

  It 'Does not show an INFO message for exit codes 0..3' {
    Mock Write-InfoMsg {} -Verifiable

    $exit_code  = 0
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $exit_code  = 1
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $exit_code  = 2
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $exit_code  = 3
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    Should -Invoke -CommandName "Write-InfoMsg" -Times 0
  }

  It 'Logs exit code 4 (MismatchedFilesFolders)' {
    Remove-Item "${logfile}" -ErrorAction SilentlyContinue

    $exit_code  = 4
    $expected_log_entry = "[NOTICE ] Job1: MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

    Mock Write-NoticeMsg {}
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    $expected_log_entry = Format-RegexString "${expected_log_entry}"
    "${logfile}" | Should -FileContentMatch "${expected_log_entry}"
  }

  It 'Shows a NOTICE message for exit code 4' {
    $exit_code  = 4
    $expected_message = "Job1: MismatchedFilesFolders (Examine the output log. Some housekeeping may be needed.)"

    Mock Write-NoticeMsg { $script:message_was = "${message}" } -Verifiable
    LogAndShowRobocopyErrors "${logfile}" "Job1" $exit_code

    Should -Invoke -CommandName "Write-NoticeMsg" -Times 1
    "${message_was}" | Should -Be "${expected_message}"
  }

}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
