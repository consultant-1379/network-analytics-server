$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules\"
$moduleMockMethod = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources\mocked.modules"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

if(-not $env:PsModulePath.Contains($moduleMockMethod )) {
    $env:PSModulePath = $env:PSModulePath + ";$($moduleMockMethod)"
}

Import-Module Logger
Import-Module Sqlps
Import-Module -DisableNameChecking FindDataSource

$params = @{dbName = "netAnServer"; connectIdentifer="localhost"; sqlAdminPassword="Ericsson01"; dbPassword="Ericsson02"}

Describe "Find Datasource"  {

    Mock -ModuleName Logger Log-Message {}

    It "Test datasource is returned"{
        Mock -ModuleName FindDataSource Invoke-Sqlcmd { @{title='datasource'}, @{item_id='ffff-fffff'}  }
        $check = Check-DataSource $params
        $check.title | Should Be 'datasource'
        $check.item_id | Should Be 'ffff-fffff'
    }

    It "Test an exception is thrown when the wrong password sql database password is entered"{
        Mock -ModuleName FindDataSource Invoke-Sqlcmd { Throw }
        $check = Check-DataSource $params
        $check | Should Be $False

    }

    It "Test datasource is not returned"{
        Mock -ModuleName FindDataSource Invoke-Sqlcmd { }
        $check = Check-DataSource $params
        $check| Should Be $False
       
    }

}