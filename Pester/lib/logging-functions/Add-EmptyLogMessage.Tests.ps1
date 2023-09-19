BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/logging-functions.ps1"
  $logfile = "${ProjectRoot}Pester/resources/logging-functions/Add-EmptyLogMessage.Tests.log"
}



Describe 'Write-LogMessage' {
  # Check file content: https://pester.dev/docs/v4/usage/assertions#filecontentmatchmultiline

  It 'Correctly inserts 1 empty line.' {
    Remove-Item "${logfile}" -ErrorAction SilentlyContinue
    Add-EmptyLogMessage "${logfile}"

    "${logfile}" | Should -FileContentMatchMultiline '\n$'
  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
