# Pester

Test files for the [Pester test framework](https://pester.dev/).

Call tests using:

    Invoke-Pester .

or

    Invoke-Pester -Output Detailed .

Example output:

    PS C:\dev\pwsh-robocopy-backup\Pester> Invoke-Pester -Output Detailed .
    Pester v5.5.0

    Starting discovery in 1 files.
    Discovery found 18 tests in 18ms.
    Running tests.

    Running tests from 'C:\dev\pwsh-robocopy-backup\Pester\filesystem-functions\GetParentDir.Tests.ps1'
    Describing getParentDir
    Context no placeholders
      [+] returns parent folder for existing file 3ms (2ms|1ms)
      [+] returns parent folder for non-existing file 2ms (2ms|0ms)
      [+] returns the drive for a short path 1ms (1ms|0ms)
      [+] returns an empty value for a too short path 1ms (1ms|0ms)
    Context filename patterns
      [+] returns parent folder for pattern with 1 matching file 2ms (1ms|1ms)
      [+] returns parent folder for pattern with 2 or more matching files 2ms (1ms|0ms)
      [+] returns parent folder for pattern with no matching file 5ms (5ms|0ms)
    Context directory patterns
      [+] returns path with placeholder for dir pattern with 1 matching *directory* 4ms (4ms|1ms)
      [+] returns path with placeholder for dir pattern with 2 or more matching *directories* 4ms (4ms|0ms)
      [+] returns path with placeholder for dir and file pattern with matching files in different directories 5ms (4ms|0ms)
    Context directory entries
      [+] returns the parent path for . (link to the current dir) 2ms (2ms|1ms)
      [+] returns the parents parent path for .. (link to the parent dir) 2ms (1ms|0ms)
      [+] returns path with placeholder for dir pattern and . 2ms (1ms|0ms)
      [+] returns path with placeholder for dir pattern and .. 2ms (1ms|0ms)
      [+] returns the drive for a short path and . 1ms (1ms|0ms)
      [+] returns the drive for a short path and .. 1ms (1ms|0ms)
      [+] returns an empty value for a too short path and . 1ms (1ms|0ms)
      [+] returns an empty value for a too short path and .. 1ms (1ms|0ms)
    Tests completed in 136ms
    Tests Passed: 18, Failed: 0, Skipped: 0 NotRun: 0
    PS C:\dev\pwsh-robocopy-backup\Pester>
