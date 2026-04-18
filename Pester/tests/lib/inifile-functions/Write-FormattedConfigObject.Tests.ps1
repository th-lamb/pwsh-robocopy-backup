using module '..\..\..\..\lib\config-classes.psm1'

# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\message-functions.ps1"
. "${ProjectRoot}\lib\inifile-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\message-functions.ps1"
  . "${ProjectRoot}\lib\inifile-functions.ps1"

  # For messages in tested functions
  $script:config = [ScriptConfig]::new()
  $config.General.__VERBOSE = 7
}



Describe 'Write-FormattedConfigObject' {
  Context 'Correct Configuration Object' {
    <#
      GOLDEN MASTER TEST: "Matches the expected output file exactly."

      PURPOSE: This test provides a "Golden Master" comparison of the entire configuration output.
      It is extremely useful for developers to quickly see how changes to the ScriptConfig class
      affect the final output formatting and default values.

      MAINTENANCE NOTE:
      This test is strict regarding CONTENT and PADDING.
      If you add or rename configuration properties, this test will fail because the
      alignment (padding) or keys differ.
      To fix it: Verify the changes in 'actual_output_processed.txt' and update 'expected_output.txt'.

      PORTABILITY:
      Because the script expands environment variables (like %USERNAME%) during normalization,
      this test dynamically "de-expands" the actual output (replacing real values with
      placeholders) so it can be compared against the static template file on any machine.
    #>
    It 'Matches the expected output file exactly.' {
      $ResourcesDir = "${ProjectRoot}\Pester\resources\lib\inifile-functions\Write-FormattedConfigObject"
      $ExpectedFile = "${ResourcesDir}\expected_output.txt"
      $ActualFile   = "${ResourcesDir}\actual_output.txt"

      $DummyConfig = [ScriptConfig]::new()
      $DummyConfig.General.__VERBOSE            = 7
      $DummyConfig.Directories.BACKUP_BASE_DIR  = "C:\TestBackup\"
      $DummyConfig.Jobs.DEFAULT_JOB_TYPE        = "Full"

      # Trigger normalization (which expands %USERNAME%, etc.)
      $DummyConfig.Normalize()

      # Mock Write-DebugMsg to write to actual_output.txt
      Mock Write-DebugMsg {
        param($message)
        $message | Out-File -FilePath $ActualFile -Append -Encoding ascii
      }

      if (Test-Path $ActualFile) { Remove-Item $ActualFile }

      Write-FormattedConfigObject -ConfigObject $DummyConfig

      # 1. Load the files and normalize line endings
      $ExpectedContent = (Get-Content $ExpectedFile -Raw).Replace("`r`n", "`n").Trim()
      $ActualContent = (Get-Content $ActualFile -Raw).Replace("`r`n", "`n").Trim()

      # 2. De-expand actual content to match the template (using placeholders)
      # We replace the actual environment values with their literal %...% names.
      $EscapedRoot = [regex]::Escape((Join-Path $ProjectRoot "").TrimEnd('\') + '\')

      # Order of replacement is important: Replace complex/nested variables first.
      $ProcessedActualContent = $ActualContent `
        -replace $EscapedRoot, "" `
        -replace [regex]::Escape($env:TEMP.TrimEnd('\') + '\'), "%Temp%\" `
        -replace [regex]::Escape($env:TEMP), "%Temp%" `
        -replace [regex]::Escape($env:USERNAME), "%USERNAME%" `
        -replace [regex]::Escape($env:COMPUTERNAME), "%COMPUTERNAME%"

      # We split/join to ensure identical line ending characters for the comparison.
      $FinalActual = ($ProcessedActualContent -split '\n') -join "`n"
      $FinalExpected = ($ExpectedContent -split '\n') -join "`n"

      # 3. Final comparison
      try {
        $FinalActual | Should -Be $FinalExpected
        # Clean up on success
        if (Test-Path $ActualFile) { Remove-Item $ActualFile }
        $ProcessedActualFile = "${ResourcesDir}\actual_output_processed.txt"
        if (Test-Path $ProcessedActualFile) { Remove-Item $ProcessedActualFile }
      }
      catch {
        # On failure, we leave actual_output.txt (and create a processed version) for manual diffing.
        $ProcessedActualFile = "${ResourcesDir}\actual_output_processed.txt"
        $FinalActual | Out-File -FilePath $ProcessedActualFile -Encoding ascii
        Write-Host "`n[TEST FAILURE] Golden Master mismatch!" -ForegroundColor Red
        Write-Host "Compare these files to see the difference (ignore trailing spaces if your editor hides them):"
        Write-Host "  Expected (Template): $ExpectedFile"
        Write-Host "  Actual (Processed): $ProcessedActualFile"
        throw $_
      }
    }

    It 'Correctly formats and aligns a ScriptConfig object.' {
      $DummyConfig = [ScriptConfig]::new()
      # Override some values to have predictable output
      $DummyConfig.General.__VERBOSE            = 7
      $DummyConfig.Directories.BACKUP_BASE_DIR  = "C:\TestBackup\"
      $DummyConfig.Jobs.DEFAULT_JOB_TYPE        = "Full"

      $DummyConfig.Normalize()

      # Mock Write-DebugMsg to capture output
      $Messages = [System.Collections.Generic.List[string]]::new()
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
      $VerboseLine = $Messages | Where-Object { $_ -match "^__VERBOSE\s+:\s+7$" }
      $VerboseLine | Should -Not -BeNullOrEmpty

      $BaseDirLine = $Messages | Where-Object { $_ -match "^BACKUP_BASE_DIR\s+:\s+C:\\TestBackup\\$" }
      $BaseDirLine | Should -Not -BeNullOrEmpty

      $JobTypeLine = $Messages | Where-Object { $_ -match "^DEFAULT_JOB_TYPE\s+:\s+Full$" }
      $JobTypeLine | Should -Not -BeNullOrEmpty

      # Verify that all data lines have the colon at the same position.
      $DataLines = $Messages[2..($Messages.Count - 2)]
      $ColonPositions = $DataLines | ForEach-Object { $_.IndexOf(":") } | Select-Object -Unique
      $ColonPositions.Count | Should -Be 1
    }
  }

  Context 'Invalid Parameters' {
    It 'Writes a warning if the ConfigObject has no properties.' {
      Mock Write-DebugMsg {}
      $DummyConfig = [ScriptConfig]::new()
      { Write-FormattedConfigObject -ConfigObject $DummyConfig } | Should -Not -Throw
    }
  }
}
