$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\FeatureInstaller"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\FeatureInstaller"
$extractedFeaturePackage = "$($testResourceDirectory)\unzipped-feature-package"

$featurePackageContents = @{
    'Analysis.part0.exe' = "$($extractedFeaturePackage)\Analysis.part0.exe";
    'InformationPackage.part0.exe' = "$($extractedFeaturePackage)\InformationPackage.part0.exe"
}

Import-Module FeatureInstaller

Describe "FeatureInstaller-UnprotectFeaturePackageContents Unit Tests" {

    <# These Tests require the LSFORCE host variable to be set for a valid licence server.
        It requires that the licence for the plaform is installed on the system #>

    AfterEach {
        Remove-Item "$($extractedFeaturePackage)\Analysis.part0.zip" -recurse -force -confirm:$false -ErrorAction SilentlyContinue
        Remove-Item "$($extractedFeaturePackage)\InformationPackage.part0.zip" -recurse -force -confirm:$false -ErrorAction SilentlyContinue
    }

    Context "When extracting the files" {
       
        It "The Unprotect-FeaturePacakgeContents should return a hashtable of extracted zipfiles" {
            $extractedFiles = Unprotect-FeaturePackageContents $featurePackageContents
            $extractedFiles[0] | Should Be $True 
            $files = $extractedFiles[1]

            $files['Analysis.part0.zip'] | Should Be "$($extractedFeaturePackage)\Analysis.part0.zip"
            $files['InformationPackage.part0.zip'] | Should Be "$($extractedFeaturePackage)\InformationPackage.part0.zip"
            $files.Count | Should Be 2
        }

        IT "Should return false with an error message if extraction fails" {
            $lsForceHost = $env:LSFORCEHOST
            $env:LSFORCEHOST = "0.0.0.0"
            $extractedFiles = Unprotect-FeaturePackageContents $featurePackageContents
            $env:LSFORCEHOST = $lsForceHost
            $errorMessage = "There was a problem in extracting the licenced media: Analysis.part0.exe.`nPlease check your Sentinel Licence server is running and that the correct licence is installed for this feature."
            $extractedFiles[0] | Should Be $False
            $extractedFiles[1] | Should Be $errorMessage
        }
    }
}