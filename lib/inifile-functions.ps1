#region Helper functions

#TODO: Use for new function Read-Config
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

<# TODO: Create enum for all the containers?
  GeneralSettings -> General,
  DirectorySettings -> Directories,
  ...,
  ArchivingSettings -> Archiving

  To be used for correctness **and consistency** in:
  - class ScriptConfig?
  - function Get-Container?
  - more?
#>
# enum ConfigContainers {
#   GeneralSettings = "General"
#   DirectorySettings = "Directories"
#   FileSettings = "Files"
#   LoggingSettings = "Logging"
#   JobSettings = "Jobs"
#   ArchivingSettings = "Archiving"
# }



#TODO: Add Pester tests to test the default values!

# Container for general settings
class GeneralSettings {
  [int]$__VERBOSE = 6         # Info
}

# Container for directory-related settings
class DirectorySettings {
  # Directories for the backup itself
  <#TODO: Define default values for these 3? Example:
    - Base Dir            : .\Backup\   (relative path below the script dir)
    - User Base Dir       : .\Backup\%Username%
    - (actual) Backup Dir : .\Backup\%Username%\%Computername%
  #>
  <#TODO: Use . or ${SCRIPT_DIR}?
    - ${SCRIPT_DIR} should always be the script dir.
    - . could be any current directory from where the script is called?
  #>
  [string]$BACKUP_BASE_DIR = ".\Backup\"                           # Or "${SCRIPT_DIR}Backup\"?
  [string]$BACKUP_USER_BASE_DIR = ".\Backup\%Username%\"                # Or "${SCRIPT_DIR}Backup\%Username%\"?"
  [string]$BACKUP_DIR = ".\Backup\%Username%\%Computername%\" # Or "${SCRIPT_DIR}Backup\%Username%\%Computername%\"?

  # Other mandatory directories
  [string]$BACKUP_TEMPLATES_DIR = "${SCRIPT_DIR}templates\"             # Note: Must be ${SCRIPT_DIR} not "."!
  [string]$BACKUP_JOB_DIR = ".\Backup\%Username%\robocopy-jobs\"  # Or "${SCRIPT_DIR}Backup\%Username%\robocopy-jobs\"?

  # Optional directories
  #TODO: Make sure this works as intended!
  [string]$TRACE_LOG_DIR = "%Temp%"

  # Method to ensure all paths are formatted correctly.
  [void] Normalize() {
    # List of properties that are definitely directories
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
  [string]$BACKUP_DIRLIST = "dir-list.conf"     # e.g. .\Backup\<username>\<Computername>\dir-list.conf

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
  #TODO: Rename to BACKUP_LOGFILE_NAME?
  [string]$BACKUP_LOGFILE = "Backup.log"          # e.g. .\Backup\<username>\<Computername>\Backup.log

  # Error log
  #TODO: Rename to ERROR_LOGFILE_NAME?
  [string]$ERROR_LOGFILE = "Error.log"            # e.g. .\Backup\<username>\<Computername>\Error.log

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
  [GeneralSettings]$General = [GeneralSettings]::new()
  [DirectorySettings]$Directories = [DirectorySettings]::new()
  [FileSettings]$Files = [FileSettings]::new()
  [LoggingSettings]$Logging = [LoggingSettings]::new()
  [JobSettings]$Jobs = [JobSettings]::new()
  [ArchivingSettings]$Archiving = [ArchivingSettings]::new()

  #TODO: You can still have "top-level" settings here if needed
  # [string]$Version = "1.0.0"
}

#endregion Configuration Object ################################################



#region Read-Config

function Get-Container {
  # Returns the container (inside the Configuration Object) for the specified section in the INI file.
  # Returns $null if the section is unrecognized.
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory = $true)]
    [string]$IniHeader
  )

  # Translation (INI Header -> Class Property)
  $SectionMap = @{
    "General"               = "General"
    "Mandatory Directories" = "Directories"
    "Directories"           = "Directories"
    "Files"                 = "Files"
    "Logging Settings"      = "Logging"
    "Job Settings"          = "Jobs"
    "Archiving Settings"    = "Archiving"
  }

  return $SectionMap[$iniHeader]
}

#TODO: Add Pester tests for Read-Config (as the old ones for Read-SettingsFile)
function Read-Config {
  <# Reads the specified INI file and returns a Configuration Object with all settings.
    The structure of the Config Object is like $Config.Container.Property = Value
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$IniFile
  )

  $Config = [ScriptConfig]::new()

  if (-not (Test-Path $IniFile)) {
    Write-WarningMsg "Settings file not found: [$IniFile]. Using default values."
    return $Config
  }

  $IniFileContent = Get-Content "${IniFile}"
  $TargetContainer = $null

  # Temporarily disable -WhatIf to ensure the configuration is loaded into the script scope (PowerShell 5.1 workaround).
  $oldWhatIfPreference = $WhatIfPreference
  try {
    $WhatIfPreference = $false

    foreach ($Line in $IniFileContent) {
      $Line = $Line.Trim()
      if ($Line -match '^\[(.+)\]$') {
        # Look up the code-friendly name using the human-friendly header
        $IniHeader = $Matches[1].Trim()
        $TargetContainer = Get-Container -IniHeader "${IniHeader}"

        if ($null -eq $TargetContainer) {
          Write-WarningMsg "Unrecognized section in INI file: [$IniHeader]"
        }
      }
      elseif ($Line -match '^(.+?)=(.+)$' -and $TargetContainer) {
        $key = $Matches[1].Trim()
        $val = $Matches[2].Trim()

        $SubObject = $Config.$TargetContainer

        # Use PowerShell's hidden 'PSObject' to check if the property exists
        if ($SubObject.PSObject.Properties[$key] -and -not [string]::IsNullOrWhiteSpace($val)) {
          $prop = $SubObject.PSObject.Properties[$key]

          # Handle Booleans correctly
          if ($prop.TypeNameOfValue -eq 'System.Boolean') {
            if ($val -match '^(true|1|yes|on)$') { $SubObject.$key = $true }
            elseif ($val -match '^(false|0|no|off)$') { $SubObject.$key = $false }
          }
          # Expand paths for strings
          elseif ($prop.TypeNameOfValue -eq 'System.String') {
            # Temporarily set a local variable so that cross-references in the INI file
            # (e.g. ${BACKUP_BASE_DIR}) can be expanded by Get-ExpandedPath.
            $SubObject.$key = Get-ExpandedPath $val
            Set-Variable -Name $key -Value $SubObject.$key -Scope Local
          }
          else {
            $SubObject.$key = $val
            Set-Variable -Name $key -Value $SubObject.$key -Scope Local
          }
        }
      }
    }

    # Ensure paths are normalized
    <# FIXME: Final call of `$Config.Directories.Normalize()` might be too late for combined variables!
      Example: the user defines `BACKUP_BASE_DIR=C:\Backups` (without trailing backslash) and re-uses
      this variable to for in `BACKUP_USER_BASE_DIR=${BACKUP_BASE_DIR}%USERNAME%\`.
      When `$Config.Directories.Normalize()` is called, the expanded paths are already assembled and
      the *missing "\" is in the middle* of the string!
    #>
    $Config.Directories.Normalize()
  }
  finally {
    $WhatIfPreference = $oldWhatIfPreference
  }

  <# TODO: Output new settings
    - As in old function Read-SettingsFile?
    - Just "print" the Configuration Object?
  #>
  # if ($VarNames.Count -gt 0) {
  #   Write-FormattedValueList $VarNames $VarValues
  # }

  return $Config
}

#endregion Read-Config #########################################################



#TODO: Remove the old function
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
