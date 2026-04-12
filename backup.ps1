# 2023, Thomas Lambeck
#
# Backup with PowerShell and robocopy using a list of directories/files to backup.
#
################################################################################



#region ChangeLog

<#
  - 2023-03-02, Version 0.0.01, Thomas Lambeck
    - File created
  - 2023-05-08, Version 0.0.02, Thomas Lambeck
    - Better check for $ROBOCOPY (search in Windows PATH environment variable if no path is provided).
  - 2023-06-18, Version 0.1.00, Thomas Lambeck
    - Checks for necessary directories and files, including creation where possible.
#>

#endregion ChangeLog ###########################################################



#region TODO

<# TODO: Sections?
  - ...
  - Get options and option arguments.
  - Check the plausibility of the provided option arguments.
  - ...
  - ??? more?
  - Is it possible to log errors directly?
#>

#TODO: Use more Write-NormalMessage() and Write-VerboseMessage() instead of Write-DebugMsg() or Write-InfoMsg()?

<# TODO: Check for Constrained Language Mode!
  - Disables access to Environment Variables.
  - more?

  Info:
  - https://www.youtube.com/watch?v=zW69MisrsWk
  - https://devblogs.microsoft.com/powershell/powershell-constrained-language-mode/
#>

#endregion TODO ################################################################



[CmdletBinding(SupportsShouldProcess = $true)]
param(
  # Skip all interactive prompts and pauses (useful for automation/CI).
  [Parameter(Mandatory = $false)]
  [switch]$NonInteractive,
  # Create job files but do not actually run Robocopy (useful for testing/validation).
  [Parameter(Mandatory = $false)]
  [switch]$SkipExecution
)

# Set-StrictMode -Version Latest ensures that common coding errors like typos in property names
# (e.g., $Config.Loging instead of $Config.Logging) are caught immediately.
Set-StrictMode -Version Latest



#region Bootstrap Logging

# Message buffer for early events occurring before the logging library is loaded.
$script:earlyMsgBuffer = [System.Collections.Generic.List[PSObject]]::new()

function Write-EarlyMsg {
  <# Local helper for logging before libraries are sourced.
    Writes to console immediately and saves to buffer for later log file flushing.
  #>
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('EMERG', 'ALERT', 'CRIT', 'ERR', 'WARNING', 'NOTICE', 'INFO', 'DEBUG')]
    [string]$severity,
    [Parameter(Mandatory = $true)]
    [string]$message
  )

  # Store the message for later.
  $timestamp = Get-Date -Format s
  $script:earlyMsgBuffer.Add([PSCustomObject]@{
      Timestamp = $timestamp
      Severity  = $severity
      Message   = $message
    })

  # Format the severity label similar to Format-SeverityLabel. Example: INFO = [INFO   ]
  $sb = [System.Text.StringBuilder]::new("$severity")
  while ($sb.Length -lt 7) {
    [void]$sb.Append(" ")
  }
  $severityLabel = "[$sb]"

  # Write the message to the console.
  $color = switch ($severity) {
    { $_ -in "EMERG", "ALERT", "CRIT", "ERR" } { "Red" }
    "WARNING" { "Yellow" }
    "DEBUG" { "DarkGray" }
    Default { "White" }
  }

  Write-Host "${severityLabel} ${message}" -ForegroundColor $color

}

#endregion Bootstrap Logging ###################################################



#region Constant values

# Temporarily disable -WhatIf for internal setup (PowerShell 5.1 workaround).
$oldWhatIfPreference = $WhatIfPreference
$WhatIfPreference = $false

#TODO: Make versioning "generic" - using commands like "git tag v0.1.00" and %%SCRIPT_VERSION%% here?
Set-Variable -Name "SCRIPT_VERSION" -Option ReadOnly -Value "0.3.03"
Set-Variable -Name "SCRIPT_DIR" -Option ReadOnly -Value ((Split-Path -parent "${PSCommandPath}") + "\")
Set-Variable -Name "COMPUTERNAME" -Option ReadOnly -Value ([System.Environment]::ExpandEnvironmentVariables("%COMPUTERNAME%"))

# Restore the original -WhatIf preference.
$WhatIfPreference = $oldWhatIfPreference

#endregion Constant values #####################################################



#region Helpers

[bool]$CalledViaRightclick = $false

if ($MyInvocation.InvocationName.Equals("&")) {
  # Windows PowerShell
  if ( (Get-ExecutionPolicy -Scope Process) -eq 'Bypass') { $CalledViaRightclick = $true }
}
else {
  # PowerShell 7
  if ($MyInvocation.Line -eq "") { $CalledViaRightclick = $true }
}

#endregion Helpers



Write-EarlyMsg INFO "Backup Script version ${SCRIPT_VERSION} started."
$startTime = (Get-Date)



#region Change working dir to script location

try {
  # We use the .NET method because it is immune to -WhatIf interception in PS 5.1.
  [System.IO.Directory]::SetCurrentDirectory("${SCRIPT_DIR}")
}
catch {
  # Log to native stderr (often captured by logs).
  [Console]::ForegroundColor = 'red'
  [Console]::Error.WriteLine("Failed to change working directory to [${SCRIPT_DIR}]! Error: $_")
  [Console]::ResetColor()
  exit 2
}

#endregion Change working dir to script location ###############################



#region Import function libraries

#TODO: Hard-coded for now, later an import function for different library folders might be better.
#TODO: Search order: current directory, parallel folder "lib" or standard directory

try {
  . lib\message-functions.ps1       # No dependencies
  . lib\network-functions.ps1       # No dependencies
  . lib\logging-functions.ps1       # Depends on message-functions.
  . lib\filesystem-functions.ps1    # Depends on logging-functions, message-functions.
  . lib\job-functions.ps1           # Depends on message-functions.
  . lib\job-archive-functions.ps1   # Depends on logging-functions, message-functions.
  . lib\inifile-functions.ps1       # Depends on message-functions.
  . lib\robocopy-functions.ps1      # Depends on logging-functions.
  . lib\job-type-functions.ps1      # Depends on logging-functions, message-functions.
}
catch {
  Write-EarlyMsg ERR ("Failed to import function libraries from lib\ subfolder! " + `
      "Ensure the folder exists in the script directory. Error: $_")
  exit 2
}

#endregion Import function libraries ###########################################



#region Read settings file

Write-EarlyMsg INFO "Reading the settings file..."

# Configuration object with default values
$Config = [ScriptConfig]::new()

# Populate with values from the ini file.
$iniFile = $PSCommandPath -replace "\.ps1$", ".ini"
$Config = Read-Config -IniFile "${iniFile}"

Write-EarlyMsg INFO "Settings file read."

#endregion Read settings file ##################################################



#region Check necessary directories and files

Write-EarlyMsg INFO "Checking necessary directories and files..."

# Create logfile folder if necessary. (May be different from $BACKUP_DIR.)
$FSobject = Get-ParentDir $Config.Logging.BACKUP_LOGFILE
if (! ${FSobject}.Exists) {
  Write-EarlyMsg INFO "Creating logfile directory..."
  [void](New-Directory 'LOGFILE_DIR' "$($FSobject.Path)" $Config.Logging.BACKUP_LOGFILE)
  Write-EarlyMsg INFO "Logfile directory created."
}

<# Some folders/files are mandatory. The rest can be created automatically.
  - Mandatory:
    - BACKUP_TEMPLATES_DIR
    - DIRLIST_TEMPLATE
    - JOB_TEMPLATE_INCR, ...
  - Created automatically:
    - BACKUP_BASE_DIR
    - BACKUP_USER_BASE_DIR
    - BACKUP_DIR
    - BACKUP_JOB_DIR
    - BACKUP_DIRLIST (copy of the template)
    - BACKUP_LOGFILE
    #TODO: Check if we use $ERROR_LOGFILE anywhere, we might not need it at all.
    - ERROR_LOGFILE
#>

Test-NecessaryDirectory 'BACKUP_TEMPLATES_DIR' $Config.Directories.BACKUP_TEMPLATES_DIR $Config.Logging.BACKUP_LOGFILE
Test-NecessaryFile 'DIRLIST_TEMPLATE' $Config.Files.DIRLIST_TEMPLATE $Config.Logging.BACKUP_LOGFILE
Test-NecessaryFile 'JOB_TEMPLATE_INCR' $Config.Files.JOB_TEMPLATE_INCR $Config.Logging.BACKUP_LOGFILE
Test-NecessaryFile 'JOB_TEMPLATE_FULL' $Config.Files.JOB_TEMPLATE_FULL $Config.Logging.BACKUP_LOGFILE
Test-NecessaryFile 'JOB_TEMPLATE_PURGE' $Config.Files.JOB_TEMPLATE_PURGE $Config.Logging.BACKUP_LOGFILE
Test-NecessaryFile 'JOB_TEMPLATE_ARCHIVE' $Config.Files.JOB_TEMPLATE_ARCHIVE $Config.Logging.BACKUP_LOGFILE
Test-NecessaryFile 'JOB_TEMPLATE_GLOBAL_EXCLUSIONS' $Config.Files.JOB_TEMPLATE_GLOBAL_EXCLUSIONS $Config.Logging.BACKUP_LOGFILE
Test-NecessaryFile 'JOB_TEMPLATE_LOGGING' $Config.Files.JOB_TEMPLATE_LOGGING $Config.Logging.BACKUP_LOGFILE

# Note: Different cases for $BACKUP_BASE_DIR (some cannot be created)!
$DirType = Get-SpecifiedBackupBaseDirType $Config.Directories.BACKUP_BASE_DIR
Write-DebugMsg "BackupBaseDir type: ${DirType}"

switch ("${DirType}") {
  "directory" {
    [void](New-Directory 'BACKUP_BASE_DIR' $Config.Directories.BACKUP_BASE_DIR $Config.Logging.BACKUP_LOGFILE)
  }
  { $_ -in "drive letter", "network share" } {
    Test-NecessaryDirectory 'BACKUP_BASE_DIR' $Config.Directories.BACKUP_BASE_DIR $Config.Logging.BACKUP_LOGFILE
  }
  "relative path" {
    # Interpret as path below script dir, current drive or ...?
    #TODO: This may not yet have a test case!
    #TODO: Check if the following change to $Config.Directories.BACKUP_BASE_DIR has correct syntax!
    # $AbsoluteBaseDir = "${SCRIPT_DIR}\${BACKUP_BASE_DIR}"
    $AbsoluteBaseDir = "${SCRIPT_DIR}\$($Config.Directories.BACKUP_BASE_DIR)"
    [void](New-Directory 'BACKUP_BASE_DIR (absolute path)' "${AbsoluteBaseDir}" $Config.Logging.BACKUP_LOGFILE)
  }
  "network computer" {
    Write-CritMsg "Cannot use a server as BACKUP_BASE_DIR, specify a share!"
    exit 1
  }
  Default {
    Write-CritMsg "Unexpected BackupBaseDir type: ${DirType}"
    exit 1
  }
}

#TODO: Report creation of these dirs (as INFO).
[void](New-Directory 'BACKUP_USER_BASE_DIR' $Config.Directories.BACKUP_USER_BASE_DIR $Config.Logging.BACKUP_LOGFILE)
[void](New-Directory 'BACKUP_DIR' $Config.Directories.BACKUP_DIR $Config.Logging.BACKUP_LOGFILE)
[void](New-Directory 'BACKUP_JOB_DIR' $Config.Directories.BACKUP_JOB_DIR $Config.Logging.BACKUP_LOGFILE)

# Make sure that robocopy has been found if only "robocopy" is defined in the ini file!
$RobocopyExecutable = Get-ExecutablePath 'ROBOCOPY' $Config.Files.ROBOCOPY $Config.Logging.BACKUP_LOGFILE

# Create the dir-list from the template if necessary.
$IsDirlistCreated = New-FileFromTemplate 'BACKUP_DIRLIST' $Config.Files.BACKUP_DIRLIST $Config.Files.DIRLIST_TEMPLATE $Config.Logging.BACKUP_LOGFILE

if ($IsDirlistCreated -and -not $NonInteractive) {
  Write-InfoMsg "Opening the dir-list in Editor and wait..."
  Notepad.exe $Config.Files.BACKUP_DIRLIST | Out-Null
}

Write-EarlyMsg INFO "Necessary directories and files checked."

#endregion Check necessary directories and files ###############################



#region Start logging to actual logfile

Add-EmptyLineToLogfile $Config.Logging.BACKUP_LOGFILE # One empty line between the previous and this backup.

# Flushes early bootstrap messages to the real log file now that BACKUP_LOGFILE is available.
if (![string]::IsNullOrWhiteSpace($Config.Logging.BACKUP_LOGFILE)) {
  foreach ($msg in $script:earlyMsgBuffer) {
    # Using direct Add-LogMessage (ignoring __VERBOSE for early info).
    Add-LogMessage -logfile $Config.Logging.BACKUP_LOGFILE -severity $msg.Severity -message $msg.Message
  }
  $script:earlyMsgBuffer.Clear()
}

#endregion Start logging to actual logfile #####################################



#region Ask for job type

$SelectedJobType = Get-UserSelectedJobType -DefaultJobType $Config.Jobs.DEFAULT_JOB_TYPE -logfile $Config.Logging.BACKUP_LOGFILE -MaxWaitingTimeS $Config.Jobs.JOB_TYPE_SELECTION_MAX_WAITING_TIME_S -NonInteractive:$NonInteractive

switch ($SelectedJobType) {
  "Incremental" { $RobocopyJobTypeTemplate = $Config.Files.JOB_TEMPLATE_INCR }
  "Full" { $RobocopyJobTypeTemplate = $Config.Files.JOB_TEMPLATE_FULL }
  "Purge" { $RobocopyJobTypeTemplate = $Config.Files.JOB_TEMPLATE_PURGE }
  "Archive" { $RobocopyJobTypeTemplate = $Config.Files.JOB_TEMPLATE_ARCHIVE }
  "Cancel" { exit 0 }
  Default {
    # Illegal choice
    #TODO: Maybe a different exit code? (1 was for syntax errors, 2 for missing files, more?)
    exit 2
  }
}

#endregion Ask for job type ####################################################



#region Archive previous jobs

LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "Archiving previous jobs..."

Export-PreviousJobsArchive $Config.Directories.BACKUP_JOB_DIR $Config.Jobs.JOB_FILE_NAME_SCHEME $Config.jobs.JOB_LOGFILE_NAME_SCHEME $Config.Archiving.ARCHIVE_NAME_SCHEME $Config.Archiving.MAX_ARCHIVES_COUNT

LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "Previous jobs archived."

#endregion Archive previous job files ##########################################



#region Create job files

LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "----- Creating job files -----".PadRight(70, "-")

<# Create a job file for each directory in the dir-list.
  - Loop over all lines.
  - Start new job for every directory (lines without leading spaces).
  - Add included/excluded files/directories (lines with leading "  + " or "  - ") to
    the job file (robocopy options /IF, /XF, /XD).
#>

# Local variables
[int32]$SourceDefinitionsCount = 0

[bool]$StartNewJob = $false
[int32]$CurrentJobNum = 0
[string]$CurrentSourceDefinition = ""  # Last source definition, in case entries consist of more than one line.
[string]$CurrentSourceType = ""

[bool]$FinishPreviousJob = $false
[bool]$ContinueCurrentJob = $false
[bool]$SingleFileDefinition = $false
[bool]$SingleFileJob = $false

[string]$SourceDir = ""
[string]$TargetDir = ""
$IncludedFiles = [System.Collections.Generic.List[string]]::new()
$ExcludedDirs = [System.Collections.Generic.List[string]]::new()
$ExcludedFiles = [System.Collections.Generic.List[string]]::new()

[int32]$JobsCreatedCount = 0

function Invoke-AddJobFile {
  # Creates the current job using all values collected from the dir-list.
  Write-DebugMsg "Invoke-AddJobFile()"

  Add-JobFile `
    $Config.Directories.BACKUP_JOB_DIR `
    "${COMPUTERNAME}" `
    $script:CurrentJobNum `
    "${Script:CurrentSourceDefinition}" `
    "${Script:SourceDir}" `
    "${Script:TargetDir}" `
    $script:IncludedFiles `
    $script:ExcludedDirs `
    $script:ExcludedFiles `
    $script:SingleFileJob

  $script:JobsCreatedCount = ($script:JobsCreatedCount + 1)
  Write-DebugMsg "JobsCreatedCount  : $script:JobsCreatedCount"

  Initialize-JobRelatedInfo

  Write-DebugMsg "-----".PadRight(70, "-")
}

function Initialize-JobRelatedInfo {
  # Resets all values that apply for a whole job definition, possibly
  # consisting of multiple lines in the dir-list.
  Write-DebugMsg "Initialize-JobRelatedInfo()"
  $script:CurrentJobNum = 0
  $script:CurrentSourceDefinition = ""
  $script:CurrentSourceType = ""
  $script:SourceDir = ""
  $script:TargetDir = ""
  $script:IncludedFiles.Clear()
  $script:ExcludedDirs.Clear()
  $script:ExcludedFiles.Clear()
  $script:SingleFileJob = $false
}

function Initialize-LineRelatedInfo {
  # Resets all values that apply only for the current line in the dir-list.
  Write-DebugMsg "Initialize-LineRelatedInfo()"
  $script:StartNewJob = $false
  $script:FinishPreviousJob = $false
  $script:ContinueCurrentJob = $false
  $script:SingleFileDefinition = $false
  $script:LineType = ""
}

# Process the dir-list.

#TODO: Remove the function _processDirectoryList and make the code top-level?
function _processDirectoryList {
  $DirListContent = Get-Content $Config.Files.BACKUP_DIRLIST

  ForEach ($line in $DirListContent) {
    Write-DebugMsg "Next line               : ${line}"

    # Expand all entries first to avoid interpreting environment variables etc. as filenames.
    $expanded = Get-ExpandedPath "${line}"

    #region Determine what to do depending on the type of the current line. ----

    <# A job definition ends with:
      - an empty line or comment;
      - the next source-dir, source-file or source-file-pattern;
      - on errors; or
      - EOF
    #>
    $LineType = Get-DirlistLineType "${expanded}" $Config.Logging.BACKUP_LOGFILE
    $LineTypeLabel = "${LineType}".PadRight(24)
    Write-DebugMsg "${LineTypeLabel}: ${expanded}"

    switch -Wildcard ("${LineType}") {
      "error: *" {
        # The fallback value of function Get-DirlistLineType
        # No message: function Get-DirlistLineType reports the error/warning.
        #LogAndShowMessage $Config.Logging.BACKUP_LOGFILE ERR "Error in dir-list: ${line}"
        $script:FinishPreviousJob = $true
      }
      "invalid: *" {
        LogAndShowMessage $Config.Logging.BACKUP_LOGFILE WARNING "Invalid entry in dir-list: ${line}"
        $script:FinishPreviousJob = $true
      }
      "ignore" {
        $script:FinishPreviousJob = $true
      }
      "source-file" {
        $script:StartNewJob = $true
        $script:FinishPreviousJob = $true
        $script:SingleFileDefinition = $true  # Current line is a single-file definition - the job for it will be a single-file job.

        # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-switch?view=powershell-7.3#multiple-matches
        continue
      }
      "source-*" {
        # Only source-dir or source-file-pattern
        $script:StartNewJob = $true
        $script:FinishPreviousJob = $true
      }
      "incl-files-pattern" {
        $script:ContinueCurrentJob = $true
      }
      "excl-files-pattern" {
        $script:ContinueCurrentJob = $true
      }
      "excl-dirs-pattern" {
        $script:ContinueCurrentJob = $true
      }
    }

    #endregion Determine what to do depending on the type of the current line.

    #region Plausibility checks ------------------------------------------------

    if ($script:FinishPreviousJob) {
      if ($script:CurrentJobNum -eq 0) {
        $script:FinishPreviousJob = $false
      }
    }

    if ($script:ContinueCurrentJob) {
      if ($script:CurrentJobNum -eq 0) {
        $script:ContinueCurrentJob = $false
        LogAndShowMessage $Config.Logging.BACKUP_LOGFILE ERR "No folder/job defined for: ${line}"
      }
    }

    #endregion Plausibility checks ---------------------------------------------

    # Show what we are going to do.
    if ($script:FinishPreviousJob -or $script:StartNewJob -or $script:ContinueCurrentJob -or $script:SingleFileJob) {
      $TaskList = [System.Collections.Generic.List[string]]::new()
      if ($script:FinishPreviousJob) { $TaskList.Add("Finish previous job") }
      if ($script:StartNewJob) { $TaskList.Add("Start new job") }
      if ($script:ContinueCurrentJob) { $TaskList.Add("Continue current job") }
      if ($script:SingleFileJob) { $TaskList.Add("Copy single file") }

      $tasks = ($TaskList -join ", ")
      Write-DebugMsg "Task(s)                 : ${tasks}"

      $TaskList.Clear()
      $tasks = ""
    }

    #region Actual job creation ------------------------------------------------

    if ($script:FinishPreviousJob) {
      Write-DebugMsg "----- Finishing the previous job -----".PadRight(70, "-")
      Invoke-AddJobFile
    }

    if ($script:StartNewJob) {
      Write-DebugMsg "----- Starting a new job -----".PadRight(70, "-")
      $script:SourceDefinitionsCount = ($script:SourceDefinitionsCount + 1)
      $script:CurrentJobNum = $script:SourceDefinitionsCount
      $script:CurrentSourceDefinition = "${line}"
      $script:CurrentSourceType = "${LineType}"
      $script:SingleFileJob = $script:SingleFileDefinition

      Write-DebugMsg "SourceDefinitionsCount  : $script:SourceDefinitionsCount"
      Write-DebugMsg "CurrentJobNum           : $script:CurrentJobNum"
      Write-DebugMsg "CurrentSourceDefinition : ${Script:CurrentSourceDefinition}"
      Write-DebugMsg "CurrentSourceType       : ${Script:CurrentSourceType}"

      # Determine basic information for the job.
      switch -Wildcard ("${Script:CurrentSourceType}") {
        "source-dir" { $script:SourceDir = "${expanded}" }
        "source-file*" {
          # <--- pattern!
          $FSobject = Get-ParentDir "${expanded}"
          $script:SourceDir = $FSobject.Path

          # Add the filename (pattern) to $IncludedFiles because we must NOT use *.* later!
          $SourceFilename = Split-Path -Leaf "${expanded}"
          Write-DebugMsg "SourceFilename          : ${SourceFilename}"
          $script:IncludedFiles.Add("${SourceFilename}")
          $SourceFilename = ""
        }
      }
      Write-DebugMsg "SourceDir               : ${Script:SourceDir}"

      if ("${Script:SourceDir}" -eq "") {
        LogAndShowMessage $Config.Logging.BACKUP_LOGFILE ERR "Parent directory not specified for: ${line}"
        Initialize-JobRelatedInfo
      }
      else {
        $script:TargetDir = Get-TargetDir $Config.Directories.BACKUP_DIR "${Script:SourceDir}"
        Write-DebugMsg "TargetDir               : ${Script:TargetDir}"
      }

      Write-DebugMsg "-----".PadRight(70, "-")
    }

    if ($script:SingleFileJob) {
      Write-DebugMsg "----- Copying a single file -----".PadRight(70, "-")
      Invoke-AddJobFile
    }

    # Add included/excluded files/directories to the job file (robocopy options /IF, /XF, /XD).
    if ($script:ContinueCurrentJob) {
      Write-DebugMsg "----- Continuing the job -----".PadRight(70, "-")
      # Determine additional information for the job.
      $entry = "${expanded}".Substring(4)   # Remove the leading "  + " or "  - "
      Write-DebugMsg "entry                   : ${entry}"

      switch ("${LineType}") {
        "incl-files-pattern" { $script:IncludedFiles.Add("${entry}") }
        "excl-files-pattern" { $script:ExcludedFiles.Add("${entry}") }
        "excl-dirs-pattern" { $script:ExcludedDirs.Add("${entry}") }
      }

      Write-DebugMsg "IncludedFiles.Count     : $($script:IncludedFiles.Count)"
      Write-DebugMsg "ExcludedFiles.Count     : $($script:ExcludedFiles.Count)"
      Write-DebugMsg "ExcludedDirs.Count      : $($script:ExcludedDirs.Count)"

      Write-DebugMsg "-----".PadRight(70, "-")
    }

    #endregion Actual job creation ---------------------------------------------

    # Reset values that can only apply for 1 line.
    Initialize-LineRelatedInfo

  }

}

_processDirectoryList

Write-DebugMsg "----- End of the dir-list -----".PadRight(70, "-")

# Finish the last job?
$FinishLastJob = ($script:CurrentJobNum -ne 0)

if ($FinishLastJob) {
  Write-DebugMsg "----- Finishing the last job -----".PadRight(70, "-")
  Invoke-AddJobFile
}

LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "$script:JobsCreatedCount job file(s) created."

Write-DebugMsg "----- Results -----".PadRight(70, "-")
Write-DebugMsg "SourceDefinitionsCount: $script:SourceDefinitionsCount"
Write-DebugMsg "StartNewJob           : $script:StartNewJob"
Write-DebugMsg "ContinueCurrentJob    : $script:ContinueCurrentJob"
Write-DebugMsg "FinishPreviousJob     : $script:FinishPreviousJob"
Write-DebugMsg "IncludedFiles.Count   : $($script:IncludedFiles.Count)"
Write-DebugMsg "ExcludedFiles.Count   : $($script:ExcludedFiles.Count)"
Write-DebugMsg "ExcludedDirs.Count    : $($script:ExcludedDirs.Count)"
Write-DebugMsg "JobsCreatedCount      : $script:JobsCreatedCount"
Write-DebugMsg "-----".PadRight(70, "-")

#endregion Create job files ####################################################



#region Run jobs

[int32]$JobResultOkCount = 0
[int32]$JobResultWarningCount = 0
[int32]$JobResultErrorCount = 0

$JobFiles = @(Get-ChildItem -Path (Join-Path $Config.Directories.BACKUP_JOB_DIR "*") -Include $Config.Jobs.JOB_FILE_NAME_SCHEME -File |
Sort-Object { [int]([regex]::Match($_.Name, 'Job(\d+)\.RCJ').Groups[1].Value) })
$JobfilesCount = $JobFiles.Count

if ($JobfilesCount -eq 0) {
  LogAndShowMessage $Config.Logging.BACKUP_LOGFILE WARNING "No jobfiles created!"
}
else {
  LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "Running $JobfilesCount job(s)..."

  if ($SkipExecution) {
    LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "Skipping execution as requested (-SkipExecution)."
  }
  else {
    for ($i = 0; $i -lt $JobfilesCount; $i++) {
      $UserDefinedJob = $JobFiles[$i]
      Write-InfoMsg "Job: ${UserDefinedJob}..."

      #TODO: Make sure we don't add an "empty" /job: statement for JOB_LOGFILE_VERBOSITY=none!
      [int32]$RobocopyExitCode = 0
      if ($PSCmdlet.ShouldProcess("${UserDefinedJob}", "Run Robocopy job")) {
        & "${RobocopyExecutable}" `
          "/job:${RobocopyJobTypeTemplate}" `
          "/job:$($Config.Files.JOB_TEMPLATE_GLOBAL_EXCLUSIONS)" `
          "/job:$($Config.Files.JOB_TEMPLATE_LOGGING)" `
          "/job:${UserDefinedJob}" | Out-Host

        $RobocopyExitCode = $LASTEXITCODE
      }
      else {
        # In -WhatIf mode, we simulate a successful (no changes) exit code.
        $RobocopyExitCode = 0
      }

      Write-DebugMsg "Robocopy exit code: $RobocopyExitCode"

      # Log errors. Use the jobname (Job1..n) from the filename.
      [string]$JobName = [regex]::Match($UserDefinedJob.Name, 'Job\d+').Value

      LogAndShowRobocopyError $Config.Logging.BACKUP_LOGFILE "${JobName}" $RobocopyExitCode

      # Update counters.
      switch ($RobocopyExitCode) {
        { $_ -in 0..7 } {
          $JobResultOkCount = ($JobResultOkCount + 1)
        }
        { $_ -in 8..15 } {
          $JobResultWarningCount = ($JobResultWarningCount + 1)
        }
        16 {
          $JobResultErrorCount = ($JobResultErrorCount + 1)
        }
      }

    }

    LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "$JobResultOkCount jobs finished successfully, $JobResultWarningCount with warnings, $JobResultErrorCount with errors."

  }

}

#endregion Run jobs ############################################################



# Finished
$endTime = (Get-Date)
$elapsedTime = $endTime - $startTime
$message = "Script finished in {0:hh} h {0:mm} min {0:ss} sec." -f $elapsedTime
LogAndShowMessage $Config.Logging.BACKUP_LOGFILE INFO "${message}"



# Only pause for user input if the script was started via Windows Explorer (Right-click)
# and we are not in non-interactive mode.
if ($CalledViaRightclick -and -not $NonInteractive) {
  Write-Host -NoNewLine "Press any key to quit..."
  [void][System.Console]::ReadKey($true)
}
