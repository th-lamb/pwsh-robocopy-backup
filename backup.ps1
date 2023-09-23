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

<#
  - Sections?
    - ...
    - Get options and option arguments.
    - Check the plausibility of the provided option arguments.
    - ...
    - ??? more?
    - Is it possible to log errors directly?
#>

#TODO: Use more Write-NormalMessage() and Write-VerboseMessage() instead of Write-DebugMsg() or Write-InfoMsg()?

#endregion TODO ################################################################



#region Constant values

Set-Variable -Name "SCRIPT_VERSION" -Option ReadOnly -Value 0.1.00
Set-Variable -Name "SCRIPT_DIR" -Option ReadOnly -Value ((Split-Path -parent "${PSCommandPath}") + "\")
Set-Variable -Name "COMPUTERNAME" -Option ReadOnly -Value ([System.Environment]::ExpandEnvironmentVariables("%COMPUTERNAME%"))

#endregion Constant values #####################################################



$startTime = (Get-Date)



#region Change working dir to script location

try {
  Set-Location "${SCRIPT_DIR}"
} catch {
  [Console]::ForegroundColor = 'red'
  [Console]::Error.WriteLine("Failed to change working directory to [${SCRIPT_DIR}]!")
  [Console]::ResetColor()

  exit 2
}

#endregion Change working dir to script location ###############################



#region Import function libraries

#TODO: Hard-coded for now, later an import function for different library folders might be better.
#TODO: Search order: current directory, parallel folder "lib" or standard directory

. lib\message-functions.ps1       # No dependencies
. lib\logging-functions.ps1       # Depends on message-functions.
. lib\filesystem-functions.ps1    # Depends on logging-functions, message-functions.
. lib\job-functions.ps1           # Depends on message-functions.
. lib\job-archive-functions.ps1   # Depends on logging-functions, message-functions.
. lib\inifile-functions.ps1       # Depends on message-functions.
. lib\robocopy-functions.ps1      # Depends on logging-functions.
. lib\job-type-functions.ps1      # Depends on logging-functions, message-functions.

#endregion Import function libraries ###########################################



#region Read settings file

# No info message here, because $__VERBOSE is not defined before reading the settings file.
#TODO: Maybe use cmdline parameters if provided? (Maybe too much effort to just get some more info messages.)
#LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Reading the settings file..."

Read-SettingsFile ($PSCommandPath -replace ".ps1", ".ini")

Add-EmptyLineToLogfile "${BACKUP_LOGFILE}"
LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Settings file read."

#endregion Read settings file ##################################################



#region Check necessary directories and files

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Checking necessary directories and files..."

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

# Different cases for $BACKUP_BASE_DIR (some cannot be created)!
$dir_type = Get-SpecifiedBackupBaseDirType "${BACKUP_BASE_DIR}"
Write-DebugMsg "BackupBaseDir type: ${dir_type}"

switch ("${dir_type}") {
  "directory" {
    New-NecessaryDirectory 'BACKUP_BASE_DIR' "${BACKUP_BASE_DIR}" "${BACKUP_LOGFILE}"
  }
  {$_ -in "drive letter", "network share"} {
    Test-NecessaryDirectory 'BACKUP_BASE_DIR' "${BACKUP_BASE_DIR}" "${BACKUP_LOGFILE}"
  }
  "relative path" {
    # Interpret as path below script dir, current drive or ...?
    $absolute_base_dir = "${SCRIPT_DIR}\${BACKUP_BASE_DIR}"
    New-NecessaryDirectory 'BACKUP_BASE_DIR (absolute path)' "${absolute_base_dir}" "${BACKUP_LOGFILE}"
  } 
  "network computer" {
    Write-CritMsg "Cannot use a server as BACKUP_BASE_DIR, specify a share!"
    exit 1
  }
  Default {
    Write-CritMsg "Unexpected BackupBaseDir type: ${dir_type}"
    exit 1
  }
}

#TODO: Report creation of these dirs (as INFO).
#TODO: And store a variable to prepend this info when the logging starts? (Until now the log-file starts with "Dir-list created from template.")
#     -> Maybe add all log messages to a list before the log-file exists, and add all of them when it exists?
New-NecessaryDirectory 'BACKUP_USER_BASE_DIR' "${BACKUP_USER_BASE_DIR}" "${BACKUP_LOGFILE}"
New-NecessaryDirectory 'BACKUP_DIR' "${BACKUP_DIR}" "${BACKUP_LOGFILE}"
New-NecessaryDirectory 'BACKUP_JOB_DIR' "${BACKUP_JOB_DIR}" "${BACKUP_LOGFILE}"

# Make sure that robocopy has been found if only "robocopy" is defined in the ini file!
$robocopy_exe = Get-ExecutablePath 'ROBOCOPY' "${ROBOCOPY}" "${BACKUP_LOGFILE}"

# Create the dir-list from the template if necessary.
$dirlist_created = New-NecessaryFile 'BACKUP_DIRLIST' "${BACKUP_DIRLIST}" "${DIRLIST_TEMPLATE}" "${BACKUP_LOGFILE}"

if ($dirlist_created) {
  Write-InfoMsg "Opening the dir-list in Editor and wait..."
  Notepad.exe "${BACKUP_DIRLIST}" | Out-Null
}

#Test-NecessaryFile 'BACKUP_LOGFILE' "${BACKUP_LOGFILE}" "${BACKUP_LOGFILE}"
#Test-NecessaryFile 'ERROR_LOGFILE' "${ERROR_LOGFILE}" "${ERROR_LOGFILE}"

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Necessary directories and files checked."

#endregion Check necessary directories and files ###############################



#region Ask for job type

$selected_job_type = Get-UserSelectedJobType "${DEFAULT_JOB_TYPE}" "${BACKUP_LOGFILE}"

switch ($selected_job_type) {
  "Incremental" { $robocopy_job_type_template = $ROBOCOPY_JOB_TYPE_TEMPLATE_INCR }
  "Full"        { $robocopy_job_type_template = $ROBOCOPY_JOB_TYPE_TEMPLATE_FULL }
  "Purge"       { $robocopy_job_type_template = $ROBOCOPY_JOB_TYPE_TEMPLATE_PURGE }
  "Archive"     { $robocopy_job_type_template = $ROBOCOPY_JOB_TYPE_TEMPLATE_ARCHIVE }
  "Cancel"      { exit 0 }
  Default {
    # Illegal choice
    #TODO: Maybe a different exit code? (1 was for syntax errors, 2 for missing files, more?)
    exit 2
  }
}

#endregion Ask for job type ####################################################



#region Archive previous jobs

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Archiving previous jobs..."

Export-OldJobs "${BACKUP_JOB_DIR}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

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
[Int32]$source_defs_count = 0

[System.Boolean]$start_new_job = $false
[Int32]$current_job_num = 0
[String]$current_source_definition = ""  # Last source definition, in case entries consist of more than one line.
[String]$current_source_type = ""

[System.Boolean]$finish_previous_job = $false
[System.Boolean]$continue_curr_job = $false
[System.Boolean]$copy_single_file = $false

[String]$source_dir = ""
[String]$target_dir = ""
[System.Collections.ArrayList]$included_files = New-Object System.Collections.ArrayList
[System.Collections.ArrayList]$excluded_dirs = New-Object System.Collections.ArrayList
[System.Collections.ArrayList]$excluded_files = New-Object System.Collections.ArrayList

[Int32]$jobs_created_count = 0

[Int32]$job_result_ok_count = 0
[Int32]$job_result_warning_count = 0
[Int32]$job_result_error_count = 0

function _callCreateJob {
  # Creates the current job using all values collected from the dir-list.
  Write-DebugMsg "_callCreateJob()"

  Add-JobFile `
    "${BACKUP_JOB_DIR}" `
    "${COMPUTERNAME}" `
    $current_job_num `
    "${current_source_definition}" `
    "${source_dir}" `
    "${target_dir}" `
    $included_files `
    $excluded_dirs `
    $excluded_files `
    $copy_single_file

  $Script:jobs_created_count = ($jobs_created_count + 1)
  Write-DebugMsg "jobs_created_count: $jobs_created_count"

  _resetJobRelatedInfo

  Write-DebugMsg "----------------------------------------------------------------------"
}

function _resetJobRelatedInfo {
  # Resets all values that apply for a whole job definition, possibly
  # consisting of multiple lines in the dir-list.
  Write-DebugMsg "_resetJobRelatedInfo()"
  $Script:current_job_num = 0
  $Script:current_source_definition = ""
  $Script:current_source_type = ""
  $Script:source_dir = ""
  $Script:target_dir = ""
  $Script:included_files.Clear()
  $Script:excluded_dirs.Clear()
  $Script:excluded_files.Clear()
  $Script:copy_single_file = $false   # job- and line-related
}

function _resetLineRelatedInfo {
  # Resets all values that apply only for the current line in the dir-list.
  Write-DebugMsg "_resetLineRelatedInfo()"
  $Script:start_new_job = $false
  $Script:finish_previous_job = $false
  $Script:continue_curr_job = $false
  $Script:copy_single_file = $false   # job- and line-related
  $Script:line_type = ""
}

# Process the dir-list.
$dir_list_content = Get-Content "${BACKUP_DIRLIST}"

ForEach($line in $dir_list_content) {
  Write-DebugMsg "Next line: ${line}"

  # Expand all entries first to avoid interpreting environment variables etc. as filenames.
  $expanded = Get-ExpandedPath "${line}"

  <# Determine what to do depending on the type of the current line.
    A job definition ends with:
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
      $finish_previous_job = $true
      LogAndShowMessage "${BACKUP_LOGFILE}" ERR "Error in dir-list: ${line}"
    }
    "invalid: *" {
      $finish_previous_job = $true
      LogAndShowMessage "${BACKUP_LOGFILE}" WARNING "Invalid entry in dir-list: ${line}"
    }
    "ignore" {
      $finish_previous_job = $true
    }
    "source-file" {
      $copy_single_file = $true
      $start_new_job = $true
      $finish_previous_job = $true
      #https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-switch?view=powershell-7.3#multiple-matches
      continue
    }
    "source-*" {
      # Only source-dir or source-file-pattern
      $start_new_job = $true
      $finish_previous_job = $true
    }
    "incl-files-pattern" {
      $continue_curr_job = $true
    }
    "excl-files-pattern" {
      $continue_curr_job = $true
    }
    "excl-dirs-pattern" {
      $continue_curr_job = $true
    }
  }

  # Plausibility checks
  if ($finish_previous_job) {
    if ($current_job_num -eq 0) {
      $finish_previous_job = $false
    }
  }

  if ($continue_curr_job) {
    if ($current_job_num -eq 0) {
      $continue_curr_job = $false
      LogAndShowMessage "${BACKUP_LOGFILE}" ERR "No folder/job defined for: ${line}"
    }
  }

  # Show what we are going to do.
  if ($finish_previous_job -or $start_new_job -or $continue_curr_job -or $copy_single_file) {
    $task_list = New-Object System.Collections.ArrayList
    if ($finish_previous_job) { $task_list.Add("Finish previous job") > $null }
    if ($start_new_job) { $task_list.Add("Start new job") > $null }
    if ($continue_curr_job) { $task_list.Add("Continue current job") > $null }
    if ($copy_single_file) { $task_list.Add("Copy single file") > $null }

    $tasks = ($task_list -join ", ")
    Write-DebugMsg "Task(s): ${tasks}"

    $task_list.Clear()
    $tasks = ""
  }

  # Actual job creation

  if ($finish_previous_job) {
    Write-DebugMsg "----- Finishing the previous job: ------------------------------------"
    _callCreateJob
  }

  if ($start_new_job) {
    Write-DebugMsg "----- Starting a new job: --------------------------------------------"
    $source_defs_count = ($source_defs_count + 1)
    $current_job_num = $source_defs_count
    $current_source_definition = "${line}"
    $current_source_type = "${line_type}"

    Write-DebugMsg "source_defs_count : $source_defs_count"
    Write-DebugMsg "current_job_num   : $current_job_num"
    Write-DebugMsg "current_source_definition: ${current_source_definition}"
    Write-DebugMsg "current_source_type : ${current_source_type}"

    #TODO: Check here whether source exists?
    #TODO: Also determine whether the type is correct? (e.g. missing trailing "\" on a folder)
    #Write-Host "expanded: ${expanded}" -ForegroundColor Yellow

    # Determine basic information for the job.
    switch -Wildcard ("${current_source_type}") {
      "source-dir" { $source_dir = "${expanded}" }
      "source-file*" {                                      # <--- pattern!
        $source_dir = Get-ParentDir "${expanded}"

        # Add the filename (pattern) to $included_files because we must NOT use *.* later!
        $source_filename = Split-Path -Leaf "${expanded}"
        Write-DebugMsg "source_filename   : ${source_filename}"
        $included_files.Add("${source_filename}") > $null
        $source_filename = ""
      }
    }
    Write-DebugMsg "source_dir        : ${source_dir}"

    if ("${source_dir}" -eq "") {
      LogAndShowMessage "${BACKUP_LOGFILE}" ERR "Parent directory not specified for: ${line}"
      _resetJobRelatedInfo
    } else {
      $target_dir = Get-TargetDir "${BACKUP_DIR}" "${source_dir}"
      Write-DebugMsg "target_dir        : ${target_dir}"
    }

    Write-DebugMsg "----------------------------------------------------------------------"
  }

  if ($copy_single_file) {
    Write-DebugMsg "----- Copying a single file: -----------------------------------------"
    _callCreateJob
  }

  # Add included/excluded files/directories to the job file (robocopy options /IF, /XF, /XD).
  if ($continue_curr_job) {
    Write-DebugMsg "----- Continuing the job: --------------------------------------------"
    # Determine additional information for the job.
    $entry = "${line}".Substring(4)   # Remove the leading "  + " or "  - "
    Write-DebugMsg "entry               : ${entry}"

    switch ("${line_type}") {
      "incl-files-pattern"  {$included_files.Add("${entry}") > $null}
      "excl-files-pattern"  {$excluded_files.Add("${entry}") > $null}
      "excl-dirs-pattern"   {$excluded_dirs.Add("${entry}") > $null}
    }

    Write-DebugMsg ("included_files.Count: " + $included_files.Count)
    Write-DebugMsg ("excluded_files.Count: " + $excluded_files.Count)
    Write-DebugMsg ("excluded_dirs.Count : " + $excluded_dirs.Count)

    Write-DebugMsg "----------------------------------------------------------------------"
  }

  # Reset values that can only apply for 1 line.
  _resetLineRelatedInfo

}

Write-DebugMsg "----- End of the dir-list --------------------------------------------"

# Finish the last job?
$finish_last_job = ($current_job_num -ne 0)

if ($finish_last_job) {
  Write-DebugMsg "----- Finishing the last job: ----------------------------------------"
  _callCreateJob
}

LogAndShowMessage "${BACKUP_LOGFILE}" INFO "$jobs_created_count job file(s) created."

#Write-Host "----- Results ------------------------------------------------------------------" -ForegroundColor DarkCyan
#Write-Host "source_defs_count   : $source_defs_count" -ForegroundColor DarkCyan
#Write-Host "start_new_job       : $start_new_job" -ForegroundColor DarkCyan
#Write-Host "continue_curr_job   : $continue_curr_job" -ForegroundColor DarkCyan
#Write-Host "finish_previous_job : $finish_previous_job" -ForegroundColor DarkCyan
#Write-Host "included_files.Count:" $included_files.Count -ForegroundColor DarkCyan
#Write-Host "excluded_dirs.Count :" $excluded_dirs.Count -ForegroundColor DarkCyan
#Write-Host "excluded_files.Count:" $excluded_files.Count -ForegroundColor DarkCyan
#Write-Host "jobs_created_count  : $jobs_created_count" -ForegroundColor DarkCyan
#Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkCyan

#endregion Create job files ####################################################



#region Run jobs

$jobfiles = New-Object System.Collections.ArrayList
$jobfiles = Get-ChildItem -Path "${BACKUP_JOB_DIR}*" -Include "${JOB_FILE_NAME_SCHEME}" -File
$jobfiles_count = $jobfiles.Count

if ($jobfiles_count -eq 0) {
  LogAndShowMessage "${BACKUP_LOGFILE}" WARNING "No jobfiles created!"
} else {
  LogAndShowMessage "${BACKUP_LOGFILE}" INFO "Running $jobfiles_count job(s)..."

  for ($i = 0; $i -lt $jobfiles_count; $i++) {
    $user_defined_job = $jobfiles[$i]
    Write-InfoMsg "Job: ${user_defined_job}..."

    #TODO: Make sure we don't add an "empty" /job: statement for JOB_LOGFILE_VERBOSITY=none!
    $process = Start-Process -Wait -PassThru -NoNewWindow `
      -FilePath "${robocopy_exe}" `
      -ArgumentList "/job:""${robocopy_job_type_template}""", `
                    "/job:""${ROBOCOPY_JOB_TEMPLATE_GLOBAL_EXCLUSIONS}""", `
                    "/job:""${ROBOCOPY_JOB_TEMPLATE_LOGGING}""", `
                    "/job:""${user_defined_job}"""

    [Int32]$robocopy_exit_code = $process.ExitCode
    Write-DebugMsg "Robocopy exit code: $robocopy_exit_code"

    # Log errors. Use the jobname (Job1..n) from the filename.
    [Int32]$job_name_pos = ("${user_defined_job}".LastIndexOf("-") + 1)
    [Int32]$job_name_length = ("${user_defined_job}".LastIndexOf(".") - $job_name_pos)
    [String]$job_name = "${user_defined_job}".Substring($job_name_pos, $job_name_length)

    LogAndShowRobocopyErrors "${BACKUP_LOGFILE}" "${job_name}" $robocopy_exit_code

    # Update counters.
    switch ($robocopy_exit_code) {
      {$_ -in 0..7} {
        $job_result_ok_count = ($job_result_ok_count + 1)
      }
      {$_ -in 8..15} {
        $job_result_warning_count = ($job_result_warning_count + 1)
      }
      16 {
        $job_result_error_count = ($job_result_error_count + 1)
      }
    }

  }

  LogAndShowMessage "${BACKUP_LOGFILE}" INFO "$job_result_ok_count jobs finished successful, $job_result_warning_count with warnings, $job_result_error_count with errors."

}

#endregion Run jobs ############################################################



# Finished
$endTime = (Get-Date)
$elapsedTime = $endTime-$startTime
$message = "Script finished in {0:hh} h {0:mm} min {0:ss} sec." -f $elapsedTime
LogAndShowMessage "${BACKUP_LOGFILE}" INFO "${message}"



#:Abort
#:End
#Write-Host -NoNewLine "Press any key to quit..."
#[void][System.Console]::ReadKey($true)
