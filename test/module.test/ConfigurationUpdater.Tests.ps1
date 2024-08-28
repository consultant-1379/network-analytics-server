$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$resourcesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources\ConfigurationsTest\"
$webworkerTest = $resourcesUnderTest + "WebWorker-Test\"
write-host $modulesUnderTest
if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module ConfigurationUpdater


$validParams=@{
    'serverConfInstall'=$resourcesUnderTest;
    'serverConfInstallXml'=$resourcesUnderTest+'ServerTest\server.xml';
    'serverConfig'=$resourcesUnderTest+'testServer.xml';
    'nodeManagerServices'=$resourcesUnderTest;
    'webConfigLog4net'=$resourcesUnderTest+'log4net.config';
    'webConfigWeb'=$resourcesUnderTest+'Spotfire.Dxp.Worker.Web.config';
    'webConfigHost'=$resourcesUnderTest+'Spotfire.Dxp.Worker.Host.exe.config';
    'certPassword'='testpassword';
    'serverCertInstall'=$resourcesUnderTest;
    'webWorkerDir'=$resourcesUnderTest
}

$invalidParams=@{
    'serverConfInstall'=$resourcesUnderTest;
    'serverConfInstallXml'=$resourcesUnderTest+'server.xml';
    'nodeManagerServices'=$resourcesUnderTest;
    'webConfigLog4net'=$resourcesUnderTest+'testLog4net.config';
    'webConfigWeb'=$resourcesUnderTest+'testSpotfire.Dxp.Worker.Web.config';
    'webConfigHost'=$resourcesUnderTest+'testSpotfire.Dxp.Worker.Host.exe.config';
    'certPassword'='testpassword';
    'webWorkerDir'=$resourcesUnderTest
}

$invalidWebParams=@{
    'serverConfInstall'=$resourcesUnderTest;
    'serverConfInstallXml'=$resourcesUnderTest+'server.xml';
    'nodeManagerServices'=$resourcesUnderTest;
    'certPassword'='testpassword';
    'serverCertInstall'=$resourcesUnderTest;
    'webWorkerDir'=$resourcesUnderTest
}

Describe "ConfigurationUpdater.psm1 Test Cases" {
    
    $serverTestUpdate=$resourcesUnderTest+"testServer.xml"
    $serverTestXml=$resourcesUnderTest+"server.xml"
    $serverTest=$resourcesUnderTest +"ServerTest\server.xml"
    $log4netFile=$resourcesUnderTest+"log4net.config"
    $webConfigFile=$resourcesUnderTest+"Spotfire.Dxp.Worker.Web.config"
    $hostExeFile=$resourcesUnderTest+"Spotfire.Dxp.Worker.Host.exe.config"

    Copy-Item -Path $serverTestUpdate -Destination $serverTest -Force
    Copy-Item -Path $log4netFile -Destination $webworkerTest -Force
    Copy-Item -Path $webConfigFile -Destination $webworkerTest -Force
    Copy-Item -Path $hostExeFile -Destination $webworkerTest -Force

    Mock -ModuleName Logger Log-Message {}

    Context "When checking if server.xml is already updated" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName ConfigurationUpdater Test-ServerXml {}

        It "Should Return True if server.xml is already updated" {
            $serverXmlTest = Test-ServerXml($validParams)
            $serverXmlTest | Should be $True
        }
        
        Copy-Item -Path $serverTestXml -Destination $serverTest -Force

        It "Should Return False if server.xml is not already updated" {
            $serverXmlTest = Test-ServerXml($invalidParams)
            $serverXmlTest | Should be $False
        }
    }

    Context "When checking if web configuration files are already updated" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName ConfigurationUpdater Test-WebConfig {}

        It "Should Return True if web configurations are already updated" {
            $webConfigTest = Test-WebConfig($validParams)
            $webConfigTest | Should be $True
        }
        It "Should Return False if web configurations are not already updated" {
            $webConfigTest = Test-WebConfig($invalidParams)
            $webConfigTest | Should be $False
        }
    }

    Context "Test updating server.xml" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName ConfigurationUpdater Update-ServerXml {}

        It "Should Return True if server.xml is updated" {
            $result = Update-ServerXml($validParams)
            $result | Should Be $True
        }
        It "Should Return False if server.xml is not updated" {
            $result = Update-ServerXml($invalidParams)
            $result | Should Be $False
        }
    }

    Context "Test updating web configuration files" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName ConfigurationUpdater Update-WebConfiguration {}

        It "Should Return True if web configurations are updated" {
            $result = Update-WebConfiguration($validParams)
            $result | Should Be $True
        }
        It "Should Return False if web configurations are not updated" {
            $result = Update-WebConfiguration($invalidWebParams)
            $result | Should Be $False
        }
    }

}
