$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module RepDBUtilities

InModuleScope RepDBUtilities {

    $VALID_RECORD = @{
        'FEATURE-NAME' = "Some Feature Name";
        'PRODUCT-ID' = "CXP8888888";
        'RSTATE' = "R1A";
        'BUILD' = "123";
        'STATUS' = "INSTALLED";
        'LIBRARY-PATH' = "/Ericsson/Some/Path To LIB";
        'RELEASE' = "15A"
    }

    $OLD_VALID_RECORD = @{
        'FEATURE-NAME' = "Some Feature Name";
        'PRODUCT-ID' = "CXP8888888";
        'RSTATE' = "R1A";
        'BUILD' = "122";
        'STATUS' = "INSTALLED";
        'LIBRARY-PATH' = "/Ericsson/Some/Path";
        'RELEASE' = "15A"
    }

    $INVALID_RECORD = @{
        'FEATURE-NAME' = "Some Feature Name";
        'PRODUCT-ID' = "CXP8888888";
        'RSTATE' = $NULL;
        'BUILD' = "123";
        'STATUS' = "INSTALLED";
        'LIBRARY-PATH' = "/Ericsson/Some/Path";
        'RELEASE' = "15A"
    }

    Describe "RepDBUtilities.psm1 Unit Tests" {

        Mock -ModuleName Logger Log-Message {}

        Context "When validating a record for insertion" {

            It "The Validate-Record should return true if all keys are present" {
                $actualResult = Test-Record -record $VALID_RECORD
                $actualResult | Should Be $true
            }  

            # All other scenarios i.e. null value or missing key are covered in 
            # NetAnServerUtility.Tests.ps1 
        }

        Context "When inserting a record when same feature previously installed" {

            Mock -Module RepDBUtilities Get-InstalledFeatureRecord { 
                    $record = @{}         
                    $record['FEATURE-NAME'] = "Some Feature Name";
                    $record['PRODUCT-ID'] = "CXP8888888";
                    $record['RSTATE'] = "R1A";
                    $record['BUILD'] = "122";
                    $record['STATUS'] = "INSTALLED";
                    $record['LIBRARY-PATH'] = "/Ericsson/Some/Path";
                    $record['RELEASE'] = "15A"
                    return $record
            } 
            

            Mock -Module RepDBUtilities Update-FeatureStatus { return $True } -Verifiable -ParameterFilter {
                $($record['STATUS']) -eq "REMOVED" -and $($record['BUILD']) -eq "122"
            } -Scope Context

            Mock -Module RepDBUtilities Add-NewFeatureRecord {} -Verifiable -ParameterFilter {
                $($record['STATUS']) -eq 'INSTALLED' -and $($record['BUILD']) -eq "123"
            } -Scope Context

            It "The Add-FeatureRecord should return false if a record is invalid" {
                $actualResult = Add-FeatureRecord -record $INVALID_RECORD -password "password"
                $actualResult | Should Be $False
            }

            It "The Update-FeatureStatus should be called with the old feature set to 
                'REMOVED' and  Add-NewFeatureRecord with the new feature set to 'INSTALLED'" {
                Add-FeatureRecord -record $VALID_RECORD -password "password"
                Assert-VerifiableMocks
            }
        }


        Context "When inserting a record when no previous feature installed" {
            Mock -Module RepDBUtilities Update-FeatureStatus {}        
            Mock -Module RepDBUtilities Get-InstalledFeatureRecord { 
                return $Null
            } -Scope Context

            Mock -Module RepDBUtilities Add-NewFeatureRecord {} 

            It "The Update-FeatureStatus Function should not be called" {
                Add-FeatureRecord -record $VALID_RECORD
                Assert-MockCalled -Module RepDBUtilities Update-FeatureStatus -Exactly 0 -Scope It
            } 
        }
        
        Context "When calling Get-InstalledFeatureRecord" {
            Mock -Module RepDBUtilities Invoke-SQL { return @($true, $null)} -Verifiable -ParameterFilter { 
                $Query -eq "SELECT * FROM NETWORK_ANALYTICS_FEATURE WHERE [PRODUCT-ID] = 'CNA11223344' AND [STATUS] = 'INSTALLED'"
            }       

            It "Should remove white space, _,-,\,/ from product number" {
                Get-InstalledFeatureRecord -product_number "CNA 11/22_33-44" -Password "password"
                Assert-VerifiableMocks
            }
        }

        Context "When a feature is already installed" {

            Mock -ModuleName RepDBUtilities Invoke-SQL { return @($true, @{'Build' = 'b- 102'})}

            It "The Test-ShouldFeatureBeInstalled Function should return $False when the 
                new build number is less than installed build number" {

                $expectedResult = $False
                $actual = Test-ShouldFeatureBeInstalled -productNumber "CXP8888888" -buildNumber "b_101" -password "Password"
                $actual | Should Be $expectedResult
            }


            It "The Test-ShouldFeatureBeInstalled Function should return $True when the 
                new build number is greater than installed build number" {

                $expectedResult = $True
                $actual = Test-ShouldFeatureBeInstalled -productNumber "CXP8888888" -buildNumber "b**103" -password "Password"
                $actual | Should Be $expectedResult
            }

            It "The Test-ShouldFeatureBeInstalled Function should return $False when the 
                new build number is equal than installed build number" {

                $expectedResult = $False
                $actual = Test-ShouldFeatureBeInstalled -productNumber "CXP8888888" -buildNumber "b/\102" -password "Password"
                $actual | Should Be $expectedResult
            }
        }


        Context "When no feature is previously installed" {
            Mock -ModuleName RepDBUtilities Invoke-SQL { return @($true, $null)}

            It "The Test-ShouldFeatureBeInstalled function should return true" {
                $expectedResult = $True
                $actual = Test-ShouldFeatureBeInstalled -productNumber "CXP8888888" -buildNumber "b/\102" -password "Password"
                $actual | Should Be $expectedResult
            }
        }


    }
}

