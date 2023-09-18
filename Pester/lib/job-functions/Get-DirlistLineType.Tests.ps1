BeforeAll {
  $ProjectRoot = "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/job-functions.ps1"

  # For logging in tested functions
  . "${ProjectRoot}lib/logging-functions.ps1"
  $logfile = "${PSScriptRoot}/Get-DirlistLineType.Tests.log"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $__VERBOSE = 6

  # Other functions
  . "${ProjectRoot}lib/filesystem-functions.ps1"
}



Describe 'Get-DirlistLineType' {
  Context 'Possible types' {
    It 'Ignores an empty line.' {
      $entry = ""
      $expected = "ignore"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Ignores a comment.' {
      $entry = "::foo"
      $expected = "ignore"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes a source-file.' {
      $entry = "C:\Users\desktop.ini"
      $expected = "source-file"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes a source-dir.' {
      $entry = "C:\Users\"
      $expected = "source-dir"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes a source-file-pattern.' {
      $entry = "C:\cygwin64\*.ico"
      $expected = "source-file-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes an incl-files-pattern.' {
      $entry = "  + *.txt"
      $expected = "incl-files-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes an excl-files-pattern.' {
      $entry = "  - *.txt"
      $expected = "excl-files-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes an excl-dirs-pattern.' {
      $entry = "  - *\test\"
      $expected = "excl-dirs-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }
  }
}



AfterAll {
  #Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
