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



function _showOptions
{
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('incr', 'full', 'cleanup')]
    [String]$standard_job_type
  )

  Write-Host "__________________________________________________"
  Write-Host ""
  Write-Host "  Press a key to select the job-type:"
  Write-Host ""

  if ( "${standard_job_type}" -eq "incr")
  {
    Write-Color -Text "  [I] ", "I", "ncremental backup (standard)" -Color White, DarkCyan, White
    Write-Color -Text "  [F] ", "F", "ull backup" -Color White, DarkCyan, White
    Write-Color -Text "  [C] ", "C", "leanup" -Color White, DarkCyan, White
  }
  elseif ( "${standard_job_type}" -eq "full")
  {
    Write-Color -Text "  [I] ", "I", "ncremental backup" -Color White, DarkCyan, White
    Write-Color -Text "  [F] ", "F", "ull backup (standard)" -Color White, DarkCyan, White
    Write-Color -Text "  [C] ", "C", "leanup" -Color White, DarkCyan, White
  }
  elseif ( "${standard_job_type}" -eq "cleanup")
  {
    Write-Color -Text "  [I] ", "I", "ncremental backup" -Color White, DarkCyan, White
    Write-Color -Text "  [F] ", "F", "ull backup" -Color White, DarkCyan, White
    Write-Color -Text "  [C] ", "C", "leanup (standard)" -Color White, DarkCyan, White
  }

  Write-Host "__________________________________________________"

}

function UserSelectedJobType
{
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('incr', 'full', 'cleanup')]
    [String]$standard_job_type,
    [String]$logfile
  )

  _showOptions "${standard_job_type}"

  [Int32]$max_wait_time_ms = ${JOB_TYPE_SELECTION_MAX_WAITING_TIME_S} * 1000
  [Int32]$check_interval_ms = 100
  [Int32]$already_waited_ms = 0

  # https://powershell.one/tricks/input-devices/detect-key-press
  do
  {
    # Wait for a key to be available:
    if ([Console]::KeyAvailable)
    {
      # Read the key, and consume it so it won't be echoed to the console:
      #$keyInfo = [Console]::ReadKey($true)
      $keyInfo = [Console]::ReadKey()
      break
    }

    # Wait.
    Start-Sleep -Milliseconds $check_interval_ms
    $already_waited_ms = $already_waited_ms + $check_interval_ms

    # Write a dot every second.
    if ( ($already_waited_ms % 1000) -eq 0 )
    {
      Write-Host '.' -NoNewline
    }

  } while ($already_waited_ms -lt $max_wait_time_ms)

  # Emit a new line
  Write-Host

  switch($keyInfo.key)
  {
    'i'
    {
      Write-Host "You selected Incremental Backup."
      return "incr"
    }
    'f'
    {
      Write-Host "You selected Full Backup."
      return "full"
    }
    'c'
    {
      Write-Host "You selected Cleanup."
      return "cleanup"
    }
    'Enter'   # User just pressed ENTER.
    {
      Write-Host "You didn't select a job-type. Using the default: Incremental Backup"
      return "${standard_job_type}"
    }
    ''        # User didn't press a key.
    {
      Write-Host "You didn't select a job-type. Using the default: Incremental Backup"
      return "${standard_job_type}"
    }
    Default { Write-Host "Unknown job type selected! Aborting." }
  }

}
