#         Message functions library
#         =========================
# 
# Provides different (colored) messages depending on their severity level.
# - Severity levels: https://en.wikipedia.org/wiki/Syslog#Severity_level
# - Colors inspired by ANSI Z535.6
# 
# Does not use the standard PowerShell streams 1..6 (Output, Error, Warning, 
# Verbose, ...), only Write-Host to write to the console with different colors.
# 
# There are two variants of all message functions. Example:
# - Write-InfoMsg(): Prints the message only.
#TODO: infoLog is removed?
# - infoLog(): Prints a timestamp before the message.
# 
# 
#     How to use in your script?
#     ==========================
# 
# 1. Source this file.
# 
# 2. Define variable ${__VERBOSE} with value 0..7 in your script.
#    -> Set ${__VERBOSE} via options --quiet, --verbose or similar.
# 
# 3. Replace Write-Host commands with function calls depending on the message severity.
#    -> e.g. Write-NoticeMsg() for important (but expected) messages, and Write-ErrMsg() 
#       for unexpected errors
# 
# 
#     When will a message be shown?
#     =============================
# 
# The message functions are related to a specific severity level. Messages will 
# be shown if $__VERBOSE is equal to or higher than this level.
# 
#   | Function            | Severity (value)| Condition           |
#   +---------------------+-----------------+---------------------+
#   | Write-EmergMsg()    | emerg     (0)   | none (always shown) |
#   | Write-AlertMsg()    | alert     (1)   | ""                  |
#   | Write-CritMsg()     | crit      (2)   | ""                  |
#   | Write-ErrMsg()      | err       (3)   | ""                  |
#   | Write-WarningMsg()  | warning   (4)   | ${__VERBOSE} >= 4   |
#   | Write-NoticeMsg()   | notice    (5)   | ${__VERBOSE} >= 5   |
#   | Write-InfoMsg()     | info      (6)   | ${__VERBOSE} >= 6   |
#   | Write-DebugMsg()    | debug     (7)   | ${__VERBOSE} = 7    |
# 
# 
#     Helper functions
#     ================
# 
# Not meant to be called directly:
# - Write-ColoredMessage()
# - _coloredLog()
# - Test-VerbosityIsDefined()
# 
# 
#     Wrappers for simple verbose modes
#     =================================
# 
# - Write-QuietMessage()  : Interpreted as a warning
# - Write-NormalMessage() : Interpreted as "info" but will already be shown at 
#                           verbose level 5 (severity level "notice").
# - Write-VerboseMessage(): Interpreted as "info" but will only be shown at verbose 
#                           level 7 (severity level "debug").
# 
################################################################################



#         Change log
#         ==========
# 2023-03-20, Version 0.0.01, Thomas Lambeck
# - File created
################################################################################



#region Helper functions - Colored message (without and with timestamp)

function Write-ColoredMessage {
  <# Writes the specified message to the console with colors depending on the severity level of the message.

    Notes:
    * Severity levels: https://en.wikipedia.org/wiki/Syslog#Severity_level
    * Colors inspired by ANSI Z535.6
    * Throws an exception on illegal severity levels.
TODO:
    * Redirects errors (emerg...warning) to stderr and other messages to stdout.
      -> Powershell has 6 streams!

    Parameters:
    $1   Severity level: emerg|alert|crit|err|warning|notice|info|debug
    $2   The message
  #>
  #TODO: Use the enum in logging-functions for $severity.
  param (
    [String]$severity,
    [String]$message
  )

  $is_err = $false

  switch ($severity) {
    "emerg" {
      $is_err = $true
      $background_color = "Red"
      $foreground_color = "White"
    }
    "alert" {
      $is_err = $true
      $background_color = "Red"
      $foreground_color = "Black"
    }
    "crit" {
      $is_err = $true
      $background_color = "Yellow"
      $foreground_color = "Black"
    }
    "err" {
      $is_err = $true
      $background_color = "White"
      $foreground_color = "Red"
    }
    "warning" {
      $background_color = "White"
      $foreground_color = "Black"
    }
    "notice" {
      $background_color = "Blue"
      $foreground_color = "White"
    }
    "info" {
      $background_color = "Black"
      $foreground_color = "White"
    }
    "debug" {
      $background_color = "Black"
      $foreground_color = "DarkGray"
    }
    Default {
      # Illegal severity level!
      $err_message = "Write-ColoredMessage(): Illegal severity level specified: ${severity}"
      Write-ColoredMessage "err" "${err_message}"
      Throw "${err_message}"
    }
  }

  #TODO: Finish the remaining section!
  #Write-Host "${message}" -ForegroundColor "${foreground_color}" -BackgroundColor "${background_color}"

  if ($is_err) {
    #Write-Error "${message}"
    #Write-Error "${message}" 2>> .\error.log                     # Nothing in console, the whole verbose error message in the logfile

    #[Console]::ForegroundColor = "${foreground_color}"
    #[Console]::BackgroundColor = "${background_color}"

    #[Console]::Error.WriteLine("${message}")                     # no output to the logfile
    #[Console]::Error.WriteLine("${message}") 1>> .\1.log         # no output to the logfile
    #[Console]::Error.WriteLine("${message}") 2>> .\2.log         # no output to the logfile
    #[Console]::Error.WriteLine("${message}") 3>> .\3.log         # no output to the logfile
    #[Console]::Error.WriteLine("${message}") 4>> .\4.log         # no output to the logfile
    #[Console]::Error.WriteLine("${message}") 5>> .\5.log         # no output to the logfile
    #[Console]::Error.WriteLine("${message}") 6>> .\6.log         # no output to the logfile
    #[Console]::Error.WriteLine("${message}") 2>> .\error.log     # no output to the logfile
    #[Console]::Error.WriteLine("${message}") >> .\error.log      # no output to the logfile

    #[Console]::ResetColor()

    Write-Host "${message}" -ForegroundColor "${foreground_color}" -BackgroundColor "${background_color}" # 6>> .\error.log

  } else {
    #TODO: remove the redirection after testing
    Write-Host "${message}" -ForegroundColor "${foreground_color}" -BackgroundColor "${background_color}" # 6>> .\success.log
  }

}

#endregion Helper functions - Colored message (without and with timestamp) #####



#region Helper functions - checks

function Test-VerbosityIsDefined {
  <# Returns false if ${__VERBOSE} is not defined or 
    if ${__VERBOSE} is not between 0..7.
  #>

  $MIN=0
  $MAX=7

  (
    "${__VERBOSE}" -ge "${MIN}") -and
    ("${__VERBOSE}" -le "${MAX}"
  )

}

#endregion Helper functions - checks ###########################################



#region Wrappers for severity levels (without timestamp)

function Write-EmergMsg {
  <# Write-ColoredMessage() for severity level 0 (emerg).
    Notice: No verbose level check, always shown
  #>
  param (
    [String]$message
  )

  Write-ColoredMessage "emerg" "[EMERG  ] ${message}"

}

function Write-AlertMsg {
  <# Write-ColoredMessage() for severity level 1 (alert).
    Notice: No verbose level check, always shown
  #>
  param (
    [String]$message
  )

  Write-ColoredMessage "alert" "[ALERT  ] ${message}"

}

function Write-CritMsg {
  <# Write-ColoredMessage() for severity level 2 (crit).
    Notice: No verbose level check, always shown
  #>
  param (
    [String]$message
  )

  Write-ColoredMessage "crit" "[CRIT   ] ${message}"

}

function Write-ErrMsg {
  <# Write-ColoredMessage() for severity level 3 (err).
    Notice: No verbose level check, always shown
  #>
  param (
    [String]$message
  )

  Write-ColoredMessage "err" "[ERR    ] ${message}"

}

function Write-WarningMsg {
  # Write-ColoredMessage() for severity level 4 (warning).
  param (
    [String]$message
  )

  # Check: ${__VERBOSE} is defined and between 0..7?
  if (! (Test-VerbosityIsDefined) ) {
    Write-ErrMsg "__VERBOSE is not defined and between 0..7!"
    Throw "__VERBOSE is not defined and between 0..7!"
  }

  # Show message if ${__VERBOSE} >= 4 (warning).
  if ("$__VERBOSE" -ge 4) {
    Write-ColoredMessage "warning" "[WARNING] ${message}"
  }

}

function Write-NoticeMsg {
  # Write-ColoredMessage() for severity level 5 (notice).
  param (
    [String]$message
  )

  # Check: ${__VERBOSE} is defined and between 0..7?
  if (! (Test-VerbosityIsDefined) ) {
    Write-ErrMsg "__VERBOSE is not defined and between 0..7!"
    Throw "__VERBOSE is not defined and between 0..7!"
  }

  # Show message if ${__VERBOSE} >= 5 (notice).
  if ("$__VERBOSE" -ge 5) {
    Write-ColoredMessage "notice" "[NOTICE ] ${message}"
  }

}

function Write-InfoMsg {
  # Write-ColoredMessage() for severity level 6 (info).
  param (
    [String]$message
  )

  # Check: ${__VERBOSE} is defined and between 0..7?
  if (! (Test-VerbosityIsDefined) ) {
    Write-ErrMsg "__VERBOSE is not defined and between 0..7!"
    Throw "__VERBOSE is not defined and between 0..7!"
  }

  # Show message if ${__VERBOSE} >= 6 (info).
  if ("$__VERBOSE" -ge 6) {
    Write-ColoredMessage "info" "[INFO   ] ${message}"
  }

}

function Write-DebugMsg {
  # Write-ColoredMessage() for severity level 7 (debug).
  param (
    [String]$message
  )

  # Check: ${__VERBOSE} is defined and between 0..7?
  if (! (Test-VerbosityIsDefined) ) {
    Write-ErrMsg "__VERBOSE is not defined and between 0..7!"
    Throw "__VERBOSE is not defined and between 0..7!"
  }

  # Show message if ${__VERBOSE} >= 7 (debug).
  if ("$__VERBOSE" -ge 7) {
    Write-ColoredMessage "debug" "[DEBUG  ] ${message}"
  }

}

#endregion Wrappers for severity levels (without timestamp) ####################



#region ... with additional exit codes

function Stop-WithEmergMessage {
  #TODO: Change text: no "_coloredLog" anymore!
  <# _coloredLog() for severity level 0 (emerg) and exit with specified exit code.
    Notice: No verbose level check, always shown

    Parameters:
    $1  exit with code
    $2  string to log
  #>
  param (
    [Int32]$exit_code,
    [String]$message
  )

  Write-EmergMsg "${message}"
  exit $exit_code

}

function Stop-WithAlertMessage {
  #TODO: Change text: no "_coloredLog" anymore!
  <# _coloredLog() for severity level 1 (alert) and exit with specified exit code.
    Notice: No verbose level check, always shown

    Parameters:
    $1  exit with code
    $2  string to log
  #>
  param (
    [Int32]$exit_code,
    [String]$message
  )

  Write-AlertMsg "${message}"
  exit $exit_code

}

function Stop-WithCritMessage {
  #TODO: Change text: no "_coloredLog" anymore!
  <# _coloredLog() for severity level 2 (crit) and exit with specified exit code.
    Notice: No verbose level check, always shown

    Parameters:
    $1  exit with code
    $2  string to log
  #>
  param (
    [Int32]$exit_code,
    [String]$message
  )

  Write-CritMsg "${message}"
  exit $exit_code

}

function Stop-WithErrMessage {
  #TODO: Change text: no "_coloredLog" anymore!
  <# _coloredLog() for severity level 3 (err) and exit with specified exit code.
    Notice: No verbose level check, always shown

    Parameters:
    $1  exit with code
    $2  string to log
  #>
  param (
    [Int32]$exit_code,
    [String]$message
  )

  Write-ErrMsg "${message}"
  exit $exit_code

}

#endregion ... with additional exit codes ######################################



#region Wrappers for simple verbose modes

function Write-QuietMessage {
  <# Shows the specified message even in quiet mode.
    -> Message is interpreted as a warning.
  #>
  param (
    [String]$message
  )

  # Colored warning message if ${__VERBOSE} >= 4.
  Write-WarningMsg "${message}"

}

function Write-NormalMessage {
  <# Shows the specified message in normal mode.

    Notes:
    The Message will be interpreted as "info" but will already be shown at 
    verbose level 5 (severity level "notice").
  #>
  param (
    [String]$message
  )

  # Check: ${__VERBOSE} is defined and between 0..7?
  if (! (Test-VerbosityIsDefined) ) {
    Write-ErrMsg "__VERBOSE is not defined and between 0..7!"
    Throw "__VERBOSE is not defined and between 0..7!"
  }

  # Show message if ${__VERBOSE} >= 5 (notice).
  if ("$__VERBOSE" -ge 5) {
    Write-ColoredMessage "info" "[INFO   ] ${message}"
  }

}

function Write-VerboseMessage {
  <# Shows the specified message only in verbose mode.
    -> Message is interpreted as an info message.
  #>
  param (
    [String]$message
  )

  # Check: ${__VERBOSE} is defined and between 0..7?
  if (! (Test-VerbosityIsDefined) ) {
    Write-ErrMsg "__VERBOSE is not defined and between 0..7!"
    Throw "__VERBOSE is not defined and between 0..7!"
  }

  # Show message if ${__VERBOSE} = 7 (debug).
  if ("$__VERBOSE" -eq 7) {
    Write-ColoredMessage "info" "[INFO   ] ${message}"
  }

}

#endregion Wrappers for simple verbose modes ###################################
