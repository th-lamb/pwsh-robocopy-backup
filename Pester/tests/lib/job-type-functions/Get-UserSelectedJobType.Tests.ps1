$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\job-type-functions.ps1"
. "${ProjectRoot}\lib\logging-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\job-type-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}\Pester\resources\lib\job-type-functions\"

  $Script:DefaultJob = "Incremental"
  # For logging in tested functions (mandatory parameter)
  $Script:logfile = "${workingFolder}Get-UserSelectedJobType.Tests.log"

  Mock _showJobTypeList {}
  Mock Add-LogMessage {
    # $Script:used_severity = $Severity
    # $Script:used_message = $Message
  } #-Verifiable
}



Describe 'Get-UserSelectedJobType' {
  Context 'User selects a job type' {
    It 'User selects: [I]    Incremental' {
      $KeyToPress     = "I"
      $KeyToPressCher = 'i'
      $expected       = "Incremental"

      # 1. Create the fake 'I' key press
      $keyPress = [pscustomobject]@{
        Key       = [ConsoleKey]::$KeyToPress
        Character = [char]$KeyToPressCher
      }

      # 2. Mock the wrapper to return our fake key
      Mock Get-ConsoleKeyInfo { return $keyPress }

      # 3. Mock Start-Sleep so the 1-second timeout doesn't actually slow down the test
      Mock Start-Sleep {}
      Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }

    It 'User selects: [F]    Full backup' {
      $KeyToPress     = "F"
      $KeyToPressCher = 'f'
      $expected       = "Full"

      $keyPress = [pscustomobject]@{
        Key       = [ConsoleKey]::$KeyToPress
        Character = [char]$KeyToPressCher
      }

      Mock Get-ConsoleKeyInfo { return $keyPress }
      Mock Start-Sleep {}
      Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }

    It 'User selects: [P]    Purge' {
      $KeyToPress     = "P"
      $KeyToPressCher = 'p'
      $expected       = "Purge"

      $keyPress = [pscustomobject]@{
        Key       = [ConsoleKey]::$KeyToPress
        Character = [char]$KeyToPressCher
      }

      Mock Get-ConsoleKeyInfo { return $keyPress }
      Mock Start-Sleep {}
      Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }

    It 'User selects: [A]    Files with Archive attribute' {
      $KeyToPress     = "A"
      $KeyToPressCher = 'a'
      $expected       = "Archive"

      $keyPress = [pscustomobject]@{
        Key       = [ConsoleKey]::$KeyToPress
        Character = [char]$KeyToPressCher
      }

      Mock Get-ConsoleKeyInfo { return $keyPress }
      Mock Start-Sleep {}
      Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }

    It 'User selects: [S]    Start (use the default)' {
      $KeyToPress     = "S"
      $KeyToPressCher = 's'
      $expected       = "Incremental"

      $keyPress = [pscustomobject]@{
        Key       = [ConsoleKey]::$KeyToPress
        Character = [char]$KeyToPressCher
      }

      Mock Get-ConsoleKeyInfo { return $keyPress }
      Mock Start-Sleep {}
      Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }
  }

  Context 'Default values' {
    It 'Returns default if the user does NOT press any key' {
      $expected = "Incremental"

      # Simulate no key ever being pressed.
      # Mock Get-ConsoleKeyInfo { return $null }
      # Mock Start-Sleep {} # Still mock this so the test is fast!
      # Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }

    It 'Returns default if the user presses ENTER' { #-Skip:$true {
      $expected = "Incremental"

      $keyPress = [pscustomobject]@{
        Key       = [ConsoleKey]::Enter
        KeyChar   = [char]13
        Modifiers = 0
      }

      Mock Get-ConsoleKeyInfo { return $keyPress }
      Mock Start-Sleep {}
      Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }
  }

  Context 'User cancels' {
    It 'User selects: [ESC]  Cancel' {
      $expected = "Cancel"

      $keyPress = [pscustomobject]@{
        Key       = [ConsoleKey]::Escape
        KeyChar   = [char]27
      }

      Mock Get-ConsoleKeyInfo { return $keyPress }
      Mock Start-Sleep {}
      Mock Write-Host {}

      $result = Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS 1
      $result | Should -Be "${expected}"
    }
  }
}



AfterAll {
  # Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
