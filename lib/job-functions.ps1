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
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$specified_type,
    [Parameter(Mandatory=$true)]
    [String]$existing_type
  )

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
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    #[Parameter(Mandatory=$true)]   # A line in the dir-list can be empty!
    [String]$entry,
    [Parameter(Mandatory=$true)]
    [String]$logfile
  )

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
    $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}"

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
    $temp = "${entry}".Substring(4)   # Remove the leading "  - "

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
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$base_dir,
    [Parameter(Mandatory=$true)]
    [String]$folder_spec
  )

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
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [Parameter(Mandatory=$true)]
    [AllowEmptyString()]
    [String]$line,
    [Parameter(Mandatory=$true)]
    [System.Boolean]$create_new_file
  )

  if (${create_new_file}) {
    "${line}" | Out-File -FilePath "${jobfile_path}" -Encoding utf8
  } else {
    "${line}" | Out-File -FilePath "${jobfile_path}" -Encoding utf8 -Append
  }

}

function _writeHeader {
  # Writes the job file header.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [Parameter(Mandatory=$true)]
    [String]$computername,
    [Parameter(Mandatory=$true)]
    [Int32]$current_job_num,
    [Parameter(Mandatory=$true)]
    [String]$dirlist_entry
  )

  #TODO: Use $JOB_FILE_NAME_SCHEME or similar from the inifile to make sure that function Export-OldJobs uses the same scheme!
  # e.g.  $JOB_FILE_NAME_SCHEME = "${computername}-Job*.RCJ"
  # or    $JOB_FILE_NAME_SCHEME = "${computername}-Job%job_num%.RCJ"
  _writeToJobfile -jobfile_path "${jobfile_path}" -line ":: Robocopy Job ${computername}-Job${current_job_num}" -create_new_file $true
  _writeToJobfile -jobfile_path "${jobfile_path}" -line ":: For dir-list entry: ${dirlist_entry}" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false

}

function _addDirectories {
  # Adds source and target directory to the job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [Parameter(Mandatory=$true)]
    [String]$source_dir,
    [Parameter(Mandatory=$true)]
    [String]$target_dir
  )

  _writeToJobfile -jobfile_path "${jobfile_path}" -line ":: Source Directory" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "/SD:${source_dir}" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line ":: Destination Directory" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "/DD:${target_dir}" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false

}

function _addUserSettings {
  # Adds user settings (e.g. logging options) to the job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [Parameter(Mandatory=$true)]
    [String]$logfile_path
  )

  _writeToJobfile -jobfile_path "${jobfile_path}" -line ":: ----- User settings ---------------------------------------------------------" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line ":: Logging options" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "/UNILOG:${logfile_path}" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false
  _writeToJobfile -jobfile_path "${jobfile_path}" -line ":: Copy options" -create_new_file $false

}

function _addIncludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be included (robocopy option /IF).
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [System.Collections.ArrayList]$included_files
  )

  # Append the Robocopy switch
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "/IF :: Include the following Files." -create_new_file $false

  # Append all entries
  foreach ($entry in $included_files) {
    _writeToJobfile -jobfile_path "${jobfile_path}" -line "  ${entry}" -create_new_file $false
  }

}

function _addExcludedDirs {
  <# Adds all directories in the specified list to the specified job file
    as directories to be excluded (robocopy option /XD).
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [System.Collections.ArrayList]$excluded_dirs
  )

  # Append the Robocopy switch
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "/XD :: eXclude Directories matching given names/paths." -create_new_file $false

  # Append all entries
  foreach ($entry in $excluded_dirs) {
    _writeToJobfile -jobfile_path "${jobfile_path}" -line "  ${entry}" -create_new_file $false
  }

}

function _addExcludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be excluded (robocopy option /XF).
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [System.Collections.ArrayList]$excluded_files
  )

  # Append the Robocopy switch
  _writeToJobfile -jobfile_path "${jobfile_path}" -line "/XF :: eXclude Files matching given names/paths/wildcards." -create_new_file $false

  # Append all entries
  foreach ($entry in $excluded_files) {
    _writeToJobfile -jobfile_path "${jobfile_path}" -line "  ${entry}" -create_new_file $false
  }

}

function _finalizeJob {
  # Adds all included/excluded entries to the specified job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$jobfile_path,
    [System.Collections.ArrayList]$included_files,
    [System.Collections.ArrayList]$excluded_dirs,
    [System.Collections.ArrayList]$excluded_files,
    [Parameter(Mandatory=$true)]
    [System.Boolean]$copy_single_file
  )

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
      _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false
      $spacer_needed = $false
    }

    _addExcludedDirs "${jobfile_path}" $excluded_dirs
    $spacer_needed = $true
  }

  if (! ($excluded_files.Count -eq 0) ) {
    if ($spacer_needed) {
      _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false
      $spacer_needed = $false
    }

    _addExcludedFiles "${jobfile_path}" $excluded_files
  }

  # Add robocopy option /LEV:1 to copy only a single file?
  if ($copy_single_file) {
    _writeToJobfile -jobfile_path "${jobfile_path}" -line "" -create_new_file $false
    _writeToJobfile -jobfile_path "${jobfile_path}" -line "/LEV:1 :: only copy the top n LEVels of the source directory tree." -create_new_file $false
  }

}

function Add-JobFile {
  # Creates the specified job file, including a simple header.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$backup_job_dir,
    [Parameter(Mandatory=$true)]
    [String]$computername,
    [Parameter(Mandatory=$true)]
    [Int32]$current_job_num,
    [Parameter(Mandatory=$true)]
    [String]$dirlist_entry,
    [Parameter(Mandatory=$true)]
    [String]$source_dir,
    [Parameter(Mandatory=$true)]
    [String]$target_dir,
    [System.Collections.ArrayList]$included_files,
    [System.Collections.ArrayList]$excluded_dirs,
    [System.Collections.ArrayList]$excluded_files,
    [Parameter(Mandatory=$true)]
    [System.Boolean]$copy_single_file
  )

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
  _writeHeader -jobfile_path "${jobfile_path}" -computername "${computername}" -current_job_num $current_job_num -dirlist_entry "${dirlist_entry}"

  # Add paths
  _addDirectories -jobfile_path "${jobfile_path}" -source_dir "${source_dir}" -target_dir "${target_dir}"

  # Add next section for user-dependent settings
  _addUserSettings -jobfile_path "${jobfile_path}" -logfile_path "${logfile_path}"

  # Add included/excluded files/directories (and additional options).
  _finalizeJob -jobfile_path "${jobfile_path}" -included_files $included_files -excluded_dirs $excluded_dirs -excluded_files $excluded_files -copy_single_file $copy_single_file

}

#endregion Jobfile creation ####################################################
