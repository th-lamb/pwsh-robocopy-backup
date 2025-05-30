BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 5  # Reduced to 5 because New-NecessaryFile writes an INFO message.

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  $Script:logfile = "${workingFolder}New-NecessaryFile.Tests.log"
}



Describe 'New-NecessaryFile' {
  Context 'Expected situations' {
    It 'Successfully creates a copy of the specified file' {
      $file_to_be_created = "${workingFolder}file_to_be_created.txt"
      $template_file      = "${workingFolder}template_file.txt"

      Mock LogAndShowMessage {}

      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue
      New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      $exists = Test-Path -Path "${file_to_be_created}" -PathType Leaf
      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue

      $exists | Should -Be $true
    }

    It 'Returns $true after successful copying' {
      $file_to_be_created = "${workingFolder}file_to_be_created.txt"
      $template_file      = "${workingFolder}template_file.txt"

      Mock LogAndShowMessage {}

      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue
      $return_value = New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      Remove-Item "${file_to_be_created}" -ErrorAction SilentlyContinue

      $return_value | Should -Be $true
    }

    It 'Does nothing if the file already exists' {
      $file_to_be_created = "${workingFolder}existing_file"
      $template_file      = "${workingFolder}template_file.txt"

      $return_value = New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"

      $return_value | Should -Be $false
    }
  }

  Context 'Unexpected situations' {
    It 'Fails if there already is a *directory* with the same name' {
      $file_to_be_created = "${workingFolder}existing_dir"
      $template_file      = "${workingFolder}template_file.txt"

      Mock LogAndShowMessage {}

      {
        New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" "${logfile}"
      } | Should -Throw

      $exists = Test-Path -Path "${file_to_be_created}" -PathType Leaf
      $exists | Should -Be $false
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty definition_name.' {
      {
        New-NecessaryFile ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty path.' {
      {
        New-NecessaryFile 'Test' ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty template.' {
      $file_to_be_created = "${workingFolder}file_to_be_created.txt"

      {
        New-NecessaryFile 'Test' "${file_to_be_created}" ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty logfile.' {
      $file_to_be_created = "${workingFolder}file_to_be_created.txt"
      $template_file      = "${workingFolder}template_file.txt"

      {
        New-NecessaryFile 'Test' "${file_to_be_created}" "${template_file}" ""
      } | Should -Throw
    }
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
