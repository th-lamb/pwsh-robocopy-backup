using module '..\..\..\..\lib\config-classes.psm1'

$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

Describe 'Update-ConfigProperty' {
  BeforeAll {
    $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
    . "${ProjectRoot}\lib\message-functions.ps1"
    . "${ProjectRoot}\lib\inifile-functions.ps1"
    . "${ProjectRoot}\lib\filesystem-functions.ps1"

    # We need a mock for Get-ExpandedPath as it's called for String types
    Mock Get-ExpandedPath {
      param($PathSpec)
      return "C:\${PathSpec}"
    }
  }

  Context 'Boolean Handling' {
    $TestCases = @(
      @{ MyInput = 'true';  Expected = $true }
      @{ MyInput = '1';     Expected = $true }
      @{ MyInput = 'yes';   Expected = $true }
      @{ MyInput = 'on';    Expected = $true }
      @{ MyInput = 'TRUE';  Expected = $true }
      @{ MyInput = 'Yes';   Expected = $true }
      @{ MyInput = 'false'; Expected = $false }
      @{ MyInput = '0';     Expected = $false }
      @{ MyInput = 'no';    Expected = $false }
      @{ MyInput = 'off';   Expected = $false }
      @{ MyInput = 'FALSE'; Expected = $false }
      @{ MyInput = 'No';    Expected = $false }
    )

    It "Correctly converts '<MyInput>' to <Expected>" -TestCases $TestCases {
      <# We pass all combinations to Update-ConfigProperty and then check
        whether $Config.Logging.ENABLE_TRACE_LOG has the correct value.
      #>
      param($MyInput, $Expected)

      $Config = [ScriptConfig]::new()
      # ENABLE_TRACE_LOG is a [bool] in the Logging container.
      Update-ConfigProperty -Config $Config -TargetContainer 'Logging' -Key 'ENABLE_TRACE_LOG' -Val $MyInput

      $Config.Logging.ENABLE_TRACE_LOG | Should -BeExactly $Expected
    }

    It 'Ignores empty input for boolean properties (no update).' {
      $Config = [ScriptConfig]::new()
      # Default is $true, we try to set it to '' which should be ignored.
      Update-ConfigProperty -Config $Config -TargetContainer 'Logging' -Key 'ENABLE_TRACE_LOG' -Val ''

      $Config.Logging.ENABLE_TRACE_LOG | Should -Be $true
    }
  }

  Context 'String Handling and Expansion' {
    It 'Calls Get-ExpandedPath for string properties.' {
      $Config = [ScriptConfig]::new()
      # BACKUP_BASE_DIR is a [string] in the Directories container
      Update-ConfigProperty -Config $Config -TargetContainer 'Directories' -Key 'BACKUP_BASE_DIR' -Val 'SomePath'

      $Config.Directories.BACKUP_BASE_DIR | Should -Be "C:\SomePath\"
    }
  }

  Context 'Default Type Handling (Integer)' {
    It 'Correctly handles integer types.' {
      $Config = [ScriptConfig]::new()
      # __VERBOSE is an [int] in the General container
      Update-ConfigProperty -Config $Config -TargetContainer 'General' -Key '__VERBOSE' -Val '3'

      $Config.General.__VERBOSE | Should -Be 3
    }
  }

  Context 'Scope Injection' {
    It 'Injects the variable into the caller scope for cross-references.' {
      $Config = [ScriptConfig]::new()

      # We call it and check if a local variable is created in THIS scope
      # Note: Scope 1 in Update-ConfigProperty refers to its caller, which is this 'It' block.
      Update-ConfigProperty -Config $Config -TargetContainer 'General' -Key 'MY_TEST_VAR' -Val 'SomeValue'
      # MY_TEST_VAR won't be in $Config because it's not a property of GeneralSettings,
      # but it SHOULD be set as a local variable if it WERE a property.
      # Wait, the code checks if the property exists FIRST.
      # Let's use an existing property.

      Update-ConfigProperty -Config $Config -TargetContainer 'General' -Key '__VERBOSE' -Val '4'

      $__VERBOSE | Should -Be 4
    }
  }

  Context 'Safety' {
    It 'Does not update non-existent properties.' {
      $Config = [ScriptConfig]::new()
      Update-ConfigProperty -Config $Config -TargetContainer 'General' -Key 'NON_EXISTENT' -Val 'Value'

      $Config.General.PSObject.Properties['NON_EXISTENT'] | Should -BeNullOrEmpty
    }
  }
}
