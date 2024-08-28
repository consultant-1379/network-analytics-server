$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
write-host $modulesUnderTest
if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module NetAnServerNodeManagerInstaller


$validMap = @{
    'nodeServiceName'='some value';
    'nodeManagerSoftware'='name.exe';
    'installNodeManagerDir'='c:\path\to\dir';
    'nodeManagerLog'='c:\path\to\someLogDir.log';
    'nodeRegistrationPort'='8888';
    'nodeCommunicationPort'='9080';
}

$invalidMap = @{
    'serviceNetAnServer'='some value';
    'serverSoftware'='name.exe';
    'instaDir'='c:\path\to\dir';
    'serverLog'='c:\path\to\someLogDir.log';
    'serverPort'='8888'
}


$nodeMap = @{
    'dbName'='databaseOne';
    'connectIdentifer'='nameServer';
    'dbUser'='newUser';
    'configToolPassword'='newPassword';
   }



$serverName = $(hostname)
$nodeManagerHostName = $(hostname) 

$validCommand = '/s /v"/qn /l*vx c:\path\to\someLogDir.log INSTALLDIR=c:\path\to\dir NODEMANAGER_REGISTRATION_PORT=8888  NODEMANAGER_COMMUNICATION_PORT=9080 SERVER_NAME='+$serverName +'  SERVER_BACKEND_REGISTRATION_PORT= SERVER_BACKEND_COMMUNICATION_PORT= NODEMANAGER_HOST_NAMES='+$nodeManagerHostName+' START_SERVICE=1'


Describe "NetAnServerNodeManagerInstaller.psm1 Test Cases" {

    Context "When Checking if NodeManager is installed" {    
    
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerNodeManagerInstaller Test-ServiceExists { return $True }
                   
        It "Test-NodeManagerSoftwareInstalled Should be True If Service Exists" {
            $params = @{'nodeServiceName'='exists'}
            $status = Test-NodeManagerSoftwareInstalled $params
            $status | Should Be $True
            Assert-MockCalled -ModuleName Logger Log-Message -Exactly 2 -Scope It
        } 
    }

     Context "When Checking if NodeManager is not installed" { 

        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerNodeManagerInstaller Test-ServiceExists { return $False }
                   
        
        It "Test-NodeManagerSoftwareInstalled Should be False If Service Does Not Exist" {
            $params = @{'nodeServiceName'='not-exists'}
            $status = Test-NodeManagerSoftwareInstalled $params
            $status | Should Be $False
            Assert-MockCalled -ModuleName Logger Log-Message -Exactly 2 -Scope It
        }       
    } 

    Context "When Checking NodeManager Installed Validate Parameters Passed" {
        
        Mock -ModuleName Logger Log-Message {}

        It "When Validating Params Should Return False if Parameter is not found in map" {
            $params = @{'serviceNetnServer'='exists'}
            $result = Approve-Params $params
            $result | Should Be $False
        } 

        It "When Validating Params Should Return True if All Parameter are found in map" {
            $result = Approve-Params $validMap
            $result | Should Be $True
        }
       
        It "When Validating Params Should Return False if Parameter is found in map but Null" {
            $params = @{'nodeManagerLog'= $null}
            $result = Approve-Params $params
            $result | Should Be $False
        }

        It "When Validating Params Should Return False if parameters are null" {
            $params = $null
            $result = Approve-Params $params
            $result | Should Be $False
        }
    }

     Context "When a Valid Map is passed" {
        
        Mock -ModuleName Logger Log-Message {}

        It "The Get-NodeManagerArguments Function should return a list of 1 arguments" {
            $args = Get-NodeManagerArguments $validMap
            $args | Should Not Be NullOrEmpty
            $args.Count | Should Be 1
        }

        It "The Get-NodeManagerArguments Function should return a list of formatted valid arguments" {
            $args = Get-NodeManagerArguments $validMap
            $args | Should BeExactly $validCommand
        }
    }

    
    Context "When the Install-NetAnServerServer is Called" {   
           Mock -ModuleName Logger Log-Message  {}
           Mock -ModuleName NetAnServerNodeManagerInstaller Test-NodeManagerSoftwareInstalled { return $False }
           Mock -ModuleName NetAnServerNodeManagerInstaller Install-Software{}

        It "If Software not installed. Should Call Install-Software" {
            $result = Install-NetAnServerNodeManager $validMap
            Assert-MockCalled -ModuleName NetAnServerNodeManagerInstaller Install-Software -Exactly 1 -Scope It
        }
    }

      Context "When a valid map is passed to Install-Software" {
        
        Mock -ModuleName Logger Log-Message {}

        $params = Get-NodeManagerArguments $validMap

        Mock -ModuleName NetAnServerNodeManagerInstaller Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' 0
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } -ParameterFilter { 
                $FilePath -eq $validMap['nodeManagerSoftware'] -and ( $ArgumentList -eq $params )
        }

        
        It "Start-Process Should be called" {
            Install-Software $validMap
            Assert-VerifiableMocks 
        } 

        It "Start-Process Should be called with the correct Arguments" {
            Install-Software $validMap
            Assert-MockCalled -ModuleName NetAnServerNodeManagerInstaller Start-Process -Exactly 1 -Scope It
        }            
   }

   Context "When the Install-NetAnServerNodeManagerInstaller is Called" {
        
        Mock -ModuleName Logger Log-Message  {}  

        $params = Get-NodeManagerArguments $validMap        

        Mock -ModuleName NetAnServerNodeManagerInstaller Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' -1
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } -ParameterFilter { 
                $FilePath -eq $validMap['nodeManagerSoftware'] -and ( $ArgumentList -eq $params )
        }

        Mock -ModuleName NetAnServerNodeManagerInstaller Test-NodeManagerSoftwareInstalled {}

        It "Should Return false if incorrect parameters are passed" {
            $result = Install-NetAnServerNodeManager $invalidMap
            $result | Should Be $False
        }

        It "Should Return False if Exit Code is not 0" {
             $result = Install-NetAnServerNodeManager $validMap
             $result | Should Be $False
             Assert-MockCalled -ModuleName NetAnServerNodeManagerInstaller Test-NodeManagerSoftwareInstalled -Exactly 1 -Scope It
        }
   }


    Context "When Get-NodeID is called with no NodeID available" {

        Mock -ModuleName Logger Log-Message  {} 
        Mock -ModuleName NetAnServerNodeManagerInstaller Invoke-UtilitiesSQL  {return @($False)}
        
         It "Should Return false when no node-id is called" {
            $result = Get-NodeID $nodeMap
            $result | Should Be $False
        }       

    }

    
    Context "When Get-NodeID is called and returns ID" {
        Mock -ModuleName Logger Log-Message  {} 
        Mock -ModuleName NetAnServerNodeManagerInstaller Invoke-UtilitiesSQL  {return @($True, 'rrwoeruo444')}

      It "Should Return node-ID when node-id is available" {
            $result = Get-NodeID $nodeMap
            $result | Should Be 'rrwoeruo444'
        } 

    }

     Context "When Trust-Node is called successfully and returns true" {
        Mock -ModuleName Logger Log-Message  {} 
        Mock -ModuleName NetAnServerNodeManagerInstaller Get-NodeID  {return 'rrwoeruo444'}
        Mock -ModuleName NetAnServerNodeManagerInstaller Use-ConfigTool  {return $True}

      It "Should Return True when Trust-Node is successful" {
            $result = Trust-Node $nodeMap
            $result | Should Be $True
        } 

    }

      Context "When nodeID is not returned TrustNode returns false" {
        Mock -ModuleName Logger Log-Message  {} 
        Mock -ModuleName NetAnServerNodeManagerInstaller Get-NodeID  {return $false}

      It "Should Return False when nodeID is false" {
            $result = Trust-Node $nodeMap
            $result | Should Be $False
        } 

    }
        
}


Remove-Module Logger
Remove-Module NetAnServerNodeManagerInstaller
  
