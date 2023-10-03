#region Helper functions

function Write-FormattedValueList {
  [CmdletBinding()]
  param (
    #TODO: [Parameter(Mandatory=$true)]
    #[Parameter(Mandatory=$true)]
    #[AllowEmptyCollection()]
    [System.Collections.ArrayList]$var_names,
    #TODO: [Parameter(Mandatory=$true)]
    #[Parameter(Mandatory=$true)]
    #[AllowEmptyCollection()]
    [System.Collections.ArrayList]$var_values
  )

  #region Check parameters
  if ($PSBoundParameters.Count -eq 0) {
    Write-Error "Write-FormattedValueList(): No parameters provided!"
    Throw "No parameters provided!"
  }

  #TODO: [Parameter(Mandatory=$true)] for var_names
  if (! $PSBoundParameters.ContainsKey('var_names')) {
    Write-Error "Write-FormattedValueList(): Parameter var_names not provided!"
    Throw "Parameter var_names not provided!"
  }

  #TODO: [Parameter(Mandatory=$true)] for var_values
  # [...]
  #endregion Check parameters

  [System.Collections.ArrayList]$var_names_same_length = New-Object System.Collections.ArrayList

  # Determine the longest variable name.
  $max_length = $( $var_names | Sort-Object length -desc | Select-Object -first 1 ).Length

  # Make shorter variable names longer.
  for ($i = 0; $i -lt $var_names.Count; $i++) {
    $var_name = $($var_names[$i])
    $num_spaces_to_add = $( $max_length - $var_name.Length )
    $var_name_with_spaces = "${var_name}" + (" " * $num_spaces_to_add)
    $var_names_same_length.Add("${var_name_with_spaces}") > $null

  }

  # Show debug messages.
  Write-DebugMsg "--------------------------------------------------------------------------------"
  Write-DebugMsg "Values from the settings file:"
  for ($i = 0; $i -lt $var_names.Count; $i++) {
    Write-DebugMsg "$($var_names_same_length[$i]): $($var_values[$i])"
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
    [Parameter(Mandatory=$true)]
    [String]$ini_file
  )

  [System.Collections.ArrayList]$var_names = New-Object System.Collections.ArrayList
  [System.Collections.ArrayList]$var_values = New-Object System.Collections.ArrayList

  $ini_file_content = Get-Content "${ini_file}"

  ForEach($line in $ini_file_content) {
    if (
      ($line -ne "") -and               # Empty line
      (! $line.StartsWith("[")) -and    # Section
      (! $line.StartsWith(";")) -and    # Commented out
      ($line.Contains("="))
    ) {
      $var_name = ($line -split "=")[0]
      $var_value = ($line -split "=")[1]

      # Store for debug messages.
      $var_names.Add("${var_name}") > $null
      $var_values.Add("${var_value}") > $null

      # Interpret numeric values as Int32; others as String.
      if (Test-IsNumeric $var_value) {
        [Int32]$int_value = $var_value
        Set-Variable -Name "${var_name}" -Value $int_value -Scope script

      } elseif ( ${var_value} -is [String] ) {
        $expanded = Get-ExpandedPath "${var_value}"
        Set-Variable -Name "${var_name}" -Value "${expanded}" -Scope script

      }

    }

  }

  if ($var_names.Count -gt 0) {
    Write-FormattedValueList $var_names $var_values
  }

}
