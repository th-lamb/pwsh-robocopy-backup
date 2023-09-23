BeforeAll {
  $ProjectRoot = Resolve-Path "${PSScriptRoot}/../../../"
  . "${ProjectRoot}lib/inifile-functions.ps1"
  $script:ini_file = "${PSScriptRoot}/Read-SettingsFile.Tests.ini"

  . "${ProjectRoot}lib/filesystem-functions.ps1"

  # For messages in tested functions
  . "${ProjectRoot}lib/message-functions.ps1"
  $script:__VERBOSE = 6
}



Describe 'Read-SettingsFile' {
  It 'Reads strings as string.' {
    $var_name = "STRING_VALUE_1"
    $expected = "String"

    Read-SettingsFile "${ini_file}"

    $result = $( Get-Variable "${var_name}" -ValueOnly ).GetType().Name
    $result | Should -Be "${expected}"
  }

  It 'Reads int values as Int32.' {
    $var_name = "INT_VALUE_1"
    $expected = "Int32"

    Read-SettingsFile "${ini_file}"

    $result = $( Get-Variable "${var_name}" -ValueOnly ).GetType().Name
    $result | Should -Be "${expected}"
  }
}
