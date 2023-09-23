BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/logging-functions.ps1"
  $infoLog = "${ProjectRoot}Pester/resources/logging-functions/info.log"
  $errorLog = "${ProjectRoot}Pester/resources/logging-functions/error.log"

  function Format-RegexString {
    Param(
      [String]$message
    )

    $temp = "${message}".Replace("[", "\[")
    $temp = "${temp}".Replace("]", "\]")
    $result = ".*${temp}$"

    return "${result}"
  }
}



Describe 'Add-LogMessage' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatch

  Context 'Errors' {
    It 'Correctly writes EMERG message.' {
      $logfile  = "${errorLog}"
      $severity = "EMERG"
      $message  = "Emergency message"
      $expected = "[EMERG  ] Emergency message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage "${logfile}" $severity "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes ALERT message.' {
      $logfile  = "${errorLog}"
      $severity = "ALERT"
      $message  = "Alert message"
      $expected = "[ALERT  ] Alert message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage "${logfile}" $severity "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes CRIT message.' {
      $logfile  = "${errorLog}"
      $severity = "CRIT"
      $message  = "Critical message"
      $expected = "[CRIT   ] Critical message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage "${logfile}" $severity "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes ERR message.' {
      $logfile  = "${errorLog}"
      $severity = "ERR"
      $message  = "Error message"
      $expected = "[ERR    ] Error message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage "${logfile}" $severity "${message}"

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
      Add-LogMessage "${logfile}" $severity "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes NOTICE message.' {
      $logfile  = "${infoLog}"
      $severity = "NOTICE"
      $message  = "Notice message"
      $expected = "[NOTICE ] Notice message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage "${logfile}" $severity "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes INFO message.' {
      $logfile  = "${infoLog}"
      $severity = "INFO"
      $message  = "Info message"
      $expected = "[INFO   ] Info message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage "${logfile}" $severity "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }

    It 'Correctly writes DEBUG message.' {
      $logfile  = "${infoLog}"
      $severity = "DEBUG"
      $message  = "Debug message"
      $expected = "[DEBUG  ] Debug message"

      Remove-Item "${logfile}" -ErrorAction SilentlyContinue
      Add-LogMessage "${logfile}" $severity "${message}"

      $expected = Format-RegexString "${expected}"
      "${logfile}" | Should -FileContentMatch "${expected}"
    }
  }
}



AfterAll {
  Remove-Item "${infoLog}" -ErrorAction SilentlyContinue
  Remove-Item "${errorLog}" -ErrorAction SilentlyContinue
}
