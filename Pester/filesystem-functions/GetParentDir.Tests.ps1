BeforeAll {
  . $PSScriptRoot/../../lib/filesystem-functions.ps1

  # For messages and logging in tested functions
  . $PSScriptRoot/../../lib/message-functions.ps1
  $__VERBOSE = 6

  # For dirlistLineType()
  . $PSScriptRoot/../../lib/job-functions.ps1
  $logfile = "${PSScriptRoot}/GetParentDir.Tests.log"
}



Describe 'getParentDir' {
  Context 'no placeholders' {
    It 'returns parent folder for existing file' {
      $path_spec  = "${PSScriptRoot}\test_files\Test1\test.ini"
      $expected   = "${PSScriptRoot}\test_files\Test1\"

      $parent_dir = getParentDir "${path_spec}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns parent folder for non-existing file' {
      $pattern  = "${PSScriptRoot}\test_files\Test1\test.xml"
      $expected = "${PSScriptRoot}\test_files\Test1\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns the drive for a short path' {
      $pattern  = "C:\test\"
      $expected = "C:\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns an empty value for a too short path' {
      $pattern  = "C:\"
      $expected = ""

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }
  }

  Context 'filename patterns' {
    It 'returns parent folder for pattern with 1 matching file' {
      $pattern  = "${PSScriptRoot}\test_files\Test1\test*.ini"
      $expected = "${PSScriptRoot}\test_files\Test1\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns parent folder for pattern with 2 or more matching files' {
      $pattern  = "${PSScriptRoot}\test_files\Test1\test*.txt"
      $expected = "${PSScriptRoot}\test_files\Test1\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns parent folder for pattern with no matching file' {
      $pattern  = "${PSScriptRoot}\test_files\Test1\test*.xml"
      $expected = "${PSScriptRoot}\test_files\Test1\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }
  }

  Context 'directory patterns' {
    #TODO: Use dirlistLineType() or not?
    # -> Error: invalid: source directory pattern
    # -> The Backup checks the line type first.

    It 'returns path with placeholder for dir pattern with 1 matching *directory*' {
      $pattern  = "${PSScriptRoot}\test_files\Tes*1\test.ini"
      $expected = "${PSScriptRoot}\test_files\Tes*1\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns path with placeholder for dir pattern with 2 or more matching *directories*' {
      $pattern  = "${PSScriptRoot}\test_files\Test*\test.ini"
      $expected = "${PSScriptRoot}\test_files\Test*\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns path with placeholder for dir and file pattern with matching files in different directories' {
      $pattern  = "${PSScriptRoot}\test_files\Test*\test*.ini"
      $expected = "${PSScriptRoot}\test_files\Test*\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }
  }

  Context 'directory entries' {
    It 'returns the parent path for . (link to the current dir)' {
      $pattern  = "${PSScriptRoot}\test_files\Test1\."
      $expected = "${PSScriptRoot}\test_files\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns the parents parent path for .. (link to the parent dir)' {
      $pattern  = "${PSScriptRoot}\test_files\Test1\.."
      $expected = "${PSScriptRoot}\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns path with placeholder for dir pattern and .' {
      $pattern  = "${PSScriptRoot}\test_files\Test*\."
      $expected = "${PSScriptRoot}\test_files\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns path with placeholder for dir pattern and ..' {
      $pattern  = "${PSScriptRoot}\test_files\Test*\.."
      $expected = "${PSScriptRoot}\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns the drive for a short path and .' {
      $pattern  = "C:\test\."
      $expected = "C:\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns the drive for a short path and ..' {
      $pattern  = "C:\test1\test2\.."
      $expected = "C:\"

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns an empty value for a too short path and .' {
      $pattern  = "C:\."
      $expected = ""

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }

    It 'returns an empty value for a too short path and ..' {
      $pattern  = "C:\test\.."
      $expected = ""

      $parent_dir = getParentDir "${pattern}"
      "${parent_dir}" | Should -eq "${expected}"
    }
  }
}
