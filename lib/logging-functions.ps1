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



function logMessage
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
    Write-Error "logMessage(): Parameter logfile not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('message'))
  {
    Write-Error "logMessage(): Parameter message not provided!"
    exit 1
  }
  #endregion

  $date_time = (Get-Date -Format s)
  $severity_header = _inSquareBrackets "${severity}"  # e.g. [INFO   ]

  try {
    "${date_time} ${severity_header} ${message}" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  }
  catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "logMessage(): Cannot write to logfile ${logfile}. Message: ${severity_header} ${message}" -ForegroundColor White -BackgroundColor Red
  }

}

function logAndShowMessage
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
    Write-Error "logAndShowMessage(): Parameter logfile not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('message'))
  {
    Write-Error "logAndShowMessage(): Parameter message not provided!"
    exit 1
  }
  #endregion

  switch ($severity)
  {
    EMERG
    {
      emergMsg "${message}"
      logMessage "${logfile}" EMERG "${message}"
    }
    ALERT
    {
      alertMsg "${message}"
      logMessage "${logfile}" ALERT "${message}"
    }
    CRIT
    {
      critMsg "${message}"
      logMessage "${logfile}" CRIT "${message}"
    }
    ERR
    {
      errMsg "${message}"
      logMessage "${logfile}" ERR "${message}"
    }
    WARNING
    {
      warningMsg "${message}"
      logMessage "${logfile}" WARNING "${message}"
    }
    NOTICE
    {
      noticeMsg "${message}"
      logMessage "${logfile}" NOTICE "${message}"
    }
    INFO
    {
      infoMsg "${message}"
      logMessage "${logfile}" INFO "${message}"
    }
    DEBUG
    {
      debugMsg "${message}"
      logMessage "${logfile}" DEBUG "${message}"
    }
  }

}

function logInsertEmptyLine
{
  # Appends an empty line to the $logfile.
  Param(
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "logInsertEmptyLine(): Parameter logfile not provided!"
    exit 1
  }
  #endregion

  try {
    "" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  }
  catch {
    # We use Write-Host with special colors because the output of Write-Error is quite difficult to read!
    Write-Host "logInsertEmptyLine(): Cannot write to logfile ${logfile}." -ForegroundColor White -BackgroundColor Red
  }

}
