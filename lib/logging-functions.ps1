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



function Write-LogMessage {
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
    Write-Error "Write-LogMessage(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('message')) {
    Write-Error "Write-LogMessage(): Parameter message not provided!"
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
    Write-Host "Write-LogMessage(): Cannot write to logfile ${logfile}. Message: ${severity_header} ${message}" -ForegroundColor White -BackgroundColor Red
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
      Write-LogMessage "${logfile}" EMERG "${message}"
    }
    ALERT {
      ShowAlertMsg "${message}"
      Write-LogMessage "${logfile}" ALERT "${message}"
    }
    CRIT {
      ShowCritMsg "${message}"
      Write-LogMessage "${logfile}" CRIT "${message}"
    }
    ERR {
      ShowErrMsg "${message}"
      Write-LogMessage "${logfile}" ERR "${message}"
    }
    WARNING {
      ShowWarningMsg "${message}"
      Write-LogMessage "${logfile}" WARNING "${message}"
    }
    NOTICE {
      ShowNoticeMsg "${message}"
      Write-LogMessage "${logfile}" NOTICE "${message}"
    }
    INFO {
      ShowInfoMsg "${message}"
      Write-LogMessage "${logfile}" INFO "${message}"
    }
    DEBUG {
      ShowDebugMsg "${message}"
      Write-LogMessage "${logfile}" DEBUG "${message}"
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
