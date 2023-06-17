function ReadSettingsFile {
  param (
    [String]$ini_file
  )

  #$ini_file = $PSCommandPath -replace ".ps1", ".ini"
  $ini_file_content = Get-Content "${ini_file}"

  ForEach($line in $ini_file_content)
  {
    if (
      ($line -ne "") -and
      (! $line.StartsWith("[")) -and 
      (! $line.StartsWith(";")) -and 
      ($line.Contains("="))
    )
    {
      $var_name = ($line -split "=")[0]
      $var_value = ($line -split "=")[1]

      $expanded = expandedPath "${var_value}"

      Set-Variable -Name $var_name -Value ${expanded} -Scope script
    }
  }

  ShowDebugMsg "__VERBOSE                 : ${__VERBOSE}"
  #ShowDebugMsg "BACKUP_CONFIG_DIR         : ${BACKUP_CONFIG_DIR}"
  #ShowDebugMsg "LIB_DIR                   : ${LIB_DIR}"
  ShowDebugMsg "BACKUP_TEMPLATES_DIR      : ${BACKUP_TEMPLATES_DIR}"
  ShowDebugMsg "BACKUP_BASE_DIR           : ${BACKUP_BASE_DIR}"
  ShowDebugMsg "BACKUP_USER_BASE_DIR      : ${BACKUP_USER_BASE_DIR}"
  ShowDebugMsg "BACKUP_DIR                : ${BACKUP_DIR}"
  ShowDebugMsg "BACKUP_JOB_DIR            : ${BACKUP_JOB_DIR}"
  ShowDebugMsg "ROBOCOPY                  : ${ROBOCOPY}"
  ShowDebugMsg "ROBOCOPY_JOB_TEMPLATE_INCR: ${ROBOCOPY_JOB_TEMPLATE_INCR}"
  ShowDebugMsg "BACKUP_DIRLIST            : ${BACKUP_DIRLIST}"
  ShowDebugMsg "BACKUP_LOGFILE            : ${BACKUP_LOGFILE}"
  ShowDebugMsg "ERROR_LOGFILE             : ${ERROR_LOGFILE}"
  ShowDebugMsg "BACKUP_JOB_NAME_SCHEME    : ${BACKUP_JOB_NAME_SCHEME}"
  ShowDebugMsg "BACKUP_JOB_LOG_NAME_SCHEME: ${BACKUP_JOB_LOG_NAME_SCHEME}"
  ShowDebugMsg "ARCHIVE_NAME_SCHEME       : ${ARCHIVE_NAME_SCHEME}"
  ShowDebugMsg "MAX_ARCHIVES_COUNT        : ${MAX_ARCHIVES_COUNT}"
  #ShowDebugMsg "BACKUP_GLOBAL_EXCLUDE_DIRS_LIST : ${BACKUP_GLOBAL_EXCLUDE_DIRS_LIST}"
  #ShowDebugMsg "BACKUP_GLOBAL_EXCLUDE_FILES_LIST: ${BACKUP_GLOBAL_EXCLUDE_FILES_LIST}"
  #ShowDebugMsg "BACKUP_GLOBAL_ROBOCOPY_OPTIONS  : ${BACKUP_GLOBAL_ROBOCOPY_OPTIONS}"

}
