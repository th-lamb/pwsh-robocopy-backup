$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../..").ProviderPath

# Smoke Test for backup.ps1
# This test executes the script in a sandbox and verifies its behavior using -WhatIf.

Describe "backup.ps1 Smoke Test" {
    $SandboxRoot = $null
    $smokeTestPs1 = $null
    $smokeTestIni = $null
    $smokeTestConf = $null

    #TODO: Extract functions like "path-resolution" to be re-used by all smoke tests?
    BeforeAll {
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../..").ProviderPath
        # --- ROBUST PATH RESOLUTION ---
        $current = $PSScriptRoot
        while ($current -and -not $ProjectRoot) {
            if (Test-Path (Join-Path $current "backup.ps1")) {
            } else {
                $current = Split-Path $current -Parent
            }
        }

        if (-not $ProjectRoot) {
            throw "Could not find ProjectRoot (searching for backup.ps1 upwards from $PSScriptRoot)"
        }

        $SandboxRoot = Join-Path $ProjectRoot "Pester\resources\backup_ps1\smoke-tests\BasicRun"
        if (-not (Test-Path $SandboxRoot)) {
            throw "Sandbox directory not found: $SandboxRoot"
        }
        $SandboxRoot = (Get-Item $SandboxRoot).FullName

        # --- CRITICAL SAFETY CHECK ---
        if ($SandboxRoot -eq "C:\" -or $SandboxRoot -eq "C:\Windows" -or -not $SandboxRoot.StartsWith($ProjectRoot)) {
            throw "SandboxRoot resolution failed or is outside ProjectRoot: $SandboxRoot"
        }

        Write-Host "Sandbox Root: $SandboxRoot"

        $smokeTestPs1 = Join-Path $SandboxRoot "smoke-test.ps1"
        $smokeTestIni = Join-Path $SandboxRoot "smoke-test.ini"
        #TODO: Read $smokeTestConf from the inifile, not hardcoded?
        $smokeTestConf = Join-Path $SandboxRoot "smoke-test-dir-list.conf"

        # --- PRE-TEST CLEANUP ---
        # Remove artifacts from previous runs so we start fresh,
        # but they remain available for inspection after a test.
        $artifacts = @(
            $smokeTestPs1,
            $smokeTestIni,
            $smokeTestConf,
            (Join-Path $SandboxRoot "destination"),
            (Join-Path $SandboxRoot "stdout.txt")
        )
        foreach ($path in $artifacts) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # 1. Prepare the sandbox script
        Copy-Item (Join-Path $ProjectRoot "backup.ps1") -Destination $smokeTestPs1 -Force

        # 2. Prepare the sandbox ini file
        $iniSource = Join-Path $SandboxRoot "test-backup.ini"
        if (Test-Path $iniSource) {
            Copy-Item $iniSource -Destination $smokeTestIni -Force
        } else {
            throw "test-backup.ini not found in $SandboxRoot"
        }

        # 3. Prepare the sandbox dir-list
        $dirListSource = Join-Path $SandboxRoot "test-dir-list.conf"
        if (Test-Path $dirListSource) {
            Copy-Item $dirListSource -Destination $smokeTestConf -Force
        } else {
            throw "test-dir-list.conf not found in $SandboxRoot"
        }

        # 4. Prepare the sandbox lib/ and templates/ folder.
        $libPath = Join-Path $SandboxRoot "lib"
        $null = New-Item -ItemType Directory -Path $libPath -Force
        Remove-Item -Path "$libPath\*" -Recurse -Force -ErrorAction SilentlyContinue

        $templatesPath = Join-Path $SandboxRoot "templates"
        $null = New-Item -ItemType Directory -Path $templatesPath -Force
        Remove-Item -Path "$templatesPath\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Copy .ps1 files to the lib/ folder.
        # Note: we use the -Filter parameter
        Get-ChildItem -Path (Join-Path $ProjectRoot "lib") -Filter "*.ps1" |
            Copy-Item -Destination $libPath -Force

        # Copy "dir-list-template.conf" and .RCJ files to the templates/ folder.
        # Note: we use the -Include parameter
        Get-ChildItem -Path (Join-Path $ProjectRoot "templates\*") -Include "*.RCJ", "dir-list-template.conf" |
            Copy-Item -Destination $templatesPath -Force

        # 5. Create the sandbox source/ folder and some dummy files.
        $sourcePath = Join-Path $SandboxRoot "source"
        $sourceDir = New-Item -ItemType Directory -Path $sourcePath -Force
        Remove-Item -Path "$sourcePath\*" -Recurse -Force -ErrorAction SilentlyContinue

        Set-Content -Path (Join-Path $sourceDir.FullName "test1.txt") -Value "test content 1"
        Set-Content -Path (Join-Path $sourceDir.FullName "test2.txt") -Value "test content 2"
        Set-Content -Path (Join-Path $sourceDir.FullName "exclude_me.txt") -Value "I should be excluded"
        Set-Content -Path (Join-Path $sourceDir.FullName "test3.tmp") -Value "I should be excluded too"
    }

    It "Runs successfully with -SkipExecution and simulates the workflow" {
        $stdoutFile = Join-Path $SandboxRoot "stdout.txt"
        $stderrFile = Join-Path $SandboxRoot "stderr.txt"

        # Act: Run the script as a separate process and capture output
        # We use -SkipExecution instead of -WhatIf to allow the script to actually create job files in the sandbox.
        # Note: The smoke test currently uses "powershell.exe" (Windows PowerShell 5.1) for execution,
        # but the script is designed to be compatible with "pwsh.exe" (PowerShell 7+) as well.
        $process = Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$smokeTestPs1`"", "-SkipExecution", "-NonInteractive" `
            -WorkingDirectory $SandboxRoot `
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
