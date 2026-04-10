# Pester test structure

## Repeated sourcing

### Why is sourcing duplicated at all?

All files dot-source the library files **twice**: once at the top level of the script and once inside
a `BeforeAll` block.

This is a known Pester v5 requirement caused by **scope isolation**. Pester runs `Describe`/`It` blocks
in a child scope, and variables/functions defined at the script's top level are not automatically visible
inside those blocks (or vice versa). The top-level sourcing makes functions available for
**`BeforeDiscovery`** and for any code that runs during the **discovery phase** (e.g. `$TestCases` arrays
that reference the functions directly). The `BeforeAll` sourcing makes them available for the
**run phase** (the actual `It` blocks).

### `BeforeAll` at the top level of the file

```powershell
# Top level (discovery phase)
$ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
. "${ProjectRoot}\lib\filesystem-functions.ps1"

BeforeAll {
  # Run phase
  $ProjectRoot = (Resolve-Path "${PSScriptRoot}/../../../../").ProviderPath
  . "${ProjectRoot}\lib\filesystem-functions.ps1"
}

Describe 'SomeFunction' {
  ...
}
```

This is the recommended structure.

- The `BeforeAll` at file scope applies to all `Describe` blocks in the file.
- In a single-`Describe` file (as most of these are), it is functionally equivalent to putting it inside
  the `Describe` block. But putting it at file scope is slightly preferable because:
  - It makes the setup intent clear: "these are global pre-conditions for this entire test file".
  - It matches the pattern recommended in Pester v5 documentation for file-level setup.
