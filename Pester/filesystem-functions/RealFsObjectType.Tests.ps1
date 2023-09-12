BeforeAll {
  . "${PSScriptRoot}/../../lib/filesystem-functions.ps1"
}



Describe 'RealFsObjectType' {
  BeforeDiscovery {
    . "${PSScriptRoot}/../../lib/filesystem-functions.ps1"
    $skip_network_share_subfolder = ! ( FolderExists "\\NODE304" )
  }

  Context 'Existing directories/files' {
    It 'recognizes existing directory                       e.g. C:\Users\...\Music\' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes existing directory with placeholder (*)  e.g. C:\Users\...\Mu*ic\' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic\"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes existing file                            e.g. C:\Users\...\Music\title1.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title1.mp3"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes existing file with placeholders          e.g. C:\Users\...\Music\title*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title*.mp3"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    #TODO: recognizes hidden files with patterns
    # -> "C:\Users\*.ini"
    # -> Currently not working: https://github.com/PowerShell/PowerShell/issues/6473
  }

  Context 'non-existent directories/files' {
    It 'recognizes non-existent directory                   e.g. C:\Users\...\Music2\' {
      $path_spec  = "${PSScriptRoot}\test_files\Music2\"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes non-existent directory with placeholder  e.g. C:\Users\...\Mu*ic2\' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic2\"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes non-existent file                        e.g. C:\Users\...\Music\title0.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title0.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes non-existent file with placeholder       e.g. C:\Users\...\Music\title0*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title0*.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Placeholders in both, directory and filename' {
    It 'recognizes existing directory and file              e.g. C:\Users\...\Mu*ic\title1*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic\title1*.mp3"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes non-existent directory                   e.g. C:\Users\...\Mu*ic2\title1*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic2\title1*.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes non-existent file                        e.g. C:\Users\...\Mu*ic\title0*.mp3' {
      $path_spec  = "${PSScriptRoot}\test_files\Mu*ic\title0*.mp3"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Type mismatch' {
    It 'recognizes folder defined as file (no trailing \)   e.g. C:\Users\...\Music' {
      $path_spec  = "${PSScriptRoot}\test_files\Music"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes file defined as folder (trailing \)      e.g. C:\Users\...\Music\title1.mp3\' {
      $path_spec  = "${PSScriptRoot}\test_files\Music\title1.mp3\"
      $expected   = "file"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Drive letters' {
    It 'recognizes existing drive letter without \          e.g. C:' {
      $path_spec  = "C:"
      $expected   = "drive letter"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes existing drive letter with \             e.g. C:\' {
      $path_spec  = "C:\"
      $expected   = "drive letter"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes non-existent drive letter without \      e.g. Z:' {
      $path_spec  = "Z:"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes non-existent drive letter with \         e.g. Z:\' {
      $path_spec  = "Z:\"
      $expected   = $false

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Network shares' {
    It 'recognizes network share with trailing backslash' {
      $path_spec  = "\\NODE304\Backup\"
      $expected   = "network share"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes network share without trailing backslash' {
      $path_spec  = "\\NODE304\Backup"
      $expected   = "network share"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    #TODO: Skip if not in the correct network?
    It 'recognizes subfolder of a network share' -Skip:$skip_network_share_subfolder {
      $path_spec  = "\\NODE304\Backup\win-backup\"
      $expected   = "directory"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    #TODO: File on a network share
#    It 'recognizes file on a network share' {
#      $path_spec  = "\\NODE304\Backup\..."
#      $expected   = "file"
#
#      $object_type = RealFsObjectType "${path_spec}"
#      "${object_type}" | Should -eq "${expected}"
#    }
  }

  Context 'Network computer' {
    It 'recognizes network computer with trailing backslash' {
      $path_spec  = "\\NODE304\"
      $expected   = "network computer"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'recognizes network computer without trailing backslash' {
      $path_spec  = "\\NODE304"
      $expected   = "network computer"

      $object_type = RealFsObjectType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }
}
