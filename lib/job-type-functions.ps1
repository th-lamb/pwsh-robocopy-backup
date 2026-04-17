# Info:
# https://stackoverflow.com/a/2688572/5944475
# https://www.reddit.com/r/PowerShell/comments/d74lce/how_to_underline_text_in_output_using_writehost/



#region Helper functions

# https://stackoverflow.com/a/2688572/5944475
function Write-Color {
  param(
    [String[]]$Text,
    [ConsoleColor[]]$Color
  )
  for ($i = 0; $i -lt $Text.Length; $i++) {
    Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
  }
  Write-Host
}

#Write-Color -Text Red,White,Blue -Color Red,White,Blue

function Get-ConsoleKeyInfo {
  <# This is the only place using the non-mockable .NET methods.
    But we can mock Get-ConsoleKeyInfo in Pester tests.
  #>
  # https://powershell.one/tricks/input-devices/detect-key-press
  if ([Console]::KeyAvailable) {
    return [Console]::ReadKey($true)
  }
  return $null
}

#endregion Helper functions ####################################################



function _showJobTypeList {
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Incremental', 'Full', 'Purge', 'Archive', 'Cancel')]
    [string]$DefaultJobType
  )

  Write-Host "__________________________________________________"
  Write-Host ""
  Write-Host "  Press a key to select the backup job-type:"
  Write-Host ""

  if ( "${DefaultJobType}" -eq "Incremental") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup (", "default", ")" -Color White, Yellow, White, Green, White
    Write-Color -Text "  [F]    ", "`e[4mF`e[24m", "ull backup" -Color White, Yellow, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files)" -Color White, Yellow, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute)" -Color White, Red, White, Yellow, White
  }
  elseif ( "${DefaultJobType}" -eq "Full") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mF`e[24m", "ull backup (", "default", ")" -Color White, Yellow, White, Green, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files)" -Color White, Yellow, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute)" -Color White, Red, White, Yellow, White
  }
  elseif ( "${DefaultJobType}" -eq "Purge") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mF`e[24m", "ull backup" -Color White, Yellow, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files) (", "default", ")" -Color White, Yellow, White, Green, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute)" -Color White, Red, White, Yellow, White
  }
  elseif ( "${DefaultJobType}" -eq "Archive") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mF`e[24m", "ull backup" -Color White, Yellow, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files)" -Color White, Yellow, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute) (", "default", ")" -Color White, Red, White, Yellow, White, Green, White
  }
  elseif ( "${DefaultJobType}" -eq "Cancel") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mF`e[24m", "ull backup" -Color White, Yellow, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files)" -Color White, Yellow, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute)" -Color White, Red, White, Yellow, White
  }

  Write-Host ""
  Write-Color -Text "  [S]    ", "`e[4mS`e[24m", "tart (use the default)" -Color White, Yellow, White
  Write-Host ""
  Write-Color -Text "  [", "ESC", "]", "  Cancel" -Color White, Red, White, Red
  Write-Host "__________________________________________________"

}

function Get-UserSelectedJobType {
  [OutputType([System.String])]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Incremental', 'Full', 'Purge', 'Archive', 'Cancel')]
    [string]$DefaultJobType,
    [Parameter(Mandatory = $true)]
    [string]$logfile,
    [Parameter(Mandatory = $true)]
    [int32]$MaxWaitingTimeS,
    # Skip all interactive prompts and pauses (useful for automation/CI).
    [Parameter(Mandatory = $false)]
    [switch]$NonInteractive
  )

  if ($NonInteractive) {
    LogAndShowMessage -logfile "${logfile}" -severity INFO -message "Non-interactive mode. Using the default: ${DefaultJobType}"
    return "${DefaultJobType}"
  }

  Add-LogMessage -logfile "${logfile}" -severity INFO -message "Asking the user for the job-type..."

  [int32]$MaxWaitTimeMilliseconds = $MaxWaitingTimeS * 1000
  [int32]$CheckIntervalMilliseconds = 100
  [int32]$AlreadyWaitedMilliseconds = 0
  [string]$result = ""
  $keyInfo = $null

  _showJobTypeList "${DefaultJobType}"
  Write-Host "Automatic start in ${MaxWaitingTimeS} seconds."

  :waitForKey do {
    $keyInfo = Get-ConsoleKeyInfo

    # Ignore some keys; continue waiting for a meaningful key press.
    if ($null -ne $keyInfo) {
      switch ($keyInfo.Key) {
        { $_ -in 'LeftWindows', 'Tab', 'VolumeDown', 'VolumeUp' } { continue waitForKey }
        Default { break waitForKey }
      }
    }

    # Wait.
    Start-Sleep -Milliseconds $CheckIntervalMilliseconds
    $AlreadyWaitedMilliseconds = $AlreadyWaitedMilliseconds + $CheckIntervalMilliseconds

    # Write a dot every second.
    if ( ($AlreadyWaitedMilliseconds % 1000) -eq 0 ) {
      Write-Host '.' -NoNewline
    }

  } while ($AlreadyWaitedMilliseconds -lt $MaxWaitTimeMilliseconds)

  # Emit a new line
  Write-Host

  # Extract the key name as a string.
  # Works for both real [ConsoleKeyInfo] and Pester mock [PSCustomObject], since both
  # expose a .Key property of type [ConsoleKey] whose .ToString() yields the key name.
  [string]$pressedKey = ""
  if ($null -ne $keyInfo) {
    $pressedKey = $keyInfo.Key.ToString()
  }

  switch ($pressedKey) {
    'I' {
      $result = "Incremental"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "Incremental selected."
    }

    'F' {
      $result = "Full"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "Full selected."
    }

    'P' {
      $result = "Purge"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "Purge selected."
    }

    'A' {
      $result = "Archive"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "Archive selected."
    }

    'S' {
      $result = "${DefaultJobType}"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "Start selected. Using the default: ${DefaultJobType}"
    }

    'ESCAPE' {
      $result = "Cancel"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "User pressed ESCAPE. Cancel."
    }

    'ENTER' {
      Write-Host "Using the default."
      $result = "${DefaultJobType}"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "User just pressed ENTER. Using the default: ${DefaultJobType}"
    }

    '' {
      # User didn't press any key.
      Write-Host "Using the default."
      $result = "${DefaultJobType}"
      Add-LogMessage -logfile "${logfile}" -severity INFO -message "User didn't select a job-type. Using the default: ${DefaultJobType}"
    }

    Default {
      # Illegal choice
      Add-LogMessage -logfile "${logfile}" -severity DEBUG -message "User clicked: ${pressedKey}"
      LogAndShowMessage "${logfile}" WARNING "Illegal choice. Cancel."
      $result = "Cancel"
    }
  }

  Write-Host "${result}"

  return "${result}"

}
