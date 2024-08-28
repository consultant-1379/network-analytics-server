$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
write-host $modulesUnderTest
if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module AnalystInstaller


$validMap = @{
    'analystSoftware'='name.exe';
    'analystLog'='c:\path\to\someLogDir.log';
    'serverPort'='443';
}



$serverName = $(hostname)


$validCommand = '/s /v"/qn /l*vx c:\path\to\someLogDir.log SERVERURL=https://'+$serverName+':443'


Describe "AnalystInstaller.psm1 Test Cases" {

    Context "When Checking if Analyst is installed" {    
    
        Mock -ModuleName Logger Log-Message {} 
        Mock -ModuleName AnalystInstaller Get-WmiObject {return $True}  
        Mock -ModuleName AnalystInstaller ForEach-Object  {return $True}   
                   
        It "Test-AnalystSoftwareInstalled Should be True If Software Exists" {
            $status = Test-AnalystSoftwareInstalled $validMap
            $status | Should Be $True
            Assert-MockCalled -ModuleName Logger Log-Message -Exactly 2 -Scope It
        } 
    }

     Context "When Checking if Analyst is not installed" { 

        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName AnalystInstaller Get-WmiObject {return $False}  
        Mock -ModuleName AnalystInstaller ForEach-Object  {return $False} 
                   
        
        It "Test-NodeManagerSoftwareInstalled Should be False If Service Does Not Exist" {
            $status = Test-AnalystSoftwareInstalled $validMap
            $status | Should Be $False
            Assert-MockCalled -ModuleName Logger Log-Message -Exactly 2 -Scope It
        }       
    } 
    
     Context "When Checking Analyst Installed Validate Parameters Passed" {
        
        Mock -ModuleName Logger Log-Message {}

        It "When Validating Params Should Return False if Parameter is not found in map" {
            $params = @{'log'='exists'}
            $result = Approve-Params $params
            $result | Should Be $False
        } 

        It "When Validating Params Should Return True if All Parameter are found in map" {
            $result = Approve-Params $validMap
            $result | Should Be $True
        }
       
        It "When Validating Params Should Return False if Parameter is found in map but Null" {
            $params = @{'analystLog'= $null}
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

        It "The Get-AnalystArguments Function should return a list of 1 arguments" {
            $args = Get-AnalystArguments $validMap
            $args | Should Not Be NullOrEmpty
            $args.Count | Should Be 1
        }

        It "The Get-AnalystArguments Function should return a list of formatted valid arguments" {
            $args = Get-AnalystArguments $validMap
            $args | Should BeExactly $validCommand
        }
    }

     Context "When the Install-NetAnServerAnalyst is Called" {   
           Mock -ModuleName Logger Log-Message  {}
           Mock -ModuleName AnalystInstaller Test-AnalystSoftwareInstalled{ return $False }
           Mock -ModuleName AnalystInstaller Install-AnalystSoftware{}

        It "If Software not installed. Should Call Install-AnalystSoftware" {
            $result = Install-NetAnServerAnalyst $validMap
            Assert-MockCalled -ModuleName AnalystInstaller Install-AnalystSoftware -Exactly 1 -Scope It
        }
    }
    
     Context "When a valid map is passed to Install-AnalystSoftware" {
        
        Mock -ModuleName Logger Log-Message {}

        $params = Get-AnalystArguments $validMap

        Mock -ModuleName AnalystInstaller Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' 0
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } -ParameterFilter { 
                $FilePath -eq $validMap['analystSoftware'] -and ( $ArgumentList -eq $params )
        }

        
        It "Start-Process Should be called" {
            Install-AnalystSoftware $validMap
            Assert-VerifiableMocks 
        } 

        It "Start-Process Should be called with the correct Arguments" {
            Install-AnalystSoftware $validMap
            Assert-MockCalled -ModuleName AnalystInstaller Start-Process -Exactly 1 -Scope It
        }            
   } 
   
   Context "When the Install-NetAnServerAnalyst is Called" {
        
        Mock -ModuleName Logger Log-Message  {}  

        $params = Get-AnalystArguments $validMap        

        Mock -ModuleName AnalystInstaller Start-Process {
                $p = New-Object psobject
                Add-Member -in $p NoteProperty 'ExitCode' -1
                Add-Member -InputObject $p -MemberType ScriptMethod -Name WaitForExit -Value {}
                Add-Member -InputObject $p -MemberType ScriptMethod -Name Kill -Value {}
                return $p
            } -ParameterFilter { 
                $FilePath -eq $validMap['analystSoftware'] -and ( $ArgumentList -eq $params )
        }

        Mock -ModuleName AnalystInstaller Test-AnalystSoftwareInstalled {}

        It "Should Return false if incorrect parameters are passed" {
            $result = Install-NetAnServerAnalyst $invalidMap
            $result | Should Be $False
        }

        It "Should Return False if Exit Code is not 0" {
             $result = Install-NetAnServerAnalyst $validMap
             $result | Should Be $False
             Assert-MockCalled -ModuleName AnalystInstaller Test-AnalystSoftwareInstalled -Exactly 1 -Scope It
        }
   }
      
}


Remove-Module Logger
Remove-Module AnalystInstaller
  
