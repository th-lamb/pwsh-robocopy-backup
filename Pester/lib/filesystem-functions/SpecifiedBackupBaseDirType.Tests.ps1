BeforeAll {
  . "${PSScriptRoot}/../../../lib/filesystem-functions.ps1"
}



Describe 'SpecifiedBackupBaseDirType' {
  Context 'BACKUP_BASE_DIR types' {
    It 'Relative path' {
      $path_spec  = "Backup\"
      $expected   = "relative path"

      $object_type = SpecifiedBackupBaseDirType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'Drive letter' {
      $path_spec  = "C:"
      $expected   = "drive letter"

      $object_type = SpecifiedBackupBaseDirType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'Local path' {
      $path_spec  = "C:\Backup\"
      $expected   = "directory"

      $object_type = SpecifiedBackupBaseDirType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'Network computer' {
      $path_spec  = "\\fileserver"
      $expected   = "network computer"

      $object_type = SpecifiedBackupBaseDirType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'Network share' {
      $path_spec  = "\\fileserver\Backup"
      $expected   = "network share"

      $object_type = SpecifiedBackupBaseDirType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }

    It 'Network folder' {
      $path_spec  = "\\fileserver\Backup\foo\"
      $expected   = "directory"

      $object_type = SpecifiedBackupBaseDirType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }

  Context 'Syntax errors etc.' {
    It 'recognizes an empty string' {
      $path_spec  = ""
      $expected   = "empty string"

      $object_type = SpecifiedBackupBaseDirType "${path_spec}"
      "${object_type}" | Should -eq "${expected}"
    }
  }
}
