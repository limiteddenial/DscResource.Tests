$script:ModuleName = 'AppVeyor'
$script:moduleRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$env:APPVEYOR_BUILD_FOLDER = 'c:\project\'
Describe "$($script:ModuleName) Unit Tests" {
    BeforeAll {
        Import-Module -Name (Join-Path -Path $script:moduleRootPath -ChildPath "$($script:ModuleName).psm1") -Force
        Import-Module -Name (Join-Path -Path $script:moduleRootPath -ChildPath "TestHelper.psm1") -Force
    } # End BeforeAll

    InModuleScope $script:ModuleName {
        # Added functions that are specific to AppVeyor environment so mocks would not fail
        Function Add-AppveyorTest { }
        Function Resolve-CoverageInfo { }
        Function Invoke-UploadCoveCoveIoReport { }
        Describe 'Invoke-AppveyorTestScriptTask' { 
            context 'CodeCoverage' {
                $pesterReturnedValues = @{
                    PassedCount = 1
                    FailedCount = 0
                }
                BeforeAll {
                    Mock -CommandName Add-AppveyorTest -MockWith { }
                    Mock -CommandName Push-TestArtifact -MockWith { }
                    Mock -CommandName Invoke-UploadCoveCoveIoReport -MockWith { }
                    Mock -CommandName Test-Path -MockWith { return $False }
                    Mock -CommandName Get-ChildItem -MockWith { return "file.Tests.ps1" }
                    Mock -CommandName Get-ChildItem -MockWith { return $null } -ParameterFilter {$Include -eq '*.config.ps1'}
                    Mock -CommandName Resolve-CoverageInfo -MockWith { }
                    Mock -CommandName Invoke-Pester -MockWith { return $pesterReturnedValues}
                    Mock -CommandName Invoke-Pester -MockWith { return $pesterReturnedValues} -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources\**\*.psm1"}
                    Mock -CommandName Invoke-Pester -MockWith { return $pesterReturnedValues} -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCResources\**\*.psm1"}
                    # Making sure there is no output when performing tests 
                    Mock -CommandName Write-Verbose -MockWith { }
                    Mock -CommandName Write-Warning -MockWith { }
                    Mock -CommandName Write-Info -MockWith { }
                } # End BeforeAll
                AfterEach {
                    Assert-MockCalled -CommandName Test-Path -Times 1 -Exactly -Scope It -ParameterFilter {$Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources"}
                    Assert-MockCalled -CommandName Test-Path -Times 1 -Exactly -Scope It -ParameterFilter {$Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCResources"}
                    Assert-MockCalled -CommandName Test-Path -Times 2 -Exactly -Scope It
                    Assert-MockCalled -CommandName Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter {$Include -eq '*.config.ps1'}
                    Assert-MockCalled -CommandName Get-ChildItem -Times 2 -Exactly -Scope It
                } # End AfterEach
                It 'Should only include DSCClassResources for CodeCoverage' {
                    Mock -CommandName Test-Path -MockWith { return $true } -ParameterFilter {$Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources"}
                    Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter {$Path -and $Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCResources"}
                    
                    { Invoke-AppveyorTestScriptTask -CodeCoverage } | Should Not Throw

                    Assert-MockCalled -CommandName Invoke-Pester -Times 1 -Exactly -Scope It -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources\**\*.psm1"}
                    Assert-MockCalled -CommandName Invoke-Pester -Times 0 -Exactly -Scope It -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCResources\**\*.psm1"}
                } # End It DSCClassResources only
                It 'Should only include DSCResources for CodeCoverage' {
                    Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter {$Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources"}
                    Mock -CommandName Test-Path -MockWith { return $true } -ParameterFilter {$Path -and $Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCResources"}
                    
                    { Invoke-AppveyorTestScriptTask -CodeCoverage } | Should Not Throw

                    Assert-MockCalled -CommandName Invoke-Pester -Times 0 -Exactly -Scope It -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources\**\*.psm1"}
                    Assert-MockCalled -CommandName Invoke-Pester -Times 1 -Exactly -Scope It -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCResources\**\*.psm1"}
                } # End It DSCResources only
                It 'Should use DSCResources and DSCClassResources for CodeCoverage' {
                    Mock -CommandName Test-Path -MockWith { return $true } -ParameterFilter {$Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources"}
                    Mock -CommandName Test-Path -MockWith { return $true } -ParameterFilter {$Path -and $Path -eq "$env:APPVEYOR_BUILD_FOLDER\DSCResources"}
                    
                    { Invoke-AppveyorTestScriptTask -CodeCoverage } | Should Not Throw

                    Assert-MockCalled -CommandName Invoke-Pester -Times 1 -Exactly -Scope It -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCClassResources\**\*.psm1"}
                    Assert-MockCalled -CommandName Invoke-Pester -Times 1 -Exactly -Scope It -ParameterFilter {$CodeCoverage -contains "$env:APPVEYOR_BUILD_FOLDER\DSCResources\**\*.psm1"}
                } # End It Both DSCResources and DSCClassResources
            } # End context CodeCoverage
        } # End Describe Invoke-AppveyorTestScriptTask Tests
    } # End inModuleScope
} # End Describe Module Unit Tests
