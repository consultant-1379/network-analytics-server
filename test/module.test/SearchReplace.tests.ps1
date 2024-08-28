$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$scriptDir = (get-item $PSScriptRoot ).Parent.FullName
$emptyFolder = "$scriptDir\resources\EmptyFolderForSearchReplaceTests"
$testFolder = "$scriptDir\resources\FolderForSearchReplaceTests"
$noTestFolder = "$scriptDir\resources\noFolder"
$newGuid = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
$guidToFind = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
$testFile = "$scriptDir\resources\FileForSearchReplaceTests.xml"
$movedTestFile = "$testFolder\FileForSearchReplaceTests.xml"




if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}


Function Make-TempDir() {    
    New-Item -ItemType directory -Path $testFolder -Force
}

Function Remove-TempDir() {
    If(Test-Path $testFolder){
        Remove-Item $testFolder -Force -Recurse
    }
}
Import-Module Logger
Import-Module -DisableNameChecking SearchReplace



Describe "Test SearchReplace Unit Tests" {
    
    Mock -ModuleName Logger Log-Message {}

    BeforeEach {
        Import-Module -DisableNameChecking SearchReplace
        Make-TempDir
    }

    AfterEach {
        Remove-Module SearchReplace
        Remove-TempDir
    }
    
    It "Test SearchReplace Should return False as folder is not present" {
        $check = SearchReplace $noTestFolder $guidToFind $newGuid
        $check | Should Be $False
    }
    
    It "Test SearchReplace Should return False as folder is empty" {
        $check = SearchReplace $emptyFolder $guidToFind $newGuid
        $check | Should Be $False
        
    }

    It "Test SearchReplace Should return True as SearchReplace successfull" {
        Copy-Item $testFile $movedTestFile
        $check = SearchReplace $testFolder $guidToFind $newGuid
        $check| Should Be $True
        
    }


}