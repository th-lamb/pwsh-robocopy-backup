BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/filesystem-functions.ps1"
}



Describe 'Get-ExpandedPath' {
  Context 'Script variables' {
    It 'Expands script variable - at the beginning' {
      $script_variable = "C:\test1\"

      $path_spec  = "${script_variable}test2\"
      $expected   = "C:\test1\test2\"

      $result = Get-ExpandedPath "${path_spec}"
      $result | Should -Be "${expected}"
    }

    It 'Expands script variable - in the middle' {
      $script_variable = "test1"

      $path_spec  = "C:\${script_variable}\test2\"
      $expected   = "C:\test1\test2\"

      $result = Get-ExpandedPath "${path_spec}"
      $result | Should -Be "${expected}"
    }

    It 'Expands script variable - at the end' {
      $script_variable = "test2\"

      $path_spec  = "C:\test1\${script_variable}"
      $expected   = "C:\test1\test2\"

      $result = Get-ExpandedPath "${path_spec}"
      $result | Should -Be "${expected}"
    }

    It 'Expands multiple script variables' {
      $first = "C:"
      $second = "test2\"

      $path_spec  = "${first}\test1\${second}"
      $expected   = "C:\test1\test2\"

      $result = Get-ExpandedPath "${path_spec}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Environment variables' {
    It 'Expands environment variable' {
      $env_variable = "%HOMEDRIVE%"

      $path_spec  = "${env_variable}\Backup\"
      $expected   = "C:\Backup\"

      $result = Get-ExpandedPath "${path_spec}"
      $result | Should -Be "${expected}"
    }
  }

  Context '(Windows) known folders' {
    It 'Expands known folder' {
      $path_spec = "%Documents%\test\"

      $known_folder = Get-KnownFolderPath "Documents"
      $expected = "${known_folder}\test\"

      $result = Get-ExpandedPath "${path_spec}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Combinations' {
    It 'Expands combination of known folder and variable' {
      $subfolder = "test\"
      $path_spec = "%Documents%\${subfolder}"

      $known_folder = Get-KnownFolderPath "Documents"
      $expected = "${known_folder}\test\"

      $result = Get-ExpandedPath "${path_spec}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Get-ExpandedPath ""
      } | Should -Throw
    }
  }
}
