BeforeAll {
  $ProjectRoot = "${PSScriptRoot}\..\..\..\"  # Backslashes for the jobfile!
  . "${ProjectRoot}lib/job-functions.ps1"

  $workingFolder    = "${ProjectRoot}Pester\resources\job-functions\"  # Backslashes for the jobfile!
  $created_jobfiles_folder  = "${workingFolder}created_jobfiles\"
  $expected_jobfiles_folder = "${workingFolder}expected_jobfiles\"

  #TODO: Currently a global variable – not a parameter!
  $BACKUP_JOB_DIR = "${created_jobfiles_folder}"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6
}



Describe 'Add-JobFile' {
  It 'Writes a correct job file for line type: source-dir.' {
    # Parameters
    [String]$computername               = "MyComputer"
    [Int32]$current_job_num             = 1
    [String]$dirlist_entry              = "C:\foo\"
    [String]$source_dir                 = "C:\foo\"
    [String]$target_dir                 = "C:\Backup\C\foo\"
    [System.Collections.ArrayList]$included_files = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_dirs = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_files = New-Object System.Collections.ArrayList
    [System.Boolean]$copy_single_file   = $false

    # Add data to the arrays?
    #$included_files
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile  = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: source-file.' {
    # Parameters
    [String]$computername               = "MyComputer"
    [Int32]$current_job_num             = 2
    [String]$dirlist_entry              = "C:\foo\bar.txt"
    [String]$source_dir                 = "C:\foo\"
    [String]$target_dir                 = "C:\Backup\C\foo\"
    [System.Collections.ArrayList]$included_files = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_dirs = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_files = New-Object System.Collections.ArrayList
    [System.Boolean]$copy_single_file   = $true

    # Add data to the arrays?
    $included_files.Add("bar.txt")
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile  = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: source-file-pattern.' {
    # Parameters
    [String]$computername               = "MyComputer"
    [Int32]$current_job_num             = 3
    [String]$dirlist_entry              = "C:\foo\*.txt"
    [String]$source_dir                 = "C:\foo\"
    [String]$target_dir                 = "C:\Backup\C\foo\"
    [System.Collections.ArrayList]$included_files = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_dirs = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_files = New-Object System.Collections.ArrayList
    [System.Boolean]$copy_single_file   = $true

    # Add data to the arrays?
    $included_files.Add("*.txt")
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile  = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: incl-files-pattern.' {
    # Parameters
    [String]$computername               = "MyComputer"
    [Int32]$current_job_num             = 4
    [String]$dirlist_entry              = "C:\foo\"
    [String]$source_dir                 = "C:\foo\"
    [String]$target_dir                 = "C:\Backup\C\foo\"
    [System.Collections.ArrayList]$included_files = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_dirs = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_files = New-Object System.Collections.ArrayList
    [System.Boolean]$copy_single_file   = $false

    # Add data to the arrays?
    $included_files.AddRange( @("*.txt", "*.xml") )
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile  = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  #TODO: ? excl-files-pattern -> $excluded_files.Add()

  #TODO: ? excl-dirs-pattern  -> $excluded_dirs.Add()

}



AfterAll {
  #TODO: Cleanup
  #Remove-Item "${created_jobfiles_folder}*.RCJ" -ErrorAction SilentlyContinue
}
