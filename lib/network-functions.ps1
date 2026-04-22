#region Helper functions

function Get-ComputernameFromUncPath {
  [OutputType([System.String])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [string]$UncPath
  )

  # Check if this really is a UNC path.
  if ( ! ( [bool]([System.Uri]"${UncPath}").IsUnc ) ) {
    Write-Error "Get-ComputernameFromUncPath(): Not a UNC path: ${UncPath}"
    Throw "Not a UNC path: ${UncPath}"
  }

  $temp = "${UncPath}".Replace("\\", "")
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
  [OutputType([bool])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [string]$ServerPathSpec
  )

  $ServerName = Get-ComputernameFromUncPath "${ServerPathSpec}"

  # We check for SMB ports (445 and 139) because this script uses Robocopy.
  # Using TCP connection checks is more reliable than ICMP (Ping) because
  # some networks (like Hotel WiFis) hijack DNS and respond to Pings for
  # any hostname, but won't have SMB ports open.

  $ports = @(445, 139)
  foreach ($port in $ports) {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
      $asyncResult = $tcpClient.BeginConnect($ServerName, $port, $null, $null)
      $wait = $asyncResult.AsyncWaitHandle.WaitOne(1000, $false)
      if ($wait) {
        $tcpClient.EndConnect($asyncResult)
        $tcpClient.Close()
        return $true
      }
      $tcpClient.Close()
    }
    catch {
      $tcpClient.Close()
      return $false
    }
  }

  return $false

}

#endregion Availability checks #################################################
