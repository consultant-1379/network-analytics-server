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
# Name    : UpdateInformationPackage.ps1
# Date    : 24/06/2015
# Revision: PA1
# Purpose : #  The datasource guid must be changed in the InformationPackage.
            #  This script uses the ZipUnZip module and the SearchReplace module to change the datasource guid 
            #  value and replace it in all the documents with FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF.
            #  The files are then zipped and the InformationPackage zip replaced with the new one.

# Usage   : UpdateInformationPackage ([String] $informationPackageFullPath, [String] $dataSourceGuid)
#           
#

#---------------------------------------------------------------------------------

#----------------------------------------------------------------------------------
#  Following parameters must not be modified
#----------------------------------------------------------------------------------
param ( 
        [Parameter(Mandatory=$true)] 
        [String]$informationPackageFullPath,
        [Parameter(Mandatory=$true)] 
        [String]$dataSourceGuid
    )

$installParams = @{}
$installParams.Add('tempUnZipFolder',"c:\temp\UnzipInformationPackage")
$installParams.Add('installDir', "c:\Ericsson\NetAnServer")
$installParams.Add('tempZip',"c:\temp\InformationPackage.part0.zip")               
$installParams.Add('PSModuleDir', $installParams.installDir + "\Modules")
$installParams.Add('guidReplacement',"FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")


#----------------------------------------------------------------------------------
#  Set PSModulePath and Copy modules
#----------------------------------------------------------------------------------

if(-not $env:PSModulePath.Contains($installParams.PSModuleDir)){
    $PSPath = $env:PSModulePath + ";"+$installParams.PSModuleDir
    [Environment]::SetEnvironmentVariable("PSModulePath", $PSPath, "Machine")
    $env:PSModulePath = $PSPath
}

Import-Module -DisableNameChecking ZipUnZip
Import-Module -DisableNameChecking SearchReplace


$logger = Get-Logger($LoggerNames.Install)

Function Main {


    #----------------------------------------------------------------------------------
    #  Unzip InformationPackage
    #----------------------------------------------------------------------------------
    If(Test-Path $installParams.tempUnZipFolder){
        $unZipSuccessful = Unzip-File $informationPackageFullPath $installParams.tempUnZipFolder
    }Else{
        New-Item -ItemType directory -Path $installParams.tempUnZipFolder -Force
        $unZipSuccessful = Unzip-File $informationPackageFullPath $installParams.tempUnZipFolder
    }


    #----------------------------------------------------------------------------------
    #  Search and replace DataSource GUID
    #----------------------------------------------------------------------------------
    If($unZipSuccessful){
        $searchReplaceSuccessful = SearchReplace $installParams.tempUnZipFolder $dataSourceGuid $installParams.guidReplacement
    }Else{
        Write-Host "Unzip unsuccessful." -ForegroundColor Red
        Exit 0    

    }


    #----------------------------------------------------------------------------------
    #  Zip InformationPackage
    #----------------------------------------------------------------------------------
    If($searchReplaceSuccessful){
        Zip-Dir $installParams.tempUnZipFolder $installParams.tempZip
        Copy-Item -Path $installParams.tempZip -Destination $informationPackageFullPath -Recurse -Force
        Write-Host "Updated InformationPackage zip" -ForegroundColor Green
    }Else{
        Write-Host  "SearchReplace unsuccessful."
        Exit 0

    }

    #Clean-up the temp folder
    Remove-Item $installParams.tempUnZipFolder -Force -Recurse
    Remove-Item $installParams.tempZip -Force -Recurse

}
#----------------------------------------------------------------------------------
#  Exit Function to Log error and terminate.
#----------------------------------------------------------------------------------


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