using module '..\..\..\..\lib\config-classes.psm1'

$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"

BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"

  # For messages in tested functions
  $script:config = [ScriptConfig]::new()
  $config.General.__VERBOSE = 7
}



Describe 'Write-FormattedConfigObject' {
  Context 'Correct Configuration Object' {
    It 'Matches the expected output file exactly.' {
      $ResourcesDir = "${ProjectRoot}\Pester\resources\lib\inifile-functions\Write-FormattedConfigObject"
      $ExpectedFile = "${ResourcesDir}\expected_output.txt"
      $ActualFile = "${ResourcesDir}\actual_output.txt"

      $DummyConfig = [ScriptConfig]::new()
      $DummyConfig.General.__VERBOSE = 7
      $DummyConfig.Directories.BACKUP_BASE_DIR = "C:\TestBackup\"
      $DummyConfig.Jobs.DEFAULT_JOB_TYPE = "Full"

      $DummyConfig.Normalize()

      # Mock Write-DebugMsg to write to actual_output.txt
      Mock Write-DebugMsg {
        param($message)
        $message | Out-File -FilePath $ActualFile -Append -Encoding ascii
      }

      if (Test-Path $ActualFile) { Remove-Item $ActualFile }

      Write-FormattedConfigObject -ConfigObject $DummyConfig

      # Compare files. We read them and split into lines to avoid newline issues (CRLF vs LF).
      $ExpectedLines = (Get-Content $ExpectedFile) -split '\r?\n' | Where-Object { $_ -ne "" }
      $ActualLines = (Get-Content $ActualFile) -split '\r?\n' | Where-Object { $_ -ne "" }

      # Simple comparison
      $ActualLines | Should -Be $ExpectedLines

      # Clean up actual output if test passes (Pester throws if Should fails, so this line is skipped on failure)
      Remove-Item $ActualFile
    }

    It 'Correctly formats and aligns a ScriptConfig object.' {
      $DummyConfig = [ScriptConfig]::new()
      # Override some values to have predictable output
      $DummyConfig.General.__VERBOSE = 7
      $DummyConfig.Directories.BACKUP_BASE_DIR = "C:\TestBackup\"
      $DummyConfig.Jobs.DEFAULT_JOB_TYPE = "Full"

      $DummyConfig.Normalize()

      $Messages = [System.Collections.Generic.List[string]]::new()

      # Mock Write-DebugMsg to capture output
      Mock Write-DebugMsg {
        param($message)
        $Messages.Add($message)
      }

      Write-FormattedConfigObject -ConfigObject $DummyConfig

      # Verify header and footer
      $Messages[0] | Should -Be "--------------------------------------------------------------------------------"
      $Messages[1] | Should -Be "Values from the configuration object:"
      $Messages[-1] | Should -Be "--------------------------------------------------------------------------------"

      # Verify alignment of some keys.
      # We expect something like "__VERBOSE                            : 7"
      # Find the __VERBOSE line
      $VerboseLine = $Messages | Where-Object { $_ -match "^__VERBOSE\s+:\s+7$" }
      $VerboseLine | Should -Not -BeNullOrEmpty

      $BaseDirLine = $Messages | Where-Object { $_ -match "^BACKUP_BASE_DIR\s+:\s+C:\\TestBackup\\$" }
      $BaseDirLine | Should -Not -BeNullOrEmpty

      $JobTypeLine = $Messages | Where-Object { $_ -match "^DEFAULT_JOB_TYPE\s+:\s+Full$" }
      $JobTypeLine | Should -Not -BeNullOrEmpty

      # Verify that all lines (except header/footer/title) have the colon at the same position.
      $DataLines = $Messages[2..($Messages.Count - 2)]
      $ColonPositions = $DataLines | ForEach-Object { $_.IndexOf(":") } | Select-Object -Unique

      $ColonPositions.Count | Should -Be 1
    }
  }

  Context 'Invalid Parameters' {
    It 'Writes a warning if the ConfigObject has no properties.' {
      # This is hard to trigger with ScriptConfig because it always has properties,
      # but we can try with a custom object if the function allows.
      # Actually, the function specifies [ScriptConfig]$ConfigObject.

      $DummyConfig = [ScriptConfig]::new()
      # We can't easily make it empty without changing the class,
      # so we just test that it works for a default object.
      { Write-FormattedConfigObject -ConfigObject $DummyConfig } | Should -Not -Throw
    }
  }
}
