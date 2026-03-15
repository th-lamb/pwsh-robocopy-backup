# pwsh-robocopy-backup

[![Run Pester Tests](https://github.com/th-lamb/pwsh-robocopy-backup/actions/workflows/run-tests.yml/badge.svg)](https://github.com/th-lamb/pwsh-robocopy-backup/actions/workflows/run-tests.yml)
[![Lint Code Base](https://github.com/th-lamb/pwsh-robocopy-backup/actions/workflows/super-linter.yml/badge.svg)](https://github.com/th-lamb/pwsh-robocopy-backup/actions/workflows/super-linter.yml)

Backup with PowerShell and robocopy using a list of directories/files to backup.

## TODO/Limitations

Constrained Language Mode disables access to Environment Variables!

## Run tests

    .\run-tests.ps1

    # Verbose output
    # Similar to: Invoke-Pester -Output Detailed -Path .
    .\run-tests.ps1 -Detailed

    # Writes xml file for CI/CD pipeline
    .\run-tests.ps1 -CI

    # Combined
    .\run-tests.ps1 -Detailed -CI
