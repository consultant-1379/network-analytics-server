$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

Import-Module FeatureInstaller
Import-Module Logger 
$permGUID='xxxx'
$userDetails=@{}
 $userDetails.Add('username','NetANServer01')
 $userDetails.Add('password','Ericsson01') 


Describe "FeatureInstaller.psm1 LibraryBuilder  Unit Tests" {
    Mock -Module Logger Log-Message{}
    Mock -Module FeatureInstaller Invoke-SqlQuery {}
    Context "When A Parent Child relationship doesnt exists" {
        
        Mock -Module FeatureInstaller Invoke-SqlQuery { @($True,  @{'Count' ="0"})} -Verifiable -ParameterFilter { $Query -eq "select count(*) as Count  from dbo.LIB_ITEMS where TITLE='child' and PARENT_ID ='parent'"}

        It "The Test-ChildExists funciton should return False" {
            $actual = Test-ChildExists  "child" "parent" "Ericsson2"
            $actual | Should Be $False
            Assert-VerifiableMocks
        }

    }

    Context "When A Parent Child relationship exists" {
        
        Mock -Modulename FeatureInstaller Invoke-SqlQuery { @($True,  @{'Count' ="0"})} -Verifiable -ParameterFilter { $Query -eq "select count(*) as Count  from dbo.LIB_ITEMS where TITLE='child' and PARENT_ID ='parent'"}

        It "The Test-ChildExists function should return True" {
            $actual = Test-ChildExists "child" "parent" "Ericsson2"
            $actual | Should Be $False
            Assert-VerifiableMocks
        }
    }
    Context "When Test-ChildExists called with incorrect arguments or argument is null" {
        
        Mock -Modulename FeatureInstaller Invoke-SqlQuery { @($False, $null)} -Verifiable -ParameterFilter { $Query -eq "select count(*) as Count  from dbo.LIB_ITEMS where TITLE='' and PARENT_ID ='parent'"}

        It "The Test-ChildExists function should return False" {
            $actual = Test-ChildExists  $null "parent" "Ericsson2"
            $actual | Should Be $False
            Assert-VerifiableMocks
        }
    }
    Context "When Get-ChildGUID called with incorrect arguments or argument is null" {
        
        Mock -Modulename FeatureInstaller Invoke-SqlQuery { @($False, $null)} -Verifiable -ParameterFilter { $Query -eq "select ITEM_ID from dbo.LIB_ITEMS where TITLE='' and PARENT_ID ='parent'"}
        It "The Get-ChildGUID function should return False" {
            $actual = Get-ChildGUID  $null "parent" "Ericsson2"
            $actual[0] | Should Be $False
            Assert-VerifiableMocks
        }
    }
    Context "When Get-ChildGUID called returns correct results" {
        
        Mock -Modulename FeatureInstaller Invoke-SqlQuery { @($True, @{'ITEM_ID' ="ffff"})} -Verifiable -ParameterFilter { $Query -eq "select ITEM_ID from dbo.LIB_ITEMS where TITLE='child' and PARENT_ID ='parent'"}
        It "The Get-ChildGUID function should return guid" {
             $actualResult = Get-ChildGUID  "child" "parent" "Ericsson2"
             $actualResult[1] | Should Be "ffff"
        }
    }
    Context "When Get-PermRootGUIDcalled returns correct results" {
        
        Mock -Modulename FeatureInstaller Invoke-SqlQuery { @($True, @{'ITEM_ID' ="ffff"})} -Verifiable -ParameterFilter { $Query -eq "select ITEM_ID from dbo.LIB_ITEMS where PARENT_ID is NULL and TITLE='root'"}
        It "The Get-PermRootGUID function should return guid" {
             $actualResult = Get-PermRootGUID "Ericsson2"
             $actualResult[1] | Should Be "ffff"
        }
    }
    Context "When Get-FolderITEMType returns correct results" {
        
        Mock -Modulename FeatureInstaller Invoke-SqlQuery { @($True, @{'TYPE_ID' ="ffff"})} -Verifiable -ParameterFilter { $Query -eq "select TYPE_ID from dbo.LIB_ITEM_TYPES where LABEL='folder'"}
        It "The Get-FolderITEMType function should return guid" {
             $actualResult = Get-FolderITEMType "Ericsson2"
             $actualResult[1] | Should Be "ffff"
        }
    }

    Context "Add-LibraryStructure is called when Structure /Ericsson Library/LTE/LTE CFA Guided Analysis Already exists" {
         Mock -Modulename FeatureInstaller Get-PermRootGUID { @($True,'ffff')}
         Mock -Modulename FeatureInstaller Test-ChildExists { $True} 
         Mock -Modulename FeatureInstaller Get-ChildGUID { @($True,'ffff')} 
        It "The Add-LibraryStructure  function should return Trure" {
             $actualResult = Add-LibraryStructure "/Ericsson Library/LTE/LTE CFA Guided Analysis" $userDetails
             $actualResult | Should Be "True"
             
        }
    }
        Context "Add-LibraryStructure is called when Structure /Ericsson Library/LTE/ exists and LTE CFA Guided Analysis needes to be added" {
         Mock -Modulename FeatureInstaller Get-PermRootGUID { @($True,'ffff')}
         Mock -Modulename FeatureInstaller Test-ChildExists { $False} -Verifiable -ParameterFilter {$child -eq "LTE CFA Guided Analysis"}
         Mock -Modulename FeatureInstaller Test-ChildExists { $True} -Verifiable -ParameterFilter {$child -eq "Ericsson Library"}
         Mock -Modulename FeatureInstaller Test-ChildExists { $True} -Verifiable -ParameterFilter {$child -eq "LTE"}
         Mock -Modulename FeatureInstaller Invoke-LibraryPackageCreation { @($True,"abc.zip","/abc/abc.zip")} -Verifiable -ParameterFilter {$foldername -eq "LTE CFA Guided Analysis"}
         Mock -Modulename FeatureInstaller Import-LibraryElement { $True} -Verifiable -ParameterFilter {$element -eq "/abc/abc.zip"}
         Mock -Modulename FeatureInstaller Get-ChildGUID { @($True,'ffff')}
         Mock -Modulename FeatureInstaller Get-ChildGUID { @($True,'zzzz')} -Verifiable -ParameterFilter {$child -eq "LTE CFA Guided Analysis"}
         Mock -Modulename FeatureInstaller Set-Parent { $True} -Verifiable -ParameterFilter {$childGUID -eq "zzzz"}  
        It "The Add-LibraryStructure  function should return Trure" {
             $actualResult = Add-LibraryStructure "/Ericsson Library/LTE/LTE CFA Guided Analysis" $userDetails
             $actualResult | Should Be "True"
             Assert-VerifiableMocks
             
        }
    }
}