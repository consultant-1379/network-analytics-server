$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"
$usagelog = "$((Get-Item $pwd).Parent.FullName)\resources\ConcurrentUsers\usage.log.txt"
if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module NetAnServerUtility

Import-Module ConcurrentUsers  


Describe "ConcurrentUsers.psm1 Unit Tests" {
[datetime]$Global:timeStamp = get-date -date "14/09/2015 07:36:55"
$RECORD = @{
    'TIMESTAMP' = "09/14/2015 07:15:55";
    'ANALYST' = "0";
    'AUTHOR' = "0";
    'CONSUMER' = "0";
    'OTHER' = "3";
    'TOTAL' = "3";
    }

Mock -ModuleName ConcurrentUsers get-date { $timeStamp } 
    It "Should return string  of all counts and time" {
        $result = Get-ConcurrentUsers $usagelog "Ericsson01"
        $result.OTHER|  Should Be 3       
        }
        

}


