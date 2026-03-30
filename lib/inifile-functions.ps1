#region Helper functions

function Write-FormattedValueList {
  [CmdletBinding()]
  param (
    [System.Collections.Generic.List[string]]$VarNames,
    [System.Collections.Generic.List[string]]$VarValues
  )

  #region Check parameters
  if ($PSBoundParameters.Count -ne 2) {
    Write-Error "Write-FormattedValueList(): Wrong number of parameters provided!"
    Throw "Wrong number of parameters provided!"
  }

  if ( $VarNames.Count -eq 0 ) {
    Write-WarningMsg "Write-FormattedValueList(): Parameter VarNames is an empty collection!"
    return
  }

  if ( $VarValues.Count -eq 0 ) {
    Write-WarningMsg "Write-FormattedValueList(): Parameter VarValues is an empty collection!"
    return
  }
  #endregion Check parameters

  $VarNamesSameLength = [System.Collections.Generic.List[string]]::new()

  # Determine the longest variable name.
  $MaxLength = $( $VarNames | Sort-Object length -desc | Select-Object -first 1 ).Length

  # Make shorter variable names longer.
  for ($i = 0; $i -lt $VarNames.Count; $i++) {
    $VarName = $($VarNames[$i])
    $NumSpacesToAdd = $( $MaxLength - $VarName.Length )
    $VarNameWithSpaces = "${VarName}" + (" " * $NumSpacesToAdd)
    $VarNamesSameLength.Add("${VarNameWithSpaces}")

  }

  # Show debug messages.
  Write-DebugMsg "--------------------------------------------------------------------------------"
  Write-DebugMsg "Values from the settings file:"
  for ($i = 0; $i -lt $VarNames.Count; $i++) {
    Write-DebugMsg "$($VarNamesSameLength[$i]): $($VarValues[$i])"
  }
  Write-DebugMsg "--------------------------------------------------------------------------------"

}

# https://stackoverflow.com/a/10939609/5944475
function Test-IsNumeric ($Value) {
  return $Value -match "^[\d\.]+$"
}

#endregion Helper functions ####################################################



function Read-SettingsFile {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]$IniFile
  )

  $VarNames = [System.Collections.Generic.List[string]]::new()
  $VarValues = [System.Collections.Generic.List[string]]::new()

  $IniFileContent = Get-Content "${IniFile}"

  # Temporarily disable -WhatIf to ensure the configuration is loaded into the script scope (PowerShell 5.1 workaround).
  $oldWhatIfPreference = $WhatIfPreference
  $WhatIfPreference = $false

  ForEach ($line in $IniFileContent) {
    if (
      ($line -ne "") -and # Empty line
      (! $line.StartsWith("[")) -and # Section
      (! $line.StartsWith(";")) -and # Commented out
      ($line.Contains("="))
    ) {
      $VarName = ($line -split "=")[0]
      $VarValue = ($line -split "=")[1]

      # Store for debug messages.
      $VarNames.Add("${VarName}")
      $VarValues.Add("${VarValue}")

      # Interpret numeric values as Int32; others as String.
      if (Test-IsNumeric $VarValue) {
        [Int32]$IntValue = $VarValue
        Set-Variable -Name "${VarName}" -Value $IntValue -Scope script

      }
      elseif ( ${VarValue} -is [String] ) {
        $expanded = Get-ExpandedPath "${VarValue}"
        Set-Variable -Name "${VarName}" -Value "${expanded}" -Scope script

      }

    }

  }

  $WhatIfPreference = $oldWhatIfPreference

  if ($VarNames.Count -gt 0) {
    Write-FormattedValueList $VarNames $VarValues
  }

}
