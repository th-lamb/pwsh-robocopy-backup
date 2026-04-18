# Variable Scoping and Linter Compatibility in Pester Tests

When writing Pester tests, we face a tradeoff between clean code, variable leakage prevention, and linter (PSScriptAnalyzer) satisfaction.

## The Problem

PSScriptAnalyzer (the PowerShell linter) often flags variables defined in `BeforeAll` as "assigned but never used" because it doesn't understand Pester's Domain Specific Language (DSL) where these variables are automatically shared with `It` blocks.

## Comparison of Scoping Options

<!-- markdownlint-disable MD033 -->
| Option | Style | Linter Happy? | Leakage Protection? | Verdict |
| :--- | :--- | :---: | :---: | :--- |
| **1. Local** | `$var = 'val'` in `BeforeAll`<br>`$var` in `It` | ❌ No | ✅ Yes | **Clean but noisy.** Linter complains about unused variables. |
| **2. Script** | `$script:var = 'val'` in `BeforeAll`<br>`$script:var` in `It` | ✅ Yes | ❌ No | **Explicit but dangerous.** Any modification in an `It` block leaks to all other tests in this file. |
| **3. Mixed** | `$script:var = 'val'` in `BeforeAll`<br>`$var` in `It` | ✅ Yes | ✅ Yes | **Recommended.** Satisfies the linter and maintains Pester's "copy-on-write" protection. |
<!-- markdownlint-enable MD033 -->

## Recommended Pattern (Option 3)

To ensure the linter is happy and your tests remain isolated (no leakage), use the `$script:` prefix **only** during the initial definition in `BeforeAll`. Use the variable **without** the prefix inside your tests.

### Example

```powershell
BeforeAll {
    # Define shared constants with $script: prefix to satisfy the linter
    $script:BACKUP_LOGFILE = "C:\Temp\test.log"
    $script:DEFAULT_JOB_TYPE = "Incremental"
}

It 'Uses the variables safely' {
    # Access WITHOUT the prefix to benefit from Pester's isolation
    # If you modify it here, it stays local to THIS test.
    $result = My-Function -Logfile $BACKUP_LOGFILE -Type $DEFAULT_JOB_TYPE
    $result | Should -Be 'Success'
}
```

This pattern ensures that:

1. **Linter is satisfied:** It sees the script-scope definition and understands the variable is intended for broader use.
2. **Tests are isolated:** Accessing without the prefix triggers PowerShell's "copy-on-write" behavior, preventing one test from accidentally changing a value for another.
3. **Code is idiomatic:** It follows common Pester 5 practices for sharing data while maintaining safety.
