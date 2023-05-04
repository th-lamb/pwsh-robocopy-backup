# 2023, Thomas Lambeck
#
# Backup with robocopy based on a dir-list.
# Backup with PowerShell and robocopy using a dir-list.
# Backup with PowerShell and robocopy using a list of directories/files.
# Backup with PowerShell and robocopy using a list of directories/files to backup.
#
################################################################################



#region ChangeLog

<#
- 2023-03-02, Version 0.0.01, Thomas Lambeck
  - File created
#>

#endregion ChangeLog ###########################################################



#region TODO

<#
- Sections?
  - ...
  - Get options and option arguments.
  - Check the plausibility of the provided option arguments.
  - ...
  - Show a message and ask for the job type (full, incremental, cleanup, ...?).
    +-----------------------+-----------+-------------+-----------------+
    | Job type              | Command   | Parameters  | More?           |
    +-----------------------+-----------+-------------+-----------------+
    | full backup (folders) | /MIR      | /XJ         | /XF *.tmp *.wbk |
    | incremental (folders) | /E        | /XJ         | same?           |
    | cleanup (folders)     | /E /PURGE | /XL /XJ     | none?           |
    +-----------------------+-----------+-------------+-----------------+
  - ??? more?
  - Is it possible to log errors directly?
#>

#TODO Use more normalMessage() and verboseMessage() instead of debugMsg() or infoMsg()?

#endregion TODO ################################################################



#region Constant values

Set-Variable -Name "SCRIPT_VERSION" -Option ReadOnly -Value 0.0.01
Set-Variable -Name "SCRIPT_DIR" -Option ReadOnly -Value ((Split-Path -parent "${PSCommandPath}") + "\")
Set-Variable -Name "COMPUTERNAME" -Option ReadOnly -Value ([System.Environment]::ExpandEnvironmentVariables("%COMPUTERNAME%"))

#endregion Constant values #####################################################



$startTime = (Get-Date)



#region Change working dir to script location

try {
  Set-Location "${SCRIPT_DIR}"
}
catch {
  [Console]::ForegroundColor = 'red'
  [Console]::Error.WriteLine("Failed to change working directory to [${SCRIPT_DIR}]!")
  [Console]::ResetColor()
  
  exit 2
}

#endregion Change working dir to script location ###############################



#region Import function libraries

#TODO Hard-coded for now, later an import function for different library folders might be better.
#TODO Search order: current directory, parallel folder "lib" or standard directory

. lib\message-functions.ps1       # No dependencies
. lib\logging-functions.ps1       # Depends on message-functions.
. lib\filesystem-functions.ps1    # Depends on logging-functions, message-functions.
. lib\job-functions.ps1           # Depends on message-functions.
. lib\job-archive-functions.ps1   # Depends on logging-functions, message-functions.
. lib\inifile-functions.ps1       # Depends on message-functions.
. lib\robocopy-functions.ps1      # Depends on logging-functions.

#endregion Import function libraries ###########################################



#region Read settings file

# No info message here, because $__VERBOSE is not defined before reading the settings file.
#TODO Maybe use cmdline parameters if provided? (Maybe too much effort to just get some more info messages.)
#logAndShowMessage "${BACKUP_LOGFILE}" INFO "Reading the settings file..."

readSettingsFile ($PSCommandPath -replace ".ps1", ".ini")

logInsertEmptyLine "${BACKUP_LOGFILE}"
logAndShowMessage "${BACKUP_LOGFILE}" INFO "Settings file read."

#endregion Read settings file ##################################################



#region Check necessary directories and files

logAndShowMessage "${BACKUP_LOGFILE}" INFO "Checking necessary directories and files..."

#TODO $BACKUP_SERVER needs a different check! checkNecessaryFolder() does not work for UNC paths.
#checkNecessaryFolder 'BACKUP_SERVER' "${BACKUP_SERVER}" "${BACKUP_LOGFILE}"
#2023-04-29T14:23:02 [ERR    ] Following folder has been moved or deleted:
#\\NODE304
#TODO $BACKUP_SERVER might also be an IP address!

checkNecessaryFolder 'BACKUP_BASE_DIR' "${BACKUP_BASE_DIR}" "${BACKUP_LOGFILE}"
checkNecessaryFolder 'BACKUP_USER_BASE_DIR' "${BACKUP_USER_BASE_DIR}" "${BACKUP_LOGFILE}"
checkNecessaryFolder 'BACKUP_DIR' "${BACKUP_DIR}" "${BACKUP_LOGFILE}"
checkNecessaryFolder 'BACKUP_TEMPLATES_DIR' "${BACKUP_TEMPLATES_DIR}" "${BACKUP_LOGFILE}"
checkNecessaryFolder 'BACKUP_JOB_DIR' "${BACKUP_JOB_DIR}" "${BACKUP_LOGFILE}"

checkNecessaryFile 'ROBOCOPY_EXE' "${ROBOCOPY_EXE}" "${BACKUP_LOGFILE}"
checkNecessaryFile 'ROBOCOPY_JOB_TEMPLATE_INCR'  "${ROBOCOPY_JOB_TEMPLATE_INCR}" "${BACKUP_LOGFILE}"
checkNecessaryFile 'BACKUP_DIRLIST'  "${BACKUP_DIRLIST}" "${BACKUP_LOGFILE}"
#checkNecessaryFile 'BACKUP_LOGFILE'  "${BACKUP_LOGFILE}" "${BACKUP_LOGFILE}"
#checkNecessaryFile 'ERROR_LOGFILE'  "${ERROR_LOGFILE}" "${ERROR_LOGFILE}"

logAndShowMessage "${BACKUP_LOGFILE}" INFO "Necessary directories and files checked."

#endregion Check necessary directories and files ###############################



#region Archive previous jobs

logAndShowMessage "${BACKUP_LOGFILE}" INFO "Archiving previous jobs..."

archiveOldJobs "${BACKUP_JOB_DIR}" "${BACKUP_JOB_NAME_SCHEME}" "${BACKUP_JOB_LOG_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

logAndShowMessage "${BACKUP_LOGFILE}" INFO "Previous jobs archived."

#endregion Archive previous job files ##########################################



#region Create job files

logAndShowMessage "${BACKUP_LOGFILE}" INFO "Creating job files..."

<#
Creates a job file for each dir in the dir-list.
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

function _callCreateJob
{
  # Creates the current job using all values collected from the dir-list.
  debugMsg "_callCreateJob()"

  createJob `
    "${COMPUTERNAME}" `
    $current_job_num `
    "${current_source_definition}" `
    "${source_dir}" `
    "${target_dir}" `
    $included_files `
    $excluded_dirs `
    $excluded_files `
    $copy_single_file

  $script:jobs_created_count = ($jobs_created_count + 1)
  debugMsg "jobs_created_count: $jobs_created_count"

  _resetJobRelatedInfo

  debugMsg "----------------------------------------------------------------------"
}

function _resetJobRelatedInfo
{
  # Resets all values that apply for a whole job definition, possibly
  # consisting of multiple lines in the dir-list.
  debugMsg "_resetJobRelatedInfo()"
  $script:current_job_num = 0
  $script:current_source_definition = ""
  $script:current_source_type = ""
  $script:source_dir = ""
  $script:target_dir = ""
  $script:included_files.Clear()
  $script:excluded_dirs.Clear()
  $script:excluded_files.Clear()
  $script:copy_single_file = $false   # job- and line-related
}

function _resetLineRelatedInfo
{
  # Resets all values that apply only for the current line in the dir-list.
  debugMsg "_resetLineRelatedInfo()"
  $script:start_new_job = $false
  $script:finish_previous_job = $false
  $script:continue_curr_job = $false
  $script:copy_single_file = $false   # job- and line-related
  $script:line_type = ""
}

# Process the dir-list.
$dir_list_content = Get-Content "${BACKUP_DIRLIST}"

ForEach($line in $dir_list_content)
{
  debugMsg "Next line: ${line}"

  # Expand all entries first to avoid interpreting environment variables etc. as filenames.
  $expanded = expandedPath "${line}"

  <# Determine what to do depending on the type of the current line.
  A job definition ends with:
  - an empty line or comment;
  - the next source-dir, source-file or source-file-pattern;
  - on errors; or
  - EOF
  #>
  $line_type = dirlistLineType "${expanded}" "${BACKUP_LOGFILE}"
  debugMsg "${line_type}: ${expanded}"

  switch -Wildcard ("${line_type}")
  {
    "error: *"  # The fallback value of function dirlistLineType
    {
      $finish_previous_job = $true
      logAndShowMessage "${BACKUP_LOGFILE}" ERR "Error in dir-list: ${line}"
    }
    "invalid: *"
    {
      $finish_previous_job = $true
      logAndShowMessage "${BACKUP_LOGFILE}" WARNING "Invalid entry in dir-list: ${line}"
    }
    "ignore"
    {
      $finish_previous_job = $true
    }
    "source-file"
    {
      $copy_single_file = $true
      $start_new_job = $true
      $finish_previous_job = $true
      #https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-switch?view=powershell-7.3#multiple-matches
      continue
    }
    "source-*"  # Only source-dir or source-file-pattern
    {
      $start_new_job = $true
      $finish_previous_job = $true
    }
    "incl-files-pattern"
    {
      $continue_curr_job = $true
    }
    "excl-files-pattern"
    {
      $continue_curr_job = $true
    }
    "excl-dirs-pattern"
    {
      $continue_curr_job = $true
    }
  }

  # Plausibility checks
  if ($finish_previous_job)
  {
    if ($current_job_num -eq 0)
    {
      $finish_previous_job = $false
    }
  }

  if ($continue_curr_job)
  {
    if ($current_job_num -eq 0)
    {
      $continue_curr_job = $false
      logAndShowMessage "${BACKUP_LOGFILE}" ERR "No folder/job defined for: ${line}"
    }
  }

  # Show what we are going to do.
  if ($finish_previous_job -or $start_new_job -or $continue_curr_job -or $copy_single_file)
  {
    $task_list = New-Object System.Collections.ArrayList
    if ($finish_previous_job) { $task_list.Add("Finish previous job") > $null }
    if ($start_new_job) { $task_list.Add("Start new job") > $null }
    if ($continue_curr_job) { $task_list.Add("Continue current job") > $null }
    if ($copy_single_file) { $task_list.Add("Copy single file") > $null }

    $tasks = ($task_list -join ", ")
    debugMsg "Task(s): ${tasks}"

    $task_list.Clear()
    $tasks = ""
  }

  # Actual job creation

  if ($finish_previous_job)
  {
    debugMsg "----- Finishing the previous job: ------------------------------------"
    _callCreateJob
  }

  if ($start_new_job)
  {
    debugMsg "----- Starting a new job: --------------------------------------------"
    $source_defs_count = ($source_defs_count + 1)
    $current_job_num = $source_defs_count
    $current_source_definition = "${line}"
    $current_source_type = "${line_type}"

    debugMsg "source_defs_count : $source_defs_count"
    debugMsg "current_job_num   : $current_job_num"
    debugMsg "current_source_definition: ${current_source_definition}"
    debugMsg "current_source_type : ${current_source_type}"

    #TODO Check here whether source exists?
    #TODO Also determine whether the type is correct? (e.g. missing trailing "\" on a folder)
    Write-Host "expanded: ${expanded}" -ForegroundColor Yellow

    # Determine basic information for the job.
    switch -Wildcard ("${current_source_type}")
    {
      "source-dir"  { $source_dir = "${expanded}" }
      "source-file*"  # <--- pattern!
      {
        $source_dir = getParentDir "${expanded}"

        # Add the filename (pattern) to $included_files because we must NOT use *.* later!
        $source_filename = Split-Path -Leaf "${expanded}"
        debugMsg "source_filename   : ${source_filename}"
        $included_files.Add("${source_filename}") > $null
        $source_filename = ""
      }
    }
    debugMsg "source_dir        : ${source_dir}"

    if ("${source_dir}" -eq "")
    {
      logAndShowMessage "${BACKUP_LOGFILE}" ERR "Parent directory not specified for: ${line}"
      _resetJobRelatedInfo
    }
    else
    {
      $target_dir = getTargetDir "${BACKUP_DIR}" "${source_dir}"
      debugMsg "target_dir        : ${target_dir}"
    }

    debugMsg "----------------------------------------------------------------------"
  }

  if ($copy_single_file)
  {
    debugMsg "----- Copying a single file: -----------------------------------------"
    _callCreateJob
  }

  # Add included/excluded files/directories to the job file (robocopy options /IF, /XF, /XD).
  if ($continue_curr_job)
  {
    debugMsg "----- Continuing the job: --------------------------------------------"
    # Determine additional information for the job.
    $entry = "${line}".Substring(4)   # Remove the leading "  + " or "  - "
    debugMsg "entry               : ${entry}"

    switch ("${line_type}")
    {
      "incl-files-pattern"  {$included_files.Add("${entry}") > $null}
      "excl-files-pattern"  {$excluded_files.Add("${entry}") > $null}
      "excl-dirs-pattern"   {$excluded_dirs.Add("${entry}") > $null}
    }

    debugMsg ("included_files.Count: " + $included_files.Count)
    debugMsg ("excluded_files.Count: " + $excluded_files.Count)
    debugMsg ("excluded_dirs.Count : " + $excluded_dirs.Count)

    debugMsg "----------------------------------------------------------------------"
  }

  # Reset values that can only apply for 1 line.
  _resetLineRelatedInfo

}

debugMsg "----- End of the dir-list --------------------------------------------"

# Finish the last job?
$finish_last_job = ($current_job_num -ne 0)

if ($finish_last_job)
{
  debugMsg "----- Finishing the last job: ----------------------------------------"
  _callCreateJob
}

logAndShowMessage "${BACKUP_LOGFILE}" INFO "$jobs_created_count job file(s) created."

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

#TODO Remove the next 2 lines after testing
#Write-Host "Abort test" -ForegroundColor Red
#return

#endregion Create job files ####################################################



#region Run jobs

$jobfiles = New-Object System.Collections.ArrayList
$jobfiles = Get-ChildItem -Path "${BACKUP_JOB_DIR}*" -Include "${BACKUP_JOB_NAME_SCHEME}" -File
$jobfiles_count = $jobfiles.Count

if ($jobfiles_count -eq 0)
{
  logAndShowMessage "${BACKUP_LOGFILE}" WARNING "No jobfiles created!"
}
else
{
  logAndShowMessage "${BACKUP_LOGFILE}" INFO "Running $jobfiles_count job(s)..."

  for ($i = 0; $i -lt $jobfiles_count; $i++)
  {
    $user_defined_job = $jobfiles[$i]
    infoMsg "Job: ${user_defined_job}..."

    $process = Start-Process -Wait -PassThru -NoNewWindow `
      -FilePath "${ROBOCOPY_EXE}" `
      -ArgumentList "/job:""${ROBOCOPY_JOB_TEMPLATE_INCR}""", "/job:""${user_defined_job}"""

    [Int32]$exit_code = $process.ExitCode
    debugMsg "Exit code: $exit_code"

    # Log errors. Use the jobname (Job1..n) from the filename.
    [Int32]$job_name_pos = ("${user_defined_job}".LastIndexOf("-") + 1)
    [Int32]$job_name_length = ("${user_defined_job}".LastIndexOf(".") - $job_name_pos)
    [String]$job_name = "${user_defined_job}".Substring($job_name_pos, $job_name_length)

    logAndShowRobocopyErrors "${BACKUP_LOGFILE}" "${job_name}" $exit_code

    # Update counters.
    switch ($exit_code)
    {
      {$_ -in 0..7}
      {
        $job_result_ok_count = ($job_result_ok_count + 1)
      }
      {$_ -in 8..15}
      {
        $job_result_warning_count = ($job_result_warning_count + 1)
      }
      16
      {
        $job_result_error_count = ($job_result_error_count + 1)
      }
    }

  }

  logAndShowMessage "${BACKUP_LOGFILE}" INFO "$job_result_ok_count jobs finished successful, $job_result_warning_count with warnings, $job_result_error_count with errors."

}

#endregion Run jobs ############################################################



# Finished
$endTime = (Get-Date)
$elapsedTime = $endTime-$startTime
$message = "Script finished in {0:hh} h {0:mm} min {0:ss} sec." -f $elapsedTime
logAndShowMessage "${BACKUP_LOGFILE}" INFO "${message}"



#:Abort
#:End
#Write-Host -NoNewLine "Press any key to quit..."
#[void][System.Console]::ReadKey($true)
