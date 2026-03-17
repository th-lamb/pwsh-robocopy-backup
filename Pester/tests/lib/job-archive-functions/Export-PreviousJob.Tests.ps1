BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/job-archive-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/job-archive-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6

  # ini-values
  Set-Variable -Name "COMPUTERNAME" -Option ReadOnly -Value ([System.Environment]::ExpandEnvironmentVariables("%COMPUTERNAME%"))
  $JOB_FILE_NAME_SCHEME = "${COMPUTERNAME}-Job*.RCJ"
  $JOB_LOGFILE_NAME_SCHEME = "${COMPUTERNAME}-Job*.log"
  $ARCHIVE_NAME_SCHEME = "${COMPUTERNAME}-Jobs-*.zip"
  $Script:MAX_ARCHIVES_COUNT = 3

  # Mocking functions (https://github.com/pester/Pester/issues/1589#issuecomment-637409980)
  function Get-TestFilenameSet {
    $jobFile1 = "${JOB_FILE_NAME_SCHEME}".Replace("*", 1)
    $jobFile2 = "${JOB_FILE_NAME_SCHEME}".Replace("*", 2)
    $jobFile3 = "${JOB_FILE_NAME_SCHEME}".Replace("*", 3)

    $logFile1 = "${JOB_LOGFILE_NAME_SCHEME}".Replace("*", 1)
    $logFile2 = "${JOB_LOGFILE_NAME_SCHEME}".Replace("*", 2)
    $logFile3 = "${JOB_LOGFILE_NAME_SCHEME}".Replace("*", 3)

    $testFiles = New-Object System.Collections.Generic.List[System.Object]

    $testFiles.Add("${jobFile1}") > $null
    $testFiles.Add("${jobFile2}") > $null
    $testFiles.Add("${jobFile3}") > $null

    $testFiles.Add("${logFile1}") > $null
    $testFiles.Add("${logFile2}") > $null
    $testFiles.Add("${logFile3}") > $null

    $testFiles.ToArray()
  }

  function Get-TestArchiveNameSet {
    $archive1 = "${ARCHIVE_NAME_SCHEME}".Replace("*", "2000-01-01T000000")
    $archive2 = "${ARCHIVE_NAME_SCHEME}".Replace("*", "2000-01-02T000000")
    $archive3 = "${ARCHIVE_NAME_SCHEME}".Replace("*", "2000-01-03T000000")

    $testArchives = New-Object System.Collections.Generic.List[System.Object]

    $testArchives.Add("${archive1}") > $null
    $testArchives.Add("${archive2}") > $null
    $testArchives.Add("${archive3}") > $null

    $testArchives.ToArray()
  }

  function Add-TestFileSet {
    $testFiles = Get-TestFilenameSet

    for ($i = 0; $i -lt $testFiles.Count; $i++) {
      $nextFile = $testFiles[$i]
      New-Item -Path "${workingFolder}${nextFile}" -ErrorAction SilentlyContinue
    }
  }

  function Add-TestArchiveSet {
    $testArchives = Get-TestArchiveNameSet

    for ($i = 0; $i -lt $testArchives.Count; $i++) {
      $nextArchive = $testArchives[$i]
      New-Item -Path "${workingFolder}${nextArchive}" -ErrorAction SilentlyContinue
    }
  }

  function Remove-TestFileSet {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param()
    $testFiles = Get-TestFilenameSet

    for ($i = 0; $i -lt $testFiles.Count; $i++) {
      $nextFile = $testFiles[$i]
      Remove-Item -Path "${workingFolder}${nextFile}" -ErrorAction SilentlyContinue
    }
  }
}



Describe 'Export-PreviousJob' {
  Context 'Correctly used' {
    BeforeEach {
      Remove-TestFileSet
      Remove-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}"
    }

    It 'Archives old jobfiles to a zip file.' {
      # Create test files.
      Add-TestFileSet

      # Get the expected timestamp from the actual files created
      $testFiles = Get-ChildItem -Path "${workingFolder}*" -Include "${JOB_FILE_NAME_SCHEME}" -File
      $last_datetime = ($testFiles | Sort-Object -Descending -Property LastWriteTime)[0].LastWriteTime.GetDateTimeFormats('s').Replace(":","")
      $archive_name = "${ARCHIVE_NAME_SCHEME}".Replace("*", "${last_datetime}")
      $expected = "${workingFolder}${archive_name}"

      # Omit output within the tested function.
      Mock Write-Host {}

      # Archive the test files.
      Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

      # Check if the zip file exists.
      Test-Path -Path "${expected}" -PathType Leaf | Should -Be $true
    }

    It 'Deletes the old jobfiles after archiving.' {
      # Create test files.
      Add-TestFileSet

      # Check if the test files exist.
      $testFiles = Get-TestFilenameSet
      for ($i = 0; $i -lt $testFiles.Count; $i++) {
        $nextFile = $testFiles[$i]
        Test-Path -Path "${workingFolder}${nextFile}" -PathType Leaf | Should -Be $true
      }

      # Omit output within the tested function.
      Mock Write-Host {}

      # Archive the test files.
      Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

      # Check if the test files are removed.
      for ($i = 0; $i -lt $testFiles.Count; $i++) {
        $nextFile = $testFiles[$i]
        Test-Path -Path "${workingFolder}${nextFile}" -PathType Leaf | Should -Be $false
      }
    }

    It 'Keeps the specified amount of old archives.' {
      Add-TestFileSet
      Add-TestArchiveSet

      # Store the amount of test archives.
      $old_number_of_archives = $( Get-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}" ).Length

      # Omit output within the tested function.
      Mock Write-Host {}

      # Archive the test files.
      Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

      # Check the amount of test archives again.
      $new_number_of_archives = $( Get-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}" ).Length

      $new_number_of_archives | Should -Be $old_number_of_archives
    }

#    It 'Shows the correct filename of the archive' {
#      #TODO: Use Mock Write-InfoMsg {...} to get the reported zip file's name?
#      #TODO: The archive name is written using Write-Host.
#    }

    AfterAll {
      # Cleanup
      Remove-TestFileSet
      Remove-Item -Path "${workingFolder}*.zip" -ErrorAction SilentlyContinue
    }
  }

  Context 'Wrong Usage' {
    #TODO: Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

    It 'Throws an exception when called with an empty backup_job_dir.' {
      {
        Export-PreviousJob ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty job_name_scheme.' {
      {
        Export-PreviousJob "${workingFolder}" ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty job_log_name_scheme.' {
      {
        Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty archive_name_scheme.' {
      {
        Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an invalid max_archives_count.' {
      {
        Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" -1
      } | Should -Throw

      {
        Export-PreviousJob "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" "a"
      } | Should -Throw
    }

    #TODO: Throws an exception when called without parameter.
#    It 'Throws an exception when called without parameter.' {
#      {
#        Get-LastDateTime
#      } | Should -Throw
#    }
  }
}



AfterAll {
  # Cleanup
  Remove-TestFileSet
  Remove-Item -Path "${workingFolder}*.zip" -ErrorAction SilentlyContinue
}
