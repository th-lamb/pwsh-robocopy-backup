BeforeAll {
  . "${PSScriptRoot}/../../lib/filesystem-functions.ps1"
}



Describe 'RealFsObjectType' {
  Context 'Existing directories/files' {
    It 'A1  existing directory                        e.g. C:\Users\...\Music\' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'A2  existing directory with placeholders (*)  e.g. C:\Users\...\Mu*ic\' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic\"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'A3  existing file                             e.g. C:\Users\...\Music\title1.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title1.mp3"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'A4  existing file with placeholders           e.g. C:\Users\...\Music\title*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title*.mp3"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    #TODO: A5  hidden files with patterns
    # -> "C:\Users\*.ini"
    # -> Currently not working: https://github.com/PowerShell/PowerShell/issues/6473
  }

  Context 'Non-existing directories/files' {
    It 'B1  non-existing directory                    e.g. C:\Users\...\Music2\' {
      $path_spec  = "${PSScriptRoot}\test_files\Music2\"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'B2  non-existing directory with placeholders  e.g. C:\Users\...\Mu*ic2\' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic2\"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'B3  non-existing file                         e.g. C:\Users\...\Music\title0.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title0.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'B4  non-existing file with placeholders       e.g. C:\Users\...\Music\title0*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title0*.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Placeholders in both, directory and filename' {
    It 'C1  existing directory and file               e.g. C:\Users\...\Mu*ic\title1*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic\title1*.mp3"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'C2  non-existing directory                    e.g. C:\Users\...\Mu*ic2\title1*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic2\title1*.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'C3  non-existing file                         e.g. C:\Users\...\Mu*ic\title0*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic\title0*.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Type mismatch' {
    It 'D1  folder defined as file (no trailing "\")  e.g. C:\Users\...\Music' {
      $path_spec  = "${PSScriptRoot}\test_files\Music"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'D2  file defined as folder (trailing "\")     e.g. C:\Users\...\Music\title1.mp3\' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title1.mp3\"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Drive letters' {
    It 'E1  existing drive letter without trailing "\"      e.g. C:' {
      $path_spec  = "C:"
      $expected   = "drive letter"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'E2  existing drive letter with trailing "\"         e.g. C:\' {
      $path_spec  = "C:\"
      $expected   = "drive letter"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'E3  non-existing drive letter without trailing "\"  e.g. Z:' {
      $path_spec  = "Z:"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'E4  non-existing drive letter with trailing "\"     e.g. Z:\' {
      $path_spec  = "Z:\"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Network shares' {
    It 'F1  Network share with trailing backslash' {
      $path_spec  = "\\NODE304\Backup\"
      $expected   = "network share"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'F2  Network share without trailing backslash' {
      $path_spec  = "\\NODE304\Backup"
      $expected   = "network share"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'F3  Subfolder of a network share' {
      $path_spec  = "\\NODE304\Backup\win-backup\"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    #TODO: File on a network share
#    It 'F4  File on a network share' {
#      $path_spec  = "\\NODE304\Backup\..."
#      $expected   = "file"
#
#      $object_type = RealFsObjectType "${path_spec}"
#      "${object_type}" | Should -eq "${expected}"
#    }
  }

  Context 'Network computer' {
    It 'G1  Network computer with trailing backslash' {
      $path_spec  = "\\NODE304\"
      $expected   = "network computer"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'G2  Network computer without trailing backslash' {
      $path_spec  = "\\NODE304"
      $expected   = "network computer"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }
}
