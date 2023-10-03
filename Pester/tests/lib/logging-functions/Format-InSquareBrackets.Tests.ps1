BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../../"
  . "${ProjectRoot}lib/logging-functions.ps1"
}



Describe 'Format-InSquareBrackets' {
  Context 'Correctly used' {
    It 'Correctly formats EMERG.' {
      $keyword  = "EMERG"
      $expected = "[EMERG  ]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats ALERT.' {
      $keyword  = "ALERT"
      $expected = "[ALERT  ]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats CRIT.' {
      $keyword  = "CRIT"
      $expected = "[CRIT   ]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats ERR.' {
      $keyword  = "ERR"
      $expected = "[ERR    ]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats WARNING.' {
      $keyword  = "WARNING"
      $expected = "[WARNING]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats NOTICE.' {
      $keyword  = "NOTICE"
      $expected = "[NOTICE ]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats INFO.' {
      $keyword  = "INFO"
      $expected = "[INFO   ]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }

    It 'Correctly formats DEBUG.' {
      $keyword  = "DEBUG"
      $expected = "[DEBUG  ]"

      $result = Format-InSquareBrackets "${keyword}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Wrong Usage' {
    It 'Throws an exception when called with an empty String.' {
      {
        Format-InSquareBrackets ""
      } | Should -Throw
    }

    It 'Throws an exception when called with an illegal keyword.' {
      {
        Format-InSquareBrackets "foo"
      } | Should -Throw
    }
  }
}
