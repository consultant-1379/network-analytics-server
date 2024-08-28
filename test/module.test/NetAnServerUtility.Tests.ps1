$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module NetAnServerUtility



$validMap = @{
    'serviceNetAnServer'='some value';
    'serverSoftware'='name.exe';
    'installDir'='c:\path\to\dir';
    'serverLog'='c:\path\to\someLogDir.log';
    'serverPort'='8888'
}

$invalidMap = @{
    'serviceNetAnServer'='some value';
    'serverSoftware'='name.exe';
    'instDir'='c:\path\to\dir';
    'serverLog'='c:\path\to\someLogDir.log';
    'serverPort'='8888'
}

$invalidMapNull = @{
    'serviceNetAnServer'='some value';
    'serverSoftware'='name.exe';
    'installDir'= $null;
    'serverLog'='c:\path\to\someLogDir.log';
    'serverPort'='8888'
}


Describe "NetAnServerUtility.psm1 Unit Test Cases" {

    BeforeEach {
        Import-Module NetAnServerUtility
    }

    AfterEach {
        Remove-Module NetAnServerUtility
    }

    It "Test-FileExists Should Return True if Files Present" {
        $exists = Test-FileExists $MyInvocation.ScriptName
        $exists | Should Be $True
    }

    It "Test-FileExists Should Return False if Files Not Present" {
        $exists = Test-FileExists "SomeRandomMissingFile.txt"
        $exists | Should Be $False
    }

    It "Test-FileExists Should Return False if No File is passed" {
        $exists = Test-FileExists $null
        $exists | Should Be $False
    }

    It "Test-ServiceExists Should Return True If Service Present" {
        $service = Get-Service | select -First 1
        $exists = Test-ServiceExists $service.Name
        $exists | Should Be $True
    }

    It "Test-ServiceExists Should Return False If Service Not Present" {
        $serviceName = "SomeRandomService"
        $exists = Test-ServiceExists $serviceName
        $exists | Should Be $False
    }

    It "Test-ServiceExists Should Return False If null is passed" {
        $serviceName = "SomeRandomService"
        $exists = Test-ServiceExists $null
        $exists | Should Be $False
    }

    It "Test-ServiceRunning Should Return True If Service Is Running" {
        $service = Get-Service | Where-Object {$_.status -eq "running"} | select -First 1
        $isRunning = Test-ServiceRunning $service.Name
        $isRunning | Should Be $True
    }

    It "Test-ServiceRunning Should Return False If Service Is Not Running" {
        $service = Get-Service | Where-Object {$_.status -ne "running"} | select -First 1
        $isRunning = Test-ServiceRunning $service.Name
        $isRunning | Should Be $False
    }

    It "Test-ServiceRunning Should Return False If No Service Name is Passed" {
        $isRunning = Test-ServiceRunning $null
        $isRunning | Should Be $False
    }

    It "Get-ServiceState Should Return null If No Service Name is Passed" {
        $isRunning = Get-ServiceState $null
        $isRunning | Should Be $null
    }  
    
    It "Get-ServiceState Should Return null If Unknown Service Name is Passed" {
        $isRunning = Get-ServiceState "SomeUnknownService"
        $isRunning | Should Be $null
    }   

    It "Get-ServiceState Should Return 'Running' If Service Name is Running" {
        $service = Get-Service | Where-Object {$_.status -eq "running"} | select -First 1
        $isRunning = Get-ServiceState $service.Name
        $isRunning | Should Be "running"
    } 

    It "Get-ServiceState Should Return 'Stopped' If Service Name is Stopped" {
        $service = Get-Service | Where-Object {$_.status -eq "stopped"} | select -First 1
        $isRunning = Get-ServiceState $service.Name
        $isRunning | Should Be "stopped"
    }
   
    Context "Get-OSCaption Mock Context" {        
        It "Test-OS Returns True if Server 2012 is Running" {
            Mock -ModuleName NetAnServerUtility Get-OSCaption { return "Microsoft Windows Server 2012 R2 Standard"}
            $correctOS = Test-OS "Server 2012"
            $correctOS | Should Be $True
        }

        It "Test-OS Returns False if Server 2008 is Running" {
            Mock -ModuleName NetAnServerUtility Get-OSCaption { return "Microsoft Windows Server 2008 R2 Standard"}
            $correctOS = Test-OS "Server 2012"
            $correctOS | Should Be $False
        }
    }

    It "Test-Alphanumeric Should return True for all numbers" {
        $isAlphanumeric = Test-Alphanumeric "12345"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Alphanumeric Should return True for all numbers and Characters" {
        $isAlphanumeric = Test-Alphanumeric "12345CDEF"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Alphanumeric Should return True for all integers" {
        $isAlphanumeric = Test-Alphanumeric 123
        $isAlphanumeric | Should Be $True
    }

    It "Test-Alphanumeric Should return True for numbers characters and whitespace" {
        $isAlphanumeric = Test-Alphanumeric "123 345cdsdg 123"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Alphanumeric Should return False for non-Alphanumeric characters" {
        $isAlphanumeric = Test-Alphanumeric "123 345cdsdg``123"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Number Should return True for all numbers" {
        $isAlphanumeric = Test-Number "12345"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Number Should return True for all numbers and Characters" {
        $isAlphanumeric = Test-Number "12345CDEF"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Number Should return False for all Characters" {
        $isAlphanumeric = Test-Number "CDEF"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Number Should return True for numbers characters and whitespace" {
        $isAlphanumeric = Test-Number "123 345cdsdg 123"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Capital Should return False for all numbers" {
        $isAlphanumeric = Test-Capital "12345"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Capital Should return True for all numbers and Capitals" {
        $isAlphanumeric = Test-Capital "12345CDEF"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Capital Should return True for Characters and Capitals" {
        $isAlphanumeric = Test-Capital "CDef"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Capital Should return False for no Capital" {
        $isAlphanumeric = Test-Capital "123 345cdsdg 123"
        $isAlphanumeric | Should Be $False
    }


    It "Test-Password Should return True for all numbers and Characters" {
        $isAlphanumeric = Test-Password "Abcdefg1"
        $isAlphanumeric | Should Be $True
    }

    It "Test-Password Should return False for all numbers" {
        $isAlphanumeric = Test-Password 12345678
        $isAlphanumeric | Should Be $False
    }

    It "Test-Password Should return False for all Characters" {
        $isAlphanumeric = Test-Password "Abcdefgh"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Password Should return False for numbers characters no Capital" {
        $isAlphanumeric = Test-Password "abcdefgh1"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Password Should return False for non-Alphanumeric characters" {
        $isAlphanumeric = Test-Password "Abcdefg1@"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Password Should return False for less than 7 characters" {
        $isAlphanumeric = Test-Password "Abcde1"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Password Should return False for greater than 14 characters" {
        $isAlphanumeric = Test-Password "AbcdefghiJklm15"
        $isAlphanumeric | Should Be $False
    }

    It "Test-Password Should return True for 7-14  characters" {
        $isAlphanumeric = Test-Password "Abcdefg1"
        $isAlphanumeric | Should Be $True
    }

    
    It "Test-IP With Valid IPv4 Address should return true" {
        $ipAddress = "192.168.0.1"
        Test-IP $ipAddress | Should Be $True
    }

    It "Test-IP With inValid IPv4 Address should return false" {
        $ipAddress = "192.168.1"
        Test-IP $ipAddress | Should Be $False
    }

    It "Test-IP With Valid IPv6 Address should return true" {
        $ipAddress = "2001:1b70:82a1:a:217:a4ff:fe77:545a"
        Test-IP $ipAddress | Should Be $True
    }

    It "Test-IP With Valid Abbreviated IPv6 Address should return true" {
        $ipAddress = "2001::545a"
        Test-IP $ipAddress | Should Be $True
    }

    It "Test-IP With Valid Abbreviated IPv6 Address should return true" {
        $ipAddress = "2001:0:0::5a"
        Test-IP $ipAddress | Should Be $True
    }

    It "Test-SoftwareInstalled Should Return True at index 0 if Software found" {
        $ms = "Microsoft"      
        $result = Test-SoftwareInstalled $ms
        $result[0] | Should Be $true
    }

    It "Test-SoftwareInstalled Should Return True and contain an array -gt 1 if software found" {
        $ms = "Microsoft"    
        $msSoftware = Get-WmiObject -Class Win32_Product | select Name  | where { $_.Name -match $ms} | select -First 1   
        $result = Test-SoftwareInstalled $ms
        $testResult = $False
        foreach($item in $result) {
            if($item.name -eq $msSoftware[0].name){
                $testResult = $True
            }
        }
        $result.Count -gt 1 | Should Be $True
        $testResult | Should Be $True
    }

    It "Test-SoftwareInstalled Should Return False at index 0 if No Software found" {
        $software = "SoftwareThatDoesn'tExist"      
        $result = Test-SoftwareInstalled $software
        $result[0] | Should Be $False
    }

    It "Test-SoftwareInstalled Should Return False at index 0 if no argument passed" {
        $result = Test-SoftwareInstalled $null
        $result[0] | Should Be $False
    }

    It "Test-ModuleLoaded Should Return True if module is loaded" {
        $result = Test-ModuleLoaded "NetAnServerUtility"
        $result | Should Be $True
    }


    Context "When Calling Test-MapForKeys" {
        
        It "Should return True if parameter is found" {
            $params = @('serviceNetAnServer')
            $result = Test-MapForKeys $validMap $params
            $result[0] | Should Be $True
        } 

        It "Should return True if all parameters are found" {
            $params = @('serviceNetAnServer', 'serverSoftware', 'installDir',
                'serverLog', 'serverPort')
            $result = Test-MapForKeys $validMap $params
            $result[0] | Should Be $True
        }
       
        It "Should Return False if Parameter is found in map but value is Null" {
            $params = @('serviceNetAnServer', 'serverSoftware', 'installDir',
                'serverLog', 'serverPort')
            $result = Test-MapForKeys $invalidMapNull $params
            $result[0] | Should Be $False
            $result[1] | Should Be "Invalid Parameters Passed. Parameter at key installDir not Found"
        }

        It "Should Return False if key is incorrect in map" {
            $params = @('serviceNetAnServer', 'serverSoftware', 'installDir',
                'serverLog', 'serverPort')
            $result = Test-MapForKeys $invalidMap $params
            $result[0] | Should Be $False
            $result[1] | Should Be "Invalid Parameters Passed. Parameter at key installDir not Found"
        }

        It "Should Return False if map is null" {
            $params = @('serviceNetAnServer', 'serverSoftware', 'installDir',
                'serverLog', 'serverPort')
            $result = Test-MapForKeys $null $params
            $result[0] | Should Be $False
            $result[1] | Should Be "Incorrect Parameters Passed. Parameter Map is Null Valued"
        }

        It "Should Return False if params are null" {
            $params = @('serviceNetAnServer', 'serverSoftware', 'installDir',
                'serverLog', 'serverPort')
            $result = Test-MapForKeys $validMap $null
            $result[0] | Should Be $False
            $result[1] | Should Be "The keys passed were null"
        }

        It "Should Return False if both are null" {
            $params = @('serviceNetAnServer', 'serverSoftware', 'installDir',
                'serverLog', 'serverPort')
            $result = Test-MapForKeys $null $null
            $result[0] | Should Be $False
            $result[1] | Should Be "Incorrect Parameters Passed. Parameter Map is Null Valued"
        }
        
    }
             
}