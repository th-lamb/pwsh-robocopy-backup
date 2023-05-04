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
    # The output of Write-Error is quite difficult to read!
    #Write-Error "logMessage(): Cannot write to logfile: ${logfile}"
    #TODO Use function errMsg from message-functions.ps1? (Might be better without an external dependency.)
    Write-Host "logMessage(): Cannot write to logfile: ${logfile}" -ForegroundColor White -BackgroundColor Red
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
      logMessage "${logfile}" EMERG "${message}"
      emergMsg "${message}"
    }
    ALERT
    {
      logMessage "${logfile}" ALERT "${message}"
      alertMsg "${message}"
    }
    CRIT
    {
      logMessage "${logfile}" CRIT "${message}"
      critMsg "${message}"
    }
    ERR
    {
      logMessage "${logfile}" ERR "${message}"
      errMsg "${message}"
    }
    WARNING
    {
      logMessage "${logfile}" WARNING "${message}"
      warningMsg "${message}"
    }
    NOTICE
    {
      logMessage "${logfile}" NOTICE "${message}"
      noticeMsg "${message}"
    }
    INFO
    {
      logMessage "${logfile}" INFO "${message}"
      infoMsg "${message}"
    }
    DEBUG
    {
      logMessage "${logfile}" DEBUG "${message}"
      debugMsg "${message}"
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
    Write-Error "logMessage(): Parameter logfile not provided!"
    exit 1
  }
  #endregion

  try {
    "" | Out-File -FilePath "${logfile}" -Encoding utf8 -Append
  }
  catch {
    #TODO Use function errMsg from message-functions.ps1? (Might be better without an external dependency.)
    Write-Host "logMessage(): Cannot write to logfile: ${logfile}" -ForegroundColor White -BackgroundColor Red
  }

}
