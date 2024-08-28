#######################################################################################
#
#
#
#   !!NOTE!!:
#   File must be renamed to CoverFile.Tests.ps1 to run.
#   The below tests require Sentinel RMS Development Kit (CodeCover) be installed on 
#   the testing machine to run.
#   The local files and directories (valid/invalid and corrupt) must also be preset 
#   for these tests to pass
#
#
#######################################################################################

$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptUnderTest = "$((Get-Item $pwd).Parent.FullName)\src\main\scripts\Licencing\CoverFile.ps1"
$tempTestDirectory = "$($pwd)\temp"
$codeCoverDir = "C:\Program Files (x86)\SafeNet Sentinel\Sentinel RMS Development Kit\8.6\English\RMS-CodeCover\"
$invalidCodeCoverDir = "C:\"
$licenceKey = "CXC1738095"
$validInputFileName = "C:\NetAnServer\network-analytics-server\test\tmp\NetAnServer.EXE"
$validOutputFileName = "$($pwd)\temp\NetAnServerCC.EXE"
$invalidInputFileName = "C:\NetAnServer.EXE"
$invalidOutputFileName = "C:\NetAnServer\network-analytics-server\test\tmp\NetAnServer.EXE"
$corruptFile = "C:\NetAnServer\network-analytics-server\test\tmp\Corrupt.EXE"

Function Make-Dir($dir) {
    New-Item -ItemType directory -Path $dir
}

Function Remove-Dir($dir) {
    Remove-Item $dir -Force -Recurse
}

Function Make-TempDir() {    
    Make-Dir($tempTestDirectory)
}

Function Remove-TempDir() {
    Remove-Dir($tempTestDirectory)
}

Describe "Test Cover-File" {

    BeforeEach {
        Make-TempDir
    }

    AfterEach {
        Remove-TempDir
    }
    
    It "Should return False as input file is not present" {
        $actual = & "$((Get-Item $pwd).Parent.FullName)\src\main\scripts\Licencing\CoverFile.ps1" $codeCoverDir $licenceKey $invalidInputFileName $validOutputFileName
        $actual | Should Be $False
    }

 
    It "Should return False as output file already exists" {
        $actual = & "$((Get-Item $pwd).Parent.FullName)\src\main\scripts\Licencing\CoverFile.ps1" $codeCoverDir $licenceKey $validInputFileName $invalidOutputFileName
        $actual | Should Be $False
    }
    
    It "Should return False as input file is corrupt" {
        $actual = & "$((Get-Item $pwd).Parent.FullName)\src\main\scripts\Licencing\CoverFile.ps1" $codeCoverDir $licenceKey $corruptFile $validOutputFileName
        $actual | Should Be $False
    }

    It "Should return False as Code cover dir is invalid." {
        $actual = & "$((Get-Item $pwd).Parent.FullName)\src\main\scripts\Licencing\CoverFile.ps1" $invalidCodeCoverDir $licenceKey $validInputFileName $validOutputFileName
        $actual | Should Be $False
    }

    It "Should return True as all params are valid." {
        $actual = & "$((Get-Item $pwd).Parent.FullName)\src\main\scripts\Licencing\CoverFile.ps1" $codeCoverDir $licenceKey $validInputFileName $validOutputFileName
        $actual | Should Be $True
    }
    
} 