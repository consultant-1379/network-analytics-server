$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules"
$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\PlatformVersionController"


if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module PlatformVersionController -Force

Describe "PlatformVersionController Module Unit Tests"  {

    Context "When reading the platform-release.xml" {

        It "should return false if no file found" {
            $someNonExistentFile = "C:\nonexistent.xml"
            $result = Get-PlatformDataFromFile $someNonExistentFile
            $result[0] | should be $false
        }

         It "should return error message if no file found" {
            $someNonExistentFile = "C:\nonexistent.xml"
            $result = Get-PlatformDataFromFile $someNonExistentFile
            $result[1] | should be "platform-release.xml not found at path: C:\nonexistent.xml"
        }

        It "should return a true if a platform-release.xml file is passed to it" {
            $platformReleaseXml = $testResourceDirectory + "\platform-release.R3A07.xml"
            $result = Get-PlatformDataFromFile $platformReleaseXml
            $result[0] | Should be $True
        }

        It "should return a hashtable if a platform-release.xml file is passed to it" {
            $platformReleaseXml = $testResourceDirectory + "\platform-release.R3A07.xml"
            $result = Get-PlatformDataFromFile $platformReleaseXml
            $result[1] | Should Not Be $null
            $result[1].GetType().Name | Should Be "HashTable"
        }

        It "should return a map will correct number of keys" {
            $platformReleaseXml = $testResourceDirectory + "\platform-release.R3A07.xml"
            $result = Get-PlatformDataFromFile $platformReleaseXml
            $keyCount = ($result[1].Keys | measure).Count
            $keyCount | Should Be 3
        }

        It "should contain the correct value for each key" {
            $platformReleaseXml = $testResourceDirectory + "\platform-release.R3A07.xml"
            $result = Get-PlatformDataFromFile $platformReleaseXml 
            $productID = $result[1]['PRODUCT-ID']
            $release = $result[1]['RELEASE']
            $rState = $result[1]['RSTATE']
            $productID | Should Be "CNA1234567"
            $release | Should Be "16.0-B"
            $rstate | Should Be "R3A07"
        }
    }
}