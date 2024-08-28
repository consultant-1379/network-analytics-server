# ********************************************************************
# Ericsson Radio Systems AB                                     Module
# ********************************************************************
#
#
# (c) Ericsson Inc. 2020 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Inc. The programs may be used and/or copied only with
# the written permission from Ericsson Inc. or in accordance with the
# terms and conditions stipulated in the agreement/contract under
# which the program(s) have been supplied.
#
# ********************************************************************
# Name    : NetAnServerDeploy.psm1
# Date    : 22/10/2020
# Revision: PA1
# Purpose : #  Deployment script for Ericsson Network Analytic Server
#              1. Decryption script for protected software
#              2. Unzip the software into a predefined folder
#              3. Copy scripts/resources/modules from ISO.
#              4. Perform clean-up
#
# ### Function: Deploy ###
#
#   This function uses Rijndael .NET library to encrypt files.
#
# Arguments:
#   $mediaDrive[string] the drive location of the NetAnServer media

# Return Values:
#   [list] - @($true|$false, [string] $message) 
#          

#----------------------------------------------------------------------------------
#  Set PSModulePath
#----------------------------------------------------------------------------------
$deployDir = "C:\Ericsson\tmp\"
$cryptedFiles = $deployDir +"CompressedFiles\"
$decryptorDir = $deployDir+"Modules\"

if(-not $env:PSModulePath.Contains($decryptorDir)) {
    $PSPath = $env:PSModulePath + ";"+$decryptorDir
    [Environment]::SetEnvironmentVariable("PSModulePath", $PSPath, "Machine")
    $env:PSModulePath = $PSPath
}

Import-Module -DisableNameChecking Decryptor

$softwareDest = $deployDir + "Software"
$scriptsDest = $deployDir + "Scripts"
$resourcesDest = $deployDir + "Resources"

$files = @{}
$files.Add('analyst', $cryptedFiles+"Analyst.zip")
$files.Add('deployment', $cryptedFiles+"DeploymentPackage.zip")
$files.Add('server', $cryptedFiles+"Server.zip")
$files.Add('nodeManager', $cryptedFiles+"NodeManager.zip")
$files.Add('languagepack', $cryptedFiles+"languagepack.zip")


### Function: Deploy ###
#
#   Main method the controlls the deployment of the NetAnServer media.
#
# Arguments:
#       [string]$mediaDrive
# Return Values:
#       [list] - @($true|$false, [string] $message)
#
Function Deploy {
    param( 
        [Parameter(Mandatory=$true)][string]$mediaDrive 
    )

    $softwareDir = $mediaDrive + "\Software\"
    $scriptsDir = $mediaDrive + "\Scripts\"
    $resourcesDir = $mediaDrive + "\Resources\"
    
    Write-Host "Copying Files..."
    try {
        if (-not (Test-Path($deployDir))) {
            New-Item $directory -type directory
        }
        Copy-Item -Path $scriptsDir -Destination $scriptsDest -Recurse -Force
        Copy-Item -Path $resourcesDir -Destination $resourcesDest -Recurse -Force
        Copy-Item -Path $softwareDir -Destination $cryptedFiles -Recurse -Force
    } catch {
        return @($false, "ERROR in the copy of files from Media location.")
    }

    # Update the file permissions, decrypt
    Write-Host "Decrypting Files..."
    foreach ($i in $files.GetEnumerator()) {
		If($i.Key -eq "applicationHF" -Or $i.Key -eq "serverHF" -Or $i.Key -eq "languagepack") {
			continue
		}
        $status =  Set-FilePermission $($i.Value)
        if ( $status[0] -ne $True) {
            return @($false, $status[1])
        } 

        $status =  Decrypt-Software $($i.Value)
        if ($status[0] -ne $True) {
            return @($false, $status[1])
        } 
    }

    Write-Host "Unzipping Files..."
    
    if (-not (Unzip-Move)) {
        return @($false, "ERROR unzipping files to " + $softwareDest)
    }

    try{
        Remove-Item $cryptedFiles -Recurse -Force
        Remove-Item $decryptorDir -Recurse -Force
    } catch {
        return @($false, "ERROR removing deployment files.")
    }
    
    return @($true, "Media deployed successfully, please go to $deployDir to proceed with the installation.")
}


### Function: Unzip-Move ###
#
#   Unzip and move the software to the expected folder.
#
# Arguments:
#       None
# Return Values:
#       [list] - @($true|$false, [string] $message)
#
Function Unzip-Move {
    try {
        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
        
        foreach ($i in $files.GetEnumerator()) {
	            if ($i.Key -eq "applicationHF") {
                [System.IO.Compression.ZipFile]::ExtractToDirectory($i.Value, $softwareDest+"\HotFix\Application")
            }
            elseif ($i.Key -eq "serverHF") {
                [System.IO.Compression.ZipFile]::ExtractToDirectory($i.Value, $softwareDest+"\HotFix\Server")
            }
            else {
                [System.IO.Compression.ZipFile]::ExtractToDirectory($i.Value, $softwareDest+"\"+$i.key)
            }
        }
    } catch {
        return @($false, "ERROR in unzipping file: " + $i.Value)
    }
    return @($true, "Files unzipped successfully")
}


### Function: Decrypt-Software ###
#
#   Call decryption script to decrypt installation software.
#
# Arguments:
#       [string]$file
# Return Values:
#       [list] - @($true|$false, [string] $message)
#
Function Decrypt-Software {
    param( 
        [string]$file 
    )

    $status =  Decrypt-File $file
    if ($status[0] -ne $True) {
        return @($false, $status[1])
    } 
    return @($true, "Decryption completed.")
}


### Function: Set-FilePermission ###
#
#   Updates file permissions to remove the readonly flag.
#
# Arguments:
#       [string] $directory
# Return Values:
#       [list] - @($true|$false, [string] $message)
#
Function Set-FilePermission {
    param( 
        [string]$file 
    )
    if (Test-Path $file) {
        try {
            Set-ItemProperty -Path $file -Name IsReadOnly -Value $false
        } catch {
            return @($false, "ERROR updating file permissions " + $file)
        }
    } else {
            return @($false, "ERROR file does not exist " + $file)
    }
    return @($true, "File permissions updated " + $file)
}

Export-ModuleMember "*"