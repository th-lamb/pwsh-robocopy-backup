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

  # Iterate through the containers and their properties in a stable order.
  $ContainerNames = @("General", "Directories", "Files", "Logging", "Jobs", "Archiving")

  foreach ($Name in $ContainerNames) {
    $Container = $ConfigObject.$Name
    if ($null -ne $Container) {
      # Use Reflection to get properties in their definition order
      $Props = $Container.GetType().GetProperties()
      foreach ($Prop in $Props) {
        $VarNames.Add($Prop.Name)
        $VarValues.Add($Prop.GetValue($Container) -as [string])
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

function Update-ConfigProperty {
  <# Updates the specified property in the Configuration Object.
    Handles type conversion (Boolean, String, etc.) and variable expansion.
    -> To be called by Read-Config.
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ScriptConfig]$Config,
    [Parameter(Mandatory = $true)]
    [string]$TargetContainer,
    [Parameter(Mandatory = $true)]
    [string]$Key,
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Val
  )

  $SubObject = $Config.$TargetContainer
  $TargetProp = $SubObject.GetType().GetProperty($Key)

  # Only process if the property exists.
  if ($null -eq $TargetProp) {
    return
  }

  $PropTypeName = $TargetProp.PropertyType.FullName

  # Only process if the property exists and value is not empty OR if it's a string (allowing empty strings).
  if ([string]::IsNullOrWhiteSpace($Val) -and $PropTypeName -ne 'System.String') {
    return
  }

  switch ($PropTypeName) {
    'System.Boolean' {
      if ($Val -match '^(true|1|yes|on)$') { $SubObject.$Key = $true }
      elseif ($Val -match '^(false|0|no|off)$') { $SubObject.$Key = $false }
    }
    'System.String' {
      # Expand paths for strings (if not empty)
      if (! [string]::IsNullOrWhiteSpace($Val)) {
        $SubObject.$Key = Get-ExpandedPath $Val
      }
      else {
        $SubObject.$Key = ""
      }

      # Fix missing backslashes BEFORE the variable is used for further expansion
      $Config.Normalize()
    }
    Default {
      $SubObject.$Key = $Val
    }
  }

  <# Set variable in caller's scope for cross-references.
    Problem:
    - Users can use "shortcuts" in the configuration file:
      `BACKUP_BASE_DIR = C:\Backup\`
      `BACKUP_USER_BASE_DIR = ${BACKUP_BASE_DIR}\username\`
    - But the ScriptConfig object keeps variables in their own container ($Config.Directories.BACKUP_BASE_DIR).
      This means that Read-Config cannot easily re-use previous variables because it does not know that
      ${BACKUP_BASE_DIR} in the INI file is the same as $BACKUP_BASE_DIR in our script.
    - Read-Config needs to resolve these shortcuts when processing subsequent lines.

    Solution:
    "Scope Injection": the -Scope 1 tells PowerShell to create or update the variable in the caller's
    scope (Read-Config).

    This allows:
    - Subsequent lines in the INI file to use variables like ${BACKUP_BASE_DIR} because we created
      a local variable $BACKUP_BASE_DIR in Read-Config.
    - `Get-ExpandedPath` (called in the next iteration) to find and replace these variables using
      PowerShell's internal `ExpandString` mechanism.
  #>
  Set-Variable -Name $Key -Value $SubObject.$Key -Scope 1
}

#TODO: Add Pester tests for Read-Config (as the other ones for Read-SettingsFile)
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

  # Temporarily disable -WhatIf to ensure the configuration is loaded into the script scope (PowerShell 5.1 workaround).
  $oldWhatIfPreference = $WhatIfPreference
  $WhatIfPreference = $false

  try {
    # Default to 'General' section for top-level settings (Finding 5)
    $TargetContainer = "General"

    switch -Regex -File $IniFile {
      '^\s*[#;]' { continue } # Skip comments
      '^\s*\[(.+)\]\s*$' {
        $IniHeader = $Matches[1].Trim()
        $TargetContainer = Get-Container -IniHeader $IniHeader
        if ($null -eq $TargetContainer) {
          Write-WarningMsg "Unrecognized section in INI file: [$IniHeader]"
        }
      }
      '^\s*([^=]+)=(.*)$' {
        if ($TargetContainer) {
          $Key = $Matches[1].Trim() # $Matches[1] -> Regex capture group 1
          $Val = $Matches[2].Trim()
          Update-ConfigProperty -Config $Config -TargetContainer $TargetContainer -Key $Key -Val $Val
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
