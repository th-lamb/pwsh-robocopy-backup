BeforeAll {
  . "${PSScriptRoot}/../../../lib/filesystem-functions.ps1"

  # For messages in tested functions
  . "${PSScriptRoot}/../../../lib/message-functions.ps1"
  $__VERBOSE = 6

  # For logging in tested functions
  . "${PSScriptRoot}/../../../lib/logging-functions.ps1"
  $logfile = "${PSScriptRoot}/New-NecessaryDirectory.Tests.log"
}



Describe 'New-NecessaryDirectory' {
  Context 'Expected situations' {
    It 'Successfully creates a new directory' {
      $dir_to_create  = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/dir_to_create"

      Remove-Item "${dir_to_create}" -ErrorAction SilentlyContinue
      New-NecessaryDirectory 'Test' "${dir_to_create}" "${logfile}"
      $exists = Test-Path -Path "${dir_to_create}" -PathType Container
      Remove-Item "${dir_to_create}" -ErrorAction SilentlyContinue

      $exists | Should -Be $true
    }

    It 'Does nothing if the directory already exists' {
      $dir_to_create  = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/existing_dir"

      New-NecessaryDirectory 'Test' "${dir_to_create}" "${logfile}"
      $exists = Test-Path -Path "${dir_to_create}" -PathType Container

      $exists | Should -Be $true
    }
  }

  Context 'Unexpected situations' {
    It 'Fails if there already is a *file* with the same name' {
      $dir_to_create    = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/existing_file"
      $expected_message = "* a file or directory with the same name already exists.`""  # Using wildcard

      Mock LogAndShowMessage {}  # Omit Write-Host output within the tested function.

      {
        New-NecessaryDirectory 'Test' "${dir_to_create}" "${logfile}"
      } | Should -Throw -ExpectedMessage "${expected_message}"

      $exists = Test-Path -Path "${dir_to_create}" -PathType Container
      $exists | Should -Be $false
    }
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
