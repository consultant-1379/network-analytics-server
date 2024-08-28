$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$tempTestDirectory = "$($pwd)\Ziptemp"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}


Function Make-TempDir() {    
    New-Item -ItemType directory -Path $tempTestDirectory
}

Function Remove-TempDir() {
    If(Test-Path $tempTestDirectory){
        Remove-Item $tempTestDirectory -Force -Recurse
    }
}
Import-Module Logger
Import-Module -DisableNameChecking ZipUnZip
$scriptDir = (get-item $PSScriptRoot ).Parent.FullName
$noFile = "$scriptDir\resources\NoFile.zip"
$zipFile = "$scriptDir\resources\fileforZipTests.zip"
$corruptFile = "$scriptDir\resources\CorruptZipForTest.zip"
$samplefolder = "$scriptDir\resources\TestFolderForZipTests"
$destZip = "$scriptDir\resources\UnitTest.zip"


Describe "Test UnZip Unit Tests" {
    
    Mock -ModuleName Logger Log-Message {}

    BeforeEach {
        Import-Module -DisableNameChecking ZipUnZip
        Make-TempDir
    }

    AfterEach {
        Remove-Module ZipUnZip
        Remove-TempDir
    }
    
    It "Test Unzip-File Should return False as file is not present" {
        $check = Unzip-File $noFile $tempTestDirectory
        $check | Should Be $False
    }
    
    It "Test Unzip-File Should return False as file is not valid" {
        $check = Unzip-File $corruptFile $tempTestDirectory
        $check | Should Be $False
        
    }

    It "Test Unzip-File Should return True as Unzip successfull" {
        $check = Unzip-File $zipFile $tempTestDirectory
        $check| Should Be $True
        
    }

}


Describe "Test Zip Unit Tests" {

    Mock -ModuleName Logger Log-Message {}

    BeforeEach {
        Import-Module -DisableNameChecking ZipUnZip
        Make-TempDir
    }

    AfterEach {
        Remove-Module ZipUnZip
        Remove-TempDir
    }

    It "Test Zip-Dir Should return True as zipfile created succesfully" {
        Zip-Dir $samplefolder $destZip
        $check =Test-FileExists $destZip
        $check | Should Be $True
    }
    
}
