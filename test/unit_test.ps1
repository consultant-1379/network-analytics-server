#
#    Script is for running unit Tests
#
#    Usage: 
#    All: runs all unit tests
#    Modules: Runs all module unit tests
#    Scripts: Runs all script unit tests
#    Tests: <path to test file>
#
#

param(
    [parameter(Position=0)]
    [ValidateSet("Modules", "Scripts", "Tests")]    
    [String] $TestTypes,
    [parameter(Position=1)]
    [String] $Tests
)

if($TestTypes -eq "Tests") {
    if( -not $Tests ) {
        Throw "You must specify a file path to tests to run"
    }

    if( -Not (Test-Path $Tests)) {
        Throw "Cannot find tests: $Tests"
    }
}
Remove-Module *
Import-Module Pester

$pwd = $PSScriptRoot
$testModulesDir = "$pwd\module.test"
$testScriptsDir = "$pwd\script.test"


$currentEnvironmentPath = $env:PsModulePath


switch ($TestTypes) {
    "Modules" {
        Set-Location $testModulesDir
        Invoke-Pester
        Set-Location $pwd
    }

    "Scripts" {
        Set-Location $testScriptsDir
        Invoke-Pester
        Set-Location $pwd
    }

    "Tests" {
        Write-Host $Tests
        Invoke-Pester $Tests
    }

    Default {
        Invoke-Pester
    }
}

Write-Host "Removing all modules" -ForegroundColor DarkBlue -BackgroundColor Green
Remove-Module *
Write-Host "Resetting Environment Variables" -ForegroundColor DarkBlue -BackgroundColor Green
#reset environment module path
$env:PsModulePath = $currentEnvironmentPath
[Environment]::SetEnvironmentVariable("PSModulePath", $currentEnvironmentPath, "Machine")

