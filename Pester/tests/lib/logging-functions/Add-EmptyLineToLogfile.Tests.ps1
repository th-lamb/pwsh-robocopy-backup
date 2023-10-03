BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/logging-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}Pester/resources/lib/logging-functions/"
  $Script:logfile = "${workingFolder}Add-EmptyLineToLogfile.Tests.log"
}



Describe 'Add-EmptyLineToLogfile' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatchmultiline

  It 'Correctly inserts 1 empty line.' {
    Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    Add-EmptyLineToLogfile "${logfile}"

    "${logfile}" | Should -FileContentMatchMultiline '\n$'
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
