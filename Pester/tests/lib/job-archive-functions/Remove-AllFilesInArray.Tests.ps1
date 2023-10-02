BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/job-archive-functions.ps1"
  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/job-archive-functions/"
}



Describe 'Remove-AllFilesInArray' {
  Context 'Correctly used' {
    It 'Removes all files specified in array.' {
      # Create 3 test files.
      New-Item -Path "${workingFolder}testfile1" -ErrorAction SilentlyContinue
      New-Item -Path "${workingFolder}testfile2" -ErrorAction SilentlyContinue
      New-Item -Path "${workingFolder}testfile3" -ErrorAction SilentlyContinue

      Test-Path "${workingFolder}testfile1" -PathType Leaf | Should -Be $true
      Test-Path "${workingFolder}testfile2" -PathType Leaf | Should -Be $true
      Test-Path "${workingFolder}testfile3" -PathType Leaf | Should -Be $true

      # Add them to an array.
      $files_to_delete = New-Object System.Collections.ArrayList
      $files_to_delete.Add("${workingFolder}testfile1") > $null
      $files_to_delete.Add("${workingFolder}testfile2") > $null
      $files_to_delete.Add("${workingFolder}testfile3") > $null

      # Call Remove-AllFilesInArray with that array.
      Mock Write-Host {}  # Omit output within the tested function.
      Remove-AllFilesInArray $files_to_delete

      # Test
      Test-Path "${workingFolder}testfile1" -PathType Leaf | Should -Be $false
      Test-Path "${workingFolder}testfile2" -PathType Leaf | Should -Be $false
      Test-Path "${workingFolder}testfile3" -PathType Leaf | Should -Be $false
    }

    It 'Returns the number of removed files.' {
      # Create 3 test files.
      New-Item -Path "${workingFolder}testfile1" -ErrorAction SilentlyContinue
      New-Item -Path "${workingFolder}testfile2" -ErrorAction SilentlyContinue
      New-Item -Path "${workingFolder}testfile3" -ErrorAction SilentlyContinue

      Test-Path "${workingFolder}testfile1" -PathType Leaf | Should -Be $true
      Test-Path "${workingFolder}testfile2" -PathType Leaf | Should -Be $true
      Test-Path "${workingFolder}testfile3" -PathType Leaf | Should -Be $true

      # Add them to an array.
      $files_to_delete = New-Object System.Collections.ArrayList
      $files_to_delete.Add("${workingFolder}testfile1") > $null
      $files_to_delete.Add("${workingFolder}testfile2") > $null
      $files_to_delete.Add("${workingFolder}testfile3") > $null

      # Call Remove-AllFilesInArray with that array.
      Mock Write-Host {}  # Omit output within the tested function.
      $result = Remove-AllFilesInArray $files_to_delete

      # Test
      $result | Should -Be 3
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Remove-AllFilesInArray ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty array.' {
      $empty_array = New-Object System.Collections.ArrayList

      {
        Remove-AllFilesInArray $empty_array
      } | Should -Throw
    }

    #TODO: Throws an exception when called without parameter.
#    It 'Throws an exception when called without parameter.' {
#      {
#        Remove-AllFilesInArray
#      } | Should -Throw
#    }
  }
}



AfterAll {
  Remove-Item "${workingFolder}testfile1" -ErrorAction SilentlyContinue
  Remove-Item "${workingFolder}testfile2" -ErrorAction SilentlyContinue
  Remove-Item "${workingFolder}testfile3" -ErrorAction SilentlyContinue
}
