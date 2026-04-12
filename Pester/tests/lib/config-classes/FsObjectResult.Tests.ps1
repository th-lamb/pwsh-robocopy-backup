using module '..\..\..\..\lib\config-classes.psm1'

BeforeAll {
  $script:FsObject = [FsObjectResult]::new()
}



Describe 'FsObjectResult' {
  $PropertiesCases = @(
    @{ ExpectedNames = @("Exists", "Type", "Path") }
  )

  It 'should have all expected properties' -TestCases $PropertiesCases {
    param($ExpectedNames)
    $properties = $script:FsObject | Get-Member -MemberType Property

    $properties.Count | Should -Be $ExpectedNames.Count
    foreach ($name in $ExpectedNames) {
      $properties.Name | Should -Contain $name
    }
  }

  $TypeCases = @(
    @{ Property = "Exists"; ExpectedType = [bool] }
    @{ Property = "Type";   ExpectedType = [string]; Val = "directory" }
    @{ Property = "Path";   ExpectedType = [string]; Val = "C:\Test\" }
  )

  It 'should have property "<Property>" with correct type' -TestCases $TypeCases {
    param($Property, $ExpectedType, $Val)
    if ($Val) { $script:FsObject.$Property = $Val }
    $script:FsObject.$Property | Should -BeOfType $ExpectedType
  }
}
