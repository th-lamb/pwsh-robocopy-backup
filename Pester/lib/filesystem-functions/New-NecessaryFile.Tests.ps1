BeforeAll {
  . "${PSScriptRoot}/../../../lib/filesystem-functions.ps1"

  # For messages in tested functions
  . "${PSScriptRoot}/../../../lib/message-functions.ps1"
  $__VERBOSE = 5  # Reduced to 5 because New-NecessaryFile writes an INFO message.

  # For logging in tested functions
  . "${PSScriptRoot}/../../../lib/logging-functions.ps1"
  $logfile = "${PSScriptRoot}/New-NecessaryFile.Tests.log"
}



Describe 'New-NecessaryFile' {
  Context 'Expected situations' {
    It 'Successfully creates a copy of the specified file' {
      $file_to_be_created = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/file_to_be_created.txt"
      $template_file      = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/template_file.txt"

      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue
      New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      $exists = Test-Path -Path "${file_to_be_created}" -PathType Leaf
      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue

      $exists | Should -Be $true
    }

    It 'Returns $true after successful copying' {
      $file_to_be_created = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/file_to_be_created.txt"
      $template_file      = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/template_file.txt"

      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue
      $return_value = New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue

      $return_value | Should -Be $true
    }

    It 'Does nothing if the file already exists' {
      $file_to_be_created = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/existing_file"
      $template_file      = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/template_file.txt"

      $return_value = New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"

      $return_value | Should -Be $false
    }
  }

  Context 'Unexpected situations' {
    It 'Fails if there already is a *directory* with the same name' {
      $file_to_be_created = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/existing_dir"
      $template_file      = "${PSScriptRoot}/../../resources/test_files/filesystem-functions/template_file.txt"

      {
        New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      } | Should -Throw

      $exists = Test-Path -Path "${file_to_be_created}" -PathType Leaf
      $exists | Should -Be $false
    }
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
