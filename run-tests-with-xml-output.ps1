try {
  # Create and configure the Pester object
  $pesterConfig = New-PesterConfiguration
  $pesterConfig.TestResult.Enabled = $true
  $pesterConfig.TestResult.OutputFormat = 'NUnitXML'
  $pesterConfig.TestResult.OutputPath = 'testResults.xml'
  $pesterConfig.Run.Path = './Pester/tests'

  # Configure Pester to automatically exit with a non-zero code on failure
  $pesterConfig.Run.Exit = $true

  # Add any other configurations you need here
  # For example, to enable code coverage:
  # $pesterConfig.CodeCoverage.Enabled = $true

  # Run Pester. It will now automatically handle the exit code.
  Invoke-Pester -Configuration $pesterConfig
}
catch {
  Write-Error "An error occurred while running Pester tests: $_"
  exit 1
}
