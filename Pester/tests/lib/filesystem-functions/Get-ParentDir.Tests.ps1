$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../..").ProviderPath
. "${ProjectRoot}\lib\filesystem-functions.ps1"
. "${ProjectRoot}\lib\message-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../..").ProviderPath
  . "${ProjectRoot}\lib\filesystem-functions.ps1"
  . "${ProjectRoot}\lib\message-functions.ps1"
  $Script:workingFolder = "${ProjectRoot}\Pester\resources\lib\filesystem-functions\"

  # For messages and logging in tested functions
  $Script:__VERBOSE = 6
}



Describe 'Get-ParentDir' {
  Context 'no placeholders' {
    It 'returns parent folder for existing file' {
      $path_spec  = "${workingFolder}existing_dir\existing_file"
      $expected   = "${workingFolder}existing_dir\"

      $FSobject = Get-ParentDir "${path_spec}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns parent folder for non-existent file' {
      $path_spec  = "${workingFolder}existing_dir\non_existent_file"
      $expected   = "${workingFolder}existing_dir\"

      $FSobject = Get-ParentDir "${path_spec}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns parent folder for file in non-existent folder' {
      $path_spec  = "${workingFolder}non_existent_dir\some_file"
      $expected   = "${workingFolder}non_existent_dir\"

      $FSobject = Get-ParentDir "${path_spec}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns the drive for a short path' {
      $path_spec  = "C:\test\"
      $expected   = "C:\"

      $FSobject = Get-ParentDir "${path_spec}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns an empty value for a too short path' {
      $path_spec  = "C:\"
      $expected   = ""

      $FSobject = Get-ParentDir "${path_spec}"
      ${FSobject}.Path | Should -Be "${expected}"
    }
  }

  Context 'filename patterns' {
    It 'returns parent folder for pattern with 1 matching file' {
      $pattern  = "${workingFolder}Test1\test*.ini"
      $expected = "${workingFolder}Test1\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns parent folder for pattern with 2 or more matching files' {
      $pattern  = "${workingFolder}Test1\test*.txt"
      $expected = "${workingFolder}Test1\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns parent folder for pattern with no matching file' {
      $pattern  = "${workingFolder}Test1\test*.xml"
      $expected = "${workingFolder}Test1\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }
  }

  Context 'directory patterns' {
    #TODO: Use Get-DirlistLineType() or not?
    # -> Error: invalid: source directory pattern
    # -> The Backup checks the line type first.

    It 'returns path with placeholder for dir pattern with 1 matching *directory*' {
      $pattern  = "${workingFolder}Tes*1\test.ini"
      $expected = "${workingFolder}Tes*1\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir pattern with 2 or more matching *directories*' {
      $pattern  = "${workingFolder}Test*\test.ini"
      $expected = "${workingFolder}Test*\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir and file pattern with matching files in different directories' {
      $pattern  = "${workingFolder}Test*\test*.ini"
      $expected = "${workingFolder}Test*\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }
  }

  Context 'directory entries' {
    It 'returns the parent path for . (link to the current dir)' {
      $pattern  = "${workingFolder}Test1\."
      $expected = "${workingFolder}"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns the parents parent path for .. (link to the parent dir)' {
      $pattern  = "${workingFolder}Test1\.."
      $expected = "${ProjectRoot}\Pester\resources\lib\"   # Parent of $workingFolder

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir pattern and .' {
      $pattern  = "${workingFolder}Test*\."
      $expected = "${workingFolder}"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns path with placeholder for dir pattern and ..' {
      $pattern  = "${workingFolder}Test*\.."
      $expected = "${ProjectRoot}\Pester\resources\lib\"   # Parent of $workingFolder

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns the drive for a short path and .' {
      $pattern  = "C:\test\."
      $expected = "C:\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns the drive for a short path and ..' {
      $pattern  = "C:\test1\test2\.."
      $expected = "C:\"

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns an empty value for a too short path and .' {
      $pattern  = "C:\."
      $expected = ""

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns an empty value for a too short path and ..' {
      $pattern  = "C:\.."
      $expected = ""

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }

    It 'returns an empty value for a too short path and ..' {
      $pattern  = "C:\test\.."
      $expected = ""

      $FSobject = Get-ParentDir "${pattern}"
      ${FSobject}.Path | Should -Be "${expected}"
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Get-ParentDir ""
      } | Should -Throw
    }
  }
}
