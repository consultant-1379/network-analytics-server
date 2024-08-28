$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Modules"


if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module Logger
Import-Module InstallLibrary


Describe "Install Library Structure"  {

   Mock -ModuleName Logger Log-Message {}

  
   Context "Test Library Structure import" {

      New-item "TestDrive:\libStrct.zip" -Type file
      $libzip = Get-Item "TestDrive:\libStrct.zip"    
      $libparams =  @{libraryLocation=$libzip}
      

      It "Install Library successfully" {
            Mock -ModuleName InstallLibrary Test-Path { return $True}
            Mock -ModuleName InstallLibrary Get-Arguments { return $True}
            Mock -ModuleName InstallLibrary Use-ConfigTool { return $True }


            $install = Install-LibraryStructure $libparams
            $expected = $True
            $install | Should Be $expected
       }

      It "Import of Library unsuccessfull" {
            Mock -ModuleName InstallLibrary Test-Path { return $True}
            Mock -ModuleName InstallLibrary Get-Arguments { return $True}
            Mock -ModuleName InstallLibrary Use-ConfigTool { return $False}


            $install = Install-LibraryStructure $libparams
            $expected = $False
            $install | Should Be $expected
       }

       It "Get-Arguments returns Null" {
            Mock -ModuleName InstallLibrary Test-Path { return $True}
            Mock -ModuleName InstallLibrary Get-Arguments { return $Null}


            $install = Install-LibraryStructure $libparams
            $expected = $False
            $install | Should Be $expected
       }



    }

     Context "Test zip file exists" {

        New-item "TestDrive:\libStrct.zip" -Type file
        $libzip = Get-Item "TestDrive:\libStrct.zip"    
        $libparams =  @{libraryLocation=$libzip}
      


        It "Zip File does not exist" {
        Mock -ModuleName InstallLibrary Test-Path { return $False}

        $install = Install-LibraryStructure $libparams
        $expected = $False
        $install | Should Be $expected

        }


     }
}