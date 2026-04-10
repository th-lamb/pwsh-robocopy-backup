$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\job-type-functions.ps1"
. "${ProjectRoot}\lib\logging-functions.ps1"
. "${ProjectRoot}\lib\message-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\job-type-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"
  . "${ProjectRoot}\lib\message-functions.ps1"

  $script:workingFolder = "${ProjectRoot}\Pester\resources\lib\job-type-functions\"

  $script:DefaultJob = "Incremental"

  # For logging in tested functions (mandatory parameter) - but should not be written to because we use Mocks.
  $script:logfile = "${workingFolder}Get-UserSelectedJobType.Tests.log"

  Mock _showJobTypeList {}
  Mock Add-LogMessage {
    # $script:used_severity = $Severity
    # $script:used_message = $Message
  } #-Verifiable
}



Describe 'Get-UserSelectedJobType' {
  BeforeEach {
    # Pester 5 runs each It block in an isolated module scope that does not inherit
    # Set-StrictMode from the enclosing script or Describe block.
    # BeforeEach is the only place where Set-StrictMode reliably applies inside It blocks.
    Set-StrictMode -Version Latest
  }

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
    It 'Checks for a pressed key every 100 ms' {
      [int32]$NumberOfSeconds = 10
      [int32]$NumberOfChecks  = 100

      # Simulate no key being pressed.
      Mock Get-ConsoleKeyInfo {}

      # Mock Write-Host to suppress output.
      Mock Write-Host {}

      # Mock Start-Sleep so the test runs instantly.
      Mock Start-Sleep {}

      # Call with specified number of seconds.
      Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS $NumberOfSeconds

      # Assert number of checks.
      Assert-MockCalled Get-ConsoleKeyInfo -Exactly -Times $NumberOfChecks
    }

    It 'Draws a dot for every second of waiting time' {
      [int32]$NumberOfSeconds = 10
      [int32]$NumberOfDots    = 10

      # Simulate no key being pressed.
      Mock Get-ConsoleKeyInfo {}

      # Mock Write-Host so we can check if dots were drawn.
      Mock Write-Host {}

      # Mock Start-Sleep so the test runs instantly.
      Mock Start-Sleep {}

      # Call with specified number of seconds.
      Get-UserSelectedJobType -DefaultJobType "${DefaultJob}" -logfile "${logfile}" -MaxWaitingTimeS $NumberOfSeconds

      # Assert number of dots.
      Assert-MockCalled Write-Host -ParameterFilter { $Object -eq '.' } -Exactly -Times $NumberOfDots
    }

    It 'Returns default if the user does NOT press any key' {
      $expected = "Incremental"

      # Simulate no key ever being pressed.
      Mock Get-ConsoleKeyInfo { return $null }
      Mock Start-Sleep {} # Still mock this so the test is fast!
      Mock Write-Host {}

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
