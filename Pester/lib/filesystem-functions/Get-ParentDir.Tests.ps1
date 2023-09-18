BeforeAll {
  $ProjectRoot = "${PSScriptRoot}\..\..\..\"  # Backslashes because PS functions return backslashes.
  . "${ProjectRoot}lib/filesystem-functions.ps1"

  # For messages and logging in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6
}



Describe 'Get-ParentDir' {
  Context 'no placeholders' {
    It 'returns parent folder for existing file' {
      $path_spec  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\test.ini"
      $expected   = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\"

      $parent_dir = Get-ParentDir "${path_spec}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns parent folder for non-existent file' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\test.xml"
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns the drive for a short path' {
      $pattern  = "C:\test\"
      $expected = "C:\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns an empty value for a too short path' {
      $pattern  = "C:\"
      $expected = ""

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }
  }

  Context 'filename patterns' {
    It 'returns parent folder for pattern with 1 matching file' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\test*.ini"
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns parent folder for pattern with 2 or more matching files' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\test*.txt"
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns parent folder for pattern with no matching file' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\test*.xml"
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }
  }

  Context 'directory patterns' {
    #TODO: Use dirlistLineType() or not?
    # -> Error: invalid: source directory pattern
    # -> The Backup checks the line type first.

    It 'returns path with placeholder for dir pattern with 1 matching *directory*' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Tes*1\test.ini"
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Tes*1\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir pattern with 2 or more matching *directories*' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test*\test.ini"
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test*\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir and file pattern with matching files in different directories' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test*\test*.ini"
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test*\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }
  }

  Context 'directory entries' {
    It 'returns the parent path for . (link to the current dir)' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\."
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns the parents parent path for .. (link to the parent dir)' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test1\.."
      $expected = "${ProjectRoot}\Pester\resources\test_files\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir pattern and .' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test*\."
      $expected = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir pattern and ..' {
      $pattern  = "${ProjectRoot}\Pester\resources\test_files\filesystem-functions\Test*\.."
      $expected = "${ProjectRoot}\Pester\resources\test_files\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns the drive for a short path and .' {
      $pattern  = "C:\test\."
      $expected = "C:\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns the drive for a short path and ..' {
      $pattern  = "C:\test1\test2\.."
      $expected = "C:\"

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns an empty value for a too short path and .' {
      $pattern  = "C:\."
      $expected = ""

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }

    It 'returns an empty value for a too short path and ..' {
      $pattern  = "C:\test\.."
      $expected = ""

      $parent_dir = Get-ParentDir "${pattern}"
      "${parent_dir}" | Should -Be "${expected}"
    }
  }
}
