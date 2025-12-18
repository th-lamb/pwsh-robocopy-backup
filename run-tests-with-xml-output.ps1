try {
  # Create a new configuration object for Pester
  $pesterConfig = New-PesterConfiguration

  # Configure it to produce an XML test report
  $pesterConfig.TestResult.Enabled = $true
  $pesterConfig.TestResult.OutputFormat = 'NUnitXML'
  $pesterConfig.TestResult.OutputPath = 'testResults.xml'

  # Set the path to the tests inside the configuration
  $pesterConfig.Run.Path = './Pester/tests'

  # Add any other configurations you need here
  # For example, to enable code coverage:
  # $pesterConfig.CodeCoverage.Enabled = $true

  # Run Pester using only the configuration object
  Write-Host "Running Pester tests..."
  $result = Invoke-Pester -Configuration $pesterConfig

  # Exit with a non-zero exit code if tests fail (important for CI)
  if ($result.FailedCount -gt 0) {
    Write-Error "Pester tests failed!"
    exit 1
  } else {
    Write-Host "Pester tests passed."
    exit 0
  }
}
catch {
  Write-Error "An error occurred while running Pester tests: $_"
  exit 1
}
