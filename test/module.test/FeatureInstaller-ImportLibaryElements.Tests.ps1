$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\FeatureInstaller"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module FeatureInstaller

Describe "FeatureInstaller.psm1 Import-LibraryElement Unit Test Cases" {

    Mock -Modulename Logger Log-Message {}
    
    Context "When no Destination supplied for library import" {
        Mock -ModuleName FeatureInstaller Use-ConfigTool {} 
        Mock -ModuleName FeatureInstaller Use-ConfigTool {} -Verifiable -ParameterFilter { $command -eq "import-library-content -t password -p C:\temp -m KEEP_NEW -u username" } 

        It "Should call Use-ConfigTool without import location when no destination supplied" {
            Import-LibraryElement -element "C:\temp" -username "username" -password "password"
            Assert-VerifiableMocks
        }
    }

    Context "When a destination is supplied" {
        Mock -ModuleName FeatureInstaller Use-ConfigTool {} 
        Mock -ModuleName FeatureInstaller Use-ConfigTool {} -Verifiable -ParameterFilter { $command -eq "import-library-content -t password -p C:\temp -m KEEP_NEW -u username -l `"/Ericsson/Test`"" } 
    
        It "Should call Use-ConfigTool with import location" {
            Import-LibraryElement -element "C:\temp" -username "username" -password "password" -destination "/Ericsson/Test"
            Assert-VerifiableMocks
        }
    }
}