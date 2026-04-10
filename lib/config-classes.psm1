#region Configuration Object

#TODO: Add Pester tests to test the default values?

# Container for general settings
class GeneralSettings {
  [int]$__VERBOSE = 6 # Info
}

# Container for directory-related settings
class DirectorySettings {
  # Directories for the backup itself
  <#TODO: Use . or ${SCRIPT_DIR}?
    - ${SCRIPT_DIR} should always be the script dir.
    - . could be any current directory from where the script is called?
  #>
  [string]$BACKUP_BASE_DIR      = ".\Backup\"                           # Or "${SCRIPT_DIR}Backup\"?
  [string]$BACKUP_USER_BASE_DIR = ".\Backup\%Username%\"                # Or "${SCRIPT_DIR}Backup\%Username%\"?"
  [string]$BACKUP_DIR           = ".\Backup\%Username%\%Computername%\" # Or "${SCRIPT_DIR}Backup\%Username%\%Computername%\"?

  # Other mandatory directories
  [string]$BACKUP_TEMPLATES_DIR = "${SCRIPT_DIR}templates\"             # Note: Must be ${SCRIPT_DIR} not "."!
  [string]$BACKUP_JOB_DIR       = ".\Backup\%Username%\robocopy-jobs\"  # Or "${SCRIPT_DIR}Backup\%Username%\robocopy-jobs\"?

  # Method to ensure all paths are formatted correctly.
  [void] Normalize() {
    # List of properties that are definitely directories
    #TODO: Make this automatic? Adding values manually is error-prone!
    $DirProperties = @('BACKUP_BASE_DIR', 'BACKUP_USER_BASE_DIR', 'BACKUP_DIR', 'BACKUP_TEMPLATES_DIR', 'BACKUP_JOB_DIR')

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
  [string]$DIRLIST_TEMPLATE     = "${SCRIPT_DIR}templates\dir-list-template.conf"
  #TODO: rename to "BACKUP_DIRLIST_NAME" to be more consistent?
  [string]$BACKUP_DIRLIST       = "dir-list.conf" # e.g. .\Backup\<username>\<Computername>\dir-list.conf

  # Templates for jobtype
  [string]$JOB_TEMPLATE_INCR    = "${SCRIPT_DIR}templates\incr_backup.RCJ"
  [string]$JOB_TEMPLATE_FULL    = "${SCRIPT_DIR}templates\full_backup.RCJ"
  [string]$JOB_TEMPLATE_PURGE   = "${SCRIPT_DIR}templates\purge.RCJ"
  [string]$JOB_TEMPLATE_ARCHIVE = "${SCRIPT_DIR}templates\only_archive_attr.RCJ"

  # Template for job settings
  [string]$JOB_TEMPLATE_GLOBAL_EXCLUSIONS = "${SCRIPT_DIR}templates\global_exclusions.RCJ"
  [string]$JOB_TEMPLATE_LOGGING = "${SCRIPT_DIR}templates\logging.RCJ"

  # Optional files
  [string]$ROBOCOPY = "robocopy"  # Fallback: Windows' own robocopy
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
  [string]$TRACE_LOG_LOCAL_DIR = "%Temp%\"        #TODO: Make sure %Temp% works as intended!
  [string]$TRACE_LOGFILE_NAME = "Trace.log"       # e.g. C:\Windows\Temp\Trace.log
  [bool]$UPLOAD_TRACE_TO_BACKUP_DIR = $true

  # Method to ensure all paths are formatted correctly.
  [void] Normalize() {
    # List of properties that are definitely directories
    $DirProperties = @('TRACE_LOG_LOCAL_DIR')

    foreach ($Prop in $DirProperties) {
      if (-not [string]::IsNullOrWhiteSpace($this.$Prop)) {
        $this.$Prop = (Join-Path $this.$Prop "").TrimEnd('\') + '\'
      }
    }
  }

  #TODO: Log rotation?
  # [int]$MaxAgeDays = 14
}

# Container for job-related settings
class JobSettings {
  # Jobtype selection by the user
  [int]$JOB_TYPE_SELECTION_MAX_WAITING_TIME_S = 30
  [string]$DEFAULT_JOB_TYPE                   = "Incremental"

  # Filename schemes
  [string]$JOB_FILE_NAME_SCHEME     = "${COMPUTERNAME}-Job*.RCJ"
  [string]$JOB_LOGFILE_NAME_SCHEME  = "${COMPUTERNAME}-Job*.log"
}

# Container for archiving-related settings
class ArchivingSettings {
  [string]$ARCHIVE_NAME_SCHEME      = "${COMPUTERNAME}-Jobs-*.zip"
  [int]$MAX_ARCHIVES_COUNT          = 10
}

# Main container for all settings
class ScriptConfig {
  [GeneralSettings]$General       = [GeneralSettings]::new()
  [DirectorySettings]$Directories = [DirectorySettings]::new()
  [FileSettings]$Files            = [FileSettings]::new()
  [LoggingSettings]$Logging       = [LoggingSettings]::new()
  [JobSettings]$Jobs              = [JobSettings]::new()
  [ArchivingSettings]$Archiving   = [ArchivingSettings]::new()

  # Method to ensure all paths in all sub-containers are formatted correctly.
  [void] Normalize() {
    $this.Directories.Normalize()
    $this.Logging.Normalize()
  }

  # "top-level" settings if needed
  # [string]$Version = "1.0.0"
}

#endregion Configuration Object ################################################



#region Object types

class FsObjectResult {
  [bool]$Exists   # $true or $false
  [string]$Type   # "directory", "file", ..., or $null if unknown
  [string]$Path   # The actual path of the found filesystem object
}

#endregion Object types ########################################################
