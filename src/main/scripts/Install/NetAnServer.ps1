﻿
# ********************************************************************
# Ericsson Radio Systems AB                                     Script
# ********************************************************************
#
#
# (c) Ericsson Inc. 2021 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Inc. The programs may be used and/or copied only with
# the written permission from Ericsson Inc. or in accordance with the
# terms and conditions stipulated in the agreement/contract under
# which the program(s) have been supplied.
#
# ********************************************************************
# Name    : NetAnServer.ps1
# Date    : 01/07/2021
# Revision: PA2
# Purpose : Call the CodeCovered file and populate the dialog during extraction.
# 
# Usage   :  .\NetAnServer.ps1
# Return Values: None
#
#---------------------------------------------------------------------------------

$netAnServer = "NetAnServer.exe"
$adhoc = "adhoc-enabler-bundle.exe"
$netAnServExeDir = $PSScriptRoot+"\Resources\Installer\"
$deployDir = "C:\Ericsson\tmp"
$netAnServExeArgs ="/t:$deployDir /q:a"
$modulesDir = $deployDir+"\Modules"
$decryptModDir = $modulesDir+"\Decryptor"
$netAnServModDir = $modulesDir+"\NetAnServerDeploy"
$decryptorFile = $deployDir+"\Decryptor.psm1"
$adhocdecryptorFile = $deployDir+"\adhoc-enabler-bundle.zip"
$decryptorFileTarget = $decryptModDir+"\Decryptor.psm1"
$netAnServDepFile = $deployDir+"\NetAnServerDeploy.psm1"
$netAnServFileTarget = $netAnServModDir+"\NetAnServerDeploy.psm1"
$rootDir = $PSScriptRoot.substring(0,2) 
$originalEnvPath = $env:PSModulePath
$env:PSModulePath = $env:PSModulePath + ";"+$modulesDir
$licenseTimeout = 15000   #15 seconds

Function Start-Exe {
    param(
        [String] $installerName,
        [String] $exeFile,
        [String] $decryptedFile
    )

    Try {
        
        Write-Host "Searching for a valid $installerName license…"
        $codeCoverproc = Start-Process $exeFile -WorkingDirectory $netAnServExeDir -ArgumentList $netAnServExeArgs -PassThru

        if(-not $codeCoverproc.WaitForExit($licenseTimeout)) {
            try {
                kill $codeCoverproc -ErrorAction Stop
            } catch {
                $errorMessage = $_.Exception.Message
                return @($false, "Network Analytics Server licensing process timed out. Unable to terminate Network Analytics Server Process. Exception: $errorMessage")
            }
            return @($false, "Network Analytics Server licensing process timed out. Licensing process killed.")
        }

        if ($codeCoverproc.ExitCode -eq 0 ) {
            If (Test-Path $decryptedFile) {
                return @($true, "$installerName license found.")
            } Else {
                return @($false, "$installerName license not found.")
            }
        } Else {
            return @($false, "Error validating license with licensing server.")
        }

    } Catch {
        return @($false, "Error with license checking.")
    }
}


Function Create-Folders {
    Try {
        If (!(Test-Path $deployDir)) {
            New-Item $deployDir -type directory | Out-Null
            New-Item $modulesDir -type directory | Out-Null
            New-Item $decryptModDir -type directory | Out-Null
            New-Item $netAnServModDir -type directory | Out-Null
            return $True
        } Else {
            Write-Host "Deployment folder $deployDir already exists. Deleting $deployDir and its contents."
            Remove-Item $deployDir -Recurse -Force
            Create-Folders
        }
    } Catch {
        return $False
    }
    
}


Function Move-Files {
    
    Try {
        If (Test-Path $deployDir) {
            If (Test-Path $decryptorFile) {
                Move-Item $decryptorFile $decryptorFileTarget -Force
            } Else {
                return @($false, "File $decryptorFile not found")
            }

            If (Test-Path $netAnServDepFile) {
                Move-Item $netAnServDepFile $netAnServFileTarget -Force

                If ((Test-Path $decryptorFileTarget) -and (Test-Path $netAnServFileTarget)) {
                    return @($true, "Deployment files moved.")
                } Else {
                    return @($false, "Network Analytics Server deployment failed, could not move deployment files.")
                }
            } Else {
                return @($false, "File $netAnServDepFile not found")
            }

        } Else {
            return @($false, "Directory $deployDir not found.")
        }
    } Catch {
        return @($false, "ERROR moving files.")
    }
}

 
Function Clean-EnvPath {
    $env:PSModulePath = $originalEnvPath
    [Environment]::SetEnvironmentVariable("PSModulePath", $originalEnvPath, "Machine")
}


Function Main {

    if( Create-Folders ) {
        
        $licCheckConsumer = Start-Exe "Consumer" $netAnServer $decryptorFile
        $licCheckAdhoc = Start-Exe "Adhoc" $adhoc $adhocdecryptorFile

        $results = [ordered]@{
            "Consumer" = $licCheckConsumer;
            "Ad-Hoc" = $licCheckAdhoc
        }

        foreach ($licCheck in $results.GetEnumerator()) {
            If ($licCheck.value[0]) {
                Write-Host $licCheck.value[1] -ForegroundColor Green
            }Else {
                Write-Host $licCheck.value[1] -ForegroundColor Red
                Clean-EnvPath
                Exit 1
            }
        }
  
        # All modules can now be deployed (adhoc modules contained in consumer)
        $res = Move-Files
        
        if( $res[0]) {
            Write-Host "Deployment files moved."
            if (Get-Module -Name NetAnServerDeploy) {
                Remove-Module NetAnServerDeploy
            }
            Import-Module -DisableNameChecking NetAnServerDeploy
            $deployResult = Deploy $rootDir
            if($deployResult[0]) {
                Write-Host $deployResult[1]
                Clean-EnvPath
                Exit 0
            } Else {
                Write-Host $deployResult[1]
                Clean-EnvPath
                Exit 1
            }
        } Else {
            Write-Host $res[1]
            Clean-EnvPath
            Exit 1
        }

    } Else {
        Write-Host "Network Analytics Server deployment failed, could not create required folders in $deployDir."
        Clean-EnvPath
        Exit 1
    }
}

Main