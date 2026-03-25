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



#region Bootstrap Logging

# Message buffer for early events occurring before the logging library is loaded.
$Script:earlyMsgBuffer = [System.Collections.Generic.List[PSObject]]::new()

function Write-EarlyMsg {
  <# Local helper for logging before libraries are sourced.
    Writes to console immediately and saves to buffer for later log file flushing.
  #>
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('EMERG', 'ALERT', 'CRIT', 'ERR', 'WARNING', 'NOTICE', 'INFO', 'DEBUG')]
    [String]$severity,
    [Parameter(Mandatory = $true)]
    [String]$message
  )

  # Store the message for later.
  $timestamp = Get-Date -Format s
  $Script:earlyMsgBuffer.Add([PSCustomObject]@{
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
Set-Variable -Name "SCRIPT_VERSION" -Option ReadOnly -Value "0.1.00"
Set-Variable -Name "SCRIPT_DIR" -Option ReadOnly -Value ((Split-Path -parent "${PSCommandPath}") + "\")
Set-Variable -Name "COMPUTERNAME" -Option ReadOnly -Value ([System.Environment]::ExpandEnvironmentVariables("%COMPUTERNAME%"))

# Restore the original -WhatIf preference.
$WhatIfPreference = $oldWhatIfPreference

#endregion Constant values #####################################################



#region Helpers

[Boolean]$CalledViaRightclick = $false

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

$iniFile = $PSCommandPath -replace "\.ps1$", ".ini"
try {
  Read-SettingsFile ("${iniFile}")
}
catch {
  Write-EarlyMsg ERR "Failed to read settings file [${iniFile}]! Error: $_"
  exit 1
}

Write-EarlyMsg INFO "Settings file read."

#endregion Read settings file ##################################################



#region Check necessary directories and files

Write-EarlyMsg INFO "Checking necessary directories and files..."

# Create logfile folder if necessary. (May be different from $BACKUP_DIR.)
$FSobject = Get-ParentDir "${BACKUP_LOGFILE}"
if (! ${FSobject}.Exists) {
  Write-EarlyMsg INFO "Creating logfile directory..."
  [void](New-Directory 'LOGFILE_DIR' $(${FSobject}.Path) "${BACKUP_LOGFILE}")
  Write-EarlyMsg INFO "Logfile directory created."
}

<# Some folders/files are mandatory. The rest can be created automatically.
  - Mandatory:
    - BACKUP_TEMPLATES_DIR
    - DIRLIST_TEMPLATE
    - ROBOCOPY_JOB_TYPE_TEMPLATE_INCR, ...
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

Test-NecessaryDirectory 'BACKUP_TEMPLATES_DIR' "${BACKUP_TEMPLATES_DIR}" "${BACKUP_LOGFILE}"
Test-NecessaryFile 'DIRLIST_TEMPLATE' "${DIRLIST_TEMPLATE}" "${BACKUP_LOGFILE}"
Test-NecessaryFile 'ROBOCOPY_JOB_TYPE_TEMPLATE_INCR' "${ROBOCOPY_JOB_TYPE_TEMPLATE_INCR}" "${BACKUP_LOGFILE}"
Test-NecessaryFile 'ROBOCOPY_JOB_TYPE_TEMPLATE_FULL' "${ROBOCOPY_JOB_TYPE_TEMPLATE_FULL}" "${BACKUP_LOGFILE}"
Test-NecessaryFile 'ROBOCOPY_JOB_TYPE_TEMPLATE_PURGE' "${ROBOCOPY_JOB_TYPE_TEMPLATE_PURGE}" "${BACKUP_LOGFILE}"
Test-NecessaryFile 'ROBOCOPY_JOB_TYPE_TEMPLATE_ARCHIVE' "${ROBOCOPY_JOB_TYPE_TEMPLATE_ARCHIVE}" "${BACKUP_LOGFILE}"
Test-NecessaryFile 'ROBOCOPY_JOB_TEMPLATE_GLOBAL_EXCLUSIONS' "${ROBOCOPY_JOB_TEMPLATE_GLOBAL_EXCLUSIONS}" "${BACKUP_LOGFILE}"
Test-NecessaryFile 'ROBOCOPY_JOB_TEMPLATE_LOGGING' "${ROBOCOPY_JOB_TEMPLATE_LOGGING}" "${BACKUP_LOGFILE}"

# Note: Different cases for $BACKUP_BASE_DIR (some cannot be created)!
$DirType = Get-SpecifiedBackupBaseDirType "${BACKUP_BASE_DIR}"
Write-DebugMsg "BackupBaseDir type: ${DirType}"

switch ("${DirType}") {
  "directory" {
    [void](New-Directory 'BACKUP_BASE_DIR' "${BACKUP_BASE_DIR}" "${BACKUP_LOGFILE}")
  }
  { $_ -in "drive letter", "network share" } {
    Test-NecessaryDirectory 'BACKUP_BASE_DIR' "${BACKUP_BASE_DIR}" "${BACKUP_LOGFILE}"
  }
  "relative path" {
    # Interpret as path below script dir, current drive or ...?
    $AbsoluteBaseDir = "${SCRIPT_DIR}\${BACKUP_BASE_DIR}"
    [void](New-Directory 'BACKUP_BASE_DIR (absolute path)' "${AbsoluteBaseDir}" "${BACKUP_LOGFILE}")
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
[void](New-Directory 'BACKUP_USER_BASE_DIR' "${BACKUP_USER_BASE_DIR}" "${BACKUP_LOGFILE}")
[void](New-Directory 'BACKUP_DIR' "${BACKUP_DIR}" "${BACKUP_LOGFILE}")
[void](New-Directory 'BACKUP_JOB_DIR' "${BACKUP_JOB_DIR}" "${BACKUP_LOGFILE}")

# Make sure that robocopy has been found if only "robocopy" is defined in the ini file!
$RobocopyExecutable = Get-ExecutablePath 'ROBOCOPY' "${ROBOCOPY}" "${BACKUP_LOGFILE}"

# Create the dir-list from the template if necessary.
$IsDirlistCreated = New-FileFromTemplate 'BACKUP_DIRLIST' "${BACKUP_DIRLIST}" "${DIRLIST_TEMPLATE}" "${BACKUP_LOGFILE}"

if ($IsDirlistCreated -and -not $NonInteractive) {
  Write-InfoMsg "Opening the dir-list in Editor and wait..."
  Notepad.exe "${BACKUP_DIRLIST}" | Out-Null
}

Write-EarlyMsg INFO "Necessary directories and files checked."

#endregion Check necessary directories and files ###############################



#region Start logging to actual logfile

Add-EmptyLineToLogfile "${BACKUP_LOGFILE}"  # One empty line between the previous and this backup.

# Flushes early bootstrap messages to the real log file now that $BACKUP_LOGFILE is available.
if ($null -ne $BACKUP_LOGFILE) {
  foreach ($msg in $Script:earlyMsgBuffer) {
    # Using direct Add-LogMessage (ignoring __VERBOSE for early mandatory info).
    Add-LogMessage -logfile $BACKUP_LOGFILE -severity $msg.Severity -message $msg.Message
  }
  $Script:earlyMsgBuffer.Clear()
}

#endregion Start logging to actual logfile #####################################



#region Ask for job type

$SelectedJobType = Get-UserSelectedJobType -default_job_type "${DEFAULT_JOB_TYPE}" -logfile "${BACKUP_LOGFILE}" -NonInteractive:$NonInteractive

switch ($SelectedJobType) {
  "Incremental" { $RobocopyJobTypeTemplate = $ROBOCOPY_JOB_TYPE_TEMPLATE_INCR }
  "Full" { $RobocopyJobTypeTemplate = $ROBOCOPY_JOB_TYPE_TEMPLATE_FULL }
  "Purge" { $RobocopyJobTypeTemplate = $ROBOCOPY_JOB_TYPE_TEMPLATE_PURGE }
  "Archive" { $RobocopyJobTypeTemplate = $ROBOCOPY_JOB_TYPE_TEMPLATE_ARCHIVE }
  "Cancel" { exit 0 }
  Default {
    # Illegal choice
    #TODO: Maybe a different exit code? (1 was for syntax errors, 2 for missing files, more?)
    exit 2
  }
}

#endregion Ask for job type ####################################################



#region Archive previous jobs

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Archiving previous jobs..."

Export-PreviousJob "${BACKUP_JOB_DIR}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Previous jobs archived."

#endregion Archive previous job files ##########################################



#region Create job files

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Creating job files..."

<# Create a job file for each directory in the dir-list.
  - Loop over all lines.
  - Start new job for every directory (lines without leading spaces).
  - Add included/excluded files/directories (lines with leading "  + " or "  - ") to
    the job file (robocopy options /IF, /XF, /XD).
#>

# Local variables
[Int32]$SourceDefinitionsCount = 0

[System.Boolean]$StartNewJob = $false
[Int32]$CurrentJobNum = 0
[String]$CurrentSourceDefinition = ""  # Last source definition, in case entries consist of more than one line.
[String]$CurrentSourceType = ""

[System.Boolean]$FinishPreviousJob = $false
[System.Boolean]$ContinueCurrentJob = $false
[System.Boolean]$SingleFileDefinition = $false
[System.Boolean]$SingleFileJob = $false

[String]$SourceDir = ""
[String]$TargetDir = ""
[System.Collections.ArrayList]$IncludedFiles = New-Object System.Collections.ArrayList
[System.Collections.ArrayList]$ExcludedDirs = New-Object System.Collections.ArrayList
[System.Collections.ArrayList]$ExcludedFiles = New-Object System.Collections.ArrayList

[Int32]$JobsCreatedCount = 0

function Invoke-AddJobFile {
  # Creates the current job using all values collected from the dir-list.
  Write-DebugMsg "Invoke-AddJobFile()"

  Add-JobFile `
    "${BACKUP_JOB_DIR}" `
    "${COMPUTERNAME}" `
    $Script:CurrentJobNum `
    "${Script:CurrentSourceDefinition}" `
    "${Script:SourceDir}" `
    "${Script:TargetDir}" `
    $Script:IncludedFiles `
    $Script:ExcludedDirs `
    $Script:ExcludedFiles `
    $Script:SingleFileJob

  $Script:JobsCreatedCount = ($Script:JobsCreatedCount + 1)
  Write-DebugMsg "JobsCreatedCount  : $Script:JobsCreatedCount"

  Initialize-JobRelatedInfo

  Write-DebugMsg "----------------------------------------------------------------------"
}

function Initialize-JobRelatedInfo {
  # Resets all values that apply for a whole job definition, possibly
  # consisting of multiple lines in the dir-list.
  Write-DebugMsg "Initialize-JobRelatedInfo()"
  $Script:CurrentJobNum = 0
  $Script:CurrentSourceDefinition = ""
  $Script:CurrentSourceType = ""
  $Script:SourceDir = ""
  $Script:TargetDir = ""
  $Script:IncludedFiles.Clear()
  $Script:ExcludedDirs.Clear()
  $Script:ExcludedFiles.Clear()
  $Script:SingleFileJob = $false
}

function Initialize-LineRelatedInfo {
  # Resets all values that apply only for the current line in the dir-list.
  Write-DebugMsg "Initialize-LineRelatedInfo()"
  $Script:StartNewJob = $false
  $Script:FinishPreviousJob = $false
  $Script:ContinueCurrentJob = $false
  $Script:SingleFileDefinition = $false
  $Script:line_type = ""
}

# Process the dir-list.

function _processDirectoryList {
  $DirListContent = Get-Content "${BACKUP_DIRLIST}"

  ForEach ($line in $DirListContent) {
    Write-DebugMsg "Next line: ${line}"

    # Expand all entries first to avoid interpreting environment variables etc. as filenames.
    $expanded = Get-ExpandedPath "${line}"

    #region Determine what to do depending on the type of the current line. ----

    <# A job definition ends with:
      - an empty line or comment;
      - the next source-dir, source-file or source-file-pattern;
      - on errors; or
      - EOF
    #>
    $line_type = Get-DirlistLineType "${expanded}" "${BACKUP_LOGFILE}"
    Write-DebugMsg "${line_type}: ${expanded}"

    switch -Wildcard ("${line_type}") {
      "error: *" {
        # The fallback value of function Get-DirlistLineType
        # No message: function Get-DirlistLineType reports the error/warning.
        #LogAndShowMessage "${BACKUP_LOGFILE}" ERR "Error in dir-list: ${line}"
        $Script:FinishPreviousJob = $true
      }
      "invalid: *" {
        LogAndShowMessage "${BACKUP_LOGFILE}" WARNING "Invalid entry in dir-list: ${line}"
        $Script:FinishPreviousJob = $true
      }
      "ignore" {
        $Script:FinishPreviousJob = $true
      }
      "source-file" {
        $Script:StartNewJob = $true
        $Script:FinishPreviousJob = $true
        $Script:SingleFileDefinition = $true  # Current line is a single-file definition - the job for it will be a single-file job.

        # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-switch?view=powershell-7.3#multiple-matches
        continue
      }
      "source-*" {
        # Only source-dir or source-file-pattern
        $Script:StartNewJob = $true
        $Script:FinishPreviousJob = $true
      }
      "incl-files-pattern" {
        $Script:ContinueCurrentJob = $true
      }
      "excl-files-pattern" {
        $Script:ContinueCurrentJob = $true
      }
      "excl-dirs-pattern" {
        $Script:ContinueCurrentJob = $true
      }
    }

    #endregion Determine what to do depending on the type of the current line.

    #region Plausibility checks ------------------------------------------------

    if ($Script:FinishPreviousJob) {
      if ($Script:CurrentJobNum -eq 0) {
        $Script:FinishPreviousJob = $false
      }
    }

    if ($Script:ContinueCurrentJob) {
      if ($Script:CurrentJobNum -eq 0) {
        $Script:ContinueCurrentJob = $false
        LogAndShowMessage "${BACKUP_LOGFILE}" ERR "No folder/job defined for: ${line}"
      }
    }

    #endregion Plausibility checks ---------------------------------------------

    # Show what we are going to do.
    if ($Script:FinishPreviousJob -or $Script:StartNewJob -or $Script:ContinueCurrentJob -or $Script:SingleFileJob) {
      $task_list = New-Object System.Collections.ArrayList
      if ($Script:FinishPreviousJob) { $task_list.Add("Finish previous job") > $null }
      if ($Script:StartNewJob) { $task_list.Add("Start new job") > $null }
      if ($Script:ContinueCurrentJob) { $task_list.Add("Continue current job") > $null }
      if ($Script:SingleFileJob) { $task_list.Add("Copy single file") > $null }

      $tasks = ($task_list -join ", ")
      Write-DebugMsg "Task(s): ${tasks}"

      $task_list.Clear()
      $tasks = ""
    }

    #region Actual job creation ------------------------------------------------

    if ($Script:FinishPreviousJob) {
      Write-DebugMsg "----- Finishing the previous job: ------------------------------------"
      Invoke-AddJobFile
    }

    if ($Script:StartNewJob) {
      Write-DebugMsg "----- Starting a new job: --------------------------------------------"
      $Script:SourceDefinitionsCount = ($Script:SourceDefinitionsCount + 1)
      $Script:CurrentJobNum = $Script:SourceDefinitionsCount
      $Script:CurrentSourceDefinition = "${line}"
      $Script:CurrentSourceType = "${line_type}"
      $Script:SingleFileJob = $Script:SingleFileDefinition

      Write-DebugMsg "SourceDefinitionsCount    : $Script:SourceDefinitionsCount"
      Write-DebugMsg "CurrentJobNum             : $Script:CurrentJobNum"
      Write-DebugMsg "CurrentSourceDefinition   : ${Script:CurrentSourceDefinition}"
      Write-DebugMsg "CurrentSourceType         : ${Script:CurrentSourceType}"

      # Determine basic information for the job.
      switch -Wildcard ("${Script:CurrentSourceType}") {
        "source-dir" { $Script:SourceDir = "${expanded}" }
        "source-file*" {
          # <--- pattern!
          #TODO: A good automated test for the main script is really needed!!!
          #TODO: -> TODO\Pester\SmokeTestingConcept.md
          $FSobject = Get-ParentDir "${expanded}"
          $Script:SourceDir = $FSobject.Path

          # Add the filename (pattern) to $IncludedFiles because we must NOT use *.* later!
          $source_filename = Split-Path -Leaf "${expanded}"
          Write-DebugMsg "source_filename   : ${source_filename}"
          $Script:IncludedFiles.Add("${source_filename}") > $null
          $source_filename = ""
        }
      }
      Write-DebugMsg "SourceDir         : ${Script:SourceDir}"

      if ("${Script:SourceDir}" -eq "") {
        LogAndShowMessage "${BACKUP_LOGFILE}" ERR "Parent directory not specified for: ${line}"
        Initialize-JobRelatedInfo
      }
      else {
        $Script:TargetDir = Get-TargetDir "${BACKUP_DIR}" "${Script:SourceDir}"
        Write-DebugMsg "TargetDir         : ${Script:TargetDir}"
      }

      Write-DebugMsg "----------------------------------------------------------------------"
    }

    if ($Script:SingleFileJob) {
      Write-DebugMsg "----- Copying a single file: -----------------------------------------"
      Invoke-AddJobFile
    }

    # Add included/excluded files/directories to the job file (robocopy options /IF, /XF, /XD).
    if ($Script:ContinueCurrentJob) {
      Write-DebugMsg "----- Continuing the job: --------------------------------------------"
      # Determine additional information for the job.
      $entry = "${expanded}".Substring(4)   # Remove the leading "  + " or "  - "
      Write-DebugMsg "entry               : ${entry}"

      switch ("${line_type}") {
        "incl-files-pattern" { $Script:IncludedFiles.Add("${entry}") > $null }
        "excl-files-pattern" { $Script:ExcludedFiles.Add("${entry}") > $null }
        "excl-dirs-pattern" { $Script:ExcludedDirs.Add("${entry}") > $null }
      }

      Write-DebugMsg "IncludedFiles.Count   : $($Script:IncludedFiles.Count)"
      Write-DebugMsg "ExcludedFiles.Count   : $($Script:ExcludedFiles.Count)"
      Write-DebugMsg "ExcludedDirs.Count    : $($Script:ExcludedDirs.Count)"

      Write-DebugMsg "----------------------------------------------------------------------"
    }

    #endregion Actual job creation ---------------------------------------------

    # Reset values that can only apply for 1 line.
    Initialize-LineRelatedInfo

  }

}

_processDirectoryList

Write-DebugMsg "----- End of the dir-list --------------------------------------------"

# Finish the last job?
$finish_last_job = ($Script:CurrentJobNum -ne 0)

if ($finish_last_job) {
  Write-DebugMsg "----- Finishing the last job: ----------------------------------------"
  Invoke-AddJobFile
}

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "$Script:JobsCreatedCount job file(s) created."

Write-DebugMsg "----- Results ------------------------------------------------------------------"
Write-DebugMsg "SourceDefinitionsCount: $Script:SourceDefinitionsCount"
Write-DebugMsg "StartNewJob           : $Script:StartNewJob"
Write-DebugMsg "ContinueCurrentJob    : $Script:ContinueCurrentJob"
Write-DebugMsg "FinishPreviousJob     : $Script:FinishPreviousJob"
Write-DebugMsg "IncludedFiles.Count   : $($Script:IncludedFiles.Count)"
Write-DebugMsg "ExcludedFiles.Count   : $($Script:ExcludedFiles.Count)"
Write-DebugMsg "ExcludedDirs.Count    : $($Script:ExcludedDirs.Count)"
Write-DebugMsg "JobsCreatedCount      : $Script:JobsCreatedCount"
Write-DebugMsg "--------------------------------------------------------------------------------"

#endregion Create job files ####################################################



#region Run jobs

[Int32]$job_result_ok_count = 0
[Int32]$job_result_warning_count = 0
[Int32]$job_result_error_count = 0

$jobfiles = New-Object System.Collections.ArrayList
$jobfiles = Get-ChildItem -Path "${BACKUP_JOB_DIR}*" -Include "${JOB_FILE_NAME_SCHEME}" -File |
Sort-Object { [int]([regex]::Match($_.Name, 'Job(\d+)\.RCJ').Groups[1].Value) }
$jobfiles_count = $jobfiles.Count

if ($jobfiles_count -eq 0) {
  LogAndShowMessage "${BACKUP_LOGFILE}" WARNING "No jobfiles created!"
}
else {
  LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Running $jobfiles_count job(s)..."

  if ($SkipExecution) {
    LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Skipping execution as requested (-SkipExecution)."
  }
  else {
    for ($i = 0; $i -lt $jobfiles_count; $i++) {
      $user_defined_job = $jobfiles[$i]
      Write-InfoMsg "Job: ${user_defined_job}..."

      #TODO: Make sure we don't add an "empty" /job: statement for JOB_LOGFILE_VERBOSITY=none!
      [Int32]$robocopy_exit_code = 0
      if ($PSCmdlet.ShouldProcess("${user_defined_job}", "Run Robocopy job")) {
        $process = Start-Process -Wait -PassThru -NoNewWindow `
          -FilePath "${RobocopyExecutable}" `
          -ArgumentList "/job:""${RobocopyJobTypeTemplate}""", `
          "/job:""${ROBOCOPY_JOB_TEMPLATE_GLOBAL_EXCLUSIONS}""", `
          "/job:""${ROBOCOPY_JOB_TEMPLATE_LOGGING}""", `
          "/job:""${user_defined_job}"""

        $robocopy_exit_code = $process.ExitCode

      }
      else {
        # In -WhatIf mode, we simulate a successful (no changes) exit code.
        $robocopy_exit_code = 0
      }

      Write-DebugMsg "Robocopy exit code: $robocopy_exit_code"

      # Log errors. Use the jobname (Job1..n) from the filename.
      [Int32]$job_name_pos = ("${user_defined_job}".LastIndexOf("-") + 1)
      [Int32]$job_name_length = ("${user_defined_job}".LastIndexOf(".") - $job_name_pos)
      [String]$job_name = "${user_defined_job}".Substring($job_name_pos, $job_name_length)

      LogAndShowRobocopyError "${BACKUP_LOGFILE}" "${job_name}" $robocopy_exit_code

      # Update counters.
      switch ($robocopy_exit_code) {
        { $_ -in 0..7 } {
          $job_result_ok_count = ($job_result_ok_count + 1)
        }
        { $_ -in 8..15 } {
          $job_result_warning_count = ($job_result_warning_count + 1)
        }
        16 {
          $job_result_error_count = ($job_result_error_count + 1)
        }
      }

    }

    LogAndShowMessage "${BACKUP_LOGFILE}" INFO "$job_result_ok_count jobs finished successfully, $job_result_warning_count with warnings, $job_result_error_count with errors."

  }

}

#endregion Run jobs ############################################################



# Finished
$endTime = (Get-Date)
$elapsedTime = $endTime - $startTime
$message = "Script finished in {0:hh} h {0:mm} min {0:ss} sec." -f $elapsedTime
LogAndShowMessage "${BACKUP_LOGFILE}" INFO "${message}"



# Only pause for user input if the script was started via Windows Explorer (Right-click)
# and we are not in non-interactive mode.
if ($CalledViaRightclick -and -not $NonInteractive) {
  Write-Host -NoNewLine "Press any key to quit..."
  [void][System.Console]::ReadKey($true)
}
