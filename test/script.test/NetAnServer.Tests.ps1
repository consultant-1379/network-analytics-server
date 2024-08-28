
#
# To run These tests you must first comment out the Main function call in NetAnServer.ps1
#
#
# ********************************************************************
$ErrorActionPreference = "silentlycontinue"
$pwd = $PSScriptRoot
$tmpDir ="C:\Ericsson"
$myFile = "C:\Ericsson\tmp\Modules\Decryptor\Decryptor.psm1"
$scriptUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Install\NetAnServer.ps1"

.$scriptUnderTest


Function Remove-TempDir() {
    If (Test-Path $tmpDir ) {
        Remove-Item $tmpDir -Recurse -Force
    }
}

Describe "Test NetAnServer Create-Folders" {
    
    BeforeEach {
        Remove-TempDir
    }
        
    It "Should return true, creating folders" {
         Create-Folders | Should Be $True
    }

    It "Should return false, creating folders" {
         Mock New-Item  { Throw }        
         Create-Folders | Should Be $False
    }
    
} 

Describe "Test NetAnServer Start-Exe" {
    
    AfterEach {
        Remove-TempDir
    }
    
    Context "When calling Start-Exe Function" {
        It "Should return True, exitcode 0 returned." {
            Create-Folders
            Mock Write-Host {}
            Mock Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' 0
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } 
            Mock Test-Path { $true }

            $check = Start-Exe
            $check[0] | Should Be $True
            $check[1] | Should Be "License found."
        }
    }

    Context "When calling Start-Exe Function" {
        It "Should return false when timeout returned." {
            Mock Write-Host {}
            Create-Folders
            Mock Start-Process {
                $p = New-Object psobject
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } 

            $check = Start-Exe
            $check[0] | Should Be $False
            $check[1] | Should Be "Error validating license with licensing server."
        }
    }

    Context "When calling Start-Exe Function" {
        It "Should return false when timeout returned." {
            Mock Write-Host {}
            Create-Folders
            Mock Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' 0
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } 
            Mock Test-Path { $false }

            $check = Start-Exe
            $check[0] | Should Be $False
            $check[1] | Should Be "License not found."
        }  
    }

    Context "When calling Start-Exe Function" {
        It "Should return false when exception thrown." {
            Mock Write-Host {}
            Create-Folders
            Mock Start-Process { throws }

            $check = Start-Exe
            $check[0] | Should Be $False
            $check[1] | Should Be "Error with license checking."
        }  
    }
} 

Describe "Test NetAnServer Move-Files" {
    
    BeforeEach {
        Remove-TempDir
    }

  
    context "When calling Move-Files Function" {
        It "Should return True as files were moved successfully " {
            Create-Folders
            Mock Test-Path { $true }

            Mock Move-Item { }
            $check = Move-Files
            $check[0] | Should Be $True
            $check[1] | Should Be "Deployment files moved."

        }
    }


    context "When calling Move-Files Function" {
        It "Should return False when directory not found" {
            Mock Test-Path { $false }
            $check = Move-Files
            $check[0] | Should Be $False
            $check[1] | Should Be "Directory C:\Ericsson\tmp not found."

        }
    }
    
    context "When calling Move-Files Function" {
        It "Should return False when Move-Item throws exception" {
            Mock Test-Path { $true }
            Mock Move-Item { Throws }
            $check = Move-Files
            $check[0] | Should Be $False
            $check[1] | Should Be "ERROR moving files."

        }
    }
        It "Should return false when Decryptor files not present" {
        Create-Folders
        $check = Move-Files 
        $check[0] | Should Be $False
        $check[1] | Should Be "File C:\Ericsson\tmp\Decryptor.psm1 not found"
    }

    It "Should return false when Deploy files not present" {
        Create-Folders
        New-Item C:\Ericsson\tmp\Decryptor.psm1 -type file
        $check = Move-Files
        $check[0] | Should Be $False
        $check[1] | Should Be "File C:\Ericsson\tmp\NetAnServerDeploy.psm1 not found"
    }
 }


Describe "Test NetAnServer Move-Files" {
    
    BeforeEach {
        Remove-TempDir
    }


    It "Should return False when directory not found" {
        Mock Test-Path { $true }
        Mock Move-Item { Throws }
        $check = Move-Files
        $check[0] | Should Be $False
        $check[1] | Should Be "ERROR moving files."

    }

} 