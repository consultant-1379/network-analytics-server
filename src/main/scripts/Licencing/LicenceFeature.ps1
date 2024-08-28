
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
# Name    : LicenceFeature.ps1
# Date    : 04/08/2015
# Revision: PA1
# Purpose : Creates EXEs from the zip files contained in <build directory>
#           Uses Sentinel CodeCover to add licencing using the feature license provided. 
# 
#         NOTE: Iexpress is a windows tool. It comes preinstalled on Windows7, It must be installed in "C:\Windows\System32\iexpress.exe"
#               This script uses the CoverFile.ps1 script which uses Sentinels Code-Cover tool
#               Sentinels RMS Development Kit 8.6.0 must be installed to use this script it must be installed in
#               "C:\Program Files (x86)\SafeNet Sentinel\Sentinel RMS Development Kit\8.6\English\RMS-CodeCover"
#
# Usage   :  .\LicenceFeature.ps1 
# Arguments:
#   [String]$licenceKey : the licence key should be the product number (e.g CNAXXXXXX) of the licence being installed.
#   [String]$featureDir : the feature parent directory
#
#---------------------------------------------------------------------------------
param(
    [string]$licenceKey,
    [String]$featureDir
)

$spaces = $featureDir.split(" ")
$codeCoverExe = "C:\Program Files (x86)\SafeNet Sentinel\Sentinel RMS Development Kit\8.6\English\RMS-CodeCover\LMS32n.exe"
$iexpressPath = "C:\Windows\System32\iexpress.exe"

If ($spaces.Count -gt 1) {
    Write-Host "Error creating licensed files, please ensure your directory path contains no spaces." -ForegroundColor Red
    Exit -1
} ElseIf (!(Test-Path $codeCoverExe)){
    Write-Host "Error creating licensed files, please ensure Sentinel RMS Development Kit is installed." -ForegroundColor Red
    Exit -1
} Elseif (!(Test-Path $iexpressPath)){
    Write-Host "Error creating licensed files, please ensure Iexpress is installed." -ForegroundColor Red
    Exit -1
}

If(!($featureDir.EndsWith("\"))){
    $featureDir = $featureDir+"\"
}

$location = $PSScriptRoot
$coverScript = $location+"/CoverFile.ps1"
$baseSED = $PSScriptRoot+"\resources\base.SED"
$tmpSed = $PSScriptRoot+"\resources\tmpSed.SED"
$codeCoverDir = "C:\Program Files (x86)\SafeNet Sentinel\Sentinel RMS Development Kit\8.6\English\RMS-CodeCover"
$tmpDir = "$featureDir"+"\tmp\"


### Function: Get-Zips ###
#
#   Returns a list of all zip file in the feature folder
#   Return Values:  [hashtable]$List
#
Function Get-Zips {
    Try {
        $resourceDirectoryContents  = gci $featureDir -recurse
        $List = $resourceDirectoryContents  | where {$_.extension -eq ".zip"}
    } Catch {
        Write-Host "Error, Directory $featureDir not found."
        Exit -1
    }
    return $List
}


### Function: Get-SEDDetails ###
#
#   Returns a hashtable ($details) with the given zip details
#
#   Arguments:  [string] $zipPath
#   Return Values:  [hastable] $details
#  
Function Get-SEDDetails {
    param(
        [String] $zipPath
    )
    $details = @{}
    $length = $zipPath.Length    
    $name = $zipPath.Substring(0,($length-4))
    $sourceFilesDir = $featureDir
    $targetName = $sourceFilesDir+$name+".exe"
    $fileName = $zipPath
    $fileName = '"'+$fileName+'"'

    $details.Add('PackageName',$name)
    $details.Add('sourceFilesDir',$sourceFilesDir)
    $details.Add('targetName',$targetName)
    $details.Add('fileName',$fileName)
    return $details
}

### Function: Create-Exe ###
#
#   Creates an EXE from the temporary SED file
#
#   Arguments:  [string] $tmpSed
#   Return Values: none
#   
Function Create-Exe {
    param(
        [Parameter(Mandatory=$true)]
        [String]$tmpSed
    )

    If (Test-Path $iexpressPath) {
        If (Test-Path $tmpSed) {
            $iexpressProc = Start-Process $iexpressPath -ArgumentList ("/N","/Q",$tmpSed) -Wait           
        } Else {

            Write-Host "SED file not found, exiting." -ForegroundColor Red
            Exit -1
        }
    
    } Else {

        Write-Host "Iexpress.exe not found, exiting." -ForegroundColor Red
        Exit -1
    }

}

### Function: Create-SED ###
#
#   Creates an SED file from the  from the temporary SED file
#   A SED file is used by the iexpress.exe application to create 
#   a self extracting directory. 
#
#   Arguments:   [string] $tmpSed
#   Return Values: none
#  
Function Create-SED {
    param(
        [hashtable] $details
    )
    Try {
        If (Test-Path $baseSED) {
            Copy-Item $baseSED $tmpSed
           
            Try {
                (gc $tmpSed) | Foreach-Object {$_ -replace '<targetName>', $details.targetName}  | Out-File $tmpSed
                (gc $tmpSed) | Foreach-Object {$_ -replace '<PackageName>', $details.PackageName}  | Out-File $tmpSed
                (gc $tmpSed) | Foreach-Object {$_ -replace '<fileName>', $details.fileName}  | Out-File $tmpSed
                (gc $tmpSed) | Foreach-Object {$_ -replace '<srcFileDir>', $details.sourceFilesDir}  | Out-File $tmpSed
                return $tmpSed

                } Catch {
                    Write-Host "Error creating SED for $details.PackageName"
                    Exit -1
                }

        } Else {
            Write-Host "SED not found, please place correct base.SED file in dir: src/scripts/resources/" -ForegroundColor Red
        }
    } Catch {
        Write-Host "Error creating SED for $details.PackageName"
                    Exit -1
    }
    
}

### Function: Get-Exes ###
#
#   Returns a list of all zip file in the resourceDirectory folder
#
#   Return Values:  [hashtable]$List
#
Function Get-Exes {
    Try {
        $resourceDirectoryContents  = gci $featureDir -recurse
        $List = $resourceDirectoryContents  | where {$_.extension -Match ".exe"}
    } Catch {
        Write-Host "Error, Directory $featureDir not found."
        Exit -1
    }
    return $List
}

### Function: Main ###
#
#   Gets the Zip files in $resources
#   Creates temp SED files
#   Creates a (Exe Self extracting Directory) from the zip
#   Covers the exes using Sentinels CodeCover
#   
Function Main {
        
    #Get the list of Zips
    $zipList = Get-Zips
    Try {      
        If (!(Test-Path $tmpDir)){
            $dir = mkdir $tmpDir
        }
    } Catch {
         Write-Warning "Error occured: $_"
    } 
        
    If ($zipList -ne $null) {
        Foreach ($zip in $zipList) {
                
            $details = Get-SEDDetails $zip
            $tmpSed = Create-SED $details

            If (Test-Path $tmpSed) {
                Create-Exe $tmpSed | Out-Null
                rm $tmpSed -Recurse

            } Else {
                Write-Host "Error creating SED, exiting." -ForegroundColor Red
                Exit -1
            }
        }
    } Else {
        Write-Host "No zip files found in $featureDir, exiting." -ForegroundColor Red
        Exit -1
    }
    
    #Get the List of exes 
    $exeList = Get-Exes
    $cCResult
    If ($exeList -ne $null) {

        Foreach ($exe in $exeList) {

            $inputFile = $exe.FullName
            $tmpName = $inputFile.Substring($inputFile.LastIndexOfAny("\")+1)
            $outputFile = $tmpDir+$tmpName
                
            $cCResult = & $coverScript $codeCoverDir $licenceKey $inputFile $outputFile
            If (!$cCResult) {
                Break
            }
        }
        If (!$cCResult) {
            Write-Host "Error creating codecovered files, exiting." -ForegroundColor Red
            Get-ChildItem $featureDir -recurse -include *.exe -force | remove-item 
            If (Test-Path $tmpDir) {
                rm -Path $tmpDir -Recurse -Force
            }
            Exit -1 
                
        }

    } Else {
            Write-Host "No exe files found in $featureDir, exiting." -ForegroundColor Red
        Exit -1
    
    }
    
    Clean-Up
    Set-Location $location

}

### Function: Clean-Up ###
#
#   Copies the codecovered files from tmp to resources
#   Removes the Zip files in resources
#   Removes the tmp folder
#   
Function Clean-Up {
    Try {
        robocopy $tmpDir $featureDir *.exe /mov | Out-Null
        Get-ChildItem $featureDir -recurse -include *.zip -force | remove-item 
        If (Test-Path $tmpDir) {
                rm -Path $tmpDir -Recurse -Force
        }

        } Catch {
            Write-Warning "Error occured: $_"
        }
}

Main
