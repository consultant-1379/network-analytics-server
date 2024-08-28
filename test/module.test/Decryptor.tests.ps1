$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$moduleMockMethod = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources\mocked.modules"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

if(-not $env:PsModulePath.Contains($moduleMockMethod)) {
    $env:PSModulePath = $env:PSModulePath + ";$($moduleMockMethod)"
}

Import-Module -DisableNameChecking Decryptor
$scriptDir = (get-item $PSScriptRoot ).Parent.FullName
$noFile = "$scriptDir\resources\NoFile.exe"
$diffPassword = "$scriptDir\resources\NetAnServerDiffPass.exe"
$corruptFile = "$scriptDir\resources\corruptFile.exe"
$notEncryptedFile = "$scriptDir\resources\NetAnServerNotEncrypted.exe"
$preMoveEncrypted = "$scriptDir\resources\NetAnServerEnc.exe"
$encryptedFile = "$scriptDir\resources\NetAnServer.exe"


Describe "Test Decryptor.tests.psm1 Unit Test" {

    It "Test Decrypt-File Should return False as file is not present" {
        $check = Decrypt-File $noFile
        $check[0] | Should Be $False
        $check[1] | Should Be "File $noFile not found."
    }

    It "Test Decrypt-File Should return False as the wrong password is used." {
        $check = Decrypt-File $diffPassword
        $check[0] | Should Be $False
        $check[1] | Should Be "Error with the decryption procedure."
    }

    It "Test Decrypt-File Should return False as file is not valid" {
        $check = Decrypt-File $corruptFile
        $check[0] | Should Be $False
        $check[1] | Should Be "Error with the decryption procedure."
    }

    It "Test Decrypt-File Should return False as file is not encrypted" {
        $check = Decrypt-File $notEncryptedFile
        $check[0] | Should Be $False
        $check[1] | Should Be "Error with the decryption procedure."
    }

    It "Test Decrypt-File Should return True and file should be decrypted" {
        Remove-Item $encryptedFile
        Copy-Item $preMoveEncrypted $encryptedFile
        $check = Decrypt-File $encryptedFile
        $check[0] | Should Be $True
        $check[1] | Should Be "File decrypted succesfully."
    }

}
