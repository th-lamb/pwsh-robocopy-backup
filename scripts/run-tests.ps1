[CmdletBinding()]
param (
  # If specified, shows detailed Pester output in the console.
  [Switch]$Detailed,

  # If specified, generates an XML report for Continuous Integration (CI) systems.
  [Switch]$CI
)

# Hardening: Ensure tests are not interrupted by an inherited confirmation state.
#
# If this script is run from a nested or suspended shell (indicated by extra '>'
# symbols in the prompt, e.g., '>>>'), the parent's confirmation preference
# (e.g., from a -Confirm call) might be inherited.
#
# This can cause Pester's internal use of 'Set-Alias' (used for Mocking) to
# trigger unexpected 'Are you sure?' prompts because 'Set-Alias' has a
# 'Medium' ConfirmImpact.
#
# Setting $ConfirmPreference to 'High' (the default) ensures that only commands
# with 'High' impact prompt for confirmation, allowing the test suite to run
# autonomously even in unusual shell states.
#
# We are raising the bar for what is considered "dangerous enough" to interrupt tests.
$ConfirmPreference = 'High' # Only prompt if the command's danger rating is >= my preference.

# Ensure Pester v5 is loaded
try {
  Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
}
catch {
  Write-Error "Pester v5.0+ is required but was not found. Please install it with: Install-Module Pester -MinimumVersion 5.0 -Force"
  exit 1
}

try {
  # 1. Create a new configuration object
  $pesterConfig = New-PesterConfiguration

  # 2. Modify the configuration based on the parameters provided
  if ($Detailed.IsPresent) {
    Write-Host "Detailed output enabled."
    $pesterConfig.Output.Verbosity = 'Detailed'
  }

  if ($CI.IsPresent) {
    Write-Host "CI mode enabled: Configuring XML output and excluding LocalOnly tests."
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXML'
    $pesterConfig.TestResult.OutputPath = Join-Path $PSScriptRoot "..\test-results\testResults.xml"
    $pesterConfig.Run.Exit = $true
    $pesterConfig.Run.Throw = $true
    $pesterConfig.Filter.ExcludeTag = 'LocalOnly'
  }

  # 3. Set the common configuration for all runs
  $pesterConfig.Run.Path = Join-Path $PSScriptRoot "..\Pester\tests"

  # Add any other configurations you need here
  # For example, to enable code coverage:
  # $pesterConfig.CodeCoverage.Enabled = $true

  # 4. Run Pester. It will now automatically handle the exit code.
  Invoke-Pester -Configuration $pesterConfig
}
catch {
  Write-Error "An error occurred while running Pester tests: $_"
  exit 1
}
