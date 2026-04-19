# This resolves to the actual directory where the project is,
# even if called from a different working directory.
$ProjectRoot = (Split-Path -Parent $PSScriptRoot) + "\"



#region Helper functions

function Expand-EnvVar {
  # Expands environment variables for all string properties of the object.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    $Object
  )

  # Use .NET Reflection to find properties (more reliable than PSObject or Get-Member)
  $Properties = $Object.GetType().GetProperties()

  foreach ($Prop in $Properties) {
    if ($Prop.PropertyType.FullName -eq 'System.String' -and $Prop.CanWrite) {
      $Value = $Prop.GetValue($Object)
      if (-not [string]::IsNullOrWhiteSpace($Value)) {
        $Expanded = [System.Environment]::ExpandEnvironmentVariables($Value)
        # Only update if changed
        if ($Expanded -ne $Value) {
          $Prop.SetValue($Object, $Expanded)
        }
      }
    }
  }
}

function Set-TrailingSlash {
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'The function only modifies internal object state, not the system.')]
  # Ensures that directory paths have a trailing backslash.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    $Object,
    [Parameter(Mandatory = $true)]
    [string[]]$PropertyNames
  )

  foreach ($PropName in $PropertyNames) {
    # Use .NET Reflection to find the property (more reliable than PSObject or Get-Member)
    $Prop = $Object.GetType().GetProperty($PropName)
    if ($Prop -and $Prop.PropertyType.FullName -eq 'System.String' -and $Prop.CanWrite) {
      $Value = $Prop.GetValue($Object)
      if (-not [string]::IsNullOrWhiteSpace($Value)) {
        # Join-Path with an empty child ensures a proper trailing separator
        # and fixes double-slashes or missing slashes.
        $Normalized = (Join-Path $Value "").TrimEnd('\') + '\'
        # Only update if changed
        if ($Normalized -ne $Value) {
          $Prop.SetValue($Object, $Normalized)
        }
      }
    }
  }
}

#endregion Helper functions ####################################################



#region Configuration Object

# Container for general settings
class GeneralSettings {
  [int]$__VERBOSE = 6 # Info

  [void] Normalize() {
    # No strings to expand or paths to normalize currently.
  }
}

# Container for directory-related settings
class DirectorySettings {
  <# Directories for the backup itself
    - $ProjectRoot is always the script dir.
    - . is any current directory from where the user calls the script.
  #>
  [string]$BACKUP_BASE_DIR      = ".\Backup\"
  [string]$BACKUP_USER_BASE_DIR = ".\Backup\%USERNAME%\"
  [string]$BACKUP_DIR           = ".\Backup\%USERNAME%\%COMPUTERNAME%\"

  # Other mandatory directories
  [string]$BACKUP_TEMPLATES_DIR = "${ProjectRoot}templates\"            # Note: Must be an absolute path!
  [string]$BACKUP_JOB_DIR       = ".\Backup\%USERNAME%\robocopy-jobs\"

  # Method to ensure all paths are formatted correctly.
  [void] Normalize() {
    # 1. Expand environment variables
    Expand-EnvVar $this

    # 2. Fix trailing slashes for directories
    Set-TrailingSlash $this @('BACKUP_BASE_DIR', 'BACKUP_USER_BASE_DIR', 'BACKUP_DIR', 'BACKUP_TEMPLATES_DIR', 'BACKUP_JOB_DIR')
  }
}

# Container for file-related settings
class FileSettings {
  # Files for the backup itself
  [string]$DIRLIST_TEMPLATE     = "${ProjectRoot}templates\dir-list-template.conf"
  [string]$BACKUP_DIRLIST       = "dir-list.conf" # Will be prefixed with BACKUP_DIR in ScriptConfig constructor

  # Templates for jobtype
  [string]$JOB_TEMPLATE_INCR    = "${ProjectRoot}templates\incr_backup.RCJ"
  [string]$JOB_TEMPLATE_FULL    = "${ProjectRoot}templates\full_backup.RCJ"
  [string]$JOB_TEMPLATE_PURGE   = "${ProjectRoot}templates\purge.RCJ"
  [string]$JOB_TEMPLATE_ARCHIVE = "${ProjectRoot}templates\only_archive_attr.RCJ"

  # Template for job settings
  [string]$JOB_TEMPLATE_GLOBAL_EXCLUSIONS = "${ProjectRoot}templates\global_exclusions.RCJ"
  [string]$JOB_TEMPLATE_LOGGING           = "${ProjectRoot}templates\logging.RCJ"

  # Optional files
  [string]$ROBOCOPY = "robocopy"  # Fallback: Windows' own robocopy

  [void] Normalize() {
    # Expand environment variables
    Expand-EnvVar $this
  }
}

# Container for logging-related settings
class LoggingSettings {
  # Standard logfile
  [string]$BACKUP_LOGFILE = "Backup.log"          # Will be prefixed with BACKUP_DIR in ScriptConfig constructor

  # Error log
  [string]$ERROR_LOGFILE = "Error.log"            # Will be prefixed with BACKUP_DIR in ScriptConfig constructor

  # Trace log
  [bool]$ENABLE_TRACE_LOG           = $true
  [string]$TRACE_LOG_LOCAL_DIR      = "%Temp%\"
  [string]$TRACE_LOGFILE_NAME       = "Trace.log"
  [bool]$UPLOAD_TRACE_TO_BACKUP_DIR = $true

  # Method to ensure all paths are formatted correctly.
  [void] Normalize() {
    # 1. Expand environment variables
    Expand-EnvVar $this

    # 2. Fix trailing slashes for directories
    Set-TrailingSlash $this @('TRACE_LOG_LOCAL_DIR')
  }
}

# Container for job-related settings
class JobSettings {
  # Jobtype selection by the user
  [int]$JOB_TYPE_SELECTION_MAX_WAITING_TIME_S = 30
  [string]$DEFAULT_JOB_TYPE                   = "Incremental"

  # Filename schemes
  [string]$JOB_FILE_NAME_SCHEME     = "%COMPUTERNAME%-Job*.RCJ"
  [string]$JOB_LOGFILE_NAME_SCHEME  = "%COMPUTERNAME%-Job*.log"

  [void] Normalize() {
    # Expand environment variables
    Expand-EnvVar $this
  }
}

# Container for archiving-related settings
class ArchivingSettings {
  [string]$ARCHIVE_NAME_SCHEME      = "%COMPUTERNAME%-Jobs-*.zip"
  [int]$MAX_ARCHIVES_COUNT          = 10

  [void] Normalize() {
    # Expand environment variables
    Expand-EnvVar $this
  }
}

# Main container for all settings
class ScriptConfig {
  [GeneralSettings]$General       = [GeneralSettings]::new()
  [DirectorySettings]$Directories = [DirectorySettings]::new()
  [FileSettings]$Files            = [FileSettings]::new()
  [LoggingSettings]$Logging       = [LoggingSettings]::new()
  [JobSettings]$Jobs              = [JobSettings]::new()
  [ArchivingSettings]$Archiving   = [ArchivingSettings]::new()

  # Constructor to link dependent defaults
  ScriptConfig() {
    # Prefix relative file paths with the backup directory
    $this.Files.BACKUP_DIRLIST = Join-Path $this.Directories.BACKUP_DIR $this.Files.BACKUP_DIRLIST
    $this.Logging.BACKUP_LOGFILE = Join-Path $this.Directories.BACKUP_DIR $this.Logging.BACKUP_LOGFILE
    $this.Logging.ERROR_LOGFILE = Join-Path $this.Directories.BACKUP_DIR $this.Logging.ERROR_LOGFILE
  }

  # Method to ensure all paths in all sub-containers are formatted correctly.
  [void] Normalize() {
    $this.General.Normalize()
    $this.Directories.Normalize()
    $this.Files.Normalize()
    $this.Logging.Normalize()
    $this.Jobs.Normalize()
    $this.Archiving.Normalize()
  }
}

#endregion Configuration Object ################################################



#region Object types

class FsObjectResult {
  [bool]$Exists   # $true or $false
  [string]$Type   # "directory", "file", ..., or $null if unknown
  [string]$Path   # The actual path of the found filesystem object
}

#endregion Object types ########################################################
