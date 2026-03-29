$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\network-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\network-functions.ps1"
  . "${ProjectRoot}\lib\filesystem-functions.ps1"
  $Script:workingFolder = "${ProjectRoot}\Pester/resources/lib/filesystem-functions/"
}



Describe 'Get-RealFsObjectType' {
  BeforeDiscovery {
    #$available = Test-Connection -BufferSize 32 -Count 1 -ComputerName "Server" -Quiet
    #$Script:skip_network_share_subfolder = !$available
    #Write-Host "skip_network_share_subfolder: $skip_network_share_subfolder" -ForegroundColor Yellow
  }

  Context 'Existing directories/files' {
    It 'recognizes existing directory                       e.g. C:\Users\...\Music\' {
      $path_spec  = "${workingFolder}Music/"
      $expected   = "directory"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes existing directory with placeholder (*)  e.g. C:\Users\...\Mu*ic\' {
      $path_spec  = "${workingFolder}Mu*ic/"
      $expected   = "directory"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes existing file                            e.g. C:\Users\...\Music\title1.mp3' {
      $path_spec  = "${workingFolder}Music/title1.mp3"
      $expected   = "file"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes existing file with placeholders          e.g. C:\Users\...\Music\title*.mp3' {
      $path_spec  = "${workingFolder}Music/title*.mp3"
      $expected   = "file"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes hidden file with placeholders            e.g. C:\Users\*.ini' {
      $path_spec  = "${workingFolder}Users/*.ini"
      $expected   = "file"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }
  }

  Context 'non-existent directories/files' {
    It 'recognizes non-existent directory                   e.g. C:\Users\...\Music2\' {
      $path_spec      = "${workingFolder}Music2/"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }

    It 'recognizes non-existent directory with placeholder  e.g. C:\Users\...\Mu*ic2\' {
      $path_spec      = "${workingFolder}Mu*ic2/"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }

    It 'recognizes non-existent file                        e.g. C:\Users\...\Music\title0.mp3' {
      $path_spec      = "${workingFolder}Music/title0.mp3"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }

    It 'recognizes non-existent file with placeholder       e.g. C:\Users\...\Music\title0*.mp3' {
      $path_spec      = "${workingFolder}Music/title0*.mp3"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }

    It 'explicitly returns Type = $null for a non-existent file (no wildcard)' {
      $path_spec  = "C:\ThisPathDefinitelyDoesNotExist.txt"
      $result     = Get-RealFsObjectType "${path_spec}"

      $result.Exists | Should -Be $false
      $result.Type | Should -Be $null
    }

    It 'explicitly returns Type = $null for a non-existent pattern (with wildcard)' {
      $path_spec  = "${workingFolder}NoMatch*.xyz"
      $result     = Get-RealFsObjectType "${path_spec}"

      $result.Exists | Should -Be $false
      $result.Type | Should -Be $null
    }
  }

  Context 'Placeholders in both, directory and filename' {
    It 'recognizes existing directory and file              e.g. C:\Users\...\Mu*ic\title1*.mp3' {
      $path_spec  = "${workingFolder}Mu*ic/title1*.mp3"
      $expected   = "file"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes non-existent directory                   e.g. C:\Users\...\Mu*ic2\title1*.mp3' {
      $path_spec      = "${workingFolder}Mu*ic2/title1*.mp3"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }

    It 'recognizes non-existent file                        e.g. C:\Users\...\Mu*ic\title0*.mp3' {
      $path_spec      = "${workingFolder}Mu*ic/title0*.mp3"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }
  }

  Context 'Type mismatch' {
    It 'recognizes folder defined as file (no trailing \)   e.g. C:\Users\...\Music' {
      $path_spec  = "${workingFolder}Music"
      $expected   = "directory"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes file defined as folder (trailing \)      e.g. C:\Users\...\Music\title1.mp3\' {
      $path_spec  = "${workingFolder}Music/title1.mp3/"
      $expected   = "file"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }
  }

  Context 'Drive letters' {
    It 'recognizes existing drive letter without \          e.g. C:' {
      $path_spec  = "C:"
      $expected   = "drive letter"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes existing drive letter with \             e.g. C:\' {
      $path_spec  = "C:\"
      $expected   = "drive letter"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes non-existent drive letter without \      e.g. Z:' {
      $path_spec      = "Z:"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }

    It 'recognizes non-existent drive letter with \         e.g. Z:\' {
      $path_spec      = "Z:\"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }
  }

  Context 'Network shares' {
    BeforeAll {
      # Portability: allow the test to run on other computers in any network.
      # Mock behavior: for directories/shares, return $true unless explicitly asking for a 'Leaf' (file).
      Mock Test-Path {
        if ($PathType -eq "Leaf") { return $false }
        return $true
      } -ParameterFilter {
        $Path -eq "\\Server\Backup\" -or
        $Path -eq "\\Server\Backup" -or
        $Path -eq "\\Server\Backup\win-backup\"
      }

      # Mock behavior: for files, return $true unless explicitly asking for a 'Container' (folder).
      Mock Test-Path {
        if ($PathType -eq "Container") { return $false }
        return $true
      } -ParameterFilter { $Path -eq "\\Server\Backup\file.txt" }

      # Don't wait for a network timeout (which can take 20-60 seconds).
      Mock Test-Path { return $false } -ParameterFilter { $Path -eq "\\NonExistent\Share" }
    }

    It 'recognizes network share with trailing backslash' {
      $path_spec  = "\\Server\Backup\"
      $expected   = "network share"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes network share without trailing backslash' {
      $path_spec  = "\\Server\Backup"
      $expected   = "network share"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes non-existent network share' {
      $path_spec      = "\\NonExistent\Share"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }

    It 'recognizes subfolder of a network share' {
      $path_spec  = "\\Server\Backup\win-backup\"
      $expected   = "directory"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes file on a network share' {
      $path_spec  = "\\Server\Backup\file.txt"
      $expected   = "file"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }
  }

  Context 'Network computer' {
    BeforeAll {
      Mock Test-ServerIsAvailable { return $true } -ParameterFilter { $server_path_spec -eq "\\Server\" -or $server_path_spec -eq "\\Server" }
      Mock Test-ServerIsAvailable { return $false } -ParameterFilter { $server_path_spec -eq "\\NonExistentServer\" -or $server_path_spec -eq "\\NonExistentServer" }
    }

    It 'recognizes network computer with trailing backslash' {
      $path_spec  = "\\Server\"
      $expected   = "network computer"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes network computer without trailing backslash' {
      $path_spec  = "\\Server"
      $expected   = "network computer"

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Type | Should -Be "${expected}"
    }

    It 'recognizes non-existent network computer' {
      $path_spec      = "\\NonExistentServer"
      $expectedExists = $false

      $object_type = Get-RealFsObjectType "${path_spec}"
      ${object_type}.Exists | Should -Be "${expectedExists}"
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Get-RealFsObjectType ""
      } | Should -Throw
    }
  }
}
