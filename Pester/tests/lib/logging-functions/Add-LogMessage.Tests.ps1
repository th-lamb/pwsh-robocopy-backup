# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\logging-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"

  # For logging in tested functions
  $script:workingFolder = "${ProjectRoot}\Pester\resources\lib\logging-functions\"
  $script:infoLog = "${workingFolder}info.log"
  $script:errorLog = "${workingFolder}error.log"

  function Format-RegexString {
    Param(
      [string]$message
    )

    $temp = "${message}".Replace("[", "\[")
    $temp = "${temp}".Replace("]", "\]")
    $result = ".*${temp}$"

    return "${result}"
  }
}



<#TODO: Add tests to check:
  - See: TODO\logfile-formatting\

  - Which severity level goes to which logfile? Example:
    - DEBUG   -> Trace.log
    - INFO    -> Backup.log
    - WARNING -> Backup.log
    - ERR     -> Error.log

  - For which __VERBOSE levels does this change? -> Different combinations? Example:
    _VERBOSE=7
      - DEBUG   -> Trace.log  + Backup.log
      - INFO    -> Trace.log  + Backup.log
      - WARNING -> Trace.log  + Backup.log
      - ERR     -> Trace.log  + Backup.log  + Error.log
    _VERBOSE=6
      - DEBUG   -> Trace.log
      - INFO    -> Trace.log  + Backup.log
      - WARNING -> Trace.log  + Backup.log
      - ERR     -> Trace.log  + Backup.log  + Error.log
    _VERBOSE=4
      - DEBUG   -> Trace.log
      - INFO    -> Trace.log
      - WARNING -> Trace.log  + Backup.log
      - ERR     -> Trace.log  + Backup.log  + Error.log
#>

Describe 'Add-LogMessage' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatch

  Context 'Errors' {
    It 'Correctly writes EMERG message.' {
      $logfile  = "${errorLog}"
      $severity = "EMERG"
      $message  = "Emergency message"
      $expected = "[EMERG  ] Emergency message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes ALERT message.' {
      $logfile  = "${errorLog}"
      $severity = "ALERT"
      $message  = "Alert message"
      $expected = "[ALERT  ] Alert message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes CRIT message.' {
      $logfile  = "${errorLog}"
      $severity = "CRIT"
      $message  = "Critical message"
      $expected = "[CRIT   ] Critical message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes ERR message.' {
      $logfile  = "${errorLog}"
      $severity = "ERR"
      $message  = "Error message"
      $expected = "[ERR    ] Error message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }
  }

  Context 'Info' {
    It 'Correctly writes WARNING message.' {
      $logfile  = "${infoLog}"
      $severity = "WARNING"
      $message  = "Warning message"
      $expected = "[WARNING] Warning message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes NOTICE message.' {
      $logfile  = "${infoLog}"
      $severity = "NOTICE"
      $message  = "Notice message"
      $expected = "[NOTICE ] Notice message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes INFO message.' {
      $logfile  = "${infoLog}"
      $severity = "INFO"
      $message  = "Info message"
      $expected = "[INFO   ] Info message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes DEBUG message.' {
      $logfile  = "${infoLog}"
      $severity = "DEBUG"
      $message  = "Debug message"
      $expected = "[DEBUG  ] Debug message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage -logfile "${logfile}" -severity $severity -message "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }
  }
}



AfterAll {
  Remove-Item "${infoLog}" -ErrorAction SilentlyContinue
  Remove-Item "${errorLog}" -ErrorAction SilentlyContinue
}
