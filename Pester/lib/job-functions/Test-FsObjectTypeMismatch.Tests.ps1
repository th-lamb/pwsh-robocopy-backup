BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-functions.ps1"

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  #$logfile = "${PSScriptRoot}/Test-FsObjectTypeMismatch.Tests.log"
}



Describe 'Test-FsObjectTypeMismatch' {
  Context 'Matching object types' {
    It 'A directory matches an expected directory.' {
      $specified_type = "directory"
      $existing_type = "directory"
      $expected = "match"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'A directory matches an expected directory pattern.' {
      $specified_type = "directory pattern"
      $existing_type = "directory"
      $expected = "match"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'A file matches an expected file.' {
      $specified_type = "file"
      $existing_type = "file"
      $expected = "match"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'A file matches an expected file pattern.' {
      $specified_type = "file pattern"
      $existing_type = "file"
      $expected = "match"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Non-existent objects' {
    It 'Non-existent directory = missing' {
      $specified_type = "directory"
      $existing_type = $false
      $expected = "missing"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Non-existent directory pattern = missing' {
      $specified_type = "directory pattern"
      $existing_type = $false
      $expected = "missing"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Non-existent file = missing' {
      $specified_type = "file"
      $existing_type = $false
      $expected = "missing"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Non-existent file pattern = missing' {
      $specified_type = "file pattern"
      $existing_type = $false
      $expected = "missing"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Type mismatch' {
    It 'A file does not match an expected directory' {
      $specified_type = "directory"
      $existing_type = "file"
      $expected = "type mismatch"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'A directory does not match an expected file' {
      $specified_type = "file"
      $existing_type = "directory"
      $expected = "type mismatch"

      $result = Test-FsObjectTypeMismatch "${specified_type}" "${existing_type}" "${logfile}"
      $result | Should -Be "${expected}"
    }
  }

  #TODO: Directory entries ("." and "..")? -> Should not be needed because omitted earlier.
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
