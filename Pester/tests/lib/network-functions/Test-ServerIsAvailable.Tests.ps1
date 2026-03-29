$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\network-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\network-functions.ps1"
}

Describe 'Test-ServerIsAvailable' {
  Context 'Valid network servers' {
    It 'Returns true for an available server' {
      # Use localhost as it should be available
      $server = "\\localhost"
      $result = Test-ServerIsAvailable $server
      $result | Should -Be $true
    }

    It 'Returns false for a non-existent server' {
      # Use a name that's highly unlikely to exist
      $server = "\\nonexistent-server-$(Get-Random)"
      $result = Test-ServerIsAvailable $server
      $result | Should -Be $false
    }
  }

  Context 'Special network cases' {
    It 'Handles the blackhole prefix 240.0.0.1 by returning false' {
      $server = "\\240.0.0.1"
      $result = Test-ServerIsAvailable $server
      $result | Should -Be $false
    }
  }
}
