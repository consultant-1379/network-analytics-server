$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$testResources = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module -DisableNameChecking NetAnServerDeploy
Import-Module -DisableNameChecking Decryptor

$noFile = "$testResources\noFile.txt"
$file = "$testResources\testFile.txt"

$files = @{}
$files.Add('analyst', "C:\projects\git\network-analytics-server\test\tmp\testFile.zip")
$files.Add('applicationHF', "C:\projects\git\network-analytics-server\test\tmp\testFile.zip")

Describe "Test NetAnServerDeploy.tests.psm1 Unit Test" {

    It "Test Set-FilePermission Should return True as file is present" {
        $check = Set-FilePermission $file
        $check[0] | Should Be $True
    }

    It "Test Set-FilePermission Should return False as file is not present" {
        $check = Set-FilePermission $noFile
        $check[0] | Should Be $False
    }

    It "Test Set-FilePermission Should return False as Set-ItemProperty fails" {
        Mock -ModuleName NetAnServerDeploy Set-ItemProperty { Throw }
        $check = Set-FilePermission $file
        $check[0] | Should Be $False
    }

    It "Test Decrypt-Software Should return False error in Decrypt method" {
        Mock -ModuleName NetAnServerDeploy Decrypt-File { @($False, "Error with the decryption procedure.") }
        $check = Decrypt-Software $file
        $check[0] | Should Be $False
    }

    It "Test Decrypt-Software Should return False error in Decrypt method" {
        Mock -ModuleName NetAnServerDeploy Decrypt-File { @($False, "Failed to decrypt the file.") }
        $check = Decrypt-Software $file
        $check[0] | Should Be $False
    }

    It "Test Decrypt-Software Should return False error in Decrypt method" {
        Mock -ModuleName NetAnServerDeploy Decrypt-File { @($False, "File $file not found.") }
        $check = Decrypt-Software $file
        $check[0] | Should Be $False
    }

    It "Test Decrypt-Software Should return True file Decrypted" {
        Mock -ModuleName NetAnServerDeploy Decrypt-File { @($True, "File decrypted succesfully.") }
        $check = Decrypt-Software $file
        $check[0] | Should Be $true
    }

}
