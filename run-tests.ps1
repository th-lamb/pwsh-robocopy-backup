[CmdletBinding()]
param (
  # If specified, shows detailed Pester output in the console.
  [Switch]$Detailed,

  # If specified, generates an XML report for Continuous Integration (CI) systems.
  [Switch]$CI
)

try {
  # 1. Create a new configuration object
  $pesterConfig = New-PesterConfiguration

  # 2. Modify the configuration based on the parameters provided
  if ($Detailed.IsPresent) {
    Write-Host "Detailed output enabled."
    $pesterConfig.Output.Verbosity = 'Detailed'
  }

  if ($CI.IsPresent) {
    Write-Host "CI mode enabled: Configuring XML output."
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXML'
    $pesterConfig.TestResult.OutputPath = 'testResults.xml'
  }

  # 3. Set the common configuration for all runs
  $pesterConfig.Run.Path = './Pester/tests'

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
