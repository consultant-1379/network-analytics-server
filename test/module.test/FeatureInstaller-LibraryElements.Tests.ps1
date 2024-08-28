$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\FeatureInstaller"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module FeatureInstaller

Describe "FeatureInstaller.psm1 LibraryPackageCreation Test Cases" {

    Mock -ModuleName Logger Log-Message {} 

    BeforeEach {
        Remove-Item $global:testTempBuildDir -recurse -force -confirm:$false -ErrorAction SilentlyContinue
        Remove-Item $global:testTempStageDir -recurse -force -confirm:$false -ErrorAction SilentlyContinue
        Remove-Item $testTempDir -recurse -force -confirm:$false -ErrorAction SilentlyContinue
        mkdir $global:testTempBuildDir
        mkdir $global:testTempStageDir
        mkdir $testTempDir
    }

    AfterEach {
        Remove-Item $global:testTempBuildDir -recurse -force -confirm:$false
        Remove-Item $global:testTempStageDir -recurse -force -confirm:$false
        Remove-Item $testTempDir -recurse -force -confirm:$false
    }

    $global:metaDataXml = "$($testResourceDirectory)\folder\meta-data.xml"
    $global:testTempBuildDir = "$($testResourceDirectory)\build"
    $global:testTempStageDir = "$($testResourceDirectory)\stage" 
    $testTempDir = "$($testResourceDirectory)\temp"

    Context "When Creating a library folder package for import" {

        Mock -Modulename FeatureInstaller Get-FolderMetaDataFile { 
            return @($True, $global:metaDataXml)
        }

       
        Mock -Modulename FeatureInstaller Get-Directory { 
            return @($True, $global:testTempBuildDir)
        } -ParameterFilter { $dirname -eq "build"}

        
        Mock -Modulename FeatureInstaller Get-Directory { 
            return @($True, $global:testTempStageDir)    
        } -ParameterFilter { $dirname -eq "stage"}

        
        It "Invoke-LibraryPackageCreation function should return boolean, filename and absolute path" {
            $isBuilt = Invoke-LibraryPackageCreation "Test"
            $isBuilt[0] | Should Be $True
            $isBuilt[1] -eq "Test.part0.zip" | Should Be $True
            $isBuilt[2] -eq "$($global:testTempStageDir)\Test.part0.zip" | Should Be $True
        }

        It "Invoke-LibraryPackageCreation function should create a zipped file with three files in the returned directory" {
            $isBuilt = Invoke-LibraryPackageCreation "Test"
            Add-Type -assembly "system.io.compression.filesystem"
            [io.compression.zipfile]::ExtractToDirectory($isBuilt[2], $testTempDir)
            Test-Path "$($testTempDir)\lastfileindicator" | Should Be $True
            Test-Path "$($testTempDir)\expectlastfileindicator" | Should Be $True
            Test-Path "$($testTempDir)\meta-data.xml" | Should Be $True
            (Get-ChildItem $testTempDir | Measure-Object).Count  | Should be 3
        }
    }

    Context  "When creating a library folder package and errors occur" {
        Mock -Modulename FeatureInstaller Get-FolderMetaDataFile { 
            return @($True, $global:metaDataXml)
        }
       
        Mock -Modulename FeatureInstaller Get-Directory { 
            return @($False, "filepath")
        } -ParameterFilter { $dirname -eq "build"}

        
        Mock -Modulename FeatureInstaller Get-Directory { 
            return @($True, $global:testTempStageDir)    
        } -ParameterFilter { $dirname -eq "stage"}

        It "The BuildLibraryPacakage function should exit with false and error message" {
            $isBuilt = Invoke-LibraryPackageCreation "Test"
            $isBuilt[0] | Should Be $False
        }
    }

    Context  "When creating a library folder package and errors occur" {
        Mock -Modulename FeatureInstaller Get-FolderMetaDataFile { 
            return @($False, "No file found")
        }
       
        Mock -Modulename FeatureInstaller Get-Directory { 
            return @($True, $global:testTempBuildDir)
        } -ParameterFilter { $dirname -eq "build"}

        
        Mock -Modulename FeatureInstaller Get-Directory { 
            return @($True, $global:testTempStageDir)    
        } -ParameterFilter { $dirname -eq "stage"}

        It "The BuildLibraryPacakage function should exit with false and error message if meta-data.xml not found" {
            $isBuilt = Invoke-LibraryPackageCreation "Test"
            $isBuilt[0] | Should Be $False
        }
    }
}