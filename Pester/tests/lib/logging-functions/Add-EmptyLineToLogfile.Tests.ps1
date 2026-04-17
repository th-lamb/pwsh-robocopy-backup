# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\logging-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\logging-functions.ps1"

  # For logging in tested functions
  $script:BACKUP_LOGFILE = "${ProjectRoot}\Pester\resources\lib\logging-functions\Add-EmptyLineToLogfile.Tests.log"
}



Describe 'Add-EmptyLineToLogfile' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatchmultiline

  It 'Correctly inserts 1 empty line.' {
    Remove-Item "$BACKUP_LOGFILE" -ErrorAction SilentlyContinue
    Add-EmptyLineToLogfile "$BACKUP_LOGFILE"

    "$BACKUP_LOGFILE" | Should -FileContentMatchMultiline '\n$'
  }
}



AfterAll {
  Remove-Item "$BACKUP_LOGFILE" -ErrorAction SilentlyContinue
}
