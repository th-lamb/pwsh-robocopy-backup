$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"
}

Describe 'Format-SeverityLabel' {
  Context 'Correctly used' {
    It 'Correctly formats EMERG.' {
      $keyword  = "EMERG"
      $expected = "[EMERG  ]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats ALERT.' {
      $keyword  = "ALERT"
      $expected = "[ALERT  ]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats CRIT.' {
      $keyword  = "CRIT"
      $expected = "[CRIT   ]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats ERR.' {
      $keyword  = "ERR"
      $expected = "[ERR    ]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats WARNING.' {
      $keyword  = "WARNING"
      $expected = "[WARNING]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats NOTICE.' {
      $keyword  = "NOTICE"
      $expected = "[NOTICE ]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats INFO.' {
      $keyword  = "INFO"
      $expected = "[INFO   ]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats DEBUG.' {
      $keyword  = "DEBUG"
      $expected = "[DEBUG  ]"

      $result = Format-SeverityLabel "${keyword}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Format-SeverityLabel ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an illegal keyword.' {
      {
        Format-SeverityLabel "foo"
      } | Should -Throw
    }
  }
}
