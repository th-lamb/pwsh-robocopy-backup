#region Object types

function RealFsObjectType
{
  <#
  Returns the type of the specified FS object; or $false for non-existent directory/file.
  #>
  param (
    [String]$path_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('path_spec'))
  {
    Write-Error "RealFsObjectType(): Parameter path_spec not provided!"
    exit 1
  }
  #endregion

  $specified_type = SpecifiedFsObjectType "${path_spec}"

  <#
  We have to "manually" check for a UNC path first because Test-Path recognizes
  network shares like "\\fileserver\backup\" as directory.
  Since this script cannot create a network share, we have to distinguish 
  between directory and network share.
  #>

  #TODO: This doesn't test if a share really exists or is available!
  switch ("${specified_type}")
  {
    "network share"     { return "${specified_type}" }
    "network computer"  { return "${specified_type}" }
  }

  # Existing directory/file
  <#
    ----------------------------------------------------------------------------
    https://github.com/PowerShell/PowerShell/issues/6473
    [...]
    Given that they lack a -Force switch, the following cmdlets are currently fundamentally incapable of finding hidden items via wildcards:

        Test-Path, Convert-Path, Resolve-Path, Split-Path -Resolve, Join-Path -Resolve, Invoke-Item
    [...]
    ----------------------------------------------------------------------------
  #>
  if (Test-Path -Path "${path_spec}" -PathType Container)
  {
    if ("${specified_type}" -eq "drive letter")
    {
      return "drive letter"
    }
    else
    {
      return "directory"
    }
  }
  elseif (Test-Path -Path "${path_spec}" -PathType Leaf)
  {
    return "file"
  }

  # In case the type is not known yet (e.g. Test-Path found no matching file).
  Test-Path -Path "${path_spec}" -PathType Any  # False for non-existent directory/file

}

function SpecifiedFsObjectType
{
  param (
    [String]$path_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('path_spec'))
  {
    Write-Error "SpecifiedFsObjectType(): Parameter path_spec not provided!"
    exit 1
  }
  #endregion

  # Test 1: syntax errors
  if ("${path_spec}" -eq "")
  {
    return "empty string"
  }

  # Test 2: drive letter
  $test_driveletter = "${path_spec}" | Select-String -Pattern '^[A-Z]:\\{0,1}$'
  if ("${path_spec}" -eq "${test_driveletter}")
  {
    return "drive letter"
  }

  # Test 3: network share or network computer.
  $is_unc_path=[bool]([System.Uri]"${path_spec}").IsUnc
  if ($is_unc_path)
  {
    <#
    Top-level element : server
    Second element    : share
    Further elements  : directories/files (that we might be able to create)
    #>

    $test_dir = "${path_spec}" | Select-String -Pattern '\\\\.+\\.+\\.+\\'
    $test_file = "${path_spec}" | Select-String -Pattern '\\\\.+\\.+\\.{1}'
    $test_share = "${path_spec}" | Select-String -Pattern '\\\\.+\\.+[\\]?'
    $test_computer = "${path_spec}" | Select-String -Pattern '\\\\.+[\\]?'

    if ("${test_dir}" -ne "")
    {
      # A directory
      #NOP: Check for directory or directory pattern later.
    }
    elseif ("${test_file}" -ne "")
    {
      # A file
      #NOP: Check for file or file pattern later.
    }
    elseif ("${test_share}" -ne "")
    {
      return "network share"  # The network share itself, not a subfolder or file.
    }
    elseif ("${test_computer}" -ne "")
    {
      return "network computer"  # The network computer itself, not a share.
    }
  }

  # Test 4: directory (pattern) or file (pattern).
  $is_pattern = $false
  $is_directory = $false
  $is_file = $false
  $is_directory_entry = $false
  $result = ""

  # conditions
  if ("${path_spec}".Contains("*"))
  {
    $is_pattern = $true
  }

  if ("${path_spec}".EndsWith("\"))
  {
    $is_directory = $true
  }
  else
  {
    $is_file = $true
  }

  if ("${path_spec}".EndsWith("\.") -or "${path_spec}".EndsWith("\.."))
  {
    $is_directory_entry = $true
  }

  # Combine the conditions.
  if ($is_directory -and ! $is_pattern)
  {
    $result = "directory"
  }
  elseif ($is_directory_entry)
  {
    $result = "directory entry"
  }
  elseif ($is_file -and ! $is_pattern)
  {
    $result = "file"
  }
  elseif ($is_pattern)
  {
    # Directory pattern or file pattern

    # We cannot just use (Split-Path -Path "${path_spec}").Contains("*") because 
    # it would give us the parent directory if $path_spec itself is a directory!
    $first_placeholder_pos = "${path_spec}".IndexOf('*')            # -1 if not found
    $last_path_separator_pos = "${path_spec}".LastIndexOf("\")      # -1 if not found

    if ( ($first_placeholder_pos -lt $last_path_separator_pos) )
    {
      $result = "directory pattern"
    }
    else
    {
      $result = "file pattern"
    }

  }

  "${result}"

}

function SpecifiedBackupBaseDirType
{
  param (
    [String]$path_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('path_spec'))
  {
    Write-Error "SpecifiedBackupBaseDirType(): Parameter path_spec not provided!"
    exit 1
  }
  #endregion

  $specified_type = SpecifiedFsObjectType "${path_spec}"

  switch ("${specified_type}")
  {
    "directory"
    {
      if ("${path_spec}".StartsWith("\\"))
      {
        return "directory"
      }
      else
      {
        if ("${path_spec}".Contains(":"))
        {
          return "directory"
        }
        else
        {
          return "relative path"
        }
      }
    }
    Default { return "${specified_type}" }
  }

}

#endregion Object types ########################################################



#region Existence checks

function FolderExists
{
  # Returns $true if the specified folder exists; otherwise $false.
  param (
    [String]$folder_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('folder_spec'))
  {
    Write-Error "FolderExists(): Parameter folder_spec not provided!"
    exit 1
  }
  #endregion

  if (Test-Path -Path "${folder_spec}" -PathType Container)
  {
    return $true
  }

  return $false

}

function FileExists
{
  # Returns $true if the specified file exists; otherwise $false.
  param (
    [String]$file_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('file_spec'))
  {
    Write-Error "FileExists(): Parameter file_spec not provided!"
    exit 1
  }
  #endregion

  if (Test-Path -Path "${file_spec}" -PathType Leaf)
  {
    return $true
  }

  return $false

}

function CheckNecessaryDirectory
{
  # Exits the script with exit-code 2 if the specified directory doesn't exist.
  param (
    [String]$definition_name,
    [String]$directory_spec,
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('definition_name'))
  {
    Write-Error "CheckNecessaryDirectory(): Parameter definition_name not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('directory_spec'))
  {
    Write-Error "CheckNecessaryDirectory(): Parameter directory_spec not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "CheckNecessaryDirectory(): Parameter logfile not provided!"
    exit 1
  }
  #endregion

  if (! (FolderExists "${directory_spec}") )
  {
    LogAndShowMessage "${logfile}" ERR "The directory '${definition_name}' has been moved or deleted:`n${directory_spec}"

    Write-Host -NoNewLine "Press any key to abort..."
    [void][System.Console]::ReadKey($true)

    exit 2

  }

  return 0

}

function CheckNecessaryFile
{
  # Exits the script with exit-code 2 if the specified file doesn't exist.
  param (
    [String]$definition_name,
    [String]$file_spec,
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('definition_name'))
  {
    Write-Error "CheckNecessaryFile(): Parameter definition_name not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('file_spec'))
  {
    Write-Error "CheckNecessaryFile(): Parameter file_spec not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "CheckNecessaryFile(): Parameter logfile not provided!"
    exit 1
  }
  #endregion

  if (! (FileExists "${file_spec}") )
  {
    LogAndShowMessage "${logfile}" ERR "The file '${definition_name}' has been moved or deleted:`n${file_spec}"

    Write-Host -NoNewLine "Press any key to abort..."
    [void][System.Console]::ReadKey($true)

    exit 2

  }

  return 0

}

function GetExecutablePath
{
  <#
  Returns the path to the specified executable if it exists.
  Also searches in the Windows PATH environment variable.
  Exits the script with exit-code 2 if the specified file doesn't exist.
  #>
  param (
    [String]$definition_name,
    [String]$file_spec,
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('definition_name'))
  {
    Write-Error "CheckNecessaryFile(): Parameter definition_name not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('file_spec'))
  {
    Write-Error "CheckNecessaryFile(): Parameter file_spec not provided!"
    exit 1
  }

  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "CheckNecessaryFile(): Parameter logfile not provided!"
    exit 1
  }
  #endregion

  if (FileExists "${file_spec}")
  {
    return "${file_spec}"
  }

  $file_in_path = (Get-Command "${file_spec}").Path

  if ("${file_in_path}" -ne "")
  {
    ShowDebugMsg "'${definition_name}' found via Windows PATH environment variable: ${file_in_path}"
    return "${file_in_path}"
  }
  else
  {
    LogAndShowMessage "${logfile}" ERR "The file '${definition_name}' has been moved or deleted:`n${file_spec}"

    Write-Host -NoNewLine "Press any key to abort..."
    [void][System.Console]::ReadKey($true)

    exit 2

  }

}

#endregion Existence checks ####################################################



#region Object creation

function CreateNecessaryDirectory
{
  <#
  Creates the specified directory and all parent folders if necessary.
  #>
  param (
    [String]$definition_name,
    [String]$dir_spec,
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('definition_name'))
  {
    Write-Error "CreateNecessaryDirectory(): Parameter definition_name not provided!"
    Throw "Parameter definition_name not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('dir_spec'))
  {
    Write-Error "CreateNecessaryDirectory(): Parameter dir_spec not provided!"
    Throw "Parameter dir_spec not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "CreateNecessaryDirectory(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }
  #endregion

  <#
  https://stackoverflow.com/a/63311340
  `New-Item -ItemType "directory" -Path ...`    : Fails if the directory already exists!
  `New-Item ... -Force`                         : Doesn't show an error if there already is a *file* with the same name!
  `[System.IO.Directory]::CreateDirectory(...)` : Creates the directory if necessary, and fails if there is a file with the same name.
  #>

  try {
    [System.IO.Directory]::CreateDirectory("${dir_spec}") | Out-Null
  }
  catch
  {
    LogAndShowMessage "${logfile}" ERR "Cannot create '${definition_name}' ${dir_spec}. Error: $_"
    Throw
  }

}

function CreateNecessaryFile
{
  <#
  Creates the specified file from the specified template.
  Returns $true if the file has been copied; otherwise $false.
  #>
  param (
    [String]$definition_name,
    [String]$file_spec,
    [String]$template,
    [String]$logfile
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('definition_name'))
  {
    Write-Error "CreateNecessaryFile(): Parameter definition_name not provided!"
    Throw "Parameter definition_name not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('file_spec'))
  {
    Write-Error "CreateNecessaryFile(): Parameter file_spec not provided!"
    Throw "Parameter file_spec not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('template'))
  {
    Write-Error "CreateNecessaryFile(): Parameter template not provided!"
    Throw "Parameter template not provided!"
  }

  if (! $PSBoundParameters.ContainsKey('logfile'))
  {
    Write-Error "CreateNecessaryFile(): Parameter logfile not provided!"
    Throw "Parameter logfile not provided!"
  }
  #endregion

  if (FileExists "${file_spec}")
  {
    return $false
  }

  try {
    #TODO: Copy-Item doesn't warn if it failed because a directory with the same name exists!
    Copy-Item -Path "${template}" -Destination "${file_spec}"
    LogAndShowMessage "${logfile}" INFO "File created from template."
    return $true
  }
  catch
  {
    LogAndShowMessage "${logfile}" ERR "Cannot create '${definition_name}' ${file_spec}. Error: $_"
    Throw
  }

}

#region Object creation ########################################################



#region Get-KnownFolderPath

# How-to: Get or Set Special Folders with PowerShell
# https://ss64.com/ps/syntax-knownfolders.html

<#
.SYNOPSIS
    Provides Get and Set functions for KnownFolders: Get-KnownFolderPath, Set-KnownFolderPath
    Any changes made will only affect the current user (HKCU).
.PARAMETER Folder
    The known folder to be read.
.PARAMETER KnownFolder
    The known folder whose path is to be set.
.PARAMETER Path
    The path to be set as the destination of KnownFolder.
.EXAMPLE
    PS> # dot source this script to make the functions available
    PS> . ./knownfolder.ps1
    
    PS> # Get the desktop path
    PS> Get-KnownFolderPath 'Desktop'
.EXAMPLE
    PS> # Set the desktop path
    PS> Set-KnownFolderPath 'Desktop' -path $ENV:USERPROFILE/Desktop
.LINK
    https://docs.microsoft.com/en-us/windows/win32/shell/known-folders
.LINK
    https://stackoverflow.com/questions/25709398/set-location-of-special-folders-with-powershell
.LINK
    https://renenyffenegger.ch/notes/Windows/dirs/_known-folders
#>
function Get-KnownFolderPath
{
    Param (
            [Parameter(Mandatory = $true)]
            [ValidateSet('3DObjects', 'AddNewPrograms', 'AdminTools', 'AppUpdates', 'CDBurning', 'ChangeRemovePrograms', 'CommonAdminTools', 'CommonOEMLinks', 'CommonPrograms', 'CommonStartMenu', 'CommonStartup', 'CommonTemplates', 'ComputerFolder', 'ConflictFolder', 'ConnectionsFolder', 'Contacts', 'ControlPanelFolder', 'Cookies', 'Desktop', 'Documents', 'Downloads', 'Favorites', 'Fonts', 'Games', 'GameTasks', 'History', 'InternetCache', 'InternetFolder', 'Links', 'LocalAppData', 'LocalAppDataLow', 'LocalizedResourcesDir', 'Music', 'NetHood', 'NetworkFolder', 'OriginalImages', 'PhotoAlbums', 'Pictures', 'Playlists', 'PrintersFolder', 'PrintHood', 'Profile', 'ProgramData', 'ProgramFiles', 'ProgramFilesX64', 'ProgramFilesX86', 'ProgramFilesCommon', 'ProgramFilesCommonX64', 'ProgramFilesCommonX86', 'Programs', 'Public', 'PublicDesktop', 'PublicDocuments', 'PublicDownloads', 'PublicGameTasks', 'PublicMusic', 'PublicPictures', 'PublicVideos', 'QuickLaunch', 'Recent', 'RecycleBinFolder', 'ResourceDir', 'RoamingAppData', 'SampleMusic', 'SamplePictures', 'SamplePlaylists', 'SampleVideos', 'SavedGames', 'SavedSearches', 'SEARCH_CSC', 'SEARCH_MAPI', 'SearchHome', 'SendTo', 'SidebarDefaultParts', 'SidebarParts', 'StartMenu', 'Startup', 'SyncManagerFolder', 'SyncResultsFolder', 'SyncSetupFolder', 'System', 'SystemX86', 'Templates', 'TreeProperties', 'UserProfiles', 'UsersFiles', 'Videos', 'Windows')]
            [string]$Folder
    )

    # Define known folder GUIDs
    $KnownFolders = @{
        '3DObjects' = '31C0DD25-9439-4F12-BF41-7FF4EDA38722';
        'AddNewPrograms' = 'de61d971-5ebc-4f02-a3a9-6c82895e5c04';
        'AdminTools' = '724EF170-A42D-4FEF-9F26-B60E846FBA4F';
        'AppUpdates' = 'a305ce99-f527-492b-8b1a-7e76fa98d6e4';
        'CDBurning' = '9E52AB10-F80D-49DF-ACB8-4330F5687855';
        'ChangeRemovePrograms' = 'df7266ac-9274-4867-8d55-3bd661de872d';
        'CommonAdminTools' = 'D0384E7D-BAC3-4797-8F14-CBA229B392B5';
        'CommonOEMLinks' = 'C1BAE2D0-10DF-4334-BEDD-7AA20B227A9D';
        'CommonPrograms' = '0139D44E-6AFE-49F2-8690-3DAFCAE6FFB8';
        'CommonStartMenu' = 'A4115719-D62E-491D-AA7C-E74B8BE3B067';
        'CommonStartup' = '82A5EA35-D9CD-47C5-9629-E15D2F714E6E';
        'CommonTemplates' = 'B94237E7-57AC-4347-9151-B08C6C32D1F7';
        'ComputerFolder' = '0AC0837C-BBF8-452A-850D-79D08E667CA7';
        'ConflictFolder' = '4bfefb45-347d-4006-a5be-ac0cb0567192';
        'ConnectionsFolder' = '6F0CD92B-2E97-45D1-88FF-B0D186B8DEDD';
        'Contacts' = '56784854-C6CB-462b-8169-88E350ACB882';
        'ControlPanelFolder' = '82A74AEB-AEB4-465C-A014-D097EE346D63';
        'Cookies' = '2B0F765D-C0E9-4171-908E-08A611B84FF6';
        'Desktop' = 'B4BFCC3A-DB2C-424C-B029-7FE99A87C641';
        'Documents' = 'FDD39AD0-238F-46AF-ADB4-6C85480369C7';
        'Downloads' = '374DE290-123F-4565-9164-39C4925E467B';
        'Favorites' = '1777F761-68AD-4D8A-87BD-30B759FA33DD';
        'Fonts' = 'FD228CB7-AE11-4AE3-864C-16F3910AB8FE';
        'Games' = 'CAC52C1A-B53D-4edc-92D7-6B2E8AC19434';
        'GameTasks' = '054FAE61-4DD8-4787-80B6-090220C4B700';
        'History' = 'D9DC8A3B-B784-432E-A781-5A1130A75963';
        'InternetCache' = '352481E8-33BE-4251-BA85-6007CAEDCF9D';
        'InternetFolder' = '4D9F7874-4E0C-4904-967B-40B0D20C3E4B';
        'Links' = 'bfb9d5e0-c6a9-404c-b2b2-ae6db6af4968';
        'LocalAppData' = 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091';
        'LocalAppDataLow' = 'A520A1A4-1780-4FF6-BD18-167343C5AF16';
        'LocalizedResourcesDir' = '2A00375E-224C-49DE-B8D1-440DF7EF3DDC';
        'Music' = '4BD8D571-6D19-48D3-BE97-422220080E43';
        'NetHood' = 'C5ABBF53-E17F-4121-8900-86626FC2C973';
        'NetworkFolder' = 'D20BEEC4-5CA8-4905-AE3B-BF251EA09B53';
        'OriginalImages' = '2C36C0AA-5812-4b87-BFD0-4CD0DFB19B39';
        'PhotoAlbums' = '69D2CF90-FC33-4FB7-9A0C-EBB0F0FCB43C';
        'Pictures' = '33E28130-4E1E-4676-835A-98395C3BC3BB';
        'Playlists' = 'DE92C1C7-837F-4F69-A3BB-86E631204A23';
        'PrintersFolder' = '76FC4E2D-D6AD-4519-A663-37BD56068185';
        'PrintHood' = '9274BD8D-CFD1-41C3-B35E-B13F55A758F4';
        'Profile' = '5E6C858F-0E22-4760-9AFE-EA3317B67173';
        'ProgramData' = '62AB5D82-FDC1-4DC3-A9DD-070D1D495D97';
        'ProgramFiles' = '905e63b6-c1bf-494e-b29c-65b732d3d21a';
        'ProgramFilesX64' = '6D809377-6AF0-444b-8957-A3773F02200E';
        'ProgramFilesX86' = '7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E';
        'ProgramFilesCommon' = 'F7F1ED05-9F6D-47A2-AAAE-29D317C6F066';
        'ProgramFilesCommonX64' = '6365D5A7-0F0D-45E5-87F6-0DA56B6A4F7D';
        'ProgramFilesCommonX86' = 'DE974D24-D9C6-4D3E-BF91-F4455120B917';
        'Programs' = 'A77F5D77-2E2B-44C3-A6A2-ABA601054A51';
        'Public' = 'DFDF76A2-C82A-4D63-906A-5644AC457385';
        'PublicDesktop' = 'C4AA340D-F20F-4863-AFEF-F87EF2E6BA25';
        'PublicDocuments' = 'ED4824AF-DCE4-45A8-81E2-FC7965083634';
        'PublicDownloads' = '3D644C9B-1FB8-4f30-9B45-F670235F79C0';
        'PublicGameTasks' = 'DEBF2536-E1A8-4c59-B6A2-414586476AEA';
        'PublicMusic' = '3214FAB5-9757-4298-BB61-92A9DEAA44FF';
        'PublicPictures' = 'B6EBFB86-6907-413C-9AF7-4FC2ABF07CC5';
        'PublicVideos' = '2400183A-6185-49FB-A2D8-4A392A602BA3';
        'QuickLaunch' = '52a4f021-7b75-48a9-9f6b-4b87a210bc8f';
        'Recent' = 'AE50C081-EBD2-438A-8655-8A092E34987A';
        'RecycleBinFolder' = 'B7534046-3ECB-4C18-BE4E-64CD4CB7D6AC';
        'ResourceDir' = '8AD10C31-2ADB-4296-A8F7-E4701232C972';
        'RoamingAppData' = '3EB685DB-65F9-4CF6-A03A-E3EF65729F3D';
        'SampleMusic' = 'B250C668-F57D-4EE1-A63C-290EE7D1AA1F';
        'SamplePictures' = 'C4900540-2379-4C75-844B-64E6FAF8716B';
        'SamplePlaylists' = '15CA69B3-30EE-49C1-ACE1-6B5EC372AFB5';
        'SampleVideos' = '859EAD94-2E85-48AD-A71A-0969CB56A6CD';
        'SavedGames' = '4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4';
        'SavedSearches' = '7d1d3a04-debb-4115-95cf-2f29da2920da';
        'SEARCH_CSC' = 'ee32e446-31ca-4aba-814f-a5ebd2fd6d5e';
        'SEARCH_MAPI' = '98ec0e18-2098-4d44-8644-66979315a281';
        'SearchHome' = '190337d1-b8ca-4121-a639-6d472d16972a';
        'SendTo' = '8983036C-27C0-404B-8F08-102D10DCFD74';
        'SidebarDefaultParts' = '7B396E54-9EC5-4300-BE0A-2482EBAE1A26';
        'SidebarParts' = 'A75D362E-50FC-4fb7-AC2C-A8BEAA314493';
        'StartMenu' = '625B53C3-AB48-4EC1-BA1F-A1EF4146FC19';
        'Startup' = 'B97D20BB-F46A-4C97-BA10-5E3608430854';
        'SyncManagerFolder' = '43668BF8-C14E-49B2-97C9-747784D784B7';
        'SyncResultsFolder' = '289a9a43-be44-4057-a41b-587a76d7e7f9';
        'SyncSetupFolder' = '0F214138-B1D3-4a90-BBA9-27CBC0C5389A';
        'System' = '1AC14E77-02E7-4E5D-B744-2EB1AE5198B7';
        'SystemX86' = 'D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27';
        'Templates' = 'A63293E8-664E-48DB-A079-DF759E0509F7';
        'TreeProperties' = '5b3749ad-b49f-49c1-83eb-15370fbd4882';
        'UserProfiles' = '0762D272-C50A-4BB0-A382-697DCD729B80';
        'UsersFiles' = 'f3ce0f7c-4901-4acc-8648-d5d44b04ef8f';
        'Videos' = '18989B1D-99B5-455B-841C-AB7C74E4DDFC';
        'Windows' = 'F38BF404-1D43-42F2-9305-67DE0B28FC23';
    }

    $guid = $KnownFolders.$("$folder")

    #https://renenyffenegger.ch/notes/Windows/dirs/_known-folders
    if ("shell32" -as [type])
    {}
    else
    {
        add-type @"
            using System;
            using System.Runtime.InteropServices;

            public class shell32
            {
                [DllImport("shell32.dll")]
                private static extern int SHGetKnownFolderPath(
                    [MarshalAs(UnmanagedType.LPStruct)] 
                    Guid       rfid,
                    uint       dwFlags,
                    IntPtr     hToken,
                    out IntPtr pszPath
                );

                public static string GetKnownFolderPath(Guid rfid)
                {
                    IntPtr pszPath;
                    if (SHGetKnownFolderPath(rfid, 0, IntPtr.Zero, out pszPath) != 0)
                    {
                        return "Could not get folder";
                    }
                    string path = Marshal.PtrToStringUni(pszPath);
                    Marshal.FreeCoTaskMem(pszPath);
                    return path;
                }
            }
"@
    }

    # now get the folder from the GUID
    $result = $([shell32]::GetKnownFolderPath("{$($guid)}"))
    "$result"
}

#endregion Get-KnownFolderPath #################################################



#region Path functions

function expandedPath
{
  <#
  Expands the specified path in three ways:
  1. Script variables.          Example: ${BACKUP_BASE_DIR}\ becomes C:\Backup\
  2. Environment variables.     Example: %HOMEDRIVE% becomes C:
  3. (Windows) known folders.   Example: %Documents% becomes C:\Users\<username>\Documents
  #>
  param (
    [String]$path_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('path_spec'))
  {
    Write-Error "expandedPath(): Parameter path_spec not provided!"
    exit 1
  }
  #endregion

  # Expand script variables.
  $expanded = $ExecutionContext.InvokeCommand.ExpandString("${path_spec}")

  # Expand environment variables of the host.
  $expanded = ([System.Environment]::ExpandEnvironmentVariables("${expanded}"))

  <#
  Expand special folders (previously known as "User Shell Folders").
  We expect a known folder to be used in one of two ways:
  - <known_folder>, or
  - <known_folder>\subfolder
  #>
  $first_delim_pos = "${expanded}".IndexOf("%")

  if ($first_delim_pos -eq 0)   # Path starts with "%".
  {
    $second_delim_pos = "${expanded}".Substring(1).IndexOf("%")

    if (! ($second_delim_pos -eq -1) )  # Path contains another "%".
    {
      $known_folder_candidate = "${expanded}".Substring(1, $second_delim_pos)
      $sub_folder = "${expanded}".Substring($second_delim_pos + 2)

      $known_folder = Get-KnownFolderPath "${known_folder_candidate}"

      # Add trailing and remove leading "\".
      if (! "${known_folder}".EndsWith("\") )
      {
        $known_folder = "${known_folder}\"
      }

      if ("${sub_folder}".Length -ge 1) {
        if ("${sub_folder}".StartsWith("\") )
        {
          $sub_folder = "${sub_folder}".Substring(1)
        }
      }

      $expanded = "${known_folder}${sub_folder}"

    }

  }

  return "${expanded}"

}

function Get-ParentDir
{
  <#
  Returns the parent directory of the specified file (pattern).
  #>
  #TODO: Additional parameter "check_file_exists" needed?
  param (
    [String]$file_spec
  )

  #region Check parameters
  if (! $PSBoundParameters.ContainsKey('file_spec'))
  {
    Write-Error "Get-ParentDir(): Parameter file_spec not provided!"
    exit 1
  }
  #endregion

  ShowDebugMsg "Get-ParentDir(): file_spec     : ${file_spec}"

  # Handle "dot" files.
  # -> Resolve-Path -Path returns an array of all matching directories!
  if ( "${file_spec}".EndsWith("\.") )
  {
    $dot_evaluated = "${file_spec}".Replace("\.", "\")
  }
  elseif ( "${file_spec}".EndsWith("\..") )
  {
    $dot_evaluated = "${file_spec}".Replace("\..", "")
    $pos = "${dot_evaluated}".LastIndexOf("\")
    $dot_evaluated = "${dot_evaluated}".Substring(0, $pos + 1)
  }
  else
  {
    $dot_evaluated = "${file_spec}"
  }

  ShowDebugMsg "Get-ParentDir(): dots evaluated: ${dot_evaluated}"

  #TODO: Currently the most reliable way?
  $parent_dir = Split-Path -Path "${dot_evaluated}"
  ShowDebugMsg "Get-ParentDir(): parent_dir    : ${parent_dir}"

  # Append trailing backslash?
  if (
    (Test-Path "${parent_dir}" -PathType Container) -and
    (! "${parent_dir}".EndsWith("\") )
  )
  {
    $parent_dir = "${parent_dir}\"
    ShowDebugMsg "Get-ParentDir(): parent_dir    : ${parent_dir}"
  }

  return "${parent_dir}"

}

#endregion Path functions ######################################################
