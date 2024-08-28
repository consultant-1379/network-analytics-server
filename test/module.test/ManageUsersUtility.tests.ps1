$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules"
write-host $modulesUnderTest

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module ManageUsersUtility

Describe "Test ManageUsersUtilty Unit Tests"  {

   Mock -ModuleName Logger Log-Message {}

       Context "Test creating user" {
           Mock -ModuleName ManageUsersUtility Invoke-ListUsers {}

            It "Add-User completes successfully" {
                Mock -ModuleName ManageUsersUtility Get-Arguments {return "CommandArguments"}
                Mock -ModuleName ManageUsersUtility Use-ConfigTool {return $True}

                $addUser = Add-User "netanserver" "userPassword01" "Consumer" "PlatformPassword"
                $addUser | Should Be $True
            }

            It "Add-User does not complete successfully when create-user arguments are null" {
                Mock -ModuleName ManageUsersUtility Get-Arguments {return $null}

                $addUser = Add-User "netanserver" "Ericsson01" "Consumer" "PlatformPassword"
                $addUser[0] | Should Be $False
            }

            It "User not created successfully" {
                Mock -ModuleName ManageUsersUtility Get-Arguments {return "CommandArguments"}
                Mock -ModuleName ManageUsersUtility Use-ConfigTool {return $False}

                $addUser = Add-User "netanserver" "Ericsson01" "Consumer" "PlatformPassword"
                $addUser[0] | Should Be $False
            }
       }

       Context "Test adding user to group" {
           Mock -ModuleName ManageUsersUtility Invoke-ListUsers {}

            It "Adding User to group does not complete successfully when add-member arguments are null" {
                Mock -ModuleName ManageUsersUtility Get-Arguments {return $null} 

                $addtogroup = Add-UserToGroup "newuser" "Consumer" "PlatformPassword"
                $addtogroup[0] | Should Be $False
            }

            It "Adding User does not add user to group successfully" {
                Mock -ModuleName ManageUsersUtility Get-Arguments {return "commandaddtogroup"}               
                Mock -ModuleName ManageUsersUtility Use-ConfigTool {return $False}

                $addtogroup = Add-UserToGroup "newuser" "Consumer" "PlatformPassword"
                $addtogroup[0] | Should Be $False
            }
       }  

       
        Context "Test user deleted successfully" {
            Mock -ModuleName ManageUsersUtility Invoke-ListUsers { return @{'USERNAME' = "netanserver"} }

            It "User is not deleted if arguments are null" {
                Mock -ModuleName ManageUsersUtility Get-Arguments {return $null}
                $deleteUser = Remove-User "netanserver" "Ericsson01"
                $deleteUser[0] | Should Be $False
            }

            It "User is not deleted successfully" {
                Mock -ModuleName ManageUsersUtility Get-Arguments {return "CommandArguments"}
                Mock -ModuleName ManageUsersUtility Use-ConfigTool {return $False}
                $deleteUser = Remove-User "netanserver" "Ericsson01"
                $deleteUser[0] | Should Be $False
            }
        }

        Context "When a user does not previously exist" {

            Mock -ModuleName ManageUsersUtility Invoke-ListUsers { return $null }

            It "The Remove-User function should return the correct error message" {
                $result = Remove-User -u "username" -pp "Ericsson01"
                $result | Should Be "The User username does not exist"
            }
        }
}