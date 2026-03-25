#region Helper functions

function Get-ComputernameFromUncPath {
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$unc_path
  )

  # Check if this really is a UNC path.
  if ( ! ( [bool]([System.Uri]"${unc_path}").IsUnc ) ) {
    Write-Error "Get-ComputernameFromUncPath(): Not a UNC path: ${unc_path}"
    Throw "Not a UNC path: ${unc_path}"
  }

  $temp = "${unc_path}".Replace("\\", "")
  $pos = "${temp}".IndexOf("\")

  if ($pos -eq -1) {
    return "${temp}"
  } else {
    return "${temp}".Substring(0, $pos)
  }

}

#endregion Helper functions



#region Availability checks

function Test-ServerIsAvailable {
  # Returns $true if the specified server is available; otherwise $false.
  [OutputType([System.Boolean])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$ServerPathSpec
  )

  # https://devblogs.microsoft.com/scripting/powertip-use-powershell-to-check-if-computer-is-up/
  # Test-Connection -BufferSize 32 -Count 1 -ComputerName 192.168.0.41 -Quiet

  $server_name = Get-ComputernameFromUncPath "${ServerPathSpec}"

  try {
    $available = Test-Connection -BufferSize 32 -Count 1 -ComputerName "${server_name}" -Quiet -ErrorAction Stop
  } catch {
    $available = $false
  }
  return $available

}

#endregion Availability checks #################################################
