# Info:
# https://ss64.com/nt/robocopy-exit.html
# https://superuser.com/questions/1651430/robocopy-what-is-the-meaning-of-mismatch-and-failed
#
################################################################################



# https://pshirwin.wordpress.com/2016/03/18/robocopy-exitcodes-the-powershell-way/
[Flags()] Enum RoboCopyExitCodes {
  NoChange = 0
  OKCopy = 1
  ExtraFiles = 2
  MismatchedFilesFolders = 4
  FailedCopyAttempts = 8
  FatalError = 16
}

function LogAndShowRobocopyErrors {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$logfile,
    [Parameter(Mandatory=$true)]
    [String]$job_name,
    [Parameter(Mandatory=$true)]
    [ValidateRange(0,16)]
    [System.Byte]$exit_code
  )

  $result = $([RoboCopyExitCodes]$exit_code)

  switch ($exit_code) {
    {$_ -in 0..3} {
      # We log only errors and warnings.
      #LogAndShowMessage "${logfile}" INFO "${job_name}: ${result}"
    }
    {$_ -in 4..7} {
      LogAndShowMessage "${logfile}" NOTICE "${job_name}: ${result} (Examine the output log. Some housekeeping may be needed.)"
    }
    {$_ -in 8..15} {
      LogAndShowMessage "${logfile}" WARNING "${job_name}: ${result}"
    }
    16 {
      LogAndShowMessage "${logfile}" ERR "${job_name}: ${result}"
    }
  }

}
