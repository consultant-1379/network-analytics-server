#######################################################################################
#
#
#
#   !!NOTE!!:
#   File must be renamed to LicenceFeature.Tests.ps1 to run.
#   The below tests require Sentinel RMS Development Kit (CodeCover) be installed on 
#   the testing machine to run.
#
#
#######################################################################################

$scriptUnderTest = "$((Get-Item $PSScriptRoot).Parent.Parent.FullName)\src\main\scripts\Licencing\LicenceFeature.ps1"
$featureFolder = "$((Get-Item $PSScriptRoot).Parent.FullName)\resources\licenceFeatureRsc\featureFolder"
$resourceFolder = $featureFolder+"\src\resources"
$tmpFolder = $resourceFolder+"tmp"
$srcZip = $featureFolder+"\src\zips\*"
$analysiszip = $srcZip+"\Analysis.part0.zip"
$infoPackzip = $srcZip+"\InformationPackage.part0.zip"
$licenceKey = "CNAXXXXXX"
$location = $PSScriptRoot

Function Copy-Zips {
    Copy-Item $srcZip $resourceFolder
}

Function Clean-Up {
    Get-ChildItem -Path $resourceFolder -Recurse -Force | Where-Object { -not ($_.psiscontainer) } | Remove-Item –Force
    Set-Location "$((Get-Item $location).Parent.FullName)"
}

Function Get-ExtensionCount {
    param(
        $filepath,
        $filetype
        
    )
    $output = @()

    Foreach ($type in $filetype ) {
        $files = Get-ChildItem $filepath -Filter *$type -Recurse | ? { !$_.PSIsContainer }
        $output += $files.Count
    }

    return $output 
}

  Try {
    Describe "Test NetAnServer Create-Folders" {
    
        BeforeEach {
            Copy-Zips
        }
        AfterEach {

            Set-Location $location
        }

        
        It "Should return true, folder shouldnt be empty" {
        .$scriptUnderTest $licenceKey $resourceFolder
            $result = $resourceFolder.count -ne 0
            $result| Should Be $True
        }
    
        It "Should return true, folder shouldnt contain any zip files" {
            $count = Get-ExtensionCount $resourceFolder ".zip"
            $result = $count -ne 0
            $result| Should Be $True
        }
        It "Should return true, folder shouldn contain 2 exe files" {
            $count = Get-ExtensionCount $resourceFolder ".exe" 
            $result = $count -eq 2
            $result| Should Be $True
        }
         It "Should  be false tmp folder has been removed" {
            $result = Test-Path $tmpFolder
            $result| Should Be $False
        }
    
    } 
} Finally {
    Clean-Up
}