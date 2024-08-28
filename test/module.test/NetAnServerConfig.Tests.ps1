$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"
$moduleMockMethod = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources\mocked.modules"

if ( -not $env:PsModulePath.contains($modulesUnderTest)) {
    $env:PsModulePath = $env:PsModulePath + ";$modulesUnderTest"
}

#adding mocked Sqlps module
if ( -not $env:PsModulePath.contains($moduleMockMethod)) {
    $env:PsModulePath = $env:PsModulePath + ";$moduleMockMethod"
}


Import-Module NetAnServerConfig
Import-Module Sqlps

Describe "NetAnServer Configuration" {

    BeforeEach {
        $drive = (Get-ChildItem Env:SystemDrive).value
        $serverIP = "127.0.0.1"
        $installParams = @{}
        $installParams.Add('netAnServerIP', $serverIP) 
        $installParams.Add('installDir', $drive + "\Ericsson\NetAnServer") 
        $installParams.Add('tomcatDir', $installParams.installDir + "\tomcat\bin\")
        $installParams.Add('configName', "Network Analytic Server Default Configuration")
        $installParams.Add('jConnSrc', $drive + "\netanserver_media\jconn4.jar")
        $installParams.Add('jConnDir', $installParams.installDir + "\tomcat\lib\")
        $installParams.Add('dbName', "netAnServer_db")
        $installParams.Add('dbUser', "netanserver")
        $installParams.Add('dbPassword', "Ericsson01")
        $installParams.Add('configToolPassword', "Ericsson01")
        $installParams.Add('dbDriverClass', "com.microsoft.sqlserver.jdbc.SQLServerDriver")
        $installParams.Add('dbURL', "jdbc:sqlserver://$($installParams.netAnServerIP):1433;DatabaseName="+$installParams.dbName)
        $installParams.Add('administrator', "netanserver")
        $installParams.Add('adminPassword', "Ericsson02")
        $installParams.Add('netAnServerDataSource', $installParams.mediaDir + "\Scripts\Resources\config\datasource_template.xml")
        $installParams.Add('logDir', "somedirectory")
        $installParams.Add('netanserverDeploy', "deployment.pkg")
        $installParams.Add('netanserverDeployAutomation', "deployautomation.pkg")
        $installParams.Add('netanserverBranding', "branding.pkg")
        $installParams.Add('netanserverGroups', "groups.txt")
        $installParams.Add('libraryLocation', $installParams.installDir +  "\library\LibraryStructure.part0.zip")
        $installParams.Add('username', "newuser")
        $installParams.Add('userPassword', "newPassword")
        $installParams.Add('groupname', "Group01")

        
    }
    

    Context "When Get-Arguments is called" {
        Mock -Module Logger Log-Message{}
        $stages = @('bootstrap', 'create-default-config', 'import-config', 'create-user', 'promote-admin','update-deployment','import-consumergroup', 'import-library-content','set-license', 'add-member','delete-user','create-genericuser', 'export-config', 'import-DBConnPool', 'set-db-config' )


        It "Should return the correct string for 'bootstrap'" {
            $logger = "log.txt"
            $output = Get-Arguments $stages[0] $installParams 
            $expected = "bootstrap -f -n -c com.microsoft.sqlserver.jdbc.SQLServerDriver " + 
                "-d jdbc:sqlserver://127.0.0.1:1433;DatabaseName=netAnServer_db" + 
                " -u netanserver -p Ericsson01 -t Ericsson01"
            $output | Should BeExactly $expected
        }

        It "Should return the correct string for 'create-default-config'" {
            $output = Get-Arguments $stages[1] $installParams 
            $expected = "create-default-config -f"
            $output | Should BeExactly $expected
        }

        It "Should return the correct string for 'import-config'" {
            $output = Get-Arguments $stages[2] $installParams 
            $expected = "import-config -t Ericsson01 -c `"Network Analytic Server Default Configuration`""
            $output | Should BeExactly $expected            
        }

        It "Should return the correct string for 'create-user'" {
            $output = Get-Arguments $stages[3] $installParams 
            $expected = "create-user -t Ericsson01 -u netanserver -p Ericsson02"
            $output | Should BeExactly $expected  
        }

        It "Should return the correct string for 'promote-admin'" {
            $output = Get-Arguments $stages[4] $installParams 
            $expected = "promote-admin -t Ericsson01 -u netanserver"
            $output | Should BeExactly $expected  
        }

        It "Should return the correct string for 'update-deployment'" {
            $output = Get-Arguments $stages[5] $installParams 
            $expected = "update-deployment -t Ericsson01 -a Production deployment.pkg,branding.pkg"
            $output | Should BeExactly $expected  
        }

        It "Should return the correct string for 'import-consumergroup'" {
            $output = Get-Arguments $stages[6] $installParams 
            $expected = "import-groups -t Ericsson01  groups.txt"
            $output | Should BeExactly $expected  
        }

        It "Should return the correct string for 'import-library-content'" {
            $output = Get-Arguments $stages[7] $installParams 
            $expected = "import-library-content -t Ericsson01 -p C:\Ericsson\NetAnServer\library\LibraryStructure.part0.zip -m KEEP_NEW -u netanserver"
            $output | Should BeExactly $expected  
        }

        It "Should return the correct string for 'set-license'" {
            $output = Get-Arguments $stages[8] $installParams '"Spotfire.Dxp.WebPlayer"' "Consumer"
            $expected = "set-license -t Ericsson01  -g `"Consumer`" -l `"Spotfire.Dxp.WebPlayer`""
            $output | Should BeExactly $expected  
        }  
              
        It "Should return the correct string for 'add-member'" {
            $output = Get-Arguments $stages[9] $installParams 
            $expected = "add-member -t Ericsson01 -g `"Group01`" -u newuser"
            $output | Should BeExactly $expected  
        }          
        It "Should return the correct string for 'delete-user'" {
            $output = Get-Arguments $stages[10] $installParams 
            $expected = "delete-user -t Ericsson01 -u newuser"
            $output | Should BeExactly $expected  
        }
        It "Should return the correct string for 'create-genericuser'" {
            $output = Get-Arguments $stages[11] $installParams 
            $expected = "create-user -t Ericsson01 -u newuser -p newPassword"
            $output | Should BeExactly $expected  
        }
        It "Should return the correct string for 'export-config'" {
            $output = Get-Arguments $stages[12] $installParams 
            $expected = "export-config -f -t Ericsson01"
            $output | Should BeExactly $expected  
        }
        It "Should return the correct string for 'import-DBConnPool'" {
            $output = Get-Arguments $stages[13] $installParams 
            $expected = "import-config  -c `"max-connections`" -t Ericsson01"
            $output | Should BeExactly $expected  
        }
        It "Should return the correct string for 'set-db-config'" {
            $output = Get-Arguments $stages[14] $installParams 
            $expected = "set-db-config -a 56"
            $output | Should BeExactly $expected  
        }
        It "Should return NULL if incorrect key passed" {
            $stage = "incorrect key"
            $expected = $NULL
            $output = Get-Arguments $stage $installParams 
            $ouput | Should Be $expected
        }
    } 

    Context "When Add-NetAnServerConfig is Called" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Import-JConnDriver { return $False }

        It "Should return False if JConn Deploy 'Import-JConnDriver' Fails" {
            $result = Add-NetAnServerConfig $installParams
            $result | Should Be $false
        } 

        It "Should return False with invalid parameters" {
            $installParams.Item('dbName') = $NULL
            $result = Add-NetAnServerConfig $installParams
            $result | Should Be $false
        }

        It "Should return False with missing parameters" {
            $installParams.Remove('dbName')
            $result = Add-NetAnServerConfig $installParams
            $result | Should Be $false
        }
    }
    
    Context "When Previous configuration installed" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Invoke-SqlQuery { 
                return @{CONFIG_COMMENT = "Network Analytic Server Default Configuration"}             
            }

        It "Test-ConfigurationExists Should return True" {
            $output = Test-ConfigurationExists $installParams
            $expected = $True
            $output | Should Be $expected
        }
    }

    Context "When Previous configuration NOT installed" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Invoke-SqlQuery { 
                return $null           
            }

        It "Test-ConfigurationExists Should return False" {
            $output = Test-ConfigurationExists $installParams
            $expected = $False
            $output | Should Be $expected
        }
    }


   Context "When all install conditions met: No Config, No User or Deployment Package" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Import-JConnDriver { return $True }
        Mock -ModuleName NetAnServerConfig Test-ConfigurationExists { return $False }
        Mock -ModuleName NetAnServerConfig Use-ConfigTool { return $True }
        Mock -ModuleName NetAnServerConfig Test-DatasourceTemplateExists { return $True }
        Mock -ModuleName NetAnServerConfig Test-ServerPackageDeployed { return $False }
        It "Should call Use-ConfigTool the correct number of times" {
            Add-NetAnServerConfig $installParams
            Assert-MockCalled -ModuleName NetAnServerConfig Use-ConfigTool  -Exactly 11 -Scope It
        } 
    }
    
    
    Context "When all install conditions met: Config and User and Group exists" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Import-JConnDriver { return $True }
        Mock -ModuleName NetAnServerConfig Test-ConfigurationExists { return $True }
        Mock -ModuleName NetAnServerConfig Use-ConfigTool { return $True }
        Mock -ModuleName NetAnServerConfig Test-UserExists { return $True }
         Mock -ModuleName NetAnServerConfig Test-GroupExists { return $True }

        It "Should call Use-ConfigTool the correct number of times" {
            Add-NetAnServerConfig $installParams
            Assert-MockCalled -ModuleName NetAnServerConfig Use-ConfigTool  -Exactly 0 
        } 
    }

    Context "When all install conditions met: Config Exists and No user and No Group Exist " {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Import-JConnDriver { return $True }
        Mock -ModuleName NetAnServerConfig Test-ConfigurationExists { return $True }
        Mock -ModuleName NetAnServerConfig Use-ConfigTool { return $True }
        Mock -ModuleName NetAnServerConfig Test-UserExists { return $False }
        Mock -ModuleName NetAnServerConfig Test-GroupExists { return $False }
        Mock -ModuleName NetAnServerConfig Test-DatasourceTemplateExists { return $True }
        Mock -ModuleName NetAnServerConfig Test-ServerPackageDeployed { return $True }
        
        It "Should call Use-ConfigTool the correct number of times" {
            Add-NetAnServerConfig $installParams
            Assert-MockCalled -ModuleName NetAnServerConfig Use-ConfigTool  -Exactly 3 
        } 
    }

      Context "When deployment package already installed" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Import-JConnDriver { return $True }
        Mock -ModuleName NetAnServerConfig Test-ConfigurationExists { return $True }
        Mock -ModuleName NetAnServerConfig Use-ConfigTool { return $True }
        Mock -ModuleName NetAnServerConfig Test-UserExists { return $true }
        Mock -ModuleName NetAnServerConfig Test-GroupExists { return $true }
        Mock -ModuleName NetAnServerConfig Test-DatasourceTemplateExists { return $true }
        Mock -ModuleName NetAnServerConfig Test-ServerPackageDeployed { return $True }
        
        It "Should call Use-ConfigTool the correct number of times" {
            Add-NetAnServerConfig $installParams
            Assert-MockCalled -ModuleName NetAnServerConfig Use-ConfigTool  -Exactly 2 
        } 
    }

    Context "When deployment package not installed" {
        Mock -ModuleName Logger Log-Message {}
        Mock -ModuleName NetAnServerConfig Import-JConnDriver { return $True }
        Mock -ModuleName NetAnServerConfig Test-ConfigurationExists { return $True }
        Mock -ModuleName NetAnServerConfig Use-ConfigTool { return $True }
        Mock -ModuleName NetAnServerConfig Test-UserExists { return $true }
        Mock -ModuleName NetAnServerConfig Test-GroupExists { return $true }
        Mock -ModuleName NetAnServerConfig Test-DatasourceTemplateExists { return $true }
        Mock -ModuleName NetAnServerConfig Test-ServerPackageDeployed { return $False }
        
        It "Should call Use-ConfigTool the correct number of times" {
            Add-NetAnServerConfig $installParams
            Assert-MockCalled -ModuleName NetAnServerConfig Use-ConfigTool  -Exactly 3
        } 
    }

}