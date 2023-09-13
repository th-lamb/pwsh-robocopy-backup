BeforeAll {
  . "${PSScriptRoot}/../../lib/filesystem-functions.ps1"

  # For messages in tested functions
  . $PSScriptRoot/../../lib/message-functions.ps1
  $__VERBOSE = 5  # Reduced to 5 because CreateNecessaryFile writes an INFO message.

  # For logging in tested functions
  . $PSScriptRoot/../../lib/logging-functions.ps1
  $logfile = "${PSScriptRoot}/CreateNecessaryFile.Tests.log"
}



Describe 'CreateNecessaryFile' {
  Context 'Expected situations' {
    It 'Successfully creates a copy of the specified file' {
      $file_to_be_created = "${PSScriptRoot}/test_files/file_to_be_created.txt"
      $template_file      = "${PSScriptRoot}/test_files/template_file.txt"

      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue
      CreateNecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      $exists = Test-Path -Path "${file_to_be_created}" -PathType Leaf
      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue

      $exists | Should -be $true
    }

    It 'Returns $true after successful copying' {
      $file_to_be_created = "${PSScriptRoot}/test_files/file_to_be_created.txt"
      $template_file      = "${PSScriptRoot}/test_files/template_file.txt"

      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue
      $return_value = CreateNecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue

      $return_value | Should -Be $true
    }

    It 'Does nothing if the file already exists' {
      $file_to_be_created = "${PSScriptRoot}/test_files/existing_file"
      $template_file      = "${PSScriptRoot}/test_files/template_file.txt"

      $return_value = CreateNecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"

      $return_value | Should -Be $false
    }
  }

  Context 'Unexpected situations' {
    It 'Fails if there already is a *directory* with the same name' {
      #TODO: Copy-Item doesn't warn if it failed because a directory with the same name exists!
      $file_to_be_created = "${PSScriptRoot}/test_files/existing_dir"
      $template_file      = "${PSScriptRoot}/test_files/template_file.txt"
      #$expected_message = "* a file or directory with the same name already exists.`""

      {
        $return_value = CreateNecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
        Write-Host "return_value: $return_value" -ForegroundColor Yellow

        $exists = Test-Path -Path "${file_to_be_created}" -PathType Leaf
        Write-Host "exists: $exists" -ForegroundColor Yellow

      } | Should -Throw # -ExpectedMessage "${expected_message}"

      $exists = Test-Path -Path "${file_to_be_created}" -PathType Leaf
      $exists | Should -be $false
    }
  }
}



AfterAll {
  #TODO: Delete the logfile?
}
