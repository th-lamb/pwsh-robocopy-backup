#     Steps
#     =====
#
# - Get all old jobfiles.
# - Continue if they exist.
# - Find all existing (0..n) archives.
# - Delete the oldest archive if it exists.
# - Determine the name of the new archive. (Use date and time of the jobfiles?)
# - Archive the jobs (jobfiles and logfiles).
# - Delete the jobs.
#
#
#     Helper functions
#     ================
#
# Not meant to be called directly:
# - Remove-FileCollection()
# - Get-LastDateTime()
#
################################################################################

#TODO: Add logging - not only console messages!

function Remove-FileCollection {
  # Deletes all files specified in the List and returns the number of deleted files.
  [OutputType([System.Int32])]
  [CmdletBinding(SupportsShouldProcess = $true)]
  param (
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$FilesToDelete
  )

  #region Check parameters
  if ( $FilesToDelete.Count -eq 0 ) {
    Write-WarningMsg "Remove-FileCollection(): Parameter FilesToDelete is an empty collection!"
    return 0
  }
  #endregion Check parameters

  [Int32]$DeletedFilesCount = 0

  foreach ($FileToDelete in $FilesToDelete) {
    if ($PSCmdlet.ShouldProcess("${FileToDelete}", "Delete file")) {
      Write-Host "${FileToDelete}" -ForegroundColor DarkRed
      try {
        Remove-Item "${FileToDelete}" -ErrorAction Stop -Confirm:$false
        $DeletedFilesCount++
      }
      catch {
        Write-Error "Cannot delete file: ${FileToDelete}"
      }
    }
  }

  $DeletedFilesCount

}

function Get-LastDateTime {
  <# Returns the date/time of the latest (youngest) file in the specified list;
    or "" if the list is empty.
  #>
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [System.Collections.Generic.List[string]]$FileList
  )

  if ($FileList.Count -eq 0) {
    return ""
  }

  # Convert string paths back to FileInfo for sorting by LastWriteTime
  $Files = $FileList | ForEach-Object { Get-Item -Path $_ }
  $LastFile = ($Files | Sort-Object -Descending -Property LastWriteTime)[0]
  $LastDatetime = $LastFile.LastWriteTime.GetDateTimeFormats('s').Replace(":", "")

  $LastDatetime

}

function Export-PreviousJobsArchive {
  # Archives old jobfiles (zip file) and then deletes them.
  [CmdletBinding(SupportsShouldProcess = $true)]
  param (
    [Parameter(Mandatory = $true)]
    [String]$BackupJobDirectory,
    [Parameter(Mandatory = $true)]
    [String]$JobNameScheme,
    [Parameter(Mandatory = $true)]
    [String]$JobLogNameScheme,
    [Parameter(Mandatory = $true)]
    [String]$ArchiveNameScheme,
    [Parameter(Mandatory = $true)]
    [System.Byte]$MaxArchivesCount  # 0..255
  )

  Write-DebugMsg "Export-PreviousJobsArchive(${BackupJobDirectory}, ${JobNameScheme}, ${JobLogNameScheme}, ${ArchiveNameScheme}, $MaxArchivesCount)"

  # Get all old job- and logfiles.
  $OldJobfiles = [System.Collections.Generic.List[string]]::new()
  Get-ChildItem -Path "${BackupJobDirectory}*" -Include "${JobNameScheme}" -File | ForEach-Object { $OldJobfiles.Add($_.FullName) }

  $OldLogfiles = [System.Collections.Generic.List[string]]::new()
  Get-ChildItem -Path "${BackupJobDirectory}*" -Include "${JobLogNameScheme}" -File | ForEach-Object { $OldLogfiles.Add($_.FullName) }

  # Continue if they exist.
  $OldJobfilesCount = $OldJobfiles.Count
  $OldLogfilesCount = $OldLogfiles.Count
  Write-DebugMsg "OldJobfilesCount: $OldJobfilesCount"
  Write-DebugMsg "OldLogfilesCount: $OldLogfilesCount"

  if (
    ($OldJobfilesCount -eq 0) -and
    ($OldLogfilesCount -eq 0)
  ) {
    Write-DebugMsg "No old jobs to archive."
    return
  }

  # Find all existing (0..n) archives.
  $OldArchives = Get-ChildItem -Path "${BackupJobDirectory}*" -Include "${ArchiveNameScheme}" -File

  # Delete the oldest archive if it exists.
  $OldArchivesCount = $OldArchives.Count
  Write-DebugMsg "OldArchivesCount  : $OldArchivesCount"

  if ($OldArchivesCount -lt $MaxArchivesCount) {
    Write-DebugMsg "$OldArchivesCount job archive(s) (MAX=$MaxArchivesCount), just archiving the existing jobs."
  }
  else {
    Write-InfoMsg "$OldArchivesCount job archives (MAX=$MaxArchivesCount), deleting the oldest one(s)."

    $OldArchives = $OldArchives | Sort-Object -Descending
    for ($i = $MaxArchivesCount - 1; $i -lt $OldArchives.Count; $i++) {
      $ArchiveToDelete = $OldArchives[$i]
      $ArchiveName = Split-Path -Leaf "${ArchiveToDelete}"

      if ($PSCmdlet.ShouldProcess("${ArchiveToDelete}", "Delete job archive")) {
        Write-InfoMsg "Deleting job archive ${ArchiveName}"
        Write-Host "${ArchiveToDelete}" -ForegroundColor DarkRed
        try {
          Remove-Item "$ArchiveToDelete" -ErrorAction Stop -Confirm:$false
        }
        catch {
          Write-Error "Cannot delete archive: ${ArchiveToDelete}"
        }
      }
    }
  }

  # Determine the name of the new archive. (Use date and time of the jobfiles?)
  # Get date/time from the logfiles if there were no jobfiles.
  if ($OldJobfilesCount -gt 0) {
    $LastDatetime = Get-LastDateTime $OldJobfiles
  }
  else {
    $LastDatetime = Get-LastDateTime $OldLogfiles
  }

  Write-DebugMsg "Last job's date/time: ${LastDatetime}"

  # Archive the jobs (jobfile and logfile).
  $ArchiveName = "${ArchiveNameScheme}".Replace("*", "${LastDatetime}")
  $ArchivePath = "${BackupJobDirectory}${ArchiveName}"
  Write-DebugMsg "ArchiveName : ${ArchiveName}"
  Write-DebugMsg "ArchivePath : ${ArchivePath}"

  if ($PSCmdlet.ShouldProcess("${ArchivePath}", "Create job archive")) {
    Write-InfoMsg "Archiving old jobs in ${ArchiveName}"
    try {
      Compress-Archive -Path "${BackupJobDirectory}${JobNameScheme}" -DestinationPath "${ArchivePath}" -Force -Confirm:$false        # -Force to overwrite if needed.
      # Update the archive only if logfiles exist! Otherwise the archive gets deleted.
      if ($OldLogfilesCount -gt 0) {
        Compress-Archive -Path "${BackupJobDirectory}${JobLogNameScheme}" -Update -DestinationPath "${ArchivePath}" -Confirm:$false   # -Update to add.
      }
      Write-Host "${ArchivePath}" -ForegroundColor DarkGreen
    }
    catch {
      Write-Error "Cannot create archive: ${ArchivePath}"
    }
  }

  # Delete the jobs.
  Write-InfoMsg "Deleting old jobs..."

  if ( $null -ne $OldJobfiles ) {
    $DeletedJobfilesCount = Remove-FileCollection $OldJobfiles
    Write-DebugMsg "$DeletedJobfilesCount jobfile(s) deleted."
  }

  if ( $null -ne $OldLogfiles ) {
    $DeletedLogfilesCount = Remove-FileCollection $OldLogfiles
    Write-DebugMsg "$DeletedLogfilesCount logfile(s) deleted."
  }

}
