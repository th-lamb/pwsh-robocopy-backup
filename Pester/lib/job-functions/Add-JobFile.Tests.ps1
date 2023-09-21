BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-functions.ps1"
  $workingFolder = "${ProjectRoot}Pester/resources/job-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6
}



#- Use
#  - FileContentMatch?                       (https://pester.dev/docs/v4/usage/assertions#filecontentmatch)
#  - Or FileContentMatchMultiline?           (https://pester.dev/docs/v4/usage/assertions#filecontentmatchmultiline)
#  - Or better PowerShell's Compare-Object?  (https://devblogs.microsoft.com/scripting/use-powershell-to-compare-two-files/)
#    -> "a better way to do this is to use Get-FileHash and compare the HASH property."

Describe 'Add-JobFile' {
  It 'Writes a correct job file for a single file.' {
    #TODO: Currently not a parameter!
    $BACKUP_JOB_DIR = "${workingFolder}"

    # Parameters
    #[String]$computername,
    [Int32]$current_job_num
    [String]$dirlist_entry
    [String]$source_dir
    [String]$target_dir
    [System.Collections.ArrayList]$included_files = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_dirs = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_files = New-Object System.Collections.ArrayList
    [System.Boolean]$copy_single_file

    # Actual values
    Set-Variable -Name "COMPUTERNAME" -Option ReadOnly -Value ([System.Environment]::ExpandEnvironmentVariables("%COMPUTERNAME%"))
    $current_job_num  = 1
    $dirlist_entry    = "C:\cygwin64\Cygwin.ico"
    $source_dir       = "C:\cygwin64\"
    $target_dir       = "C:\Backup\C\cygwin64\"
    $included_files.Add("Cygwin.ico")
    #$excluded_dirs
    #$excluded_files
    $copy_single_file = $true

    # Function call with all values.
    Add-JobFile `
      "${COMPUTERNAME}" `
      $current_job_num `
      "${dirlist_entry}" `
      "${source_dir}" `
      "${target_dir}" `
      $included_files `
      $excluded_dirs `
      $excluded_files `
      $copy_single_file

    #TODO: Create a template!
    #TODO: Compare the result!
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
  #TODO: Cleanup
}
