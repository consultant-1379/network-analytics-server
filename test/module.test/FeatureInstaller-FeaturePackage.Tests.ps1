$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\FeatureInstaller"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module FeatureInstaller

Describe "FeatureInstaller.psm1 Read-FeaturePackage Unit Tests" {

    Mock -ModuleName Logger Log-Message {} 

    BeforeEach {
        Remove-Item $global:featureExtractDir -recurse -force -confirm:$false -ErrorAction SilentlyContinue
        mkdir $global:featureExtractDir
    }

    AfterEach {
        Remove-Item $global:featureExtractDir -recurse -force -confirm:$false -ErrorAction SilentlyContinue
    }

    $global:featureExtractDir = "$($testResourceDirectory)\feature-extract"
    $validFeaturePackage = "$($testResourceDirectory)\feature-package.zip"
    $invalidFeaturePackage = "$($testResourceDirectory)\invalid-feature-package.zip"
    $invalidFeaturePackageTwo = "$($testResourceDirectory)\invalid-feature-package-two.zip"
    $nonZippedFeaturePackage = "$($testResourceDirectory)\feature-package-non-zip"

    Context "When calling Read-FeaturePackage" {

        Mock -Modulename FeatureInstaller Get-Directory { return @($True, "$($global:featureExtractDir)")}-ParameterFilter { $dirname -eq "feature-extract" }

        It "Read-FeaturePackage should return a boolean" {
            $featurePackage = Read-FeaturePackage
            $featurePackage[0].GetType().Name  | Should Be "Boolean"
        }

        It "Read-FeaturePackage should return false an error message if no parameter passed" {
            $featurePackage = Read-FeaturePackage $null
            $featurePackage[0] | Should Be $false
            $featurePackage[1] | Should Be "A feature package must be provided."
        }

        It "Read-FeaturePackage should return false and error message if incorrect path passed" {
            $featurePackage = Read-FeaturePackage "String"
            $featurePackage[0] | Should Be $False
            $featurePackage[1] | Should Be "The feature package provided does not exist. String"
        }

        It "Read-FeaturePackage should return false if a zip file is not passed" {
            $featurePackage = Read-FeaturePackage $nonZippedFeaturePackage
            $featurePackage[0] | Should Be $False
            $featurePackage[1] | Should Be "The feature package provided is invalid. It must be a zipped file.`n$nonZippedFeaturePackage"
        }

        It "Read-FeaturePackage should return true and hashtable if zip file is passed" {
            $featurePackage = Read-FeaturePackage $validFeaturePackage
            $featurePackage[0] | Should Be $True
            $featurePackage[1].GetType().Name | Should Be "Hashtable"
        }

        It "Read-FeaturePackage should return false if feature package is missing a single exe" {
            $featurePackage = Read-FeaturePackage $invalidFeaturePackage
            $featurePackage[0] | Should Be $False
            $featurePackage[1] | Should Be "The feature package provided is invalid. The following file(s) are missing:`nInformationPackage.part0.exe"
        }

        It "Read-FeaturePackage should return false if feature package is missing the feature-release.xml" {
            $featurePackage = Read-FeaturePackage $invalidFeaturePackageTwo
            $featurePackage[0] | Should Be $False
            $featurePackage[1] | Should Be "The feature package provided is invalid. The following file(s) are missing:`nfeature-release.xml"
        }

        It "Read-FeaturePackage should return a hashtable with the absolute path to the extracted files" {
            $featurePackage = Read-FeaturePackage $validFeaturePackage
            $featurePackage[0] | Should Be $True
            $resultFiles = $featurePackage[1] 
            $resultFiles['feature-release.xml'] | Should Be "$($global:featureExtractDir)\feature-release.xml"
            $resultFiles['Analysis.part0.exe'] | Should Be "$($global:featureExtractDir)\Analysis.part0.exe"
            $resultFiles['InformationPackage.part0.exe'] | Should Be "$($global:featureExtractDir)\InformationPackage.part0.exe"
        }
    }
}