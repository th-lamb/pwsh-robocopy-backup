BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/message-functions.ps1"
}



Describe 'Write-EmergMsg' {
  It 'Calls Write-ColoredMessage with "emerg" and the specified message.' {
    $test_severity    = "emerg"
    $test_message     = "Test message"
    $expected_message = "[EMERG  ] ${test_message}"

    Mock Write-ColoredMessage {
      $Script:used_severity = $Severity
      $Script:used_message  = $Message
    } -Verifiable

    Write-EmergMsg -Message "${test_message}"

    $Script:used_severity | Should -Be "${test_severity}"
    $Script:used_message | Should -Be "${expected_message}"
  }

}
