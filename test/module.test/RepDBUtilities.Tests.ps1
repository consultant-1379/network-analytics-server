$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module RepDBUtilities

InModuleScope RepDBUtilities {

    

    Describe "RepDBUtilities.psm1 Unit Tests" {

        Mock -ModuleName Logger Log-Message {}

        
        Context "Calling Write-USerAuditToFile " {
            
            Start-AwaitSession
            $enterPass = "Please enter the Network Analytics Server platform password:"
            try {
                It "should return true" {
                    Mock -ModuleName RepDBUtilities Invoke-Sqlcmd {}
                    Send-AwaitCommand Write-UserAuditToFile
                    Wait-AwaitResponse $enterPass -All
                    Send-AwaitCommand "Ericsson01"
                }
            } finally {

                Stop-AwaitSession
            }
        }
    }
        
}

