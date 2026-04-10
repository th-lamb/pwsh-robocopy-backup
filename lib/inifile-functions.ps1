using module '.\config-classes.psm1'



#region Helper functions

function Write-FormattedConfigObject {
  <# Formats and writes the contents of a ScriptConfig object to the debug stream.
    Iterates through all containers and their properties to show the final values.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ScriptConfig]$ConfigObject
  )

  $VarNames = [System.Collections.Generic.List[string]]::new()
  $VarValues = [System.Collections.Generic.List[string]]::new()

  # Iterate through the containers (General, Directories, Files, etc.)
  foreach ($ContainerProp in $ConfigObject.PSObject.Properties) {
    $Container = $ContainerProp.Value
    if ($null -ne $Container -and $Container.PSObject.Properties) {
      foreach ($SettingProp in $Container.PSObject.Properties) {
        $VarNames.Add($SettingProp.Name)
        $VarValues.Add($SettingProp.Value -as [string])
      }
    }
  }

  if ($VarNames.Count -eq 0) {
    Write-WarningMsg "Write-FormattedConfigObject(): No settings found in ConfigObject!"
    return
  }

  # Determine the longest variable name for padding.
  $MaxLength = 0
  foreach ($Name in $VarNames) {
    if ($Name.Length -gt $MaxLength) { $MaxLength = $Name.Length }
  }

  # Show debug messages.
  Write-DebugMsg "--------------------------------------------------------------------------------"
  Write-DebugMsg "Values from the configuration object:"
  for ($i = 0; $i -lt $VarNames.Count; $i++) {
    $VarName = $VarNames[$i]
    $Value = $VarValues[$i]
    $Padding = " " * ($MaxLength - $VarName.Length)
    Write-DebugMsg "$($VarName)$($Padding): $($Value)"
  }
  Write-DebugMsg "--------------------------------------------------------------------------------"

}

# https://stackoverflow.com/a/10939609/5944475
function Test-IsNumeric ($Value) {
  return $Value -match "^[\d\.]+$"
}

#endregion Helper functions ####################################################



#region Read-Config

function Get-Container {
  # Returns the container (inside the Configuration Object) for the specified section in the INI file.
  # Returns $null if the section is unrecognized.
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory = $true)]
    [string]$IniHeader
  )

  # Translation (INI Header -> Class Property)
  $SectionMap = @{
    "General"               = "General"
    "Mandatory Directories" = "Directories"
    "Directories"           = "Directories"
    "Files"                 = "Files"
    "Logging Settings"      = "Logging"
    "Job Settings"          = "Jobs"
    "Archiving Settings"    = "Archiving"
  }

  return $SectionMap[$iniHeader]
}

#TODO: Add Pester tests for Read-Config (as the order ones for Read-SettingsFile)
function Read-Config {
  <# Reads the specified INI file and returns a Configuration Object with all settings.
    The structure of the Config Object is like $Config.Container.Property = Value
  #>
  [CmdletBinding()]
  [OutputType([ScriptConfig])]
  param (
    [Parameter(Mandatory = $true)]
    [string]$IniFile
  )

  $Config = [ScriptConfig]::new()

  if (-not (Test-Path $IniFile)) {
    Write-WarningMsg "Settings file not found: [${IniFile}]. Using default values."
    return $Config
  }

  $IniFileContent = Get-Content "${IniFile}"
  $TargetContainer = $null

  # Temporarily disable -WhatIf to ensure the configuration is loaded into the script scope (PowerShell 5.1 workaround).
  $oldWhatIfPreference = $WhatIfPreference
  try {
    $WhatIfPreference = $false

    foreach ($Line in $IniFileContent) {
      $Line = $Line.Trim()
      if ($Line -match '^\[(.+)\]$') {
        # Look up the code-friendly name using the human-friendly header
        $IniHeader = $Matches[1].Trim()
        $TargetContainer = Get-Container -IniHeader "${IniHeader}"

        if ($null -eq $TargetContainer) {
          Write-WarningMsg "Unrecognized section in INI file: [$IniHeader]"
        }
      }
      elseif ($Line -match '^(.+?)=(.+)$' -and $TargetContainer) {
        $key = $Matches[1].Trim()
        $val = $Matches[2].Trim()

        $SubObject = $Config.$TargetContainer

        # Use PowerShell's hidden 'PSObject' to check if the property exists
        if ($SubObject.PSObject.Properties[$key] -and -not [string]::IsNullOrWhiteSpace($val)) {
          $prop = $SubObject.PSObject.Properties[$key]

          # Handle Booleans correctly
          if ($prop.TypeNameOfValue -eq 'System.Boolean') {
            if ($val -match '^(true|1|yes|on)$') { $SubObject.$key = $true }
            elseif ($val -match '^(false|0|no|off)$') { $SubObject.$key = $false }
          }
          # Expand paths for strings
          elseif ($prop.TypeNameOfValue -eq 'System.String') {
            # Temporarily set a local variable so that cross-references in the INI file
            # (e.g. ${BACKUP_BASE_DIR}) can be expanded by Get-ExpandedPath.
            $SubObject.$key = Get-ExpandedPath $val

            # Fix missing backslashes BEFORE the variable is used for further expansion
            $Config.Normalize()

            Set-Variable -Name $key -Value $SubObject.$key -Scope Local
          }
          else {
            $SubObject.$key = $val
            Set-Variable -Name $key -Value $SubObject.$key -Scope Local
          }
        }
      }
    }

    # Ensure paths are finally normalized (in case no strings were updated in the last iterations)
    $Config.Normalize()
  }
  finally {
    $WhatIfPreference = $oldWhatIfPreference
  }

  Write-FormattedConfigObject -ConfigObject $Config

  return $Config
}

#endregion Read-Config #########################################################
