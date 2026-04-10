# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\inifile-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\inifile-functions.ps1"
}



Describe 'Get-Container' {
  Context 'Correct INI headers' {
    It 'Returns correct container for INI header [General].' {
      $IniHeader = "General"
      $expected = "General"

      $result = $(Get-Container "${IniHeader}")
      $result | Should -Be "${expected}"
    }

    It 'Returns correct container for INI header [Mandatory Directories].' {
      $IniHeader = "Mandatory Directories"
      $expected = "Directories"

      $result = $(Get-Container "${IniHeader}")
      $result | Should -Be "${expected}"
    }

    It 'Returns correct container for INI header [Directories].' {
      $IniHeader = "Directories"
      $expected = "Directories"

      $result = $(Get-Container "${IniHeader}")
      $result | Should -Be "${expected}"
    }

    It 'Returns correct container for INI header [Files].' {
      $IniHeader = "Files"
      $expected = "Files"

      $result = $(Get-Container "${IniHeader}")
      $result | Should -Be "${expected}"
    }

    It 'Returns correct container for INI header [Logging Settings].' {
      $IniHeader = "Logging Settings"
      $expected = "Logging"

      $result = $(Get-Container "${IniHeader}")
      $result | Should -Be "${expected}"
    }

    It 'Returns correct container for INI header [Job Settings].' {
      $IniHeader = "Job Settings"
      $expected = "Jobs"

      $result = $(Get-Container "${IniHeader}")
      $result | Should -Be "${expected}"
    }

    It 'Returns correct container for INI header [Archiving Settings].' {
      $IniHeader = "Archiving Settings"
      $expected = "Archiving"

      $result = $(Get-Container "${IniHeader}")
      $result | Should -Be "${expected}"
    }
  }

  Context 'Invalid Parameters' {
    It 'Throws an exception when called with an empty String.' {
      {
        Get-Container ""
      } | Should -Throw
    }

    It 'Returns $null for invalid INI headers.' {
      $result = $(Get-Container "WRONG INI HEADER")
      $result | Should -BeNullOrEmpty
    }
  }
}
