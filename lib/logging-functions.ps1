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
  <# Wraps severity keywords in square brackets of fix length
    for easy to read log entries. Examples:
    - ERR   : [ERR    ]
    - NOTICE: [NOTICE ]
    - INFO  : [INFO   ]
  #>
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    #[ValidateSet("EMERG", "ALERT", "CRIT", "ERR", "WARNING", "NOTICE", "INFO", "DEBUG")]
    #[String]$keyword
    [Parameter(Mandatory=$true)]
    [SeverityKeyword]$keyword
  )

  $sb = [System.Text.StringBuilder]::new("[$keyword")

  while ($sb.Length -lt 8) {
    [void]$sb.Append(" ")
  }

  [void]$sb.Append("]")

  return $sb.ToString()

}

#endregion Helper functions ####################################################



function Add-LogMessage {
  <# Appends the $message to the $logfile.
    The Entry gets preceded with date/time and $severity. Example:
  2023-04-25T13:46:16 [INFO   ] This is an info message.
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [String]$logfile,
    [Parameter(Mandatory=$true)]
    [SeverityKeyword]$severity,
    [Parameter(Mandatory=$true)]
    [String]$message
  )

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
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [String]$logfile
  )

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
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [String]$logfile,
    [Parameter(Mandatory=$true)]
    [SeverityKeyword]$severity,
    [Parameter(Mandatory=$true)]
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
