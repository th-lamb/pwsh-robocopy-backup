BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-archive-functions.ps1"
  $workingFolder = "${ProjectRoot}Pester/resources/job-archive-functions/"
}



Describe 'Remove-AllFilesInArray' {
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
    $files_to_delete.Add("${workingFolder}testfile1")
    $files_to_delete.Add("${workingFolder}testfile2")
    $files_to_delete.Add("${workingFolder}testfile3")

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
    $files_to_delete.Add("${workingFolder}testfile1")
    $files_to_delete.Add("${workingFolder}testfile2")
    $files_to_delete.Add("${workingFolder}testfile3")

    # Call Remove-AllFilesInArray with that array.
    Mock Write-Host {}  # Omit output within the tested function.
    $result = Remove-AllFilesInArray $files_to_delete

    # Test
    $result | Should -Be 3
  }
}



AfterAll {
  Remove-Item "${workingFolder}testfile1" -ErrorAction SilentlyContinue
  Remove-Item "${workingFolder}testfile2" -ErrorAction SilentlyContinue
  Remove-Item "${workingFolder}testfile3" -ErrorAction SilentlyContinue
}
