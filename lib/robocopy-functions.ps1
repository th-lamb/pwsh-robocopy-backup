# Info:
# https://ss64.com/nt/robocopy-exit.html
# https://superuser.com/questions/1651430/robocopy-what-is-the-meaning-of-mismatch-and-failed
#
################################################################################



#TODO: What does "Flags() ..." do?
# https://pshirwin.wordpress.com/2016/03/18/robocopy-exitcodes-the-powershell-way/
[Flags()] Enum RoboCopyExitCodes {
  NoChange = 0
  OKCopy = 1
  ExtraFiles = 2
  MismatchedFilesFolders = 4
  FailedCopyAttempts = 8
  FatalError = 16
}

function LogAndShowRobocopyError {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [string]$JobName,
    [Parameter(Mandatory=$true)]
    [ValidateRange(0,16)]
    [System.Byte]$ExitCode,
    [Parameter(Mandatory=$false)]
    [string]$logfile = $null
  )

  $result = $([RoboCopyExitCodes]$ExitCode)

  switch ($ExitCode) {
    {$_ -in 0..3} {
      # We log only errors and warnings.
      #LogAndShowMessage INFO "${JobName}: ${result}" "${logfile}"
    }
    {$_ -in 4..7} {
      LogAndShowMessage NOTICE "${JobName}: ${result} (Examine the output log. Some housekeeping may be needed.)" "${logfile}"
    }
    {$_ -in 8..15} {
      LogAndShowMessage WARNING "${JobName}: ${result}" "${logfile}"
    }
    16 {
      LogAndShowMessage ERR "${JobName}: ${result}" "${logfile}"
    }
  }

}
