# Smoke Test

This directory contains the automated smoke test (functional test) for the main `backup.ps1` script. Unlike unit tests that check individual functions, this test verifies the entire "orchestration" logic of the script from start to finish.

## How it works

The smoke test uses a **Safe Sandbox** strategy to avoid affecting the system or real data:

1.  **Sandbox Isolation:** The test operates entirely within `Pester\resources\backup_ps1\smoke-test\`.
2.  **Environment Setup:** In the `BeforeAll` block, the test:
    - Copies the latest `backup.ps1` into the sandbox as `smoke-test.ps1`.
    - Copies the `lib/` and `templates/` folders into the sandbox.
    - Creates `smoke-test.ini` and `dir-list.conf` from templates.
    - Sets up a dummy `source/` folder with test files.
3.  **Simulated Execution:** It runs the script using the PowerShell `-WhatIf` parameter. This allows the script to go through its entire logic (reading config, checking files, calculating paths, generating job files) but **prevents** it from actually creating folders, writing the real log, or executing Robocopy.
4.  **Output Validation**: The test captures the script's console output (stdout and stderr).
    - **Standard Error Monitoring:** The test fails if anything is written to the error stream.
    - **Strict Log Prefix Validation:** Every line must begin with `[NOTICE ]`, `[INFO   ]`, `[DEBUG  ]` or be empty; otherwise, the test fails.
    - **Additional Output Verification:** Regular Expressions are used to verify that expected "WhatIf" messages and log entries (INFO/DEBUG) were generated.

### Dual-File Setup (test-backup.ini & smoke-test.ini)

The smoke test uses two `.ini` files for specific reasons:

1.  **Script Behavior:** `backup.ps1` automatically looks for a configuration file with the same name as the script (e.g., `backup.ini` for `backup.ps1`).
2.  **Sandbox Isolation:** In the smoke test, `backup.ps1` is copied and renamed to `smoke-test.ps1` to clearly distinguish it from a real backup run.
3.  **Source Control:** `test-backup.ini` is a version-controlled template in the repository containing the specific settings (like sandbox paths) required for the test.
4.  **Execution:** During setup, `test-backup.ini` is copied to `smoke-test.ini`. This ensures that when `smoke-test.ps1` runs, it finds its matching configuration file.

## What it verifies

- **Configuration Loading:** Ensures `backup.ps1` can correctly find and parse its `.ini` file.
- **Path Resolution:** Verifies that `${SCRIPT_DIR}` and other variables expand correctly to the sandbox paths.
- **Dependency Check:** Confirms that the script correctly identifies mandatory files and templates.
- **Job Generation:** Verifies that the logic for parsing `dir-list.conf` and creating `.RCJ` files is working.
- **Workflow Orchestration:** Ensures the script transitions correctly through its phases: Setup -> Job Selection -> Archiving -> Job Creation -> Execution.

## Maintenance: Keeping it up-to-date

You should update the test resources or the test script itself in the following cases:

### 1. Adding new dependencies

If you add a new library file in `lib/` or a new template in `templates/`, the `BeforeAll` block in `SmokeTest.Tests.ps1` will automatically copy the entire folders. However, if you add a **mandatory file check** in `backup.ps1`, you must:

- Add the file to the `smoke-test` resources or ensure it's simulated.
- Update `Pester\resources\backup_ps1\smoke-test\test-backup.ini` to include the new configuration key.

### 2. Changing log messages or output

The test relies on regex matching of the console output. If you significantly change the wording of "INFO" or "WARNING" messages in the main script, you may need to update the `It` block in `SmokeTest.Tests.ps1` to match the new strings.

### 3. Adding new parameters

If you add new command-line parameters to `backup.ps1`, consider adding a new `It` block to the smoke test to verify different parameter combinations.

## Running the test

To run only the smoke test:

```powershell
Invoke-Pester -Path "Pester\tests\backup_ps1\SmokeTest.Tests.ps1"
```

To run all tests (including unit tests):

```powershell
./scripts/run-tests.ps1
```

## Troubleshooting

If the test fails, check the `stdout.txt` file generated in the `Pester\resources\backup_ps1\smoke-test\` directory. It contains the full console output of the last failed run.

### Minimal Resource Footprint

If you want to "empty" the `Pester\resources\backup_ps1\smoke-test\` folder manually, you can delete everything **EXCEPT** for these mandatory files required for the test to start:

#TODO: Commit *this* .gitignore?
- **`.gitignore`**: Prevents artifacts from being committed.
- **`test-backup.ini`**: The template for the sandbox configuration.
- **`test-dir-list.conf`**: The template for the backup directory list.

The following are automatically recreated or updated every time you run the smoke test:

#TODO: Maybe we "hardcode" the `source/` folder and also commit it to Git?
- **Folders**: `lib\`, `source\`, `templates\`, and `destination\`.
- **Files**: `smoke-test.ps1`, `smoke-test.ini`, `dir-list.conf`, and `stdout.txt`.
