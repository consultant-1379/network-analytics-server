$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"
$testResourceDirectory = "$((Get-Item $pwd).Parent.FullName)\resources\FeatureInstaller"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module FeatureInstaller

Describe "FeatureInstaller.psm1 User Input Unit Test Cases" {

    Mock -ModuleName Logger Log-Message {} 

    $ENTER_USERNAME = "Please enter the Network Analytics Server Administrator username:"
    $ENTER_PASSWORD = "Please enter the Network Analytics Server platform password:"
    $ENTER_CONFIRM = "Please confirm that username and password are correct. (y/n)"
    

    Context "When Gathering User name and password - One" {

        Start-AwaitSession

        try {
            It "The Gather User Details Function should prompt for username password and confirmation" {
                Send-AwaitCommand Get-UserDetails
                Wait-AwaitResponse $ENTER_USERNAME -All
                Send-AwaitCommand "Username"
                Wait-AwaitResponse $ENTER_PASSWORD -All
                Send-AwaitCommand "Password"
                Wait-AwaitResponse $ENTER_CONFIRM -All
                Send-AwaitCommand "y"
            }

        } finally {
            Stop-AwaitSession
        }        
    }

    Context "When Gathering User name and password - Two" {

        Start-AwaitSession

        try {
            It "The Gather User Details Function should reprompt for username or password if none entered" {
                Send-AwaitCommand Get-UserDetails
                Wait-AwaitResponse $ENTER_USERNAME -All
                Send-AwaitCommand " "
                Wait-AwaitResponse $ENTER_USERNAME -All
                Send-AwaitCommand "User"
                Wait-AwaitResponse $ENTER_PASSWORD -All
                Send-AwaitCommand " "
                Wait-AwaitResponse $ENTER_PASSWORD -All
                Send-AwaitCommand "Password"
                Wait-AwaitResponse $ENTER_CONFIRM -All
                Send-AwaitCommand "y"
            }

        } finally {
            Stop-AwaitSession
        }        
    }

    Context "When Gathering User name and password - Three" {

        Start-AwaitSession

        try {
            It "The Gather User Details Function should reprompt when 'N' is selected" {
                Send-AwaitCommand Get-UserDetails
                Wait-AwaitResponse $ENTER_USERNAME -All
                Send-AwaitCommand "User"
                Wait-AwaitResponse $ENTER_PASSWORD -All
                Send-AwaitCommand "Password"
                Wait-AwaitResponse $ENTER_CONFIRM -All
                Send-AwaitCommand "n"
                Wait-AwaitResponse $ENTER_USERNAME -All
            }

        } finally {
            Stop-AwaitSession
        }        
    }


    Context "When Gathering User name and password - Four" {

        Start-AwaitSession

        try {
            It "The Gather User Details Function should reprompt confirmation when invalid value entered" {
                Send-AwaitCommand Get-UserDetails
                Wait-AwaitResponse $ENTER_USERNAME -All
                Send-AwaitCommand "User"
                Wait-AwaitResponse $ENTER_PASSWORD -All
                Send-AwaitCommand "Password"
                Wait-AwaitResponse $ENTER_CONFIRM -All
                Send-AwaitCommand "x"
                Wait-AwaitResponse $ENTER_CONFIRM -All
            }

        } finally {
            Stop-AwaitSession
        }        
    }

}