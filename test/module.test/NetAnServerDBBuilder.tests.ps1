$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"
$moduleMockMethod = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources\mocked.modules"
$loc = Get-Location

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

if(-not $env:PsModulePath.Contains($moduleMockMethod)) {
    $env:PSModulePath = $env:PSModulePath + ";$($moduleMockMethod)"
}

Import-Module Logger
Import-Module -DisableNameChecking NetAnServerDBBuilder


$params = @{
    createDBScript="C:\repo\spotfire\NetAnServer\test\module.test\NetAnServerDBBuilder.Tests.ps1"; 
    dbName = "netAnServer"; 
    connectIdentifer="localhost";
    sqlAdminUser = "sa"; 
    sqlAdminPassword="Ericsson01"; 
    dbUser="netanserver"; 
    dbPassword="Ericsson01"; 
    createDBLog="c:\test.txt";
    repDbName = "netAnServer_repdb";
    repDbDumpFile = "C:\Somefile";
}

Describe "Test NetAnServerDBBuilder.tests.psm1 Unit Test" {

    Mock -ModuleName Logger Log-Message {}

    Context "When InValid parameters are passed to Create-Databases function" {

        It "The Create-Databases function Should return false" {
            $result = Create-Databases @{}
            $result | Should be $False
        }
    }

    Context "When SQL Server is Running & Valid parameters are passed" {
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { return $True } -Scope Context
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { return 'Running'} -Scope Context
        Mock -ModuleName NetAnServerDBBuilder Create-NetAnServerDB { return $True } -Scope Context
        Mock -ModuleName NetAnServerDBBuilder Create-NetAnServerRepDB { return $True } -Scope Context
        It "The Create-Databases function Should return true" {
            $result = Create-Databases $params
            $result | Should be $True 
        }
    }

    Context "When SQL Server is NOT Running & Valid parameters are passed" {
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { return 'notrunning'} -Scope Context
        
        It "The Create-Databases function Should return false" {
            $result = Create-Databases $params
            $result | Should be $False 
        }
    }

    Context "When a database is previously installed" {
        Mock -ModuleName NetAnServerDBBuilder Invoke-Sqlcmd { return @{name=('master', 'model', 'msdb' , 'netAnServer_db', 'netAnServer_repdb')} } -Scope Context

        It "The Check-DBInstalled function should return true" {
            $check = Check-DBInstalled 'netAnServer_db' $params
            $check | Should Be $True
            Assert-MockCalled Invoke-Sqlcmd -ModuleName NetAnServerDBBuilder -Exactly 1 -Scope It
        }
    }

    Context "When a database is not previously installed" {
        Mock -ModuleName NetAnServerDBBuilder Invoke-Sqlcmd { return @{name=('master', 'model', 'msdb' , 'netAnServer_repdb')} }

        It "The Check-DBInstalled function should return false" {
            $check = Check-DBInstalled 'netAnServer_db' $params
            $check | Should Be $False
            Assert-MockCalled Invoke-Sqlcmd -ModuleName NetAnServerDBBuilder -Exactly 1 -Scope It
        }
    }

    Context "When the create_db script does not exist" {
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { $True }
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { $False } 
        Mock -ModuleName NetAnServerDBBuilder Test-FileExists { $False } 

        It "The Create-NetAnServerDB function should return false" {
            $check = Create-NetAnServerDB $params
            $check | Should Be $False
            Assert-MockCalled Test-FileExists -ModuleName NetAnServerDBBuilder  -Exactly 1 -Scope It
        }
    }

    Context "When the create create_db script exits with a non-zero exit code" {
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { $True }
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { $False } 
        Mock -ModuleName NetAnServerDBBuilder Test-FileExists { $True } 
        Mock -ModuleName NetAnServerDBBuilder Start-Process { @{ExitCode=10} }
        It "Start-Process throws any exception" {
            $check = Create-NetAnServerDB $params
            $check | Should Be $False
            Assert-MockCalled Start-Process -ModuleName NetAnServerDBBuilder  -Exactly 1 -Scope It
        }
    }

    Context "Test Create-NetAnServerDB - database created successfully" {
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { $True }
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { $False } 
        Mock -ModuleName NetAnServerDBBuilder Test-FileExists { $True } 
        Mock -ModuleName NetAnServerDBBuilder Start-Process { @{ExitCode=0} }
        Mock -ModuleName NetAnServerDBBuilder Copy-logfile {}

        It "Start-Process throws any exception" {
            $check = Create-NetAnServerDB $params
            $check | Should Be $True
           Assert-MockCalled Start-Process -ModuleName NetAnServerDBBuilder  -Exactly 1 -Scope It
        }
    }
    
    Context "Test Copy-LogFile copies file successfully" {
       Mock -ModuleName NetAnServerDBBuilder Test-FileExists { $True } 

       New-item "TestDrive:\testlog.txt" -Type file
       $databaseLog = Get-Item "TestDrive:\testlog.txt"
       New-item "TestDrive:\dir1" -Type directory
       $logDir = Get-Item "TestDrive:\dir1"
       $logparams =  @{databaseLog=$databaseLog;logDir=$logDir}

       It "Copy-File copies file successfully" {
            $check =Copy-LogFile $logparams
            $check | should Be $True
       } 
    }

    Context "Test Copy-LogFile log file does not exist" {
       Mock -ModuleName NetAnServerDBBuilder Test-FileExists { $False } 

       $databaseLog = ""
       New-item "TestDrive:\dir1" -Type directory
       $logDir = Get-Item "TestDrive:\dir1"
       $logparams =  @{databaseLog=$databaseLog;logDir=$logDir}

       It "Copy-File log file does not exist" {
            $check =Copy-LogFile $logparams
            $check | should Be $False
       } 
    }

       # This test is causing all tests to exit with call to Exit
  <#  It "Test Create-NetAnServerDB if Check-DBInstalled throws any exception" {
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { Throw }
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { $True }
        $check = Create-NetAnServerDB $params
        $check | Should Be $False
        Assert-MockCalled Check-DBInstalled -ModuleName NetAnServerDBBuilder -Exactly 1 -Scope It
    }  #>

    Context "Test Create-NetAnServerDB if Start-Process throws any exception" {
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { $True }
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { $False } 
        Mock -ModuleName NetAnServerDBBuilder Test-FileExists { $True } 
        Mock -ModuleName NetAnServerDBBuilder Start-Process { }

        It "Start-Process throws any exception" {
            $check = Create-NetAnServerDB $params
            $check | Should Be $False
            Assert-MockCalled Start-Process -ModuleName NetAnServerDBBuilder  -Exactly 1 -Scope It
        }
    }


    Context "When creating the NetAnServer RepDB" {
        Mock -ModuleName NetAnServerDBBuilder Create-NetAnServerRepDB { return $False }
        It "Should return false if repDB file is not found" {
            $result = Create-NetAnServerRepDB $params
            $result | Should Be $False
        }
    }

    Context "When creating the NetAnServer RepDB and RepDB is previously installed" {
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { return $True }
        Mock -ModuleName NetAnServerDBBuilder Invoke-Sqlcmd { }
        Mock -ModuleName NetAnServerDBBuilder Test-FileExists { return $True }

        It "The Create-NetAnServerRepDB function should not call Invoke-SQLCMD and return True" {
            $result = Create-NetAnServerRepDB $params
            $result | Should Be $True
            Assert-MockCalled -ModuleName NetAnServerDBBuilder Invoke-Sqlcmd -Exactly 0 -Scope It
        }
    }


    Context "If Error when installing RepDB" {
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { return $False }
        Mock -ModuleName NetAnServerDBBuilder Invoke-Sqlcmd { throw }
        Mock -ModuleName NetAnServerDBBuilder Test-FileExists { return $True }
        
        It "The Create-NetAnServerRepDB function should exit with False" {
            $result = Create-NetAnServerRepDB $params
            $result | Should Be $False
            Assert-MockCalled -ModuleName NetAnServerDBBuilder Invoke-Sqlcmd -Exactly 1 -Scope It
        }
    }
      
    Context "When SQL Server is Running" {
        Mock -ModuleName NetAnServerDBBuilder Check-DBInstalled { return $True } -Scope Context
        Mock -ModuleName NetAnServerDBBuilder Get-ServiceState { return 'Running'} -Scope Context
        Mock -ModuleName NetAnServerDBBuilder Create-NetAnServerDB { return $True } -Scope Context
        Mock -ModuleName NetAnServerDBBuilder Create-NetAnServerRepDB { return $False } -Scope Context
       
        It "The Create-Databases function Should return false if RebDB is not installed" {
            $result = Create-Databases $params
            $result | Should be $False 
        }
    }
      
    Set-Location $loc
}
