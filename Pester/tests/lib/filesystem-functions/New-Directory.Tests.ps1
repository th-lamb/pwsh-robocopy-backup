BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/filesystem-functions/"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $Script:__VERBOSE = 6

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  $Script:logfile = "${workingFolder}New-Directory.Tests.log"
}



Describe 'New-Directory' {
  Context 'Expected situations' {
    It 'Successfully creates a new directory' {
      $dir_to_create  = "${workingFolder}dir_to_create"

      Remove-Item "${dir_to_create}" -ErrorAction SilentlyContinue
      New-Directory 'Test' "${dir_to_create}" "${logfile}"
      $exists = Test-Path -Path "${dir_to_create}" -PathType Container
      Remove-Item "${dir_to_create}" -ErrorAction SilentlyContinue

      $exists | Should -Be $true
    }

    It 'Does nothing if the directory already exists' {
      $dir_to_create  = "${workingFolder}existing_dir"

      New-Directory 'Test' "${dir_to_create}" "${logfile}"
      $exists = Test-Path -Path "${dir_to_create}" -PathType Container

      $exists | Should -Be $true
    }
  }

  Context 'Unexpected situations' {
    It 'Fails if there already is a *file* with the same name' {
      $dir_to_create    = "${workingFolder}existing_file"
      $expected_message = "* a file or directory with the same name already exists.`""  # Using wildcard

      Mock LogAndShowMessage {}

      {
        New-Directory 'Test' "${dir_to_create}" "${logfile}"
      } | Should -Throw -ExpectedMessage "${expected_message}"

      $exists = Test-Path -Path "${dir_to_create}" -PathType Container
      $exists | Should -Be $false
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty definition_name.' {
      {
        New-Directory ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty path.' {
      {
        New-Directory 'Test' ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an empty logfile.' {
      $dir_to_create  = "${workingFolder}existing_dir"

      {
        New-Directory 'Test' "${dir_to_create}" ""
      } | Should -Throw
    }
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
