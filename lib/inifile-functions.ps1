#region Helper functions

function _debugPrintFormattedIniValues {
  param (
    [System.Collections.ArrayList]$var_names,
    [System.Collections.ArrayList]$var_values
  )

  [System.Collections.ArrayList]$var_names_same_length = New-Object System.Collections.ArrayList

  # Determine the longest variable name.
  $max_length = $( $var_names | sort length -desc | select -first 1 ).Length

  # Make shorter variable names longer.
  for ($i = 0; $i -lt $var_names.Count; $i++) {
    $var_name = $($var_names[$i])
    $num_spaces_to_add = $( $max_length - $var_name.Length )
    $var_name_with_spaces = "${var_name}" + (" " * $num_spaces_to_add)
    $var_names_same_length.Add("${var_name_with_spaces}") > $null

  }

  # Show debug messages.
  ShowDebugMsg "--------------------------------------------------------------------------------"
  ShowDebugMsg "Values from the settings file:"
  ShowDebugMsg ""
  for ($i = 0; $i -lt $var_names.Count; $i++) {
    ShowDebugMsg "$($var_names_same_length[$i]): $($var_values[$i])"
  }
  ShowDebugMsg "--------------------------------------------------------------------------------"

}

# https://stackoverflow.com/a/10939609/5944475
function Is-Numeric ($Value) {
  return $Value -match "^[\d\.]+$"
}

#endregion Helper functions ####################################################



function ReadSettingsFile {
  param (
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
      if ( Is-Numeric $var_value ) {
        [Int32]$int_value = $var_value
        Set-Variable -Name "${var_name}" -Value $int_value -Scope script

      } elseif ( ${var_value} -is [String] ) {
        $expanded = expandedPath "${var_value}"
        Set-Variable -Name "${var_name}" -Value "${expanded}" -Scope script

      }

    }

  }

  _debugPrintFormattedIniValues $var_names $var_values

}
