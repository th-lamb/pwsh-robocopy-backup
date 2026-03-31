#     Helper functions
#     ================
#
# Call structure:
# ---------------
# Add-Job     --->  _addHeader
#             --->  _addSourceAndTarget
#             --->  _addJobConfig
#             --->  _finalizeJob        --->  _addIncludedFiles
#                                       --->  _addExcludedDirs
#                                       --->  _addExcludedFiles
#             --->  _writeToJobfile
#
# Not meant to be called directly:
# - _writeToJobfile()
# - _addHeader()
# - _addSourceAndTarget()
# - _addJobConfig()
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

function _addHeader {
  # Adds the job file header.
  <# Note: No [Parameter(Mandatory = $true)] for System.Collections.Generic.List[string]
    Reason: In PS 5.1, the binder seems to "unroll" or misinterpret a Generic.List during
    the mandatory check if the list is empty.
    Result: It sees an empty list and decides it "can't bind this to a mandatory object"
    and throws the generic "empty string" error instead of a collection error.
  #>
  [CmdletBinding()]
  param (
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines,
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
  $JobLines.Add(":: Robocopy Job ${computername}-Job${CurrentJobNumber}")
  $JobLines.Add(":: For dir-list entry: ${DirlistEntry}")
  $JobLines.Add("")

}

function _addSourceAndTarget {
  # Adds source and target directory to the job file.
  [CmdletBinding()]
  param (
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines,
    [Parameter(Mandatory = $true)]
    [String]$SourceDirectory,
    [Parameter(Mandatory = $true)]
    [String]$TargetDirectory
  )

  $JobLines.Add(":: Source Directory")
  $JobLines.Add("/SD:${SourceDirectory}")
  $JobLines.Add("")
  $JobLines.Add(":: Destination Directory")
  $JobLines.Add("/DD:${TargetDirectory}")
  $JobLines.Add("")

}

function _addJobConfig {
  # Adds user settings (e.g. logging options) to the job file.
  [CmdletBinding()]
  param (
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines,
    [Parameter(Mandatory = $true)]
    [String]$LogfilePath
  )

  $JobLines.Add(":: ----- User settings ---------------------------------------------------------")
  $JobLines.Add("")
  $JobLines.Add(":: Logging options")
  $JobLines.Add("/UNILOG:${LogfilePath}")
  $JobLines.Add("")
  $JobLines.Add(":: Copy options")

}

function _addIncludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be included (robocopy option /IF).
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  [CmdletBinding()]
  param (
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$IncludedFiles
  )

  # Append the Robocopy switch
  $JobLines.Add("/IF :: Include the following Files.")

  # Append all entries
  foreach ($entry in $IncludedFiles) {
    $JobLines.Add("  ${entry}")
  }

}

function _addExcludedDirs {
  <# Adds all directories in the specified list to the specified job file
    as directories to be excluded (robocopy option /XD).
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  [CmdletBinding()]
  param (
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$ExcludedDirs
  )

  # Append the Robocopy switch
  $JobLines.Add("/XD :: eXclude Directories matching given names/paths.")

  # Append all entries
  foreach ($entry in $ExcludedDirs) {
    $JobLines.Add("  ${entry}")
  }

}

function _addExcludedFiles {
  <# Adds all files in the specified list to the specified job file
    as files to be excluded (robocopy option /XF).
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  [CmdletBinding()]
  param (
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$ExcludedFiles
  )

  # Append the Robocopy switch
  $JobLines.Add("/XF :: eXclude Files matching given names/paths/wildcards.")

  # Append all entries
  foreach ($entry in $ExcludedFiles) {
    $JobLines.Add("  ${entry}")
  }

}

function _finalizeJob {
  # Adds all included/excluded entries to the specified job file.
  [CmdletBinding()]
  param (
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$IncludedFiles,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$ExcludedDirs,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$ExcludedFiles,
    [Parameter(Mandatory = $true)]
    [System.Boolean]$CopySingleFile
  )

  $SpacerNeeded = $false

  # Always add included files. Use *.* if the list $IncludedFiles is empty.
  if ($IncludedFiles.Count -eq 0) {
    $IncludedFiles.Add("*.*")
  }

  _addIncludedFiles -JobLines $JobLines -IncludedFiles $IncludedFiles
  $SpacerNeeded = $true

  # Add excluded dirs?
  if (! ($ExcludedDirs.Count -eq 0) ) {
    if ($SpacerNeeded) {
      $JobLines.Add("")
      $SpacerNeeded = $false
    }

    _addExcludedDirs -JobLines $JobLines -ExcludedDirs $ExcludedDirs
    $SpacerNeeded = $true
  }

  if (! ($ExcludedFiles.Count -eq 0) ) {
    if ($SpacerNeeded) {
      $JobLines.Add("")
      $SpacerNeeded = $false
    }

    _addExcludedFiles -JobLines $JobLines -ExcludedFiles $ExcludedFiles
  }

  # Add robocopy option /LEV:1 to copy only a single file?
  if ($CopySingleFile) {
    $JobLines.Add("")
    $JobLines.Add("/LEV:1 :: only copy the top n LEVels of the source directory tree.")
  }

}

function _writeToJobfile {
  # Writes the specified lines to the specified job file.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$JobfilePath,
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$JobLines
  )

  # Robocopy job files (.RCJ) are expected to be in the OEM code page (e.g. CP850 on German systems).
  # Using '-Encoding oem' ensures that German umlauts etc. are written correctly for Robocopy.
  # Tested encodings and their results in Robocopy log:
  # ascii           : _tempor?r\Bahnversp?tung
  # ansi (CP1252)   : _temporr\Bahnversptung (0xE4 in CP1252 is 0xD5 in CP850, which is 'Õ')
  # unicode (UTF-16): _temporär\Bahnverspätung, but Robocopy reads: _temporõr\Bahnverspõtung
  # utf8            : _temporär\Bahnverspätung, but Robocopy reads: _tempor├ñr\Bahnversp├ñtung (UTF-8 bytes read as CP850)
  # oem (CP850)     : _temporär\Bahnverspätung (CORRECT)

  #TODO: Write the whole List to the file
  Set-Content -Path $JobfilePath -Value $JobLines -Encoding OEM -ErrorAction Stop

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
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$IncludedFiles,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$ExcludedDirs,
    [Parameter(Mandatory = $false)]
    [System.Collections.Generic.List[string]]$ExcludedFiles,
    [Parameter(Mandatory = $true)]
    [System.Boolean]$CopySingleFile
  )

  Write-DebugMsg "Add-JobFile(): BackupJobDirectory : ${BackupJobDirectory}"
  Write-DebugMsg "Add-JobFile(): computername       : ${computername}"
  Write-DebugMsg "Add-JobFile(): CurrentJobNumber   : $CurrentJobNumber"
  Write-DebugMsg "Add-JobFile(): DirlistEntry       : ${DirlistEntry}"
  Write-DebugMsg "Add-JobFile(): SourceDirectory    : ${SourceDirectory}"
  Write-DebugMsg "Add-JobFile(): TargetDirectory    : ${TargetDirectory}"
  Write-DebugMsg "Add-JobFile(): IncludedFiles.Count: $($IncludedFiles.Count)"
  Write-DebugMsg "Add-JobFile(): ExcludedDirs.Count : $($ExcludedDirs.Count)"
  Write-DebugMsg "Add-JobFile(): ExcludedFiles.Count: $($ExcludedFiles.Count)"
  Write-DebugMsg "Add-JobFile(): CopySingleFile     : $CopySingleFile"

  # Paths for the current job
  #TODO: Use $JOB_FILE_NAME_SCHEME or similar from the inifile to make sure that function Export-OldJobs uses the same scheme!
  # e.g.  $JOB_FILE_NAME_SCHEME = "${computername}-Job*.RCJ"
  # or    $JOB_FILE_NAME_SCHEME = "${computername}-Job%job_num%.RCJ"
  $JobfilePath = "${BackupJobDirectory}${computername}-Job$CurrentJobNumber.RCJ"
  $LogfilePath = "${BackupJobDirectory}${computername}-Job$CurrentJobNumber.log"

  Write-DebugMsg "Add-JobFile(): JobfilePath        : ${JobfilePath}"
  Write-DebugMsg "Add-JobFile(): LogfilePath        : ${LogfilePath}"

  #TODO: Do the ShouldProcess part only when we actually write to the file?
  if ($PSCmdlet.ShouldProcess("${JobfilePath}", "Create Robocopy job file")) {
    # Create job
    $JobLines = [System.Collections.Generic.List[string]]::new()
    _addHeader -JobLines $JobLines -computername "${computername}" -CurrentJobNumber $CurrentJobNumber -DirlistEntry "${DirlistEntry}"

    # Add paths
    _addSourceAndTarget -JobLines $JobLines -SourceDirectory "${SourceDirectory}" -TargetDirectory "${TargetDirectory}"

    # Add next section for user-dependent settings
    _addJobConfig -JobLines $JobLines -LogfilePath "${LogfilePath}"

    # Add included/excluded files/directories (and additional options).
    _finalizeJob -JobLines $JobLines -IncludedFiles $IncludedFiles -ExcludedDirs $ExcludedDirs -ExcludedFiles $ExcludedFiles -CopySingleFile $CopySingleFile
  }

  if ($PSCmdlet.ShouldProcess("${JobfilePath}", "Create Robocopy job file")) {
    _writeToJobfile -JobfilePath $JobfilePath -JobLines $JobLines
  }

}

#endregion Jobfile creation ####################################################
