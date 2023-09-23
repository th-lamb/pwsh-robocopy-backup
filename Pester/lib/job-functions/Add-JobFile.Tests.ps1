BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}\..\..\..\"  # Backslashes for the jobfile!
  Write-Host "ProjectRoot: $ProjectRoot" -ForegroundColor Yellow
  . "${ProjectRoot}lib/job-functions.ps1"

  $workingFolder    = "${ProjectRoot}Pester\resources\job-functions\"  # Backslashes for the jobfile!
  $jobfile_templates_folder = "${workingFolder}jobfile_templates\"
  $expected_jobfiles_folder = "${workingFolder}expected_jobfiles\"
  $created_jobfiles_folder  = "${workingFolder}created_jobfiles\"

  #TODO: Currently a global variable – not a parameter!
  $BACKUP_JOB_DIR = "${created_jobfiles_folder}"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6
}



Describe 'Add-JobFile' {
  BeforeAll {
    #TODO: Copy all templates to folder "expected_jobfiles".
    #TODO: Replace a placeholder with the current $workingFolder. ("simplify" the $workingFolder!)
    # - Use the Get-Content command to read a file (txt on the C drive for example). The command should be Get-Content -Path ‘C:file.txt’. Only when the file content is read, you can operate it.
    # - Use the replace operator to replace text. The command should be (Get-Content C:file.txt) -replace “old”, “new”.
    # - Use the Set-Content command to write the text to the file. The command should be Set-Content -Path ‘C:file.txt’.
  }

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
    $included_files.Add("bar.txt") > $null
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
    $included_files.Add("*.txt") > $null
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

  It 'Writes a correct job file for line type: excl-files-pattern.' {
    # Parameters
    [String]$computername               = "MyComputer"
    [Int32]$current_job_num             = 5
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
    $excluded_files.AddRange( @("*.tmp", "*.todo") )

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

  It 'Writes a correct job file for line type: excl-dirs-pattern.' {
    # Parameters
    [String]$computername               = "MyComputer"
    [Int32]$current_job_num             = 6
    [String]$dirlist_entry              = "C:\foo\"
    [String]$source_dir                 = "C:\foo\"
    [String]$target_dir                 = "C:\Backup\C\foo\"
    [System.Collections.ArrayList]$included_files = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_dirs = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$excluded_files = New-Object System.Collections.ArrayList
    [System.Boolean]$copy_single_file   = $false

    # Add data to the arrays?
    #$included_files
    $excluded_dirs.AddRange( @("C:\foo\.git\", "C:\foo\test\") )
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
}



AfterAll {
  Remove-Item "${created_jobfiles_folder}*.RCJ" -ErrorAction SilentlyContinue
  #TODO: cleanup expected_jobfiles_folder
  #Remove-Item "${expected_jobfiles_folder}*.RCJ" -ErrorAction SilentlyContinue
}
