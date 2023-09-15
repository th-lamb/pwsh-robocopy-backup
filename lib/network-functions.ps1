#region Helper functions

function computernameFromUncPath
{
  param (
    [String]$unc_path
  )

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

function ServerIsAvailable
{
  # Returns $true if the specified server is available; otherwise $false.
  param (
    [String]$server_path_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('server_path_spec'))
  {
    Write-Error "ServerIsAvailable(): Parameter server_path_spec not provided!"
    Throw "Parameter server_path_spec not provided!"
  }
  #endregion

  # https://devblogs.microsoft.com/scripting/powertip-use-powershell-to-check-if-computer-is-up/
  # Test-Connection -BufferSize 32 -Count 1 -ComputerName 192.168.0.41 -Quiet

  $server_name = computernameFromUncPath "${server_path_spec}"
  #Write-Host "server_name : ${server_name}" -ForegroundColor Blue

  #$available = Test-Connection -BufferSize 32 -Count 1 -ComputerName "${server_name}" -Quiet

  #TODO: We can't catch the Ping exception for the blackhole prefix 240.0.0.0?
  try {
    $available = Test-Connection -BufferSize 32 -Count 1 -ComputerName "${server_name}" -Quiet

    #$available = (Test-Connection -BufferSize 32 -Count 1 -ComputerName "${server_name}")

    #if (Test-Connection -BufferSize 32 -Count 1 -ComputerName "${server_name}" -Quiet | Out-Null)
    #{
    #  $available = $true
    #}
  }
  catch [System.Net.NetworkInformation.PingException]
  {
    $available = $false
  }
  #Write-Host "available   : $available" -ForegroundColor Blue

  return $available

}

#endregion Availability checks #################################################
