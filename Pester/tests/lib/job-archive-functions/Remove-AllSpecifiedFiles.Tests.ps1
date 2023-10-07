BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/job-archive-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/job-archive-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6
}



Describe 'Remove-AllSpecifiedFiles' {
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

      # Call Remove-AllSpecifiedFiles with that array.
      Mock Write-Host {}  # Omit output within the tested function.
      Remove-AllSpecifiedFiles $files_to_delete

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

      # Call Remove-AllSpecifiedFiles with that array.
      Mock Write-Host {}  # Omit output within the tested function.
      $result = Remove-AllSpecifiedFiles $files_to_delete

      # Test
      $result | Should -Be 3
    }
  }

  Context 'Wrong Usage' {
    # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.3#null-or-empty

    It 'Throws an exception when called with a null value.' {
      {
        Remove-AllSpecifiedFiles $null
      } | Should -Throw
    }

    It 'Writes a warning when called with an empty collection.' {
      Mock Write-WarningMsg {} -Verifiable

      Remove-AllSpecifiedFiles @()
      Should -Invoke -CommandName "Write-WarningMsg" -Times 1 -Exactly
    }

    It 'Returns 0 when called with an empty collection.' {
      Mock Write-WarningMsg {}

      $result = Remove-AllSpecifiedFiles @()
      $result | Should -Be 0
    }

    It 'Does not call Remove-Item when called with an empty collection.' {
      Mock Write-WarningMsg {}
      Mock Remove-Item {} -Verifiable

      Remove-AllSpecifiedFiles @()
      Should -Invoke -CommandName "Remove-Item" -Times 0
    }

    It 'Throws an exception when called with an empty String.' {
      Mock Write-Error {} -Verifiable

      {
        Remove-AllSpecifiedFiles ""
      } | Should -Throw "Parameter files_to_delete equals an empty String!"
    }

    #TODO: Throws an exception when called without parameter.
#    It 'Throws an exception when called without parameter.' {
#      {
#        Remove-AllSpecifiedFiles
#      } | Should -Throw
#    }
  }
}



AfterAll {
  Remove-Item "${workingFolder}testfile1" -ErrorAction SilentlyContinue
  Remove-Item "${workingFolder}testfile2" -ErrorAction SilentlyContinue
  Remove-Item "${workingFolder}testfile3" -ErrorAction SilentlyContinue
}
