BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/job-archive-functions.ps1"
  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/job-archive-functions/Get-LastDateTime testfiles/"
}



Describe 'Get-LastDateTime' {
  Context 'Correctly used' {
    <# Test files:
      ${workingFolder}/Get-LastDateTime testfiles/...
        ...first.txt
        ...last.txt     <--- youngest file
        ...second.txt
    #>

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

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Get-LastDateTime ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty array.' {
      $empty_array = New-Object System.Collections.ArrayList

      {
        Get-LastDateTime $empty_array
      } | Should -Throw
    }

    It 'Throws an exception when called with $null.' {
      {
        Get-LastDateTime $null
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
