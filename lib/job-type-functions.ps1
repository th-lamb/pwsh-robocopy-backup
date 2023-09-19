# Info:
# https://stackoverflow.com/a/2688572/5944475
# https://www.reddit.com/r/PowerShell/comments/d74lce/how_to_underline_text_in_output_using_writehost/



#region Helper functions

# https://stackoverflow.com/a/2688572/5944475
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
    for ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Write-Host
}

#Write-Color -Text Red,White,Blue -Color Red,White,Blue

#endregion Helper functions ####################################################



function _showOptions {
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Incremental', 'Full', 'Purge', 'Archive', 'Cancel')]
    [String]$default_job_type
  )

  Write-Host "__________________________________________________"
  Write-Host ""
  Write-Host "  Press a key to select the backup job-type:"
  Write-Host ""

  if ( "${default_job_type}" -eq "Incremental") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup (", "default", ")" -Color White, Yellow, White, Green, White
    Write-Color -Text "  [F]    ", "`e[4mF`e[24m", "ull backup" -Color White, Yellow, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files)" -Color White, Yellow, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute)" -Color White, Red, White, Yellow, White
  } elseif ( "${default_job_type}" -eq "Full") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mF`e[24m", "ull backup (", "default", ")" -Color White, Yellow, White, Green, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files)" -Color White, Yellow, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute)" -Color White, Red, White, Yellow, White
  } elseif ( "${default_job_type}" -eq "Purge") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mI`e[24m", "ull backup" -Color White, Yellow, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files) (", "default", ")" -Color White, Yellow, White, Green, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute)" -Color White, Red, White, Yellow, White
  } elseif ( "${default_job_type}" -eq "Archive") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mI`e[24m", "ull backup" -Color White, Yellow, White
    Write-Color -Text "  [P]    ", "`e[4mP`e[24m", "urge (remove deleted/renamed files)" -Color White, Yellow, White
    Write-Color -Text "  [A]    ", "Experimental: ", "Files with ", "`e[4mA`e[24m", "rchive attribute (and reset the attribute) (", "default", ")" -Color White, Red, White, Yellow, White, Green, White
  } elseif ( "${default_job_type}" -eq "Cancel") {
    Write-Color -Text "  [I]    ", "`e[4mI`e[24m", "ncremental backup" -Color White, Yellow, White
    Write-Color -Text "  [F]    ", "`e[4mI`e[24m", "ull backup" -Color White, Yellow, White
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
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Incremental', 'Full', 'Purge', 'Archive', 'Cancel')]
    [String]$default_job_type,
    [String]$logfile
  )

  Add-LogMessage "${logfile}" INFO "Asking the user for the job-type..."

  [Int32]$max_wait_time_ms = ${JOB_TYPE_SELECTION_MAX_WAITING_TIME_S} * 1000
  [Int32]$check_interval_ms = 100
  [Int32]$already_waited_ms = 0
  [String]$result = ""

  _showOptions "${default_job_type}"
  Write-Host "Automatic start in ${JOB_TYPE_SELECTION_MAX_WAITING_TIME_S} seconds."

  # https://powershell.one/tricks/input-devices/detect-key-press
  do {
    # Wait for a key to be available:
    if ([Console]::KeyAvailable) {
      # Read the key, and consume it so it won't be echoed to the console:
      $keyInfo = [Console]::ReadKey($true)
      break
    }

    # Wait.
    Start-Sleep -Milliseconds $check_interval_ms
    $already_waited_ms = $already_waited_ms + $check_interval_ms

    # Write a dot every second.
    if ( ($already_waited_ms % 1000) -eq 0 ) {
      Write-Host '.' -NoNewline
    }

  } while ($already_waited_ms -lt $max_wait_time_ms)

  # Emit a new line
  Write-Host

  switch($keyInfo.key) {
    'i' {
      $result = "Incremental"
      Add-LogMessage "${logfile}" INFO "Incremental selected."
    }

    'f' {
      $result = "Full"
      Add-LogMessage "${logfile}" INFO "Full selected."
    }

    'p' {
      $result = "Purge"
      Add-LogMessage "${logfile}" INFO "Purge selected."
    }

    'a' {
      $result = "Archive"
      Add-LogMessage "${logfile}" INFO "Archive selected."
    }

    's' {
      $result = "${default_job_type}"
      Add-LogMessage "${logfile}" INFO "Start selected. Using the default: ${default_job_type}"
    }

    'Escape' {
      $result = "Cancel"
      Add-LogMessage "${logfile}" INFO "User pressed ESCAPE. Cancel."
    }

    'Enter' {
      Write-Host "Using the default."
      $result = "${default_job_type}"
      Add-LogMessage "${logfile}" INFO "User just pressed ENTER. Using the default: ${default_job_type}"
    }

    '' {
      # User didn't press any key.
      Write-Host "Using the default."
      $result = "${default_job_type}"
      Add-LogMessage "${logfile}" INFO "User didn't select a job-type. Using the default: ${default_job_type}"
    }

    Default {
      # Illegal choice
      LogAndShowMessage "${logfile}" WARN "Illegal choice. Cancel."
      $result = "Cancel"
      Add-LogMessage "${logfile}" DEBUG "User clicked: $($keyInfo.key)"
    }

  }

  Write-Host "${result}"

  return "${result}"

}
