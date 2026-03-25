# Watch Smoke Test

This script monitors key project files and automatically runs the `BasicRun.Tests.ps1` smoke test whenever a change is saved.

## Usage

To start the watcher, run the following command from the project root:

```powershell
.\scripts\watch-smoke-test.ps1
```

To stop the watcher, press `Ctrl+C` in the terminal.

## Monitored Files

By default, the script watches for changes in:

- `backup.ps1`
- `lib\*.ps1` (all library functions)
- `Pester\tests\backup_ps1\smoke-tests\BasicRun.Tests.ps1` (the smoke test itself)

## Customization

You can override the test path or watch patterns using parameters:

```powershell
.\scripts\watch-smoke-test.ps1 -TestPath "path\to\other.Tests.ps1" -WatchPatterns @("file1.ps1", "dir\*.ps1")
```
