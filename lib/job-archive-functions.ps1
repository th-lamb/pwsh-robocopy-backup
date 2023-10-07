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
# - Remove-AllFilesInArray()
# - Get-LastDateTime()
#
################################################################################

#TODO: Add logging - not only console messages!

function Remove-AllFilesInArray {
  # Deletes all files specified in the ArrayList and returns the number of deleted files.
  [OutputType([System.Int32])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [AllowEmptyCollection()]
    [System.Collections.ArrayList]$files_to_delete
  )

  [Int32]$num_files_deleted = 0

  foreach ($file_to_delete in $files_to_delete) {
    Write-Host "${file_to_delete}" -ForegroundColor DarkRed
    Remove-Item "${file_to_delete}"
    $num_files_deleted = ($num_files_deleted + 1)
  }

  $num_files_deleted

}

function Get-LastDateTime {
  <# Returns the date/time of the latest (youngest) file in the specified list;
    or "" if the list is empty.
  #>
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [System.Collections.ArrayList]$file_list
  )

  if ($file_list.Count -eq 0) {
    return ""
  }

  $last_file = ($file_list | Sort-Object -Descending -Property LastWriteTime)[0]
  $last_datetime = $last_file.LastWriteTime.GetDateTimeFormats('s').Replace(":","")

  $last_datetime

}

function Export-OldJobs {
  # Archives old jobfiles (zip file) and then deletes them.
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$backup_job_dir,
    [Parameter(Mandatory=$true)]
    [String]$job_name_scheme,
    [Parameter(Mandatory=$true)]
    [String]$job_log_name_scheme,
    [Parameter(Mandatory=$true)]
    [String]$archive_name_scheme,
    [Parameter(Mandatory=$true)]
    [System.Byte]$max_archives_count  # 0..255
  )

  Write-DebugMsg "Export-OldJobs(${backup_job_dir}, ${job_name_scheme}, ${job_log_name_scheme}, ${archive_name_scheme}, $max_archives_count)"

  # Get all old jobfiles.
  $old_jobfiles = New-Object System.Collections.ArrayList
  $old_jobfiles = Get-ChildItem -Path "${backup_job_dir}*" -Include "${job_name_scheme}" -File

  $old_logfiles = New-Object System.Collections.ArrayList
  $old_logfiles = Get-ChildItem -Path "${backup_job_dir}*" -Include "${job_log_name_scheme}" -File

  # Continue if they exist.
  $old_jobfiles_count = $old_jobfiles.Count
  $old_logfiles_count = $old_logfiles.Count
  Write-DebugMsg "old_jobfiles_count: $old_jobfiles_count"
  Write-DebugMsg "old_logfiles_count: $old_logfiles_count"

  if (
    ($old_jobfiles_count -eq 0) -and
    ($old_logfiles_count -eq 0)
  ) {
    Write-DebugMsg "No old jobs to archive."
    return
  }

  # Find all existing (0..n) archives.
  $old_archives = New-Object System.Collections.ArrayList
  $old_archives = Get-ChildItem -Path "${backup_job_dir}*" -Include "${archive_name_scheme}" -File

  # Delete the oldest archive if it exists.
  $old_archives_count = $old_archives.Count
  Write-DebugMsg "old_archives_count: $old_archives_count"

  if ($old_archives_count -lt $max_archives_count) {
    Write-DebugMsg "$old_archives_count job archive(s) (MAX=$max_archives_count), just archiving the existing jobs."
  } else {
    Write-InfoMsg "$old_archives_count job archives (MAX=$max_archives_count), deleting the oldest one(s)."

    $old_archives = $old_archives | Sort-Object -Descending
    for ($i = $max_archives_count - 1; $i -lt $old_archives.Count; $i++) {
      $archive_to_delete = $old_archives[$i]
      $archive_name = Split-Path -Leaf "${archive_to_delete}"
      Write-InfoMsg "Deleting job archive ${archive_name}"

      Write-Host "${archive_to_delete}" -ForegroundColor DarkRed
      Remove-Item "$archive_to_delete"
    }
  }

  # Determine the name of the new archive. (Use date and time of the jobfiles?)
  # Get date/time from the logfiles if there were no jobfiles.
  $last_datetime = Get-LastDateTime $old_jobfiles

  if ("${last_datetime}" -eq "") {
    $last_datetime = Get-LastDateTime $old_logfiles
  }

  Write-DebugMsg "Last job's date/time: ${last_datetime}"

  # Archive the jobs (jobfile and logfile).
  $archive_name = "${archive_name_scheme}".Replace("*", "${last_datetime}")
  $archive_path = "${backup_job_dir}${archive_name}"
  Write-DebugMsg "archive_name: ${archive_name}"
  Write-DebugMsg "archive_path: ${archive_path}"
  Write-InfoMsg "Archiving old jobs in ${archive_name}"

  Compress-Archive -Path "${backup_job_dir}${job_name_scheme}" -DestinationPath "${archive_path}" -Force        # -Force to overwrite if needed.
  # Update the archive only if logfiles exist! Otherwise the archive gets deleted.
  if ($old_logfiles_count -gt 0) {
    Compress-Archive -Path "${backup_job_dir}${job_log_name_scheme}" -Update -DestinationPath "${archive_path}"   # -Update to add.
  }
  Write-Host "${archive_path}" -ForegroundColor DarkGreen

  # Delete the jobs.
  Write-DebugMsg "Deleting old jobs..."

  if ( $null -ne $old_jobfiles ) {
    $num_jobfiles_deleted = Remove-AllFilesInArray $old_jobfiles
    Write-DebugMsg "$num_jobfiles_deleted jobfile(s) deleted."
  }

  if ( $null -ne $old_logfiles ) {
    $num_logfiles_deleted = Remove-AllFilesInArray $old_logfiles
    Write-DebugMsg "$num_logfiles_deleted logfile(s) deleted."
  }
}
