BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
  $script:workingFolder = "${ProjectRoot}Pester/resources/filesystem-functions/"
}



Describe 'Get-SpecifiedFsObjectType' {
  Context 'Directories/files without patterns' {
    It 'recognizes a directory                              e.g. C:\Users\...\Music\' {
      $path_spec  = "${workingFolder}Music\"
      $expected   = "directory"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes a file                                   e.g. C:\Users\...\Music\title1.mp3' {
      $path_spec  = "${workingFolder}Music\title1.mp3"
      $expected   = "file"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }
  }

  Context 'Directories/files with patterns' {
    It 'recognizes a directory pattern                      e.g. C:\Users\...\Mu*ic\' {
      $path_spec  = "${workingFolder}Mu*ic\"
      $expected   = "directory pattern"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes a file pattern                           e.g. C:\Users\...\Music\title*.mp3' {
      $path_spec  = "${workingFolder}Music\title*.mp3"
      $expected   = "file pattern"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }
  }

  Context 'Placeholders in both, directory and filename' {
    It 'recognizes a directory pattern                      e.g. C:\Users\...\Mu*ic\title*.mp3' {
      $path_spec  = "${workingFolder}Mu*ic\title*.mp3"
      $expected   = "directory pattern"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }
  }

  Context 'Syntax errors etc.' {
    It 'recognizes an empty string' {
      $path_spec  = ""
      $expected   = "empty string"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes Known Folder without first %             e.g. UserProfile%\' {
      $path_spec  = "UserProfile%\"
      $expected   = "directory"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes files in Known Folder without first %    e.g. UserProfile%\.gitconfig' {
      $path_spec  = "UserProfile%\.gitconfig"
      $expected   = "file"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }
  }

  Context 'Drive letters' {
    It 'recognizes existing drive letter without \          e.g. C:' {
      $path_spec  = "C:"
      $expected   = "drive letter"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes existing drive letter with \             e.g. C:\' {
      $path_spec  = "C:\"
      $expected   = "drive letter"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }
  }

  Context 'Network shares' {
    It 'recognizes network share with trailing backslash' {
      $path_spec  = "\\NODE304\Backup\"
      $expected   = "network share"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes network share without trailing backslash' {
      $path_spec  = "\\NODE304\Backup"
      $expected   = "network share"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes subfolder of a network share' {
      $path_spec  = "\\NODE304\Backup\win-backup\"
      $expected   = "directory"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    #TODO: File on a network share
#    It 'recognizes file on a network share' {
#      $path_spec  = "\\NODE304\Backup\backup-thomas-ThinkPad-T420s.sh"
#      $expected   = "file"
#
#      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
#      "${object_type}" | Should -Be "${expected}"
#    }
  }

  Context 'Network computer' {
    It 'recognizes network computer with trailing backslash' {
      $path_spec  = "\\NODE304\"
      $expected   = "network computer"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes network computer without trailing backslash' {
      $path_spec  = "\\NODE304"
      $expected   = "network computer"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }
  }

  Context '"." and ".." entries' {
    It 'recognizes "." (current folder)' {
      $path_spec  = "C:\Users\<...>\Music\."
      $expected   = "directory entry"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }

    It 'recognizes ".." (parent folder)' {
      $path_spec  = "C:\Users\<...>\Music\.."
      $expected   = "directory entry"

      $object_type = Get-SpecifiedFsObjectType "${path_spec}"
      "${object_type}" | Should -Be "${expected}"
    }
  }
}
