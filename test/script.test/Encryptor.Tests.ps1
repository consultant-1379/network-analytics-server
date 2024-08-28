$pwd = $PSScriptRoot
$scriptUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Licencing\Encryptor.ps1"
$tempTestDirectory = "$((Get-Item $pwd).Parent.FullName)\temp"
$invalidDirectory = "C:\invalid\test.zip"
$unencrypted = "$((Get-Item $pwd).Parent.FullName)\resources\fileForEncryptTests.zip" 
$encrypted = $tempTestDirectory+"\fileForEncryptTests.zip"


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

Function UnZip {
    param(
        [string] $sourceFile
    )
    try {
        if (Test-Path $sourceFile){                            
            [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
            [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceFile,$tempTestDirectory)
            return $True
        } else {
            return $False
        }
        

    } catch {
        $ErrorMessage = $_.Exception.Message
        throw $ErrorMessage
    }
}


Describe "Test UnZip" {

    BeforeEach {
        Make-TempDir
    }

    AfterEach {
        Remove-TempDir
    }

    It "Should be false, invalid directory." {
        UnZip $invalidDirectory | Should Be $False
    }

    It "Should be true, zip file exits and is unzippable." {
        UnZip $unencrypted | Should Be $True
    }
   


}


Describe "Test Encrypt-File" {

    BeforeEach {
        Make-TempDir
    }

    AfterEach {
        Remove-TempDir
    }
    
    It "Should return False as file is not present" {
        $result = & "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Licencing\Encryptor.ps1" $invalidDirectory $encrypted
        $result[0] | Should Be $False
        $output = "File "+$invalidDirectory+" not found."
        $result[1] | Should Be $output
    }


    It "Should return True as file is present and encrypted" {
        $result = & "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Licencing\Encryptor.ps1" $unencrypted $encrypted
        $result[0] | Should Be $True
        $output = "File $unencrypted has been encrypted. Encrypted file available at $encrypted."
        $result[1] | Should Be $output
    }
    
    It "Should return True as file is not unzippable after encryption" {
        UnZip $unencrypted | Should Be $True
        $result = & "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Licencing\Encryptor.ps1" $unencrypted $encrypted
        $result[0] | Should Be $True
        $output = "File $unencrypted has been encrypted. Encrypted file available at $encrypted."
        $result[1] | Should Be $output
        { UnZip $encrypted } | Should Throw
    }
} 