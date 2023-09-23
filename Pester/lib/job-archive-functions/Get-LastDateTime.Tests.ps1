BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-archive-functions.ps1"
  $script:workingFolder = "${ProjectRoot}Pester/resources/job-archive-functions/test LastDateTime/"
}



<# Test files:
${workingFolder}/test LastDateTime/...
  ...first.txt
  ...last.txt     <--- youngest file
  ...second.txt
#>

Describe 'Get-LastDateTime' {
  It 'Finds the last saved file.' {
    $last_file_name = "last.txt"

    $expected_file = Get-ChildItem -Path "${workingFolder}${last_file_name}" -File
    $expected_date_time = $expected_file.LastWriteTime.GetDateTimeFormats('s').Replace(":","")

    [System.Collections.ArrayList]$file_list
    $file_list = Get-ChildItem -Path "${workingFolder}*" -File

    $result = Get-LastDateTime $file_list
    $result | Should -Be $expected_date_time
  }
}
