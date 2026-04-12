using module '..\..\..\..\lib\config-classes.psm1'

BeforeAll {
  $script:FsObject = [FsObjectResult]::new()
}



Describe 'FsObjectResult' {
  It 'should have the expected properties' {
    $properties = $script:FsObject | Get-Member -MemberType Property

    $properties.Count | Should -Be 3
    $properties.Name | Should -Be @('Exists', 'Path', 'Type')
  }

  It 'should have "Exists" as a Boolean' {
    $script:FsObject.Exists | Should -BeOfType [bool]
  }

  It 'should have "Type" as a String' {
    $script:FsObject.Type = "directory" # Needs initialization

    $script:FsObject.Type | Should -BeOfType [string]
  }

  It 'should have "Path" as a String' {
    $script:FsObject.Path = "C:\Test"   # Needs initialization

    $script:FsObject.Path | Should -BeOfType [string]
  }
}
