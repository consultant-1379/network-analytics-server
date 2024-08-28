
# ********************************************************************
# Ericsson Radio Systems AB                                     Script
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
# Name    : CodeCover.ps1
# Date    : 21/04/2015
# Revision: PA1
# Purpose : Use Sentinels Code-Cover tool to create licence protected file.
# ### Function: Cover-File ###
#
#   This function uses Sentinels Code-Cover tool
#   Sentinels RMS Development Kit 8.6.0 must be installed to use this script
#
# Arguments:
#   $codeCoverDir[string] Directory of the LMS32n.exe file
#   $licenceKey[string] the licence key should be the Feature Name (or CXCXXXXXX) of the licence being installed.
#   $inputFileName[string] the directory and name of the file to be encrypted.
#   $outputFileName[string] the destination directory and name of the file once encrypted.
#   
# Return Values:
#   Boolean
#
#---------------------------------------------------------------------------------
param(
     [Parameter(Mandatory=$true)][string]$codeCoverDir,
     [Parameter(Mandatory=$true)][string]$licenceKey,
     [Parameter(Mandatory=$true)][string]$inputFileName, 
     [Parameter(Mandatory=$true)][string]$outputFileName
     
)

function Cover-File {
    param(
         [string]$codeCoverDir,
         [string]$licenceKey,
         [string]$inputFileName, 
         [string]$outputFileName         
    )
    If (Test-Path $codeCoverDir"\LMS32n.exe") {
                
        $location = $PSScriptRoot 
        Set-Location "$codeCoverDir\"

        #check inputfilename exists
        If (Test-Path $inputFileName) {
        
            #check outputfile doesnt exist
            If (!(Test-Path $outputFileName)) {
            
                Try {

                    #Create argumentlist and start process
					[string[]] $argslist = "/FL$licenceKey","/CL3","/XV", $inputFileName, $outputFileName
                    Write-Host "Creating Code Covered file ..." -foregroundcolor "Green"
                    $process = (Start-Process -FilePath "LMS32n.exe" -ArgumentList $argslist -WindowStyle Hidden -PassThru)
                    $process.WaitForExit()

                    if ($process.ExitCode -eq 0) {

                        Write-Host "Code Covered file created: $outputFileName." -foregroundcolor "Green"

                    } Else {

                        Write-Host "Error creating Code Covered file, $inputFileName may be corrupt." -foregroundcolor "Red"
                        Set-Location $location
                        return $False
                    }

                } Catch {

                    Write-Host "Error creating Code Covered file." -foregroundcolor "Red"
                    return $False
                }

            } Else {

                Write-Host "OutputFile $outputFileName already exists!" -foregroundcolor "Red"
                Set-Location $location
                return $False
            }

        } Else {

            Write-Host "InputFile $inputFileName not found!" -foregroundcolor "Red"
            Set-Location $location
            return $False        
        }

        Set-Location $location
        return $True    
                    
    } Else {

        Write-Host "LMS32n.exe not found!, Sentinels RMS Development Kit 8.6.0 must be installed to use this script." -foregroundcolor "Red"
        return $False

    }
    

}
Cover-File $codeCoverDir $licenceKey $inputFileName $outputFileName
