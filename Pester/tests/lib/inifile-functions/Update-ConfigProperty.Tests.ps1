using module '..\..\..\..\lib\config-classes.psm1'

# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"
  . "${ProjectRoot}\lib\filesystem-functions.ps1"
}



Describe 'Update-ConfigProperty' {
  BeforeAll {
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
        whether $Config.Logging.TRACE_LOG_ENABLED has the correct value.
      #>
      param($MyInput, $Expected)
      $Config = [ScriptConfig]::new()

      # TRACE_LOG_ENABLED is a [bool] in the Logging container.
      Update-ConfigProperty -Config $Config -TargetContainer 'Logging' -Key 'TRACE_LOG_ENABLED' -Val $MyInput

      $Config.Logging.TRACE_LOG_ENABLED | Should -BeExactly $Expected
    }

    It 'Ignores empty input for boolean properties (no update).' {
      $Config = [ScriptConfig]::new()

      # Default is $true, we try to set it to '' which should be ignored.
      Update-ConfigProperty -Config $Config -TargetContainer 'Logging' -Key 'TRACE_LOG_ENABLED' -Val ''

      $Config.Logging.TRACE_LOG_ENABLED | Should -Be $true
    }
  }

  Context 'String Handling and Expansion' {
    It 'Calls Get-ExpandedPath for string properties.' {
      $Config = [ScriptConfig]::new()

      # BACKUP_BASE_DIR is a [string] in the Directories container.
      # Our Mock for Get-ExpandedPath just inserts "C:\" before the string.
      Update-ConfigProperty -Config $Config -TargetContainer 'Directories' -Key 'BACKUP_BASE_DIR' -Val 'SomePath'

      Should -Invoke -CommandName "Get-ExpandedPath" # -Times 1
      $Config.Directories.BACKUP_BASE_DIR | Should -Be "C:\SomePath\"
    }

    It 'Allows overwriting a string property with an empty string.' {
      $Config = [ScriptConfig]::new()
      # Default value is usually not empty. Let's set it first.
      $Config.Directories.BACKUP_BASE_DIR = "C:\OldPath\"

      Update-ConfigProperty -Config $Config -TargetContainer 'Directories' -Key 'BACKUP_BASE_DIR' -Val ''

      $Config.Directories.BACKUP_BASE_DIR | Should -BeExactly ""
    }
  }

  Context 'Default Type Handling (Integer)' {
    It 'Correctly handles integer types.' {
      $Config = [ScriptConfig]::new()

      # __VERBOSE is an [int] in the General container.
      Update-ConfigProperty -Config $Config -TargetContainer 'General' -Key '__VERBOSE' -Val '3'

      $Config.General.__VERBOSE | Should -Be 3
    }
  }

  Context 'Scope Injection' {
    It 'Injects the variable into the caller scope for cross-references.' {
      $Config = [ScriptConfig]::new()

      # We call it and check if a local variable is created in THIS scope.
      # Note: Scope 1 in Update-ConfigProperty refers to its caller, which is this 'It' block.
      Update-ConfigProperty -Config $Config -TargetContainer 'General' -Key '__VERBOSE' -Val '4'

      $__VERBOSE | Should -Be 4
    }
  }

  Context 'Safety' {
    It 'Does not update non-existent properties.' {
      $Config = [ScriptConfig]::new()
      Update-ConfigProperty -Config $Config -TargetContainer 'General' -Key 'NON_EXISTENT' -Val 'Value'

      $Properties = $Config.General | Get-Member -MemberType Property
      $Properties | Where-Object { $_.Name -eq 'NON_EXISTENT' } | Should -BeNullOrEmpty
    }
  }
}
