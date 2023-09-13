BeforeAll {
  . "${PSScriptRoot}/../../lib/filesystem-functions.ps1"

  # For messages in tested functions
  . $PSScriptRoot/../../lib/message-functions.ps1
  $__VERBOSE = 6

  # For logging in tested functions
  . $PSScriptRoot/../../lib/logging-functions.ps1
  $logfile = "${PSScriptRoot}/CreateNecessaryDirectory.Tests.log"
}



Describe 'CreateNecessaryDirectory' {
  Context 'Expected situations' {
    It 'Successfully creates a new directory' {
      $dir_to_create  = "${PSScriptRoot}/test_files/dir_to_create"

      Remove-Item "${dir_to_create}" -ErrorAction SilentlyContinue
      CreateNecessaryDirectory 'Test' "${dir_to_create}" "${logfile}"
      $exists = Test-Path -Path "${dir_to_create}" -PathType Container
      Remove-Item "${dir_to_create}" -ErrorAction SilentlyContinue

      $exists | Should -be $true
    }

    It 'Does nothing if the directory already exists' {
      $dir_to_create  = "${PSScriptRoot}/test_files/existing_dir"

      CreateNecessaryDirectory 'Test' "${dir_to_create}" "${logfile}"
      $exists = Test-Path -Path "${dir_to_create}" -PathType Container

      $exists | Should -be $true
    }
  }

  Context 'Unexpected situations' {
    It 'Fails if there already is a *file* with the same name' {
      # Backslashes to match the text of the exception thrown by [System.IO.Directory]::CreateDirectory!
      $dir_to_create    = "${PSScriptRoot}\test_files\existing_file"
      $expected_message = "Exception calling `"CreateDirectory`" with `"1`" argument(s): `"Cannot create '${dir_to_create}' because a file or directory with the same name already exists.`""

      {
        CreateNecessaryDirectory 'Test' "${dir_to_create}" "${logfile}"
      } | Should -Throw -ExpectedMessage "${expected_message}"

      $exists = Test-Path -Path "${dir_to_create}" -PathType Container
      $exists | Should -be $false
    }
  }
}
