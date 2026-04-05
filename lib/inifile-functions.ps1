#region Helper functions

function Write-FormattedValueList {
  [CmdletBinding()]
  param (
    [System.Collections.Generic.List[string]]$VarNames,
    [System.Collections.Generic.List[string]]$VarValues
  )

  #region Check parameters
  if ($PSBoundParameters.Count -ne 2) {
    Write-Error "Write-FormattedValueList(): Wrong number of parameters provided!"
    Throw "Wrong number of parameters provided!"
  }

  if ( $VarNames.Count -eq 0 ) {
    Write-WarningMsg "Write-FormattedValueList(): Parameter VarNames is an empty collection!"
    return
  }

  if ( $VarValues.Count -eq 0 ) {
    Write-WarningMsg "Write-FormattedValueList(): Parameter VarValues is an empty collection!"
    return
  }
  #endregion Check parameters

  $VarNamesSameLength = [System.Collections.Generic.List[string]]::new()

  # Determine the longest variable name.
  $MaxLength = $( $VarNames | Sort-Object length -desc | Select-Object -first 1 ).Length

  # Make shorter variable names longer.
  for ($i = 0; $i -lt $VarNames.Count; $i++) {
    $VarName = $($VarNames[$i])
    $NumSpacesToAdd = $( $MaxLength - $VarName.Length )
    $VarNameWithSpaces = "${VarName}" + (" " * $NumSpacesToAdd)
    $VarNamesSameLength.Add("${VarNameWithSpaces}")

  }

  # Show debug messages.
  Write-DebugMsg "--------------------------------------------------------------------------------"
  Write-DebugMsg "Values from the settings file:"
  for ($i = 0; $i -lt $VarNames.Count; $i++) {
    Write-DebugMsg "$($VarNamesSameLength[$i]): $($VarValues[$i])"
  }
  Write-DebugMsg "--------------------------------------------------------------------------------"

}

# https://stackoverflow.com/a/10939609/5944475
function Test-IsNumeric ($Value) {
  return $Value -match "^[\d\.]+$"
}

#endregion Helper functions ####################################################



#region Configuration Object

# Container for general settings
class GeneralSettings {
  [int]$__VERBOSE = 6         # Info
}

# Container for directory-related settings
class DirectorySettings {
  # Directories for the backup itself
  [string]$BACKUP_BASE_DIR              # e.g. C:\Backup\
  [string]$BACKUP_USER_BASE_DIR         # e.g. C:\Backup\<username>\
  [string]$BACKUP_DIR                   # e.g. C:\Backup\<username>\<Computername>\

  # Other mandatory directories
  [string]$BACKUP_TEMPLATES_DIR = "${SCRIPT_DIR}templates\"
  [string]$BACKUP_JOB_DIR               #TODO: Can we find a standard in case the user doesn't specify this?

  # Optional directories
  #TODO: Make sure this works as intended!
  [string]$TRACE_LOG_DIR = "%Temp%"

  # Method to ensure all paths are formatted correctly.
  [void] Normalize() {
    # List of properties that are definitely directories
    #TODO: Update list
    #TODO: Make this automatic? Adding values manually is error-prone!
    $DirProperties = @('BACKUP_BASE_DIR', 'BACKUP_USER_BASE_DIR', 'BACKUP_DIR', 'BACKUP_TEMPLATES_DIR', 'BACKUP_JOB_DIR', 'TRACE_LOG_DIR')

    foreach ($Prop in $DirProperties) {
      if (-not [string]::IsNullOrWhiteSpace($this.$Prop)) {
        # Join-Path with an empty child ensures a proper trailing separator
        # and fixes double-slashes or missing slashes.
        $this.$Prop = (Join-Path $this.$Prop "").TrimEnd('\') + '\'
      }
    }
  }
}

# Container for file-related settings
class FileSettings {
  # Files for the backup itself
  [string]$DIRLIST_TEMPLATE = "${SCRIPT_DIR}templates\dir-list-template.conf"
  [string]$BACKUP_DIRLIST   # e.g. C:\Backup\<username>\<Computername>\dir-list.conf

  # Templates for jobtype
  [string]$JOB_TEMPLATE_INCR = "${SCRIPT_DIR}templates\incr_backup.RCJ"
  [string]$JOB_TEMPLATE_FULL = "${SCRIPT_DIR}templates\full_backup.RCJ"
  [string]$JOB_TEMPLATE_PURGE = "${SCRIPT_DIR}templates\purge.RCJ"
  [string]$JOB_TEMPLATE_ARCHIVE = "${SCRIPT_DIR}templates\only_archive_attr.RCJ"

  # Template for job settings
  [string]$JOB_TEMPLATE_GLOBAL_EXCLUSIONS = "${SCRIPT_DIR}templates\global_exclusions.RCJ"
  [string]$JOB_TEMPLATE_LOGGING = "${SCRIPT_DIR}templates\logging.RCJ"

  # Optional files
  [string]$ROBOCOPY = "robocopy"        # Fallback: Windows' own robocopy
}

# Container for logging-related settings
class LoggingSettings {
  # Standard logfile
  [string]$BACKUP_LOGFILE = "Backup.log"          # e.g. C:\Backup\<username>\<Computername>\Backup.log

  # Error log
  [string]$ERROR_LOGFILE = "Error.log"            # e.g. C:\Backup\<username>\<Computername>\Error.log

  # Trace log
  [bool]$ENABLE_TRACE_LOG = $true
  [string]$TRACE_LOG_LOCAL_DIR = "%Temp%"         #TODO: Make sure this works as intended!
  [string]$TRACE_LOGFILE_NAME = "Trace.log"       # e.g. C:\Windows\Temp\Trace.log
  [bool]$UPLOAD_TRACE_TO_BACKUP_DIR = $true

  #TODO: Log rotation?
  # [int]$MaxAgeDays = 14
}

# Container for job-related settings
class JobSettings {
  # Jobtype selection by the user
  [int]$JOB_TYPE_SELECTION_MAX_WAITING_TIME_S = 30
  [string]$DEFAULT_JOB_TYPE = "Incremental"

  # Filename schemes
  [string]$JOB_FILE_NAME_SCHEME = "${COMPUTERNAME}-Job*.RCJ"
  [string]$JOB_LOGFILE_NAME_SCHEME = "${COMPUTERNAME}-Job*.log"
}

# Container for archiving-related settings
class ArchivingSettings {
  [string]$ARCHIVE_NAME_SCHEME = "${COMPUTERNAME}-Jobs-*.zip"
  [int]$MAX_ARCHIVES_COUNT = 10
}

# Main container for all settings
class ScriptConfig {
  [GeneralSettings]$General       = [GeneralSettings]::new()
  [DirectorySettings]$Directories = [DirectorySettings]::new()
  [FileSettings]$Files            = [FileSettings]::new()
  [LoggingSettings]$Logging       = [LoggingSettings]::new()
  [JobSettings]$Jobs              = [JobSettings]::new()
  [ArchivingSettings]$Archiving   = [ArchivingSettings]::new()

  #TODO: You can still have "top-level" settings here if needed
  # [string]$Version = "1.0.0"
}

#endregion Configuration Object ################################################



function Read-Config {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$IniFile
  )

  #FIXME: Consider $WhatIfPreference = $oldWhatIfPreference as in the old "Read-SettingsFile" function?

  $Config = [ScriptConfig]::new()
  #TODO: Do we want to return the (non-populated) container with standard values?
  if (-not (Test-Path $IniFile)) { return $Config }

  # 3. The Translation Book (INI Header -> Class Property)
  $SectionMap = @{
    "General"               = "General"
    #TODO: Is this case-sensitive: "Mandatory Directories" matches [Mandatory directories]?
    "Mandatory Directories" = "Directories"
    #TODO: The INI file has [Mandatory directories] and [Directories] <-- 2x directories!
    "Directories"           = "Directories"
    "Files"                 = "Files"
    "Logging Settings"      = "Logging"
    "Job settings"          = "Jobs"
    "Archiving settings"    = "Archiving"
  }

  $content = Get-Content $IniFile
  $targetProperty = $null

  foreach ($line in $content) {
    $line = $line.Trim()
    if ($line -match '^\[(.+)\]$') {
      # Look up the code-friendly name using the human-friendly header
      $iniHeader = $Matches[1].Trim()
      $targetProperty = $SectionMap[$iniHeader]
    }
    elseif ($line -match '^(.+?)=(.+)$' -and $targetProperty) {
      $key = $Matches[1].Trim()
      $val = $Matches[2].Trim()

      $subObject = $Config.$targetProperty

      # Use PowerShell's hidden 'PSObject' to check if the property exists
      if ($subObject.PSObject.Properties[$key] -and -not [string]::IsNullOrWhiteSpace($val)) {
        $prop = $subObject.PSObject.Properties[$key]

        # Handle Booleans correctly
        if ($prop.TypeNameOfValue -eq 'System.Boolean') {
          if ($val -match '^(true|1|yes|on)$') { $subObject.$key = $true }
          elseif ($val -match '^(false|0|no|off)$') { $subObject.$key = $false }
        }
        # Expand paths for strings
        elseif ($prop.TypeNameOfValue -eq 'System.String') {
          # Temporarily set a local variable so that cross-references in the INI file
          # (e.g. ${BACKUP_BASE_DIR}) can be expanded by Get-ExpandedPath.
          $subObject.$key = Get-ExpandedPath $val
          Set-Variable -Name $key -Value $subObject.$key -Scope Local
        }
        else {
          $subObject.$key = $val
          Set-Variable -Name $key -Value $subObject.$key -Scope Local
        }
      }
    }
  }

  # Ensure paths are normalized
  $Config.Directories.Normalize()

  return $Config
}



function Read-SettingsFile {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$IniFile
  )

  $VarNames = [System.Collections.Generic.List[string]]::new()
  $VarValues = [System.Collections.Generic.List[string]]::new()

  $IniFileContent = Get-Content "${IniFile}"

  # Temporarily disable -WhatIf to ensure the configuration is loaded into the script scope (PowerShell 5.1 workaround).
  $oldWhatIfPreference = $WhatIfPreference
  $WhatIfPreference = $false

  ForEach ($line in $IniFileContent) {
    if (
      ($line -ne "") -and # Empty line
      (! $line.StartsWith("[")) -and # Section
      (! $line.StartsWith(";")) -and # Commented out
      ($line.Contains("="))
    ) {
      $VarName = ($line -split "=")[0]
      $VarValue = ($line -split "=")[1]

      # Store for debug messages.
      $VarNames.Add("${VarName}")
      $VarValues.Add("${VarValue}")

      # Interpret numeric values as Int32; others as String.
      if (Test-IsNumeric $VarValue) {
        [Int32]$IntValue = $VarValue
        Set-Variable -Name "${VarName}" -Value $IntValue -Scope script

      }
      elseif ( ${VarValue} -is [String] ) {
        $expanded = Get-ExpandedPath "${VarValue}"
        Set-Variable -Name "${VarName}" -Value "${expanded}" -Scope script

      }

    }

  }

  $WhatIfPreference = $oldWhatIfPreference

  if ($VarNames.Count -gt 0) {
    Write-FormattedValueList $VarNames $VarValues
  }

}
