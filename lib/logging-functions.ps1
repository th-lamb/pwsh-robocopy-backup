#TODO: Check directory before showing "Cannot write to logfile" error?



enum SeverityKeyword {
  EMERG
  ALERT
  CRIT
  ERR
  WARNING
  NOTICE
  INFO
  DEBUG
}

#region Helper functions

function Format-InSquareBrackets {
  # Wraps severity keywords in square brackets of fix length 
  # for easy to read log entries. Examples:
  # - ERR   : [ERR    ]
  # - NOTICE: [NOTICE ]
  # - INFO  : [INFO   ]
  param (
    #[ValidateSet("EMERG", "ALERT", "CRIT", "ERR", "WARNING", "NOTICE", "INFO", "DEBUG")]
    #[String]$keyword
    [SeverityKeyword]$keyword
  )

  $result = "[$keyword"

  while ("${result}".Length -lt 8) {
    $result = "${result} "
  }

  $result = "${result}]"

  return $result

}

#endregion Helper functions ####################################################



function Add-LogMessage {
  # Writes the $message to the $logfile.
  #
  # The Entry gets preceded with date/time and $severity. Example:
  # 2023-04-25T13:46:16 [INFO   ] This is an info message.
  Param(
    [String]$logfile,
    #[ValidateSet("EMERG", "ALERT", "CRIT", "ERR", "WARNING", "NOTICE", "INFO", "DEBUG")]
    #[String]$severity,
    [SeverityKeyword]$severity,
    [String]$message
  )

  #region Check parameters
  # No check for $severity since it is declared as enum value.
  if (! $PSBoundParameters.ContainsKey('logfile')) {
    Write-Error "Add-LogMessage(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('message')) {
    Write-Error "Add-LogMessage(): Parameter message not provided!"
    Throw "Parameter message not provided!"
  }
  #endregion

  $date_time = (Get-Date -Format s)
  $severity_header = Format-InSquareBrackets "${severity}"  # e.g. [INFO   ]

  try {
    "${date_time} ${severity_header} ${message}" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  }
  catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "Add-LogMessage(): Cannot write to logfile ${logfile}. Message: ${severity_header} ${message}" -ForegroundColor White -BackgroundColor Red
  }

}

function LogAndShowMessage {
  # Writes the $message to the $logfile, and displays it in the console.
  Param(
    [String]$logfile,
    #[ValidateSet("EMERG", "ALERT", "CRIT", "ERR", "WARNING", "NOTICE", "INFO", "DEBUG")]
    #[String]$severity,
    [SeverityKeyword]$severity,
    [String]$message
  )

  #region Check parameters
  # No check for $severity since it is declared as enum value.
  if (! $PSBoundParameters.ContainsKey('logfile')) {
    Write-Error "LogAndShowMessage(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('message')) {
    Write-Error "LogAndShowMessage(): Parameter message not provided!"
    Throw "Parameter message not provided!"
  }
  #endregion

  switch ($severity) {
    EMERG {
      ShowEmergMsg "${message}"
      Add-LogMessage "${logfile}" EMERG "${message}"
    }
    ALERT {
      ShowAlertMsg "${message}"
      Add-LogMessage "${logfile}" ALERT "${message}"
    }
    CRIT {
      ShowCritMsg "${message}"
      Add-LogMessage "${logfile}" CRIT "${message}"
    }
    ERR {
      ShowErrMsg "${message}"
      Add-LogMessage "${logfile}" ERR "${message}"
    }
    WARNING {
      ShowWarningMsg "${message}"
      Add-LogMessage "${logfile}" WARNING "${message}"
    }
    NOTICE {
      ShowNoticeMsg "${message}"
      Add-LogMessage "${logfile}" NOTICE "${message}"
    }
    INFO {
      ShowInfoMsg "${message}"
      Add-LogMessage "${logfile}" INFO "${message}"
    }
    DEBUG {
      ShowDebugMsg "${message}"
      Add-LogMessage "${logfile}" DEBUG "${message}"
    }
  }

}

function Add-EmptyLogMessage {
  # Appends an empty line to the $logfile.
  Param(
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('logfile')) {
    Write-Error "Add-EmptyLogMessage(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }
  #endregion

  try {
    "" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  } catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "Add-EmptyLogMessage(): Cannot write to logfile ${logfile}." -ForegroundColor White -BackgroundColor Red
  }

}
