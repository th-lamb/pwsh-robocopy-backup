using module '..\..\..\..\lib\config-classes.psm1'

# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath

  $script:Config = [ScriptConfig]::new()

  $script:ExpectedTemplatesDir = Join-Path $ProjectRoot "templates\"

  $script:ExpectedDirListTemplates = Join-Path $ProjectRoot "templates\dir-list-template.conf"
  $script:ExpectedJobTemplateIncr = Join-Path $ProjectRoot "templates\incr_backup.RCJ"
  $script:ExpectedJobTemplateFull = Join-Path $ProjectRoot "templates\full_backup.RCJ"
  $script:ExpectedJobTemplatePurge = Join-Path $ProjectRoot "templates\purge.RCJ"
  $script:ExpectedJobTemplateArchive = Join-Path $ProjectRoot "templates\only_archive_attr.RCJ"
  $script:ExpectedJobTemplateGlobalExclusions = Join-Path $ProjectRoot "templates\global_exclusions.RCJ"
  $script:ExpectedJobTemplateLogging = Join-Path $ProjectRoot "templates\logging.RCJ"
}



Describe 'ScriptConfig' {
  Context 'Top-Level Structure' {
    $TopLevelContainers = @(
      @{ ExpectedNames = @("General", "Directories", "Files", "Logging", "Jobs", "Archiving") }
    )

    It 'should have all expected internal containers' -TestCases $TopLevelContainers {
      param($ExpectedNames)
      $properties = $script:Config | Get-Member -MemberType Property

      $properties.Count | Should -Be $ExpectedNames.Count
      foreach ($name in $ExpectedNames) {
        $properties.Name | Should -Contain $name
      }
    }

    $TopLevelContainerTypes = @(
      @{ ContainerName = "General";     ExpectedType = "GeneralSettings" }
      @{ ContainerName = "Directories"; ExpectedType = "DirectorySettings" }
      @{ ContainerName = "Files";       ExpectedType = "FileSettings" }
      @{ ContainerName = "Logging";     ExpectedType = "LoggingSettings" }
      @{ ContainerName = "Jobs";        ExpectedType = "JobSettings" }
      @{ ContainerName = "Archiving";   ExpectedType = "ArchivingSettings" }
    )

    It 'Container <ContainerName> has correct type' -TestCases $TopLevelContainerTypes {
      param($ContainerName, $ExpectedType)
      $script:Config.$ContainerName.GetType().Name | Should -Be $ExpectedType
    }
  }

  Context 'Second-Level Structure' {
    $SecondLevelProperties = @(
      @{ ContainerName = "General";     ExpectedProperties = @("__VERBOSE") }
      @{ ContainerName = "Directories"; ExpectedProperties = @("BACKUP_BASE_DIR", "BACKUP_DIR", "BACKUP_JOB_DIR", "BACKUP_TEMPLATES_DIR", "BACKUP_USER_BASE_DIR") }
      @{ ContainerName = "Files";       ExpectedProperties = @("DIRLIST_TEMPLATE", "BACKUP_DIRLIST", "JOB_TEMPLATE_INCR", "JOB_TEMPLATE_FULL", "JOB_TEMPLATE_PURGE", "JOB_TEMPLATE_ARCHIVE", "JOB_TEMPLATE_GLOBAL_EXCLUSIONS", "JOB_TEMPLATE_LOGGING", "ROBOCOPY") }
      @{ ContainerName = "Logging";     ExpectedProperties = @("BACKUP_LOGFILE", "ERROR_LOGFILE", "ENABLE_TRACE_LOG", "TRACE_LOG_LOCAL_DIR", "TRACE_LOGFILE_NAME", "UPLOAD_TRACE_TO_BACKUP_DIR") }
      @{ ContainerName = "Jobs";        ExpectedProperties = @("JOB_TYPE_SELECTION_MAX_WAITING_TIME_S", "DEFAULT_JOB_TYPE", "JOB_FILE_NAME_SCHEME", "JOB_LOGFILE_NAME_SCHEME") }
      @{ ContainerName = "Archiving";   ExpectedProperties = @("ARCHIVE_NAME_SCHEME", "MAX_ARCHIVES_COUNT") }
    )

    It 'should have all expected properties in Container <ContainerName>' -TestCases $SecondLevelProperties {
      param($ContainerName, $ExpectedProperties)
      $Container = $script:Config.$ContainerName
      $properties = $Container | Get-Member -MemberType Property

      $properties.Count | Should -Be $ExpectedProperties.Count
      foreach ($p in $ExpectedProperties) {
        $properties.Name | Should -Contain $p
      }
    }

    $SecondLevelPropertiesTypes = @(
      @{ Container = "General";     Property = "__VERBOSE";                      ExpectedType = "int32" }

      @{ Container = "Directories"; Property = "BACKUP_BASE_DIR";                ExpectedType = "string" }
      @{ Container = "Directories"; Property = "BACKUP_USER_BASE_DIR";           ExpectedType = "string" }
      @{ Container = "Directories"; Property = "BACKUP_DIR";                     ExpectedType = "string" }
      @{ Container = "Directories"; Property = "BACKUP_TEMPLATES_DIR";           ExpectedType = "string" }
      @{ Container = "Directories"; Property = "BACKUP_JOB_DIR";                 ExpectedType = "string" }

      @{ Container = "Files";       Property = "DIRLIST_TEMPLATE";               ExpectedType = "string" }
      @{ Container = "Files";       Property = "BACKUP_DIRLIST";                 ExpectedType = "string" }
      @{ Container = "Files";       Property = "JOB_TEMPLATE_INCR";              ExpectedType = "string" }
      @{ Container = "Files";       Property = "JOB_TEMPLATE_FULL";              ExpectedType = "string" }
      @{ Container = "Files";       Property = "JOB_TEMPLATE_PURGE";             ExpectedType = "string" }
      @{ Container = "Files";       Property = "JOB_TEMPLATE_ARCHIVE";           ExpectedType = "string" }
      @{ Container = "Files";       Property = "JOB_TEMPLATE_GLOBAL_EXCLUSIONS"; ExpectedType = "string" }
      @{ Container = "Files";       Property = "JOB_TEMPLATE_LOGGING";           ExpectedType = "string" }
      @{ Container = "Files";       Property = "ROBOCOPY";                       ExpectedType = "string" }

      @{ Container = "Logging";     Property = "BACKUP_LOGFILE";                 ExpectedType = "string" }
      @{ Container = "Logging";     Property = "ERROR_LOGFILE";                  ExpectedType = "string" }
      @{ Container = "Logging";     Property = "ENABLE_TRACE_LOG";               ExpectedType = "Boolean" }
      @{ Container = "Logging";     Property = "TRACE_LOG_LOCAL_DIR";            ExpectedType = "string" }
      @{ Container = "Logging";     Property = "TRACE_LOGFILE_NAME";             ExpectedType = "string" }
      @{ Container = "Logging";     Property = "UPLOAD_TRACE_TO_BACKUP_DIR";     ExpectedType = "Boolean" }

      @{ Container = "Jobs";        Property = "JOB_TYPE_SELECTION_MAX_WAITING_TIME_S"; ExpectedType = "int32" }
      @{ Container = "Jobs";        Property = "DEFAULT_JOB_TYPE";              ExpectedType = "string" }
      @{ Container = "Jobs";        Property = "JOB_FILE_NAME_SCHEME";          ExpectedType = "string" }
      @{ Container = "Jobs";        Property = "JOB_LOGFILE_NAME_SCHEME";       ExpectedType = "string" }

      @{ Container = "Archiving";   Property = "ARCHIVE_NAME_SCHEME";           ExpectedType = "string" }
      @{ Container = "Archiving";   Property = "MAX_ARCHIVES_COUNT";            ExpectedType = "int32" }
    )

    It 'Property <Container>.<Property> has correct type' -TestCases $SecondLevelPropertiesTypes {
      param($Container, $Property, $ExpectedType)
      $script:Config.$Container.$Property.GetType().Name | Should -Be $ExpectedType
    }
  }

  Context 'Default Initialization' {
    It 'GeneralSettings has expected default values' {
      $script:Config.General.__VERBOSE | Should -Be 6
    }

    It 'DirectorySettings has expected default paths' {
      $script:Config.Directories.BACKUP_BASE_DIR      | Should -Be ".\Backup\"
      $script:Config.Directories.BACKUP_USER_BASE_DIR | Should -Be ".\Backup\%Username%\"
      $script:Config.Directories.BACKUP_DIR           | Should -Be ".\Backup\%Username%\%Computername%\"

      # Note: $ProjectRoot in the module is calculated relative to the module's location.
      $script:Config.Directories.BACKUP_TEMPLATES_DIR | Should -Be $ExpectedTemplatesDir

      $script:Config.Directories.BACKUP_JOB_DIR       | Should -Be ".\Backup\%Username%\robocopy-jobs\"
    }

    It 'FileSettings has expected default filenames' {
      # Note: $ProjectRoot in the module is calculated relative to the module's location.
      $script:Config.Files.DIRLIST_TEMPLATE     | Should -Be $ExpectedDirListTemplates
      $script:Config.Files.BACKUP_DIRLIST       | Should -Be "dir-list.conf"

      # Note: $ProjectRoot in the module is calculated relative to the module's location.
      $script:Config.Files.JOB_TEMPLATE_INCR    | Should -Be $ExpectedJobTemplateIncr
      $script:Config.Files.JOB_TEMPLATE_FULL    | Should -Be $ExpectedJobTemplateFull
      $script:Config.Files.JOB_TEMPLATE_PURGE   | Should -Be $ExpectedJobTemplatePurge
      $script:Config.Files.JOB_TEMPLATE_ARCHIVE | Should -Be $ExpectedJobTemplateArchive

      $script:Config.Files.JOB_TEMPLATE_GLOBAL_EXCLUSIONS | Should -Be $ExpectedJobTemplateGlobalExclusions
      $script:Config.Files.JOB_TEMPLATE_LOGGING           | Should -Be $ExpectedJobTemplateLogging

      $script:Config.Files.ROBOCOPY | Should -Be "robocopy"
    }

    It 'LoggingSettings has expected default values' {
      $script:Config.Logging.BACKUP_LOGFILE | Should -Be "Backup.log"
      $script:Config.Logging.ERROR_LOGFILE  | Should -Be "Error.log"

      $script:Config.Logging.ENABLE_TRACE_LOG           | Should -Be $true
      $script:Config.Logging.TRACE_LOG_LOCAL_DIR        | Should -Be "%Temp%\"
      $script:Config.Logging.TRACE_LOGFILE_NAME         | Should -Be "Trace.log"
      $script:Config.Logging.UPLOAD_TRACE_TO_BACKUP_DIR | Should -Be $true
    }

    It 'JobSettings has expected default values' {
      $script:Config.Jobs.JOB_TYPE_SELECTION_MAX_WAITING_TIME_S | Should -Be 30
      $script:Config.Jobs.DEFAULT_JOB_TYPE                      | Should -Be "Incremental"

      $script:Config.Jobs.JOB_FILE_NAME_SCHEME    | Should -Be "${COMPUTERNAME}-Job*.RCJ"
      $script:Config.Jobs.JOB_LOGFILE_NAME_SCHEME | Should -Be "${COMPUTERNAME}-Job*.log"
    }

    It 'ArchivingSettings has expected default values' {
      $script:Config.Archiving.ARCHIVE_NAME_SCHEME  | Should -Be "${COMPUTERNAME}-Jobs-*.zip"
      $script:Config.Archiving.MAX_ARCHIVES_COUNT   | Should -Be 10
    }
  }

  Context 'Normalization' {
    It 'should normalize directory paths with trailing backslashes' {
      # Set paths without trailing backslashes - using C: to ensure it works on Windows
      $script:Config.Directories.BACKUP_BASE_DIR = "C:\Backup"
      $script:Config.Logging.TRACE_LOG_LOCAL_DIR = "C:\Logs"

      $script:Config.Normalize()

      $script:Config.Directories.BACKUP_BASE_DIR | Should -Be "C:\Backup\"
      $script:Config.Logging.TRACE_LOG_LOCAL_DIR | Should -Be "C:\Logs\"
    }
  }
}
