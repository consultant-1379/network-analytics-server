$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"
$moduleMockMethod = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources\mocked.modules"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

if(-not $env:PsModulePath.Contains($moduleMockMethod)) {
    $env:PSModulePath = $env:PSModulePath + ";$($moduleMockMethod)"
}

Import-Module NetAnServerUtility
Import-Module SQLPS -DisableNameChecking
Import-Module DefinedUsers


Describe "DefinedUsers.psm1 Unit negative Tests" {

    Mock -ModuleName DefinedUsers Invoke-UtilitiesSQL {return $false} 
    Mock -ModuleName DefinedUsers Test-ServiceRunning { $True } 
  

    It "Should return error message the database is invalid" {
        Mock Get-DefinedUsers {return @($false,'Error executing SQL statement.' )}
        $result = Get-DefinedUsers -database "Invalid" -username "netanserver" -password "Ericsson01" -serverInstance "10.59.141.10"
        
        $result[1] | Should be 'Error executing SQL statement.'
    }
       
    It "Should return error message as the username is invalid" {
        Mock Get-DefinedUsers {return @($false,'Error executing SQL statement.' )}    
        $result = Get-DefinedUsers -database "netAnServer_db" -username "InvalidUsername" -password "Ericsson01" -serverInstance "10.59.141.10"
        $result[1] | Should be 'Error executing SQL statement.'
    }
    
 
    It "Should return error message as the password is invalid" {
        Mock Get-DefinedUsers {return @($false,'Error executing SQL statement.' )}    
        $result = Get-DefinedUsers -database "netAnServer_db" -username "netanserver" -password "InvalidPassword" -serverInstance "10.59.141.10"
        $result[1] | Should be 'Error executing SQL statement.'

    }
    It "Should return error message as the password is invalid" {
        Mock Get-DefinedUsers {return @($false,'Error executing SQL statement.' )}    
        $result = Get-DefinedUsers -database "netAnServer_db" -username "netanserver" -password "Ericsson01" -serverInstance "1.2.3.4.5"
        $result[1] | Should be 'Error executing SQL statement.'
    }

}
Describe "DefinedUsers.psm1 Unit Positive Test" {

    Mock -ModuleName DefinedUsers Invoke-UtilitiesSQL {@($True, @("Consumers", 1, "BusinessAuthor", 1, "BusinessAnalyst", 1, "Others",3))}
    Mock Test-ServiceRunning { $True } 

    It "Should return true the params are valid" {
        MOck -ModuleName DefinedUsers DefinedUsersToHashTable {
        $RECORD = New-Object System.Collections.Specialized.OrderedDictionary

        $RECORD.Add('TIMESTAMP','10.00')
        $RECORD.Add( 'ANALYST','2')
        $RECORD.Add( 'AUTHOR','3')
        $RECORD.Add( 'CONSUMER','4')
        $RECORD.Add( 'OTHER','3')
        $RECORD.Add( 'TOTAL','12')
        return $RECORD
        
     }
        $result = Get-DefinedUsers -database "netanserver" -username "netanserver" -password "Ericsson01" -serverInstance "10.59.141.10"
        $result[1] | Should be 2
        $result[2] | Should be 3
        $result[3] | Should be 4
        $result[4] | Should be 3
    }
    
}


