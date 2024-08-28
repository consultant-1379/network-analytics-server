$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

$tempTestDirectory = "$($pwd)\temp"

Remove-Module *

Function Make-Dir($dir) {
    New-Item -ItemType directory -Path $dir
}

Function Remove-Dir($dir) {
    Remove-Item $dir -Force -Recurse
}

Function Make-TempDir() {    
    Make-Dir($tempTestDirectory)
}

Function Remove-TempDir() {
    Remove-Dir($tempTestDirectory)
}


Describe "Logger.Tests.ps1 Test Cases" {

    Import-Module Logger

    BeforeEach {
        Make-TempDir
    }

    AfterEach {
       Remove-TempDir
    }

    It "Test That Logfile Default Name is correct" {
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.logInfo("some message")         
        $filename = Get-ChildItem $tempTestDirectory -Name
        ($filename.contains("test-logger.log")) | Should Be $true        
    }

    It "Test That Get-Logger Returns the Same Instance" {
        $logger = Get-Logger($LoggerNames.Install)
        $otherLogger = Get-Logger($LoggerNames.Install)
        ($logger -eq $otherLogger) | Should Be $true
    }

    It "Test That Get-Logger Returns A Different Instance" {
        $logger = Get-Logger($LoggerNames.Install)
        $otherLogger = Get-Logger("test-logger2")
        ($logger -eq $otherLogger) | Should Be $false
    }
      
    It "Test That Logger Set-LogDirectory Writes to Correct LogFile Directory" {
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.logInfo("some message")        
        $fileCount = [IO.Directory]::GetFiles($tempTestDirectory).Count
        ($fileCount -eq 1) | Should Be $true
    }

    It "Test That Logger Writes all logs to same file" {
        $logger_one = Get-Logger($LoggerNames.Install)
        $logger_two = Get-Logger($LoggerNames.Install)
        $logger_three = Get-Logger($LoggerNames.Install)
        $logger_one.setLogDirectory($tempTestDirectory)
        $logger_one.logInfo("test info message")
        $logger_two.logWarning("test warning message") 
        $logger_three.logError($MyInvocaiton, "test error message")                  
        $logfile = [IO.Directory]::GetFiles($tempTestDirectory)        
        $counts  = Get-Content $tempTestDirectory"\"$($logger_one.timestamp)"_"$($logger_one.filename) | Measure-Object -Line
        #expectedLineCount
        # 1 line x logInfo
        # 1 line X logWarning
        # 5 lines x logError (1 x message, 3 x $MyInvocation 'trace', 1 x newline)
        $expectedLineCount = 7
        ($counts.Lines -eq $expectedLineCount) | Should Be $true
    } 

    It "Test That Setting Logfile Name Changes output logfile" {        
        $newLogName = "newlogname.log"
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.setLogName($newLogName)
        $logger.logInfo("some message") 
        $filename = Get-ChildItem $tempTestDirectory -Name        
        ($filename.contains($newLogName)) | Should Be $true 
    }

    It "Test That LogFile Name has Date_Time Prepended to LogFile" {
        $newLogName = 'newlogname.log'
        $logPattern = "[0-9]{8}_[0-9]{6}_$($newLogName)"
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.setLogName($newLogName)
        $logger.logInfo("some message") 
        $filename = Get-ChildItem $tempTestDirectory -Name   
        ($filename -match $logPattern) | Should Be $true
    } 
}

Describe "Mocked Logger.Tests.psm1 Module Tests" {
   
    Import-Module Logger
   
    BeforeEach {       
        Make-TempDir
    }

    AfterEach {
       Remove-TempDir
    }
        
    Mock -ModuleName Logger Log-Message {}
    Mock -ModuleName Logger Write-Host {}

    It "Test That Log-Method is called on LogInfo" {                
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.logInfo("some message", $true)
        Assert-MockCalled Log-Message -ModuleName Logger -Exactly 1 -Scope It
    }

    It "Test That Log Method is called on LogError" {            
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.logError($MyInvocation, "some message", $true)
        Assert-MockCalled Log-Message -ModuleName Logger -Exactly 1 -Scope It
    } 

    It "Test That Logging an Info Message with True, To Write-Host Is Called" {  
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.logInfo("some message", $true)
        Assert-MockCalled Write-Host -ModuleName Logger
    }

    It "Test That Logging a Message To Write-Host is not called" {  
        $logger = Get-Logger("test-logger")
        $logger.setLogDirectory($tempTestDirectory)
        $logger.logInfo("some message")
        Assert-MockCalled Write-Host -ModuleName Logger -Exactly 0 -Scope It
    }
}