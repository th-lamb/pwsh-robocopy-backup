#     Helper functions
#     ================
#
# Not meant to be called directly:
# - _writeToJobfile()
# - _writeHeader()
# - _addDirectories()
# - _addUserSettings()
# - _addIncludedFiles(), _addExcludedDirs(), _addExcludedFiles()
# - _finalizeJob()
#
################################################################################



#region Object types

function Test-FsObjectTypeMismatch {
  <# Warns if the real object type (e.g. "directory") does NOT match
    the specified type (e.g. "file pattern").

    Possible specified types:
    - directory
    - directory pattern
    - file
    - file pattern

    Possible real types:
    - directory
    - file
    - $false (non-existent)

    Expected combinations:
    - directory         : directory or $false
    - file              : file or $false
    - directory pattern : directory or $false
    - file pattern      : file or $false
  #>
  param (
    [String]$specified_type,
    [String]$existing_type
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('specified_type')) {
    Write-Error "Test-FsObjectTypeMismatch(): Parameter specified_type not provided!"
    Throw "Parameter specified_type not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('existing_type')) {
    Write-Error "Test-FsObjectTypeMismatch(): Parameter existing_type not provided!"
    Throw "Parameter existing_type not provided!"
  }
  #endregion

  # non-existent objects
  if ("${existing_type}" -eq $false) {
    return "missing"
  }

  # Matching object types
  if ("${specified_type}" -eq "${existing_type}") {
    return "match"
  }

  if ("${specified_type}".Replace(" pattern", "") -eq "${existing_type}") {
    return "match"
  }

  # Type mismatch
  if (
    ("${specified_type}".Replace(" pattern", "") -eq "directory") -and
    ("${existing_type}" -eq "file")
  ) {
    return "type mismatch"
  }

  if (
    ("${specified_type}".Replace(" pattern", "") -eq "file") -and
    ("${existing_type}" -eq "directory")
  ) {
    return "type mismatch"
  }

  return "error"

}

function Get-DirlistLineType {
  #TODO: Use an Enum? https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-switch?view=powershell-7.3#enum
  <# Returns the type of the specified line in the dir-list.

    Possible types:
    - ignore                (empty line or comment)
    - source-dir
    - incl-files-pattern    (only filenames can be included)
    - excl-files-pattern
    - excl-dirs-pattern
    - source-file           (must include the parent directory)
    - source-file-pattern

    Not implemented:
    - source-dir-pattern  -> invalid
    - directory-entry     -> invalid
  #>
  param (
    [String]$entry,
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('entry')) {
    Write-Error "Get-DirlistLineType(): Parameter entry not provided!"
    Throw "Parameter entry not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('logfile')) {
    Write-Error "Get-DirlistLineType(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }
  #endregion

  # ignore
  if (($entry -eq "") -or ($entry.StartsWith("::"))) {
    return "ignore"
  }

  # source-dir, source-file, or source-file-pattern
  if ( (! $entry.StartsWith(" ")) ) {
    # Check specified and real type, then compare and warn if necessary!
    $specified_type = Get-SpecifiedFsObjectType "${entry}"

    # Ignore invalid entries.
    switch ("${specified_type}") {
      "directory pattern" {return "invalid: source directory pattern"}
      "directory entry"   {return "invalid: directory entry (for current or parent folder)"}
    }

    $existing_type = Get-RealFsObjectType "${entry}"
    $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"

    switch ("${result}") {
      "match" {
        $object_type = "${specified_type}"
      }
      "missing" {
        LogAndShowMessage "${logfile}" WARNING "Not found: ${entry}"
        $object_type = "missing"
      }
      "type mismatch" {
        LogAndShowMessage "${logfile}" NOTICE "Type mismatch: ${entry}"
        $object_type = "${existing_type}"   # We use the real object type!
      }
      Default {
        Write-Error "Get-DirlistLineType(): Unknown result from Test-FsObjectTypeMismatch(): ${result}"
        Throw "Unknown result from Test-FsObjectTypeMismatch(): ${result}"
      }
    }

    Write-DebugMsg "Get-DirlistLineType(): object_type: ${object_type}"

    switch ("${object_type}") {
      "directory"         {return "source-dir"}
      "file"              {return "source-file"}
      "file pattern"      {return "source-file-pattern"}
      "missing"           {return "error: not found"}
    }

  }

  # incl-files-pattern, excl-files-pattern, excl-dirs-pattern
  if ($entry.StartsWith("  + ")) {
    $temp = "${entry}".Substring(4)   # Remove the leading "  + "

    # Type of the entry
    # -> An inclusion should always be a file (pattern)!
    $object_type = Get-SpecifiedFsObjectType "${temp}"

    switch ("${object_type}") {
      "directory"         {return "invalid: only file (patterns) can be included: ${entry}"}
      "file"              {return "incl-files-pattern"}
      "directory pattern" {return "invalid: only file (patterns) can be included: ${entry}"}
      "file pattern"      {return "incl-files-pattern"}
    }

  } elseif ($entry.StartsWith("  - ")) {
    $temp = "${entry}".Substring(4)   # Remove the leading "  + "

    # Type of the entry
    # -> An inclusion should always be a file (pattern)!
    $object_type = Get-SpecifiedFsObjectType "${temp}"

    switch ("${object_type}") {
      "directory"         {return "excl-dirs-pattern"}
      "file"              {return "excl-files-pattern"}
      "directory pattern" {return "excl-dirs-pattern"}
      "file pattern"      {return "excl-files-pattern"}
    }

  }

  return "error: unknown entry type for: %{entry}"

}

#endregion Object types ########################################################



#region Path functions

function Get-TargetDir {
  # Returns the desired target (backup) directory for the specified directory.
  param (
    [String]$base_dir,
    [String]$folder_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('base_dir')) {
    Write-Error "Get-TargetDir(): Parameter base_dir not provided!"
    Throw "Parameter base_dir not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('folder_spec')) {
    Write-Error "Get-TargetDir(): Parameter folder_spec not provided!"
    Throw "Parameter folder_spec not provided!"
  }
  #endregion

  # Checks
  if ("${folder_spec}" -eq "") {
    LogAndShowMessage "${BACKUP_LOGFILE}" ERR "Get-TargetDir(): No folder specified!"
    #TODO: If we show an *error* here, why do we return the base dir as target dir?
    #TODO: Can this even happen?
    Throw "Get-TargetDir(): No folder specified!"
  }

  # Corrections
  if ( ! "${base_dir}".EndsWith("\") ) {
    $base_dir = "${base_dir}\"
  }
  if ( ! "${folder_spec}".EndsWith("\") ) {
    $folder_spec = "${folder_spec}\"
  }

  # Result
  $sub_dir= ($folder_spec -replace ":", "")
  $target_dir = ${base_dir} + "$sub_dir"

  return $target_dir

}

#endregion Path functions ######################################################



#region Jobfile creation

function _writeToJobfile {
  # Writes the specified line to the specified job file.
  param (
    [String]$jobfile_path,
    [String]$line,
    [System.Boolean]$create_new_file
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_writeToJobfile(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('line')) {
    Write-Error "_writeToJobfile(): Parameter line not provided!"
    Throw "Parameter line not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('create_new_file')) {
    Write-Error "_writeToJobfile(): Parameter create_new_file not provided!"
    Throw "Parameter create_new_file not provided!"
  }
  #endregion

  if (${create_new_file}) {
    "${line}" | Out-File -FilePath "${jobfile_path}" -Encoding utf8
  } else {
    "${line}" | Out-File -FilePath "${jobfile_path}" -Encoding utf8 -Append
  }

}

function _writeHeader {
  # Writes the job file header.
  param (
    [String]$jobfile_path,
    [String]$computername,
    [Int32]$current_job_num,
    [String]$dirlist_entry
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_writeHeader(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('computername')) {
    Write-Error "_writeHeader(): Parameter computername not provided!"
    Throw "Parameter computername not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('current_job_num')) {
    Write-Error "_writeHeader(): Parameter current_job_num not provided!"
    Throw "Parameter current_job_num not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('dirlist_entry')) {
    Write-Error "_writeHeader(): Parameter dirlist_entry not provided!"
    Throw "Parameter dirlist_entry not provided!"
  }
  #endregion

  #TODO: Use $JOB_FILE_NAME_SCHEME or similar from the inifile to make sure that function Export-OldJobs uses the same scheme!
  # e.g.  $JOB_FILE_NAME_SCHEME = "${computername}-Job*.RCJ"
  # or    $JOB_FILE_NAME_SCHEME = "${computername}-Job%job_num%.RCJ"
  _writeToJobfile "${jobfile_path}" ":: Robocopy Job ${computername}-Job${current_job_num}" $true
  _writeToJobfile "${jobfile_path}" ":: For dir-list entry: ${dirlist_entry}" $false
  _writeToJobfile "${jobfile_path}" "" $false

}

function _addDirectories {
  # Adds source and target directory to the job file.
  param (
    [String]$jobfile_path,
    [String]$source_dir,
    [String]$target_dir
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_addDirectories(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('source_dir')) {
    Write-Error "_addDirectories(): Parameter source_dir not provided!"
    Throw "Parameter source_dir not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('target_dir')) {
    Write-Error "_addDirectories(): Parameter target_dir not provided!"
    Throw "Parameter target_dir not provided!"
  }
  #endregion

  _writeToJobfile "${jobfile_path}" ":: Source Directory" $false
  _writeToJobfile "${jobfile_path}" "/SD:${source_dir}" $false
  _writeToJobfile "${jobfile_path}" "" $false
  _writeToJobfile "${jobfile_path}" ":: Destination Directory" $false
  _writeToJobfile "${jobfile_path}" "/DD:${target_dir}" $false
  _writeToJobfile "${jobfile_path}" "" $false

}

function _addUserSettings {
  # Adds user settings (e.g. logging options) to the job file.
  param (
    [String]$jobfile_path,
    [String]$logfile_path
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_addUserSettings(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('logfile_path')) {
    Write-Error "_addUserSettings(): Parameter logfile_path not provided!"
    Throw "Parameter logfile_path not provided!"
  }
  #endregion

  _writeToJobfile "${jobfile_path}" ":: ----- User settings ---------------------------------------------------------" $false
  _writeToJobfile "${jobfile_path}" "" $false
  _writeToJobfile "${jobfile_path}" ":: Logging options" $false
  _writeToJobfile "${jobfile_path}" "/UNILOG:${logfile_path}" $false
  _writeToJobfile "${jobfile_path}" "" $false
  _writeToJobfile "${jobfile_path}" ":: Copy options" $false

}

function _addIncludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be included (robocopy option /IF).
  #>
  param (
    [String]$jobfile_path,
    [System.Collections.ArrayList]$included_files
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_addIncludedFiles(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('included_files')) {
    Write-Error "_addIncludedFiles(): Parameter included_files not provided!"
    Throw "Parameter included_files not provided!"
  }
  #endregion

  # Append the Robocopy switch
  _writeToJobfile "${jobfile_path}" "/IF :: Include the following Files." $false

  # Append all entries
  foreach ($entry in $included_files) {
    _writeToJobfile "${jobfile_path}" "  ${entry}" $false
  }

}

function _addExcludedDirs {
  <# Adds all directories in the specified list to the specified job file
    as directories to be excluded (robocopy option /XD).
  #>
  param (
    [String]$jobfile_path,
    [System.Collections.ArrayList]$excluded_dirs
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_addExcludedDirs(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('excluded_dirs')) {
    Write-Error "_addExcludedDirs(): Parameter excluded_dirs not provided!"
    Throw "Parameter excluded_dirs not provided!"
  }
  #endregion

  # Append the Robocopy switch
  _writeToJobfile "${jobfile_path}" "/XD :: eXclude Directories matching given names/paths." $false

  # Append all entries
  foreach ($entry in $excluded_dirs) {
    _writeToJobfile "${jobfile_path}" "  ${entry}" $false
  }

}

function _addExcludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be excluded (robocopy option /XF).
  #>
  param (
    [String]$jobfile_path,
    [System.Collections.ArrayList]$excluded_files
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_addExcludedFiles(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('excluded_files')) {
    Write-Error "_addExcludedFiles(): Parameter excluded_files not provided!"
    Throw "Parameter excluded_files not provided!"
  }
  #endregion

  # Append the Robocopy switch
  _writeToJobfile "${jobfile_path}" "/XF :: eXclude Files matching given names/paths/wildcards." $false

  # Append all entries
  foreach ($entry in $excluded_files) {
    _writeToJobfile "${jobfile_path}" "  ${entry}" $false
  }

}

function _finalizeJob {
  # Adds all included/excluded entries to the specified job file.
  param (
    [String]$jobfile_path,
    [System.Collections.ArrayList]$included_files,
    [System.Collections.ArrayList]$excluded_dirs,
    [System.Collections.ArrayList]$excluded_files,
    [System.Boolean]$copy_single_file
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('jobfile_path')) {
    Write-Error "_finalizeJob(): Parameter jobfile_path not provided!"
    Throw "Parameter jobfile_path not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('included_files')) {
    Write-Error "_finalizeJob(): Parameter included_files not provided!"
    Throw "Parameter included_files not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('excluded_dirs')) {
    Write-Error "_finalizeJob(): Parameter excluded_dirs not provided!"
    Throw "Parameter excluded_dirs not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('excluded_files')) {
    Write-Error "_finalizeJob(): Parameter excluded_files not provided!"
    Throw "Parameter excluded_files not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('copy_single_file')) {
    Write-Error "_finalizeJob(): Parameter copy_single_file not provided!"
    Throw "Parameter copy_single_file not provided!"
  }
  #endregion

  $spacer_needed = $false

  # Always add included files. Use *.* if the list $included_files is empty.
  if ($included_files.Count -eq 0) {
    $included_files.Add("*.*") > $null
  }

  _addIncludedFiles "${jobfile_path}" $included_files
  $spacer_needed = $true

  # Add excluded dirs?
  if (! ($excluded_dirs.Count -eq 0) ) {
    if ($spacer_needed) {
      _writeToJobfile "${jobfile_path}" "" $false
      $spacer_needed = $false
    }

    _addExcludedDirs "${jobfile_path}" $excluded_dirs
    $spacer_needed = $true
  }

  if (! ($excluded_files.Count -eq 0) ) {
    if ($spacer_needed) {
      _writeToJobfile "${jobfile_path}" "" $false
      $spacer_needed = $false
    }

    _addExcludedFiles "${jobfile_path}" $excluded_files
  }

  # Add robocopy option /LEV:1 to copy only a single file?
  if ($copy_single_file) {
    _writeToJobfile "${jobfile_path}" "" $false
    _writeToJobfile "${jobfile_path}" "/LEV:1 :: only copy the top n LEVels of the source directory tree." $false
  }

}

function Add-JobFile {
  # Creates the specified job file, including a simple header.
  param (
    [String]$backup_job_dir,
    [String]$computername,
    [Int32]$current_job_num,
    [String]$dirlist_entry,
    [String]$source_dir,
    [String]$target_dir,
    [System.Collections.ArrayList]$included_files,
    [System.Collections.ArrayList]$excluded_dirs,
    [System.Collections.ArrayList]$excluded_files,
    [System.Boolean]$copy_single_file
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('backup_job_dir')) {
    Write-Error "Add-JobFile(): Parameter backup_job_dir not provided!"
    Throw "Parameter backup_job_dir not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('computername')) {
    Write-Error "Add-JobFile(): Parameter computername not provided!"
    Throw "Parameter computername not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('current_job_num')) {
    Write-Error "Add-JobFile(): Parameter current_job_num not provided!"
    Throw "Parameter current_job_num not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('dirlist_entry')) {
    Write-Error "Add-JobFile(): Parameter dirlist_entry not provided!"
    Throw "Parameter dirlist_entry not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('source_dir')) {
    Write-Error "Add-JobFile(): Parameter source_dir not provided!"
    Throw "Parameter source_dir not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('target_dir')) {
    Write-Error "Add-JobFile(): Parameter target_dir not provided!"
    Throw "Parameter target_dir not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('included_files')) {
    Write-Error "Add-JobFile(): Parameter included_files not provided!"
    Throw "Parameter included_files not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('excluded_dirs')) {
    Write-Error "Add-JobFile(): Parameter excluded_dirs not provided!"
    Throw "Parameter excluded_dirs not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('excluded_files')) {
    Write-Error "Add-JobFile(): Parameter excluded_files not provided!"
    Throw "Parameter excluded_files not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('copy_single_file')) {
    Write-Error "Add-JobFile(): Parameter copy_single_file not provided!"
    Throw "Parameter copy_single_file not provided!"
  }
  #endregion

  Write-DebugMsg "Add-JobFile(): backup_job_dir       : ${backup_job_dir}"
  Write-DebugMsg "Add-JobFile(): computername         : ${computername}"
  Write-DebugMsg "Add-JobFile(): current_job_num      : $current_job_num"
  Write-DebugMsg "Add-JobFile(): dirlist_entry        : ${dirlist_entry}"
  Write-DebugMsg "Add-JobFile(): source_dir           : ${source_dir}"
  Write-DebugMsg "Add-JobFile(): target_dir           : ${target_dir}"
  Write-DebugMsg "Add-JobFile(): included_files.Count : $($included_files.Count)"
  Write-DebugMsg "Add-JobFile(): excluded_dirs.Count  : $($excluded_dirs.Count)"
  Write-DebugMsg "Add-JobFile(): excluded_files.Count : $($excluded_files.Count)"
  Write-DebugMsg "Add-JobFile(): copy_single_file     : $copy_single_file"

  # Paths for the current job
  #TODO: Use $JOB_FILE_NAME_SCHEME or similar from the inifile to make sure that function Export-OldJobs uses the same scheme!
  # e.g.  $JOB_FILE_NAME_SCHEME = "${computername}-Job*.RCJ"
  # or    $JOB_FILE_NAME_SCHEME = "${computername}-Job%job_num%.RCJ"
  $jobfile_path = "${backup_job_dir}${computername}-Job$current_job_num.RCJ"
  $logfile_path = "${backup_job_dir}${computername}-Job$current_job_num.log"

  Write-DebugMsg "Add-JobFile(): jobfile_path         : ${jobfile_path}"
  Write-DebugMsg "Add-JobFile(): logfile_path         : ${logfile_path}"

  # Create job file
  _writeHeader "${jobfile_path}" "${computername}" $current_job_num "${dirlist_entry}"

  # Add paths
  _addDirectories "${jobfile_path}" "${source_dir}" "${target_dir}"

  # Add next section for user-dependent settings
  _addUserSettings "${jobfile_path}" "${logfile_path}"

  # Add included/excluded files/directories (and additional options).
  _finalizeJob "${jobfile_path}" $included_files $excluded_dirs $excluded_files $copy_single_file

}

#endregion Jobfile creation ####################################################
