#TODO: Check directory before showing "Cannot write to logfile" error?



enum SeverityKeyword
{
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

function _inSquareBrackets
{
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

  while ("${result}".Length -lt 8)
  {
    $result = "${result} "
  }

  $result = "${result}]"

  return $result

}

#endregion Helper functions ####################################################



function LogMessage
{
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
  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "LogMessage(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('message'))
  {
    Write-Error "LogMessage(): Parameter message not provided!"
    Throw "Parameter message not provided!"
  }
  #endregion

  $date_time = (Get-Date -Format s)
  $severity_header = _inSquareBrackets "${severity}"  # e.g. [INFO   ]

  try {
    "${date_time} ${severity_header} ${message}" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  }
  catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "LogMessage(): Cannot write to logfile ${logfile}. Message: ${severity_header} ${message}" -ForegroundColor White -BackgroundColor Red
  }

}

function LogAndShowMessage
{
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
  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "LogAndShowMessage(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('message'))
  {
    Write-Error "LogAndShowMessage(): Parameter message not provided!"
    Throw "Parameter message not provided!"
  }
  #endregion

  switch ($severity)
  {
    EMERG
    {
      ShowEmergMsg "${message}"
      LogMessage "${logfile}" EMERG "${message}"
    }
    ALERT
    {
      ShowAlertMsg "${message}"
      LogMessage "${logfile}" ALERT "${message}"
    }
    CRIT
    {
      ShowCritMsg "${message}"
      LogMessage "${logfile}" CRIT "${message}"
    }
    ERR
    {
      ShowErrMsg "${message}"
      LogMessage "${logfile}" ERR "${message}"
    }
    WARNING
    {
      ShowWarningMsg "${message}"
      LogMessage "${logfile}" WARNING "${message}"
    }
    NOTICE
    {
      ShowNoticeMsg "${message}"
      LogMessage "${logfile}" NOTICE "${message}"
    }
    INFO
    {
      ShowInfoMsg "${message}"
      LogMessage "${logfile}" INFO "${message}"
    }
    DEBUG
    {
      ShowDebugMsg "${message}"
      LogMessage "${logfile}" DEBUG "${message}"
    }
  }

}

function LogInsertEmptyLine
{
  # Appends an empty line to the $logfile.
  Param(
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "LogInsertEmptyLine(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }
  #endregion

  try {
    "" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  }
  catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "LogInsertEmptyLine(): Cannot write to logfile ${logfile}." -ForegroundColor White -BackgroundColor Red
  }

}
