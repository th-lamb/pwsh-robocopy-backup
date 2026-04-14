param(
  [ValidateSet("powershell.exe", "pwsh.exe")]
  [string]$PowerShellExecutable = "powershell.exe"
)

$script:PowerShellExecutableToUse = if ([string]::IsNullOrWhiteSpace($PowerShellExecutable)) {
  "powershell.exe"
}
else {
  $PowerShellExecutable
}

# Pester can execute test blocks in scopes where script parameters are not directly visible.
# Mirror the selected executable into an environment variable for robust access in test blocks.
$env:BASICRUN_TEST_ENGINE = $script:PowerShellExecutableToUse

$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath

try {
  Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
}
catch {
  throw "Pester v5.0+ is required to run this test file. Install with: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force"
}

# Smoke Test for backup.ps1
# This test executes the script in a sandbox and verifies its behavior using -WhatIf.

Describe "backup.ps1 Smoke Test" {
  $script:SandboxRoot = $null
  $script:smokeTestPs1 = $null
  $script:smokeTestIni = $null
  $script:smokeTestConf = $null

  #TODO: Extract functions like "path-resolution" to be re-used by all smoke tests?
  BeforeAll {
    $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
    # --- ROBUST PATH RESOLUTION ---
    $current = $PSScriptRoot
    while ($current -and -not $ProjectRoot) {
      if (Test-Path (Join-Path $current "backup.ps1")) {
      }
      else {
        $current = Split-Path $current -Parent
      }
    }

    if (-not $ProjectRoot) {
      throw "Could not find ProjectRoot (searching for backup.ps1 upwards from $PSScriptRoot)"
    }

    $script:SandboxRoot = Join-Path $ProjectRoot "Pester\resources\backup_ps1\smoke-tests\BasicRun"
    if (-not (Test-Path $script:SandboxRoot)) {
      throw "Sandbox directory not found: $script:SandboxRoot"
    }
    $script:SandboxRoot = (Get-Item $script:SandboxRoot).FullName

    # --- CRITICAL SAFETY CHECK ---
    if ($script:SandboxRoot -eq "C:\" -or $script:SandboxRoot -eq "C:\Windows" -or -not $script:SandboxRoot.StartsWith($ProjectRoot)) {
      throw "SandboxRoot resolution failed or is outside ProjectRoot: $script:SandboxRoot"
    }

    Write-Host "Sandbox Root: $script:SandboxRoot"

    $script:smokeTestPs1 = Join-Path $script:SandboxRoot "smoke-test.ps1"
    # backup.ps1 now always looks for backup.ini in its own folder
    $script:smokeTestIni = Join-Path $script:SandboxRoot "backup.ini"
    #TODO: Read $smokeTestConf from the inifile, not hardcoded?
    $script:smokeTestConf = Join-Path $script:SandboxRoot "Backup\$env:USERNAME\$env:COMPUTERNAME\dir-list.conf"

    # --- PRE-TEST CLEANUP ---
    # Remove artifacts from previous runs so we start fresh,
    # but they remain available for inspection after a test.
    $artifacts = @(
      $script:smokeTestPs1,
      $script:smokeTestIni,
      (Join-Path $script:SandboxRoot "Backup"),
      (Join-Path $script:SandboxRoot "stdout.txt")
    )
    foreach ($path in $artifacts) {
      if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
      }
    }

    # 1. Prepare the sandbox script
    Copy-Item (Join-Path $ProjectRoot "backup.ps1") -Destination $script:smokeTestPs1 -Force

    # 2. Prepare the sandbox ini file
    $iniSource = Join-Path $script:SandboxRoot "test-backup.ini"
    if (Test-Path $iniSource) {
      Copy-Item $iniSource -Destination $script:smokeTestIni -Force
    }
    else {
      throw "test-backup.ini not found in $script:SandboxRoot"
    }

    # 3. Prepare the sandbox dir-list
    # Note: it now must be in the Backup subfolder because of BACKUP_DIRLIST=${BACKUP_DIR}dir-list.conf
    $dirListTargetDir = Join-Path $script:SandboxRoot "Backup\$env:USERNAME\$env:COMPUTERNAME"
    $null = New-Item -ItemType Directory -Path $dirListTargetDir -Force
    $dirListSource = Join-Path $script:SandboxRoot "test-dir-list.conf"
    if (Test-Path $dirListSource) {
      Copy-Item $dirListSource -Destination $script:smokeTestConf -Force
    }
    else {
      throw "test-dir-list.conf not found in $script:SandboxRoot"
    }

    # 4. Create an 'old' job file so the archiver doesn't complain about an empty collection.
    $jobDir = Join-Path $script:SandboxRoot "Backup\$env:USERNAME\$env:COMPUTERNAME\robocopy-jobs"
    $null = New-Item -ItemType Directory -Path $jobDir -Force
    Set-Content -Path (Join-Path $jobDir "Old-Job-2020-01-01-000000.RCJ") -Value "dummy"
    Set-Content -Path (Join-Path $jobDir "Old-Job-2020-01-01-000000.log") -Value "dummy"

    # 5. Prepare the sandbox lib/ and templates/ folder.
    $libPath = Join-Path $script:SandboxRoot "lib\"
    $null = New-Item -ItemType Directory -Path $libPath -Force
    Remove-Item -Path "$libPath\*" -Recurse -Force -ErrorAction SilentlyContinue

    $templatesPath = Join-Path $script:SandboxRoot "templates\"
    $null = New-Item -ItemType Directory -Path $templatesPath -Force
    Remove-Item -Path "$templatesPath\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Copy .ps1 files to the lib/ folder.
    # Note: we use the -Filter parameter
    Get-ChildItem -Path (Join-Path $ProjectRoot "lib\") -Filter "*.ps1" |
    Copy-Item -Destination $libPath -Force

    # Copy .psm1 files to the lib/ folder.
    # Note: we use the -Filter parameter
    Get-ChildItem -Path (Join-Path $ProjectRoot "lib\") -Filter "*.psm1" |
    Copy-Item -Destination $libPath -Force

    # Copy "dir-list-template.conf" and .RCJ files to the templates/ folder.
    # Note: we use the -Include parameter
    Get-ChildItem -Path (Join-Path $ProjectRoot "templates\*") -Include "*.RCJ", "dir-list-template.conf" |
    Copy-Item -Destination $templatesPath -Force

    # 5. Create the sandbox source/ folder and some dummy files.
    $sourcePath = Join-Path $script:SandboxRoot "source\"
    $sourceDir = New-Item -ItemType Directory -Path $sourcePath -Force
    Remove-Item -Path "$sourcePath\*" -Recurse -Force -ErrorAction SilentlyContinue

    Set-Content -Path (Join-Path $sourceDir.FullName "test1.txt") -Value "test content 1"
    Set-Content -Path (Join-Path $sourceDir.FullName "test2.txt") -Value "test content 2"
    Set-Content -Path (Join-Path $sourceDir.FullName "exclude_me.txt") -Value "I should be excluded"
    Set-Content -Path (Join-Path $sourceDir.FullName "test3.tmp") -Value "I should be excluded too"
  }

  It "Runs successfully with -SkipExecution and simulates the workflow" {
    $projectRootForIt = (Resolve-Path "${PSScriptRoot}/../../../..").ProviderPath
    $sandboxRootForIt = Join-Path $projectRootForIt "Pester\resources\backup_ps1\smoke-tests\BasicRun"
    $smokeTestPs1ForIt = Join-Path $sandboxRootForIt "smoke-test.ps1"
    $stdoutFile = Join-Path $sandboxRootForIt "stdout.txt"
    $stderrFile = Join-Path $sandboxRootForIt "stderr.txt"

    # Act: Run the script as a separate process and capture output.
    # We use -SkipExecution instead of -WhatIf to allow the script to actually create job files in the sandbox.
    # The executable is configurable to validate Windows PowerShell 5.1 and PowerShell 7+.
    $powerShellExecutableForIt = if ([string]::IsNullOrWhiteSpace($env:BASICRUN_TEST_ENGINE)) {
      "powershell.exe"
    }
    else {
      $env:BASICRUN_TEST_ENGINE
    }

    $process = Start-Process -FilePath $powerShellExecutableForIt `
      -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$smokeTestPs1ForIt`"", "-SkipExecution", "-NonInteractive" `
      -WorkingDirectory $sandboxRootForIt `
      -Wait -PassThru -NoNewWindow `
      -RedirectStandardOutput $stdoutFile `
      -RedirectStandardError $stderrFile

    # Assert: Check for evidence of a successful (simulated) run
    $process.ExitCode | Should -Be 0

    # Check for any errors in stderr (catches "abc" if redirected to stderr)
    if (Test-Path $stderrFile) {
      $stderr = Get-Content $stderrFile -Raw
      $stderr | Should -BeNullOrEmpty -Because "Standard Error should be empty. Found unexpected output/errors: `n$stderr"
    }

    $stdoutLines = Get-Content $stdoutFile
    $stdout = $stdoutLines -join "`n"

    # Validate that every line is either a valid log message or an empty line (catches "111" or "abc").
    # Note: We only allow INFO, DEBUG, and NOTICE for a clean smoke test run.
    # Higher severity levels (WARNING, ERR, etc.) should not occur.
    $validPrefixes = "\[(NOTICE |INFO   |DEBUG  )\]"
    $validLineRegex = "^($validPrefixes.*|)$"

    foreach ($line in $stdoutLines) {
      $line | Should -Match $validLineRegex -Because "Every line in stdout must follow the [SEVERITY] log format or be empty. Found unexpected line: '$line'"
    }

    # Check for specific expected messages
    #TODO: Can we check the correct order of messages?
    #TODO: We can check a lot more messages because __VERBOSE is now set to 7 in the ini file.
    $stdout | Should -Match "INFO.*Backup Script version .* started."
    $stdout | Should -Match "INFO.*Reading the settings file."
    $stdout | Should -Match "INFO.*Settings file read."
    $stdout | Should -Match "INFO.*Checking necessary directories and files..."
    # Note: directories are actually created now, so no "WhatIf" here.
    $stdout | Should -Match "INFO.*Necessary directories and files checked."
    $stdout | Should -Match "INFO.*(selected|Using the default):.*Incremental"
    $stdout | Should -Match "INFO.*Archiving previous jobs..."
    $stdout | Should -Match "INFO.*Creating job files..."
    $stdout | Should -Match "INFO.*1 job file\(s\) created."
    $stdout | Should -Match "INFO.*Running 1 job\(s\)..."
    $stdout | Should -Match "INFO.*Skipping execution as requested \(-SkipExecution\)."
    $stdout | Should -Match "INFO.*Script finished in .*"
  }

  #TODO: More than 1 smoke-test needed (e.g. for Incremental and Full Backup)?

  AfterAll {
    # Cleanup is now handled in BeforeAll to allow inspection of artifacts after the test.
  }
}
