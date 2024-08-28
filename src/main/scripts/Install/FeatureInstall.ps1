# ********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
# ********************************************************************
#
#
# (c) Ericsson Inc. 2015 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Inc. The programs may be used and/or copied only with
# the written permission from Ericsson Inc. or in accordance with the
# terms and conditions stipulated in the agreement/contract under
# which the program(s) have been supplied.
#
# ********************************************************************
# Name    : FeatureInstall.ps1
# Date    : 31/07/2015
# Purpose : #  Installation script for Analysis Install
#               1. Create logs and directories
#               2. Request input parameters from user
#             
#
# Usage   : FeatureInstall ([string] $InformationPackageFullPath)
#           
#

#---------------------------------------------------------------------------------

#----------------------------------------------------------------------------------
#  Following parameters must not be modified
#----------------------------------------------------------------------------------
param ( 
        [Parameter(Mandatory=$true)] 
        [String]$InfoPackPath
    )

$install_date = get-date -format "yyyyMMdd_HHmmss"
$serverIP = "127.0.0.1"

$installParams = @{}
$installParams.Add('installDir', "C:\Ericsson\NetAnServer")          
$installParams.Add('logDir', $installParams.installDir + "\Logs") 
$installParams.Add('setLogName', 'Feature_Install.log')          
$installParams.Add('PSModuleDir', $installParams.installDir + "\Modules")    
$installParams.Add('moduleDir', "$PSScriptRoot\Modules")



#----------------------------------------------------------------------------------
#  Set PSModulePath and Copy modules
#----------------------------------------------------------------------------------

if(-not $env:PSModulePath.Contains($installParams.PSModuleDir)){
    $PSPath = $env:PSModulePath + ";"+$installParams.PSModuleDir
    [Environment]::SetEnvironmentVariable("PSModulePath", $PSPath, "Machine")
    $env:PSModulePath = $PSPath
}

try{
    Copy-Item -Path $installParams.moduleDir -Destination $installParams.installDir -Recurse -Force
}catch {
    Write-Host "ERROR Copying modules to "+ $installParams.installDir + "." -Foreground Red
}

$loc = Get-Location

Import-Module Logger
Import-Module NetAnServerUtility
Import-Module -DisableNameChecking ZipUnZip
Import-Module -DisableNameChecking SearchReplace
Import-Module -DisableNameChecking FindDataSource


$logger = Get-Logger($LoggerNames.Install)
$logger.setLogDirectory($installParams.logDir)
$logger.setLogName($installParams.setLogName)

Function Main {
    #----------------------------------------------------------------------------------
    #  Request NetAnServer Platform password
    #----------------------------------------------------------------------------------

    while ($confirmation -ne 'y') {  
            $platformPassword = customRead-host "Network Analytics Server platform password:`n"
            if ($platformPassword){
                $confirmation = customRead-host "`n`nPlease confirm the above parameter is correct. (y/n)`n"
            }
        
            if ($confirmation -ne 'y') {
                customWrite-host "`n`nPlease re-enter the parameter.`n" 
            }
        }
        $installParams.Add('dbPassword', $platformPassword)

    
    
    





    #needed after running sql / database commands
    Set-Location $loc








    #----------------------------------------------------------------------------------
    # Cleanup / Deletion of files and folders not required
    #----------------------------------------------------------------------------------
   


}
#----------------------------------------------------------------------------------
#  Exit Function to Log error and terminate.
#----------------------------------------------------------------------------------
Function MyExit($errorString) {
    $logger.logError($MyInvocation, "Installation of NetAnServer Feature Analysis failed in method: $errorString", $True)
    Exit
}


Function customWrite-host($text) {
      Write-Host $text -ForegroundColor White
}

Function customRead-host($text) {
      Write-Host $text -ForegroundColor White -NoNewline
      Read-Host
}
  Function MyExit($errorString) {
    $logger.logError($MyInvocation, "Update of InformationPackage failed: $errorString", $True)
    Exit
}

Main