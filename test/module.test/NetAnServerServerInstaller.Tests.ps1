$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module NetAnServerServerInstaller


$validMap = @{
    'serviceNetAnServer'='some value';
    'serverSoftware'='name.exe';
    'installServerDir'='c:\path\to\dir';
    'serverLog'='c:\path\to\someLogDir.log';
    'serverPort'='8888';
    'serverRegistrationPort'='9080';
    'serverCommunicationPort'='9443'
}

$invalidMap = @{
    'serviceNetAnServer'='some value';
    'serverSoftware'='name.exe';
    'instaDir'='c:\path\to\dir';
    'serverLog'='c:\path\to\someLogDir.log';
    'serverPort'='8888'
}

$validCommand = '/s /v"/qn /l*vx c:\path\to\someLogDir.log DOWNLOAD_THIRD_PARTY=No '+
                    'INSTALLDIR=c:\path\to\dir SPOTFIRE_WINDOWS_SERVICE=Create SERVER_FRONTEND_PORT=8888 ' +
                    'SERVER_BACKEND_REGISTRATION_PORT=9080 SERVER_BACKEND_COMMUNICATION_PORT=9443 NODEMANAGER_HOST_NAMES='


Describe "NetAnServerServerInstaller.psm1 Test Cases" {

    Context "When Checking if Server is installed" {    
    
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerServerInstaller Test-ServiceExists { return $True } -ParameterFilter{$serviceName -eq "exists"} 
                   
        It "Test-ServerSoftwareInstalled Should be True If Service Exists" {
            $params = @{'serviceNetAnServer'='exists'}
            $status = Test-ServerSoftwareInstalled $params
            $status | Should Be $True
            Assert-MockCalled -ModuleName Logger Log-Message -Exactly 2 -Scope It
        } 
        
        It "Test-ServerSoftwareInstalled Should be False If Service Does Not Exist" {
            $params = @{'serviceNetAnServer'='not-exists'}
            $status = Test-ServerSoftwareInstalled $params
            $status | Should Be $False
            Assert-MockCalled -ModuleName Logger Log-Message -Exactly 2 -Scope It
        }       
    } 

    Context "When Checking Server Installed Validate Parameters Passed" {
        
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
            $params = @{'serviceNetAnServer'= $null}
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

        It "The Get-Arguments Function should return a list of 1 arguments" {
            $args = Get-Arguments $validMap
            $args | Should Not Be NullOrEmpty
            $args.Count | Should Be 1
        }

        It "The Get-Arguments Function should return a list of formatted valid arguments" {
            $args = Get-Arguments $validMap
            $args | Should BeExactly $validCommand
        }
    }

    Context "When the Install-NetAnServerServer is Called" {   
           Mock -ModuleName Logger Log-Message  {}
           Mock -ModuleName NetAnServerServerInstaller Test-ServerSoftWareInstalled { return $False }
           Mock -ModuleName NetAnServerServerInstaller Install-Software{}

        It "If Software not installed. Should Call Install-Software" {
            $result = Install-NetAnServerServer $validMap
            Assert-MockCalled -ModuleName NetAnServerServerInstaller Install-Software -Exactly 1 -Scope It
        }
    }

    Context "When a valid map is passed to Install-Software" {
        
        Mock -ModuleName Logger Log-Message {}

        $params = Get-Arguments $validMap

        Mock -ModuleName NetAnServerServerInstaller Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' 0
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } -ParameterFilter { 
                $FilePath -eq $validMap['serverSoftware'] -and ( $ArgumentList -eq $params )
        }

        
        It "Start-Process Should be called" {
            Install-Software $validMap
            Assert-VerifiableMocks 
        } 

        It "Start-Process Should be called with the correct Arguments" {
            Install-Software $validMap
            Assert-MockCalled -ModuleName NetAnServerServerInstaller Start-Process -Exactly 1 -Scope It
        }            
   }

   Context "When the Install-NetAnServerServer is Called" {
        
        Mock -ModuleName Logger Log-Message  {}  

        $params = Get-Arguments $validMap        

        Mock -ModuleName NetAnServerServerInstaller Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' -1
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } -ParameterFilter { 
                $FilePath -eq $validMap['serverSoftware'] -and ( $ArgumentList -eq $params )
        }

        Mock -ModuleName NetAnServerServerInstaller Test-ServerSoftWareInstalled {}

        It "Should Return false if incorrect parameters are passed" {
            $result = Install-NetAnServerServer $invalidMap
            $result | Should Be $False
        }

        It "Should Return False if Exit Code is not 0" {
             $result = Install-NetAnServerServer $validMap
             $result | Should Be $False
             Assert-MockCalled -ModuleName NetAnServerServerInstaller Test-ServerSoftWareInstalled -Exactly 1 -Scope It
        }
   }

}

Remove-Module Logger
Remove-Module NetAnServerServerInstaller
  
