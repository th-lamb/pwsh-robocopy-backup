$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../..").ProviderPath
. "${ProjectRoot}\lib\job-functions.ps1"
. "${ProjectRoot}\lib\message-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../..").ProviderPath
  . "${ProjectRoot}\lib\job-functions.ps1"
  . "${ProjectRoot}\lib\message-functions.ps1"

  $workingFolder = "${ProjectRoot}\Pester\resources\lib\job-functions\"  # Backslashes for the jobfile!
  $Script:jobfile_templates_folder = "${workingFolder}jobfile_templates\"
  $Script:expected_jobfiles_folder = "${workingFolder}expected_jobfiles\"
  $Script:created_jobfiles_folder = "${workingFolder}created_jobfiles\"

  # For messages in tested functions
  $Script:__VERBOSE = 6
}



Describe 'Add-JobFile' {
  BeforeAll {
    # Copy all templates to folder $expected_jobfiles_folder, and
    # replace "<ProjectRoot>" with the current $ProjectRoot.
    $templates = Get-ChildItem -Path "${jobfile_templates_folder}*" -Include "*.RCJ" -File

    for ($i = 0; $i -lt $templates.Count; $i++) {
      $template = $templates[$i]
      $template_content = (Get-Content -Path "${template}") -join "`r`n"  # See: https://stackoverflow.com/a/15041925/5944475

      $new_jobfile = "${template}".Replace("${jobfile_templates_folder}", "${expected_jobfiles_folder}")
      $updated_content = $template_content.Replace("<ProjectRoot>", "${ProjectRoot}\")

      Set-Content -Path "${new_jobfile}" -Value "${updated_content}"
    }
  }

  It 'Writes a correct job file for line type: source-dir.' {
    # Parameters
    [String]$backup_job_dir = "${created_jobfiles_folder}"
    [String]$computername   = "MyComputer"
    [Int32]$current_job_num = 1
    [String]$dirlist_entry  = "C:\foo\"
    [String]$source_dir     = "C:\foo\"
    [String]$target_dir     = "C:\Backup\C\foo\"
    $included_files = [System.Collections.Generic.List[string]]::new()
    $excluded_dirs = [System.Collections.Generic.List[string]]::new()
    $excluded_files = [System.Collections.Generic.List[string]]::new()
    [System.Boolean]$copy_single_file = $false

    # Add data to the arrays?
    #$included_files
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${backup_job_dir}" "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: source-file.' {
    # Parameters
    [String]$backup_job_dir = "${created_jobfiles_folder}"
    [String]$computername   = "MyComputer"
    [Int32]$current_job_num = 2
    [String]$dirlist_entry  = "C:\foo\bar.txt"
    [String]$source_dir     = "C:\foo\"
    [String]$target_dir     = "C:\Backup\C\foo\"
    $included_files = [System.Collections.Generic.List[string]]::new()
    $excluded_dirs = [System.Collections.Generic.List[string]]::new()
    $excluded_files = [System.Collections.Generic.List[string]]::new()
    [System.Boolean]$copy_single_file = $true

    # Add data to the arrays?
    $included_files.Add("bar.txt")
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${backup_job_dir}" "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: source-file-pattern.' {
    # Parameters
    [String]$backup_job_dir = "${created_jobfiles_folder}"
    [String]$computername   = "MyComputer"
    [Int32]$current_job_num = 3
    [String]$dirlist_entry  = "C:\foo\*.txt"
    [String]$source_dir     = "C:\foo\"
    [String]$target_dir     = "C:\Backup\C\foo\"
    $included_files = [System.Collections.Generic.List[string]]::new()
    $excluded_dirs = [System.Collections.Generic.List[string]]::new()
    $excluded_files = [System.Collections.Generic.List[string]]::new()
    [System.Boolean]$copy_single_file = $true

    # Add data to the arrays?
    $included_files.Add("*.txt")
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${backup_job_dir}" "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: incl-files-pattern.' {
    # Parameters
    [String]$backup_job_dir = "${created_jobfiles_folder}"
    [String]$computername   = "MyComputer"
    [Int32]$current_job_num = 4
    [String]$dirlist_entry  = "C:\foo\"
    [String]$source_dir     = "C:\foo\"
    [String]$target_dir     = "C:\Backup\C\foo\"
    $included_files = [System.Collections.Generic.List[string]]::new()
    $excluded_dirs = [System.Collections.Generic.List[string]]::new()
    $excluded_files = [System.Collections.Generic.List[string]]::new()
    [System.Boolean]$copy_single_file = $false

    # Add data to the arrays?
    # Explicit cast to [string[]] is needed because AddRange expects IEnumerable[string].
    $included_files.AddRange( [string[]]@("*.txt", "*.xml") )
    #$excluded_dirs
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${backup_job_dir}" "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: excl-files-pattern.' {
    # Parameters
    [String]$backup_job_dir = "${created_jobfiles_folder}"
    [String]$computername   = "MyComputer"
    [Int32]$current_job_num = 5
    [String]$dirlist_entry  = "C:\foo\"
    [String]$source_dir     = "C:\foo\"
    [String]$target_dir     = "C:\Backup\C\foo\"
    $included_files = [System.Collections.Generic.List[string]]::new()
    $excluded_dirs = [System.Collections.Generic.List[string]]::new()
    $excluded_files = [System.Collections.Generic.List[string]]::new()
    [System.Boolean]$copy_single_file = $false

    # Add data to the arrays?
    #$included_files
    #$excluded_dirs
    # Explicit cast to [string[]] is needed because AddRange expects IEnumerable[string].
    $excluded_files.AddRange( [string[]]@("*.tmp", "*.todo") )

    # Function call with all values.
    Add-JobFile "${backup_job_dir}" "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }

  It 'Writes a correct job file for line type: excl-dirs-pattern.' {
    # Parameters
    [String]$backup_job_dir = "${created_jobfiles_folder}"
    [String]$computername   = "MyComputer"
    [Int32]$current_job_num = 6
    [String]$dirlist_entry  = "C:\foo\"
    [String]$source_dir     = "C:\foo\"
    [String]$target_dir     = "C:\Backup\C\foo\"
    $included_files = [System.Collections.Generic.List[string]]::new()
    $excluded_dirs = [System.Collections.Generic.List[string]]::new()
    $excluded_files = [System.Collections.Generic.List[string]]::new()
    [System.Boolean]$copy_single_file = $false

    # Add data to the arrays?
    #$included_files
    # Explicit cast to [string[]] is needed because AddRange expects IEnumerable[string].
    $excluded_dirs.AddRange( [string[]]@("C:\foo\.git\", "C:\foo\test\") )
    #$excluded_files

    # Function call with all values.
    Add-JobFile "${backup_job_dir}" "${computername}" $current_job_num "${dirlist_entry}" "${source_dir}" "${target_dir}" $included_files $excluded_dirs $excluded_files $copy_single_file

    # Compare the result with the template!
    $jobfile_name = "${computername}-Job${current_job_num}.RCJ"
    $created_jobfile = "${created_jobfiles_folder}${jobfile_name}"
    $expected_jobfile = "${expected_jobfiles_folder}${jobfile_name}"

    $created_jobfile_hash = (Get-FileHash "${created_jobfile}").Hash
    $expected_jobfile_hash = (Get-FileHash "${expected_jobfile}").Hash

    "${created_jobfile_hash}" | Should -Be "${expected_jobfile_hash}"
  }
}



AfterAll {
  Remove-Item "${created_jobfiles_folder}*.RCJ" -ErrorAction SilentlyContinue
  Remove-Item "${expected_jobfiles_folder}*.RCJ" -ErrorAction SilentlyContinue
}
