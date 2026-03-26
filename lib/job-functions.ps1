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
    - drive letter
    - network computer
    - network share

    Possible real types:
    - directory
    - file
    - drive letter
    - network computer
    - network share
    - $null (non-existent)

    Expected combinations:
    - directory         : directory or $null
    - directory pattern : directory or $null
    - file              : file or $null
    - file pattern      : file or $null
    #TODO: More expected combinations?
  #>
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$SpecifiedType,
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [String]$ExistingType
  )

  # non-existent objects
  # Check for $null or empty string
  if ([String]::IsNullOrEmpty($ExistingType)) {
    return "missing"
  }

  # Matching object types
  if ("${SpecifiedType}" -eq "${ExistingType}") {
    return "match"
  }

  if ("${SpecifiedType}".Replace(" pattern", "") -eq "${ExistingType}") {
    return "match"
  }

  # Type mismatch
  if (
    ("${SpecifiedType}".Replace(" pattern", "") -eq "directory") -and
    ("${ExistingType}" -eq "file")
  ) {
    return "type mismatch"
  }

  if (
    ("${SpecifiedType}".Replace(" pattern", "") -eq "file") -and
    ("${ExistingType}" -eq "directory")
  ) {
    return "type mismatch"
  }

  #TODO: More checks for more combinations?

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
    [Parameter(Mandatory = $true)]
    [String]$logfile
  )

  # ignore
  if (($entry -eq "") -or ($entry.StartsWith("::"))) {
    return "ignore"
  }

  # source-dir, source-file, or source-file-pattern
  if ( (! $entry.StartsWith(" ")) ) {
    # Check specified and real type, then compare and warn if necessary!
    $SpecifiedType = Get-SpecifiedFsObjectType "${entry}"

    # Ignore invalid entries.
    switch ("${SpecifiedType}") {
      "directory pattern" { return "invalid: source directory pattern" }
      "directory entry" { return "invalid: directory entry (for current or parent folder)" }
    }

    # Ignore unavailable filesystem objects.
    $FsObject = Get-RealFsObjectType "${entry}"
    $ExistingType = $FsObject.Type

    if (! $FsObject.Exists) {
      if ($ExistingType -eq "network share" -or $ExistingType -eq "network computer") {
        LogAndShowMessage "${logfile}" WARNING "Network resource offline: ${entry}"
      }
      else {
        LogAndShowMessage "${logfile}" WARNING "Not found: ${entry}"
      }
      return "error: not found"
    }

    # Check for differences.
    $result = Test-FsObjectTypeMismatch "${SpecifiedType}" "${ExistingType}"

    switch ("${result}") {
      "match" {
        $ObjectType = "${SpecifiedType}"
      }
      "type mismatch" {
        LogAndShowMessage "${logfile}" NOTICE "Type mismatch: ${entry}"
        $ObjectType = "${ExistingType}"   # We use the real object type!
      }
      Default {
        Write-Error "Get-DirlistLineType()   : Unknown result from Test-FsObjectTypeMismatch(): ${result}"
        Throw "Unknown result from Test-FsObjectTypeMismatch(): ${result}"
      }
    }

    Write-DebugMsg "Get-DirlistLineType()   : ObjectType : ${ObjectType}"

    switch ("${ObjectType}") {
      "directory" { return "source-dir" }
      "file" { return "source-file" }
      "file pattern" { return "source-file-pattern" }
    }

  }

  # incl-files-pattern, excl-files-pattern, excl-dirs-pattern
  if ($entry.StartsWith("  + ")) {
    $temp = "${entry}".Substring(4)   # Remove the leading "  + "

    # Type of the entry
    # -> An inclusion should always be a file (pattern)!
    $ObjectType = Get-SpecifiedFsObjectType "${temp}"

    switch ("${ObjectType}") {
      "directory" { return "invalid: only file (patterns) can be included: ${entry}" }
      "file" { return "incl-files-pattern" }
      "directory pattern" { return "invalid: only file (patterns) can be included: ${entry}" }
      "file pattern" { return "incl-files-pattern" }
    }

  }
  elseif ($entry.StartsWith("  - ")) {
    $temp = "${entry}".Substring(4)   # Remove the leading "  - "

    # Type of the entry
    # -> An inclusion should always be a file (pattern)!
    $ObjectType = Get-SpecifiedFsObjectType "${temp}"

    switch ("${ObjectType}") {
      "directory" { return "excl-dirs-pattern" }
      "file" { return "excl-files-pattern" }
      "directory pattern" { return "excl-dirs-pattern" }
      "file pattern" { return "excl-files-pattern" }
    }

  }

  return "error: unknown entry type for: ${entry}"

}

#endregion Object types ########################################################



#region Path functions

function Get-TargetDir {
  # Returns the desired target (backup) directory for the specified directory.
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$BaseDirectory,
    [Parameter(Mandatory = $true)]
    [String]$FolderSpec
  )

  # Checks
  if ("${FolderSpec}" -eq "") {
    LogAndShowMessage "${BACKUP_LOGFILE}" ERR "Get-TargetDir(): No folder specified!"
    #TODO: If we show an *error* here, why do we return the base dir as target dir?
    #TODO: Can this even happen?
    Throw "Get-TargetDir(): No folder specified!"
  }

  # Corrections
  if ( ! "${BaseDirectory}".EndsWith("\") ) {
    $BaseDirectory = "${BaseDirectory}\"
  }
  if ( ! "${FolderSpec}".EndsWith("\") ) {
    $FolderSpec = "${FolderSpec}\"
  }

  # Result
  $SubDirectory = ($FolderSpec -replace ":", "")
  $TargetDirectory = ${BaseDirectory} + "$SubDirectory"

  return $TargetDirectory

}

#endregion Path functions ######################################################



#region Jobfile creation

function _writeToJobfile {
  # Writes the specified line to the specified job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [String]$line,
    [Parameter(Mandatory = $true)]
    [System.Boolean]$CreateNewFile
  )

  if (${CreateNewFile}) {
    "${line}" | Out-File -FilePath "${JobfilePath}" -Encoding oem
  }
  else {
    "${line}" | Out-File -FilePath "${JobfilePath}" -Encoding oem -Append
  }

  # Robocopy job files (.RCJ) are expected to be in the OEM code page (e.g. CP850 on German systems).
  # Using '-Encoding oem' ensures that German umlauts etc. are written correctly for Robocopy.
  # Tested encodings and their results in Robocopy log:
  # ascii           : _tempor?r\Bahnversp?tung
  # ansi (CP1252)   : _temporr\Bahnversptung (0xE4 in CP1252 is 0xD5 in CP850, which is 'Õ')
  # unicode (UTF-16): _temporär\Bahnverspätung, but Robocopy reads: _temporõr\Bahnverspõtung
  # utf8            : _temporär\Bahnverspätung, but Robocopy reads: _tempor├ñr\Bahnversp├ñtung (UTF-8 bytes read as CP850)
  # oem (CP850)     : _temporär\Bahnverspätung (CORRECT)

}

function _writeHeader {
  # Writes the job file header.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [Parameter(Mandatory = $true)]
    [String]$computername,
    [Parameter(Mandatory = $true)]
    [Int32]$CurrentJobNumber,
    [Parameter(Mandatory = $true)]
    [String]$DirlistEntry
  )

  #TODO: Use $JOB_FILE_NAME_SCHEME or similar from the inifile to make sure that function Export-OldJobs uses the same scheme!
  # e.g.  $JOB_FILE_NAME_SCHEME = "${computername}-Job*.RCJ"
  # or    $JOB_FILE_NAME_SCHEME = "${computername}-Job%job_num%.RCJ"
  _writeToJobfile -JobfilePath "${JobfilePath}" -line ":: Robocopy Job ${computername}-Job${CurrentJobNumber}" -CreateNewFile $true
  _writeToJobfile -JobfilePath "${JobfilePath}" -line ":: For dir-list entry: ${DirlistEntry}" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false

}

function _addSourceAndTarget {
  # Adds source and target directory to the job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [Parameter(Mandatory = $true)]
    [String]$SourceDirectory,
    [Parameter(Mandatory = $true)]
    [String]$TargetDirectory
  )

  _writeToJobfile -JobfilePath "${JobfilePath}" -line ":: Source Directory" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "/SD:${SourceDirectory}" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line ":: Destination Directory" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "/DD:${TargetDirectory}" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false

}

function _addJobConfig {
  # Adds user settings (e.g. logging options) to the job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [Parameter(Mandatory = $true)]
    [String]$LogfilePath
  )

  _writeToJobfile -JobfilePath "${JobfilePath}" -line ":: ----- User settings ---------------------------------------------------------" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line ":: Logging options" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "/UNILOG:${LogfilePath}" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false
  _writeToJobfile -JobfilePath "${JobfilePath}" -line ":: Copy options" -CreateNewFile $false

}

function _addIncludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be included (robocopy option /IF).
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [System.Collections.ArrayList]$IncludedFiles
  )

  # Append the Robocopy switch
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "/IF :: Include the following Files." -CreateNewFile $false

  # Append all entries
  foreach ($entry in $IncludedFiles) {
    _writeToJobfile -JobfilePath "${JobfilePath}" -line "  ${entry}" -CreateNewFile $false
  }

}

function _addExcludedDirs {
  <# Adds all directories in the specified list to the specified job file
    as directories to be excluded (robocopy option /XD).
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [System.Collections.ArrayList]$ExcludedDirs
  )

  # Append the Robocopy switch
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "/XD :: eXclude Directories matching given names/paths." -CreateNewFile $false

  # Append all entries
  foreach ($entry in $ExcludedDirs) {
    _writeToJobfile -JobfilePath "${JobfilePath}" -line "  ${entry}" -CreateNewFile $false
  }

}

function _addExcludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be excluded (robocopy option /XF).
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [System.Collections.ArrayList]$ExcludedFiles
  )

  # Append the Robocopy switch
  _writeToJobfile -JobfilePath "${JobfilePath}" -line "/XF :: eXclude Files matching given names/paths/wildcards." -CreateNewFile $false

  # Append all entries
  foreach ($entry in $ExcludedFiles) {
    _writeToJobfile -JobfilePath "${JobfilePath}" -line "  ${entry}" -CreateNewFile $false
  }

}

function _finalizeJob {
  # Adds all included/excluded entries to the specified job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [System.Collections.ArrayList]$IncludedFiles,
    [System.Collections.ArrayList]$ExcludedDirs,
    [System.Collections.ArrayList]$ExcludedFiles,
    [Parameter(Mandatory = $true)]
    [System.Boolean]$CopySingleFile
  )

  $SpacerNeeded = $false

  # Always add included files. Use *.* if the list $IncludedFiles is empty.
  if ($IncludedFiles.Count -eq 0) {
    $IncludedFiles.Add("*.*") > $null
  }

  _addIncludedFiles "${JobfilePath}" $IncludedFiles
  $SpacerNeeded = $true

  # Add excluded dirs?
  if (! ($ExcludedDirs.Count -eq 0) ) {
    if ($SpacerNeeded) {
      _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false
      $SpacerNeeded = $false
    }

    _addExcludedDirs "${JobfilePath}" $ExcludedDirs
    $SpacerNeeded = $true
  }

  if (! ($ExcludedFiles.Count -eq 0) ) {
    if ($SpacerNeeded) {
      _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false
      $SpacerNeeded = $false
    }

    _addExcludedFiles "${JobfilePath}" $ExcludedFiles
  }

  # Add robocopy option /LEV:1 to copy only a single file?
  if ($CopySingleFile) {
    _writeToJobfile -JobfilePath "${JobfilePath}" -line "" -CreateNewFile $false
    _writeToJobfile -JobfilePath "${JobfilePath}" -line "/LEV:1 :: only copy the top n LEVels of the source directory tree." -CreateNewFile $false
  }

}

function Add-JobFile {
  # Creates the specified job file, including a simple header.
  [CmdletBinding(SupportsShouldProcess = $true)]
  param (
    [Parameter(Mandatory = $true)]
    [String]$BackupJobDirectory,
    [Parameter(Mandatory = $true)]
    [String]$computername,
    [Parameter(Mandatory = $true)]
    [Int32]$CurrentJobNumber,
    [Parameter(Mandatory = $true)]
    [String]$DirlistEntry,
    [Parameter(Mandatory = $true)]
    [String]$SourceDirectory,
    [Parameter(Mandatory = $true)]
    [String]$TargetDirectory,
    [System.Collections.ArrayList]$IncludedFiles,
    [System.Collections.ArrayList]$ExcludedDirs,
    [System.Collections.ArrayList]$ExcludedFiles,
    [Parameter(Mandatory = $true)]
    [System.Boolean]$CopySingleFile
  )

  Write-DebugMsg "Add-JobFile(): BackupJobDirectory   : ${BackupJobDirectory}"
  Write-DebugMsg "Add-JobFile(): computername         : ${computername}"
  Write-DebugMsg "Add-JobFile(): CurrentJobNumber     : $CurrentJobNumber"
  Write-DebugMsg "Add-JobFile(): DirlistEntry         : ${DirlistEntry}"
  Write-DebugMsg "Add-JobFile(): SourceDirectory      : ${SourceDirectory}"
  Write-DebugMsg "Add-JobFile(): TargetDirectory      : ${TargetDirectory}"
  Write-DebugMsg "Add-JobFile(): IncludedFiles.Count  : $($IncludedFiles.Count)"
  Write-DebugMsg "Add-JobFile(): ExcludedDirs.Count   : $($ExcludedDirs.Count)"
  Write-DebugMsg "Add-JobFile(): ExcludedFiles.Count  : $($ExcludedFiles.Count)"
  Write-DebugMsg "Add-JobFile(): CopySingleFile       : $CopySingleFile"

  # Paths for the current job
  #TODO: Use $JOB_FILE_NAME_SCHEME or similar from the inifile to make sure that function Export-OldJobs uses the same scheme!
  # e.g.  $JOB_FILE_NAME_SCHEME = "${computername}-Job*.RCJ"
  # or    $JOB_FILE_NAME_SCHEME = "${computername}-Job%job_num%.RCJ"
  $JobfilePath = "${BackupJobDirectory}${computername}-Job$CurrentJobNumber.RCJ"
  $LogfilePath = "${BackupJobDirectory}${computername}-Job$CurrentJobNumber.log"

  Write-DebugMsg "Add-JobFile(): JobfilePath          : ${JobfilePath}"
  Write-DebugMsg "Add-JobFile(): LogfilePath          : ${LogfilePath}"

  if ($PSCmdlet.ShouldProcess("${JobfilePath}", "Create Robocopy job file")) {
    # Create job file
    _writeHeader -JobfilePath "${JobfilePath}" -computername "${computername}" -CurrentJobNumber $CurrentJobNumber -DirlistEntry "${DirlistEntry}"

    # Add paths
    _addSourceAndTarget -JobfilePath "${JobfilePath}" -SourceDirectory "${SourceDirectory}" -TargetDirectory "${TargetDirectory}"

    # Add next section for user-dependent settings
    _addJobConfig -JobfilePath "${JobfilePath}" -LogfilePath "${LogfilePath}"

    # Add included/excluded files/directories (and additional options).
    _finalizeJob -JobfilePath "${JobfilePath}" -IncludedFiles $IncludedFiles -ExcludedDirs $ExcludedDirs -ExcludedFiles $ExcludedFiles -CopySingleFile $CopySingleFile
  }

}

#endregion Jobfile creation ####################################################
