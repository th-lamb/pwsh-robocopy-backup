BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-archive-functions.ps1"
  $workingFolder = "${ProjectRoot}Pester/resources/job-archive-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6

  # ini-values
  Set-Variable -Name "COMPUTERNAME" -Option ReadOnly -Value ([System.Environment]::ExpandEnvironmentVariables("%COMPUTERNAME%"))
  $JOB_FILE_NAME_SCHEME = "${COMPUTERNAME}-Job*.RCJ"
  $JOB_LOGFILE_NAME_SCHEME = "${COMPUTERNAME}-Job*.log"
  $ARCHIVE_NAME_SCHEME = "${COMPUTERNAME}-Jobs-*.zip"
  $MAX_ARCHIVES_COUNT = 3

  # Mocking functions (https://github.com/pester/Pester/issues/1589#issuecomment-637409980)
  function Get-TestFileNames {
    $jobFile1 = "${JOB_FILE_NAME_SCHEME}".Replace("*", 1)
    $jobFile2 = "${JOB_FILE_NAME_SCHEME}".Replace("*", 2)
    $jobFile3 = "${JOB_FILE_NAME_SCHEME}".Replace("*", 3)

    $logFile1 = "${JOB_LOGFILE_NAME_SCHEME}".Replace("*", 1)
    $logFile2 = "${JOB_LOGFILE_NAME_SCHEME}".Replace("*", 2)
    $logFile3 = "${JOB_LOGFILE_NAME_SCHEME}".Replace("*", 3)

    $testFiles = New-Object System.Collections.Generic.List[System.Object]

    $testFiles.Add("${jobFile1}")
    $testFiles.Add("${jobFile2}")
    $testFiles.Add("${jobFile3}")

    $testFiles.Add("${logFile1}")
    $testFiles.Add("${logFile2}")
    $testFiles.Add("${logFile3}")

    $testFiles.ToArray()
  }

  function Get-TestArchiveNames {
    $archive1 = "${ARCHIVE_NAME_SCHEME}".Replace("*", "2000-01-01T000000")
    $archive2 = "${ARCHIVE_NAME_SCHEME}".Replace("*", "2000-01-02T000000")
    $archive3 = "${ARCHIVE_NAME_SCHEME}".Replace("*", "2000-01-03T000000")

    $testArchives = New-Object System.Collections.Generic.List[System.Object]

    $testArchives.Add("${archive1}")
    $testArchives.Add("${archive2}")
    $testArchives.Add("${archive3}")

    $testArchives.ToArray()
  }

  function Add-TestFiles {
    $testFiles = Get-TestFileNames

    for ($i = 0; $i -lt $testFiles.Count; $i++) {
      $nextFile = $testFiles[$i]
      New-Item -Path "${workingFolder}${nextFile}" -ErrorAction SilentlyContinue
    }
  }

  function Add-TestArchives {
    $testArchives = Get-TestArchiveNames

    for ($i = 0; $i -lt $testArchives.Count; $i++) {
      $nextArchive = $testArchives[$i]
      New-Item -Path "${workingFolder}${nextArchive}" -ErrorAction SilentlyContinue
    }
  }

  function Remove-TestFiles {
    $testFiles = Get-TestFileNames

    for ($i = 0; $i -lt $testFiles.Count; $i++) {
      $nextFile = $testFiles[$i]
      Remove-Item -Path "${workingFolder}${nextFile}" -ErrorAction SilentlyContinue
    }
  }

  function Remove-TestArchives {
    $testArchives = Get-TestArchiveNames

    for ($i = 0; $i -lt $testArchives.Count; $i++) {
      $nextArchive = $testArchives[$i]
      Remove-Item -Path "${workingFolder}${nextArchive}" -ErrorAction SilentlyContinue
    }
  }
}



Describe 'Export-OldJobs' {
  It 'Archives old jobfiles to a zip file.' {
    # Create test files.
    Add-TestFiles

    # Omit output within the tested function.
    Mock Write-Host {}

    # Archive the test files.
    Export-OldJobs "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

    # Check if the zip file (or *a* zip file?) exists?
    #TODO: This might fail if the next minute (even second?) starts just before we test the filename!
    #TODO: -> Store date/time before and after calling Export-OldJobs and search for an archive between these two?
    $formatted_date = Get-Date -Format "yyyy-MM-ddTHHmmss"
    $archive_name = "${ARCHIVE_NAME_SCHEME}".Replace("*", "${formatted_date}")
    $expected = "${workingFolder}${archive_name}"

    Test-Path -Path "${expected}" -PathType Leaf | Should -Be $true

    # Cleanup
    Remove-TestFiles
    Remove-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}"
  }

  It 'Deletes the old jobfiles after archiving.' {
    # Create test files.
    Add-TestFiles

    # Check if the test files exist.
    $testFiles = Get-TestFileNames
    for ($i = 0; $i -lt $testFiles.Count; $i++) {
      $nextFile = $testFiles[$i]
      Test-Path -Path "${workingFolder}${nextFile}" -PathType Leaf | Should -Be $true
    }

    # Omit output within the tested function.
    Mock Write-Host {}

    # Archive the test files.
    Export-OldJobs "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

    # Check if the test files are removed.
    for ($i = 0; $i -lt $testFiles.Count; $i++) {
      $nextFile = $testFiles[$i]
      Test-Path -Path "${workingFolder}${nextFile}" -PathType Leaf | Should -Be $false
    }

    # Cleanup
    Remove-TestFiles
    Remove-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}"
  }

  It 'Keeps the specified amount of old archives.' {
    Add-TestFiles
    Add-TestArchives

    # Store the amount of test archives.
    $old_number_of_archives = $( Get-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}" ).Length

    # Omit output within the tested function.
    Mock Write-Host {}

    # Archive the test files.
    Export-OldJobs "${workingFolder}" "${JOB_FILE_NAME_SCHEME}" "${JOB_LOGFILE_NAME_SCHEME}" "${ARCHIVE_NAME_SCHEME}" $MAX_ARCHIVES_COUNT

    # Check the amount of test archives again.
    $new_number_of_archives = $( Get-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}" ).Length

    $new_number_of_archives | Should -Be $old_number_of_archives

    # Cleanup
    Remove-TestFiles
    Remove-Item -Path "${workingFolder}${ARCHIVE_NAME_SCHEME}"
  }

#  It 'Shows the correct filename of the archive' {
#    #TODO: Use Mock ShowInfoMsg {...} to get the reported zip file's name?
#    #TODO: The archive name is written using Write-Host.
#  }
}



AfterAll {
  Remove-TestFiles
  Remove-TestArchives
}
