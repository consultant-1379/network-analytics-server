$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Install\NetAnServer_install.ps1"

Import-Module Await

$STARTING_MESSAGE = "Please refer to the Network Analytics Server Installation Instructions"
$FIRST_INPUT_PARAMETER = "MS SQL Server Administrator Password:"
$SECOND_INPUT_PARAMETER = "Network Analytics Server Platform Password:"
$THIRD_INPUT_PARAMETER = "Network Analytics Server Administrator User Name:"
$FOURTH_INPUT_PARAMETER = "Network Analytics Server Administrator Password:"
$CORRECT_PASSWORD = "Ericsson01"
$ADMIN_USER = "ADMIN USER"
$WRONG_PASSWORD = "ericsson01"
$ERROR_MESSAGE = "Invalid syntax"
$CONFIRM_MESSAGE = "Please confirm that all of the above parameters are correct"
$REENTER_MESSAGE = "Please re-enter the parameters"
$SET_ENV_VAR = {[Environment]::SetEnvironmentVariable("LSFORCEHOST","10.59.131.124", "User") }
$SLEEP_TIME = "5"


Describe "NetAnServer Correct Input Parameters Check" {

    # clean up to remove copied modules/scripts
    AfterEach {
        Remove-Item C:\Ericsson -Recurse -ErrorAction SilentlyContinue
    }

    Start-AwaitSession

    try {
    
                         
        It "Verifying initial start info message and first parameter" {
            Send-AwaitCommand $SET_ENV_VAR
            Send-AwaitCommand $scriptUnderTest
            start-sleep $SLEEP_TIME
            $output = Wait-AwaitResponse $STARTING_MESSAGE -All
            $output -match $STARTING_MESSAGE| Should be $true
            start-sleep $SLEEP_TIME
            $output -match $FIRST_INPUT_PARAMETER| Should be $true
        }
           
        It "Verifying first parameter correct password" {
            Send-AwaitCommand $CORRECT_PASSWORD
            $output = Wait-AwaitResponse $SECOND_INPUT_PARAMETER -All
            $output = (Receive-AwaitResponse)
            $output -match $SECOND_INPUT_PARAMETER| Should be $true            
          }

        It "Verifying second parameter correct password" {
            Send-AwaitCommand $CORRECT_PASSWORD
            $output = Wait-AwaitResponse $THIRD_INPUT_PARAMETER -All
            $output = (Receive-AwaitResponse) 
            $output -match $THIRD_INPUT_PARAMETER | Should be $true
        }

        It "Verifying third parameter correct password" {
            Send-AwaitCommand $ADMIN_USER
            $output = Wait-AwaitResponse $FOURTH_INPUT_PARAMETER -All
            $output = (Receive-AwaitResponse) 
            $output -match $FOURTH_INPUT_PARAMETER | Should be $true
        }
          
          It "Verifying fourth parameter correct password" {
            Send-AwaitCommand $CORRECT_PASSWORD
            $output = Wait-AwaitResponse $CONFIRM_MESSAGE -All
            start-sleep $SLEEP_TIME
            $output = (Receive-AwaitResponse) 
            $output -match $CONFIRM_MESSAGE | Should be $true
        }
    }
    finally {
        Stop-AwaitSession
    }
}
 
Describe "NetAnServer Wrong Input Parameters Check" {

    # clean up to remove copied modules/scripts
    AfterEach {
        Remove-Item C:\Ericsson -Recurse -ErrorAction SilentlyContinue
    }

    Start-AwaitSession

   try {

        It "Verifying second wrong parameter password check" {
             Send-AwaitCommand $scriptUnderTest
             Send-AwaitCommand $CORRECT_PASSWORD
             Send-AwaitCommand $WRONG_PASSWORD
             Start-Sleep $SLEEP_TIME
             $output = Receive-AwaitResponse
             $output -match $ERROR_MESSAGE | Should be $True
           
        }

          It "Verifying re-enter correct password for second parameter" {
             Send-AwaitCommand $CORRECT_PASSWORD
             Start-Sleep $SLEEP_TIME
             $output = Receive-AwaitResponse
             $output -match $THIRD_INPUT_PARAMETER | Should be $True
           
        }

          It "Verifying fourth wrong parameter password check" {
             Send-AwaitCommand $scriptUnderTest
             Send-AwaitCommand $CORRECT_PASSWORD
             Send-AwaitCommand $CORRECT_PASSWORD
             Send-AwaitCommand $ADMIN_USER
             Send-AwaitCommand $WRONG_PASSWORD
             Start-Sleep $SLEEP_TIME
             $output = Receive-AwaitResponse
             $output -match $ERROR_MESSAGE | Should be $True
       }

          It "Verifying re-enter correct password for fourth parameter" {
             Send-AwaitCommand $CORRECT_PASSWORD
             $output = Wait-AwaitResponse $CONFIRM_MESSAGE -All
             
             $output = (Receive-AwaitResponse)
           
             $output -match $CONFIRM_MESSAGE | Should be $True
           
        }
          
         It "Verifying Message for re-enter all parameters" {
          Send-AwaitCommand "n"
          $output = Wait-AwaitResponse $REENTER_MESSAGE -All
           $output = (Receive-AwaitResponse)
           $output -match $REENTER_MESSAGE | Should be $True
           
       }

       
    }
    finally {
        Stop-AwaitSession
    }
}
   

