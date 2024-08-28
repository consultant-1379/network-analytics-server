$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\FeatureInstaller"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module FeatureInstaller

Describe "FeatureInstaller.psm1 FeatureRelease XML Unit Test Cases" {

    Mock -ModuleName Logger Log-Message {} 

    $ericssonLibFeatureReleaseXml = "$($testResourceDirectory)\ericsson-feature-release.R1a11.xml"
    $nonEricssonLibFeatureReleaseXml = "$($testResourceDirectory)\nonericsson-feature-release.R1a11.xml"
    $invalidFeatureReleaseXml = "$($testResourceDirectory)\invalid-feature-release.R1a11.xml"
    $missingValueFeatureReleaseXml = "$($testResourceDirectory)\missing-value-feature-release.R1a11.xml"
    $missingRSTATEFeatureReleaseXml = "$($testResourceDirectory)\missing-rstate-feature-release.R1a11.xml"

   
    Context "When a feature-release.xml file is not present" {    
        It "The Read-ericssonLibFeatureReleaseXml will return false" {
            $nonExistentFile = "C:/some/non/existent/file.xml"
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $nonExistentFile
            $actualResult[0] | Should Be $False
        }
    }

    Context "When a ericsson feature-release.xml file is present" {    
        It "The Read-ericssonLibFeatureReleaseXml function will return true" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $ericssonLibFeatureReleaseXml
            $actualResult[0] | Should Be $True
        }

        It "The Read-FeatureReleaseXml function will return a hashtable if is a valid xml file" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $ericssonLibFeatureReleaseXml
            ($actualResult[1].GetType().Name -eq "HashTable") | Should Be $True
        }

        It "The Read-FeatureReleaseXml function will return a hashtable with all required fields" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $ericssonLibFeatureReleaseXml
            $featureHashTable = $actualResult[1]
            $featureHashTable.ContainsKey("Product-ID") | Should Be $True
            $featureHashTable.ContainsKey("release") | Should Be $True
            $featureHashTable.ContainsKey("featUre-Name") | Should Be $True
            $featureHashTable.ContainsKey("system-AREA") | Should Be $True
            $featureHashTable.ContainsKey("datasource-GUID") | Should Be $True
            $featureHashTable.ContainsKey("build") | Should Be $True
            $featureHashTable.ContainsKey("rstate") | Should Be $True
            $featureHashTable.ContainsKey("library-path") | Should Be $True
        }

        It "The Read-FeatureReleaseXml Function returned hashtable will have correct RState Value" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $ericssonLibFeatureReleaseXml
            $featureHashTable = $actualResult[1]
            $featureHashTable.RSTATE -eq "R1a11" | Should Be $True
        }

        It "The Read-FeatureReleaseXml Function returned hashtable will have correct build Value" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $ericssonLibFeatureReleaseXml
            $featureHashTable = $actualResult[1]
            $featureHashTable.BUILD -eq "11" | Should Be $True
        }

        It "The Read-FeatureReleaseXml Function returned hashtable will have correct library path Value" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $ericssonLibFeatureReleaseXml
            $featureHashTable = $actualResult[1]
            $featureHashTable.'LIBRARY-PATH' -eq "/Ericsson Library/LTE/Ericsson-LTE-Call-Failure-Guided-Analysis" | Should Be $True
        }
    }

    Context "When a non ericsson-library feature release xml file is present" {
        It "The Read-FeatureReleaseXml Function returned hashtable will have correct library path Value" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $nonericssonLibFeatureReleaseXml
            $featureHashTable = $actualResult[1]
            $featureHashTable.'LIBRARY-PATH' -eq "/Custom Library/LTE/Ericsson-LTE-Call-Failure-Guided-Analysis" | Should Be $True
        }
    }

    Context "When a feature release xml file is missing required fields" {
        It "The Read-FeatureReleaseXml Function will return false with an error message" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $invalidFeatureReleaseXml
            $expectedResult = $actualResult[0]
            $expectedResult | Should Be $False
        }
    }

    Context "When a feature release xml file is missing required values" {
        It "The Read-FeatureReleaseXml Function will return false with an error message" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile $missingValueFeatureReleaseXml
            $expectedResult = $actualResult[0]
            $expectedResult | Should Be $False
        }
    }

    Context "When a feature release xml file is missing required rstate" {
        It "The Read-FeatureReleaseXml Function will return false with an error message" {
            $actualResult = Read-FeatureReleaseXml -featureReleaseXmlFile  $missingRSTATEFeatureReleaseXml
            $expectedResult = $actualResult[0]
            $expectedResult | Should Be $False
        }
    }
}
