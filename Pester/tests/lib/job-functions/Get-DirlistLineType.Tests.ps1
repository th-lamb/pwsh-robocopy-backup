$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\job-functions.ps1"
. "${ProjectRoot}\lib\logging-functions.ps1"
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\job-functions.ps1"
  . "${ProjectRoot}\lib\logging-functions.ps1"
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\filesystem-functions.ps1"

  $Script:workingFolder = "${ProjectRoot}\Pester/resources/lib/job-functions/"

  # For logging in tested functions
  $Script:logfile = "${workingFolder}Get-DirlistLineType.Tests.log"

  # For messages in tested functions
  $Script:__VERBOSE = 6

  # Other functions
}



Describe 'Get-DirlistLineType' {
  Context 'Possible types' {
    It 'Ignores an empty line.' {
      $entry    = ""
      $expected = "ignore"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Ignores a comment.' {
      $entry    = "::foo"
      $expected = "ignore"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes a source-file.' -Tag 'LocalOnly' {
      $entry    = "C:\Users\desktop.ini"
      $expected = "source-file"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes a source-dir.' -Tag 'LocalOnly' {
      $entry    = "C:\Users\"
      $expected = "source-dir"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes a source-file-pattern.' -Tag 'LocalOnly' {
      $entry    = "C:\cygwin64\*.ico"
      $expected = "source-file-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes an incl-files-pattern.' {
      $entry    = "  + *.txt"
      $expected = "incl-files-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes an excl-files-pattern.' {
      $entry    = "  - *.txt"
      $expected = "excl-files-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Recognizes an excl-dirs-pattern.' {
      $entry    = "  - *\test\"
      $expected = "excl-dirs-pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Not implemented' {
    It 'Reports invalid source-dir-pattern.' {
      $entry    = "C:\User*\"
      $expected = "invalid: source directory pattern"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Reports invalid directory-entry (for current folder).' {
      $entry    = "C:\Users\."
      $expected = "invalid: directory entry (for current or parent folder)"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Reports invalid directory-entry (for parent folder).' {
      $entry    = "C:\Users\.."
      $expected = "invalid: directory entry (for current or parent folder)"

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }
  }

  Context 'Errors' {
    It 'Reports a missing directory' {
      $entry    = "C:\no_such_dir\"
      $expected = "error: not found"

      Mock LogAndShowMessage {}

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    It 'Reports a missing file' {
      $entry    = "C:\no_such_file.txt"
      $expected = "error: not found"

      Mock LogAndShowMessage {}

      $result = Get-DirlistLineType "${entry}" "${logfile}"
      $result | Should -Be "${expected}"
    }

    <#TODO: More errors? Examples:
      - Directory/file with wildcards (C:\Users\*.ini) which does not exist? -> Type = $null
      - Missing network share? -> Exists = $false (not Type = $null)
      - Missing network computer? -> same as for network share
    #>

  }
}



AfterAll {
  Remove-Item "${logfile}" -ErrorAction SilentlyContinue
}
