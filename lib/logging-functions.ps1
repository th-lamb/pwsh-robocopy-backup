using module '.\config-classes.psm1'

#TODO: Check directory before showing "Cannot write to logfile" error?

# Script-scoped variables to store log paths and settings
$script:PrimaryLogPath    = $null
$script:ErrorLogPath      = $null
$script:TraceLogEnabled   = $false
$script:TraceLogTempPath  = $null
$script:TraceLogFinalPath = $null

function Initialize-Logger {
  <# Initializes the logger with paths from the configuration.
    These paths are stored in script-scoped variables for centralized access.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ScriptConfig]$Config
  )

  $script:PrimaryLogPath    = $Config.Logging.BACKUP_LOGFILE
  $script:ErrorLogPath      = $Config.Logging.ERROR_LOGFILE
  $script:TraceLogEnabled   = $Config.Logging.TRACE_LOG_ENABLED
  $script:TraceLogTempPath  = $Config.Logging.TRACE_LOG_TEMP_PATH
  $script:TraceLogFinalPath = $Config.Logging.TRACE_LOGFILE
}

#region Helper functions

function Format-SeverityLabel {
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
    #[string]$keyword
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



#region Internal Logging Helpers

function Write-ToPrimaryLog {
  param (
    [string]$logfile,
    [SeverityKeyword]$severity,
    [string]$formattedMessage
  )

  # Filter: If writing to the main Backup.log, skip DEBUG (7) messages.
  if ($logfile -eq $script:PrimaryLogPath -and $severity -eq [SeverityKeyword]::DEBUG) {
    return
  }

  try {
    $formattedMessage | Out-File -FilePath $logfile -Encoding utf8 -Append
  }
  catch {
    Write-Host "Write-ToPrimaryLog(): Cannot write to logfile ${logfile}. Message: ${formattedMessage}" -ForegroundColor White -BackgroundColor Red
  }
}

function Write-ToErrorLog {
  param (
    [SeverityKeyword]$severity,
    [string]$formattedMessage
  )

  # Only log if severity is 3 (ERR) or less (0..3).
  if ([int]$severity -le 3 -and ! [string]::IsNullOrWhiteSpace($script:ErrorLogPath)) {
    try {
      $formattedMessage | Out-File -FilePath $script:ErrorLogPath -Encoding utf8 -Append
    }
    catch {
      Write-Host "Write-ToErrorLog(): Cannot write to error log ${script:ErrorLogPath}." -ForegroundColor White -BackgroundColor Red
    }
  }
}

function Write-ToTraceLog {
  param (
    [string]$formattedMessage
  )

  if ($script:TraceLogEnabled -and ! [string]::IsNullOrWhiteSpace($script:TraceLogTempPath)) {
    try {
      $formattedMessage | Out-File -FilePath $script:TraceLogTempPath -Encoding utf8 -Append
    }
    catch {
      Write-Host "Write-ToTraceLog(): Cannot write to trace log ${script:TraceLogTempPath}." -ForegroundColor White -BackgroundColor Red
    }
  }
}

#endregion Internal Logging Helpers ############################################



function Add-LogMessage {
  <# Appends the $message to the $logfile.
    The Entry gets preceded with date/time and $severity. Example:
    2023-04-25T13:46:16 [INFO   ] This is an info message.
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [SeverityKeyword]$severity,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string]$logfile = $script:PrimaryLogPath
  )

  $Timestamp = (Get-Date -Format s)
  $SeverityHeader = Format-SeverityLabel $severity  # e.g. [INFO   ]
  $FullMessage = "${Timestamp} ${SeverityHeader} ${message}"

  # Traffic Controller: Distribute the message to the appropriate logs.
  if (! [string]::IsNullOrWhiteSpace($logfile)) {
    Write-ToPrimaryLog -logfile $logfile -severity $severity -formattedMessage $FullMessage
  }

  Write-ToErrorLog -severity $severity -formattedMessage $FullMessage
  Write-ToTraceLog -formattedMessage $FullMessage

}

function Add-EmptyLineToLogfile {
  # Appends an empty line to the $logfile.
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string]$logfile = $script:PrimaryLogPath
  )

  if ([string]::IsNullOrWhiteSpace($logfile)) {
    return
  }

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
    [SeverityKeyword]$severity,
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string]$logfile = $script:PrimaryLogPath
  )

  # Log the message.
  Add-LogMessage -severity $severity -message "${message}" -logfile "${logfile}"

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
