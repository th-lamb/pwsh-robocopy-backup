function readSettingsFile {
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

  debugMsg "__VERBOSE                 : ${__VERBOSE}"
  #debugMsg "BACKUP_CONFIG_DIR         : ${BACKUP_CONFIG_DIR}"
  #debugMsg "LIB_DIR                   : ${LIB_DIR}"
  debugMsg "BACKUP_TEMPLATES_DIR      : ${BACKUP_TEMPLATES_DIR}"
  debugMsg "BACKUP_SERVER             : ${BACKUP_SERVER}"
  debugMsg "BACKUP_SHARE              : ${BACKUP_SHARE}"
  debugMsg "BACKUP_BASE_DIR           : ${BACKUP_BASE_DIR}"
  debugMsg "BACKUP_USER_BASE_DIR      : ${BACKUP_USER_BASE_DIR}"
  debugMsg "BACKUP_DIR                : ${BACKUP_DIR}"
  debugMsg "BACKUP_JOB_DIR            : ${BACKUP_JOB_DIR}"
  debugMsg "ROBOCOPY                  : ${ROBOCOPY}"
  debugMsg "ROBOCOPY_JOB_TEMPLATE_INCR: ${ROBOCOPY_JOB_TEMPLATE_INCR}"
  debugMsg "BACKUP_DIRLIST            : ${BACKUP_DIRLIST}"
  debugMsg "BACKUP_LOGFILE            : ${BACKUP_LOGFILE}"
  debugMsg "ERROR_LOGFILE             : ${ERROR_LOGFILE}"
  debugMsg "BACKUP_JOB_NAME_SCHEME    : ${BACKUP_JOB_NAME_SCHEME}"
  debugMsg "BACKUP_JOB_LOG_NAME_SCHEME: ${BACKUP_JOB_LOG_NAME_SCHEME}"
  debugMsg "ARCHIVE_NAME_SCHEME       : ${ARCHIVE_NAME_SCHEME}"
  debugMsg "MAX_ARCHIVES_COUNT        : ${MAX_ARCHIVES_COUNT}"
  #debugMsg "BACKUP_GLOBAL_EXCLUDE_DIRS_LIST : ${BACKUP_GLOBAL_EXCLUDE_DIRS_LIST}"
  #debugMsg "BACKUP_GLOBAL_EXCLUDE_FILES_LIST: ${BACKUP_GLOBAL_EXCLUDE_FILES_LIST}"
  #debugMsg "BACKUP_GLOBAL_ROBOCOPY_OPTIONS  : ${BACKUP_GLOBAL_ROBOCOPY_OPTIONS}"

}
