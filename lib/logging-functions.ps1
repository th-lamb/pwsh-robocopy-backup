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
  <# Appends the $message to the $logfile.
    The Entry gets preceded with date/time and $severity. Example:
  2023-04-25T13:46:16 [INFO   ] This is an info message.
  #>
  Param(
    [String]$logfile,
    [SeverityKeyword]$severity,
    [String]$message
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('logfile')) {
    Write-Error "Add-LogMessage(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }

  # No check for $severity since it is declared as enum value. (Error when PowerShell
  # tries to map the next parameter (message) to one of the enum values.

  if (! $PSBoundParameters.ContainsKey('message')) {
    Write-Error "Add-LogMessage(): Parameter message not provided!"
    Throw "Parameter message not provided!"
  }
  #endregion

  $date_time = (Get-Date -Format s)
  $severity_header = Format-InSquareBrackets $severity  # e.g. [INFO   ]

  try {
    "${date_time} ${severity_header} ${message}" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  }
  catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "Add-LogMessage(): Cannot write to logfile ${logfile}. Message: ${severity_header} ${message}" -ForegroundColor White -BackgroundColor Red
  }

}

function Add-EmptyLineToLogfile {
  # Appends an empty line to the $logfile.
  Param(
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('logfile')) {
    Write-Error "Add-EmptyLineToLogfile(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }
  #endregion

  try {
    "" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  } catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "Add-EmptyLineToLogfile(): Cannot write to logfile ${logfile}." -ForegroundColor White -BackgroundColor Red
  }

}

function LogAndShowMessage {
  <# Appends the $message to the $logfile, and writes it to the console.
    The type of message written to the console depends on the $severity.
  #>
  Param(
    [String]$logfile,
    [SeverityKeyword]$severity,
    [String]$message
  )

  # Log the message.
  Add-LogMessage "${logfile}" $severity "${message}"

  # Write the message to the console.
  switch ($severity) {
    EMERG   { Write-EmergMsg "${message}" }
    ALERT   { Write-AlertMsg "${message}" }
    CRIT    { Write-CritMsg "${message}" }
    ERR     { Write-ErrMsg "${message}" }
    WARNING { Write-WarningMsg "${message}" }
    NOTICE  { Write-NoticeMsg "${message}" }
    INFO    { Write-InfoMsg "${message}" }
    DEBUG   { Write-DebugMsg "${message}" }
  }

}
