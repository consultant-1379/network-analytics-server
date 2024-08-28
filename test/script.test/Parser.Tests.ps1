
$pwd = $PSScriptRoot
   
    $ddcSystemLogs = "C:\Ericsson\Instrumentation\DDC\SystemLogs\"
    $ddcApplicationLogs = "C:\Ericsson\Instrumentation\DDC\ApplicationLogs\"
    $userAuditDir = "C:\Ericsson\Instrumentation\UserAudit"
    $AuditLog = "C:\Program Files\TIBCO\Spotfire Web Player\6.5.2\Logfiles\AuditLog.txt"
    $TimingLog = "C:\Program Files\TIBCO\Spotfire Web Player\6.5.2\Logfiles\TimingLog.txt"
    $UserSessionStatisticsLog = "C:\Program Files\TIBCO\Spotfire Web Player\6.5.2\Logfiles\UserSessionStatisticsLog.txt"
    $OpenFilesStatisticsLog = "C:\Program Files\TIBCO\Spotfire Web Player\6.5.2\Logfiles\OpenFilesStatisticsLog.txt"
    $DocumentCacheStatisticsLog = "C:\Program Files\TIBCO\Spotfire Web Player\6.5.2\Logfiles\DocumentCacheStatisticsLog.txt"
    $MemoryStatisticsLog = "C:\Program Files\TIBCO\Spotfire Web Player\6.5.2\Logfiles\MemoryStatisticsLog.txt"
    $serverLog = "C:\Ericsson\NetAnServer\Server\tomcat\logs\server.log"
    $sqlLog = "C:\Ericsson\NetAnServer\Server\tomcat\logs\sql.log"
    
    $logFileList = @($AuditLog,$TimingLog,$UserSessionStatisticsLog,
                    $OpenFilesStatisticsLog,$DocumentCacheStatisticsLog,
                    $MemoryStatisticsLog,$serverLog,$sqlLog)
    
    New-Item $ddcSystemLogs -Type directory -ErrorAction stop | Out-Null
    New-Item $ddcApplicationLogs -Type directory -ErrorAction stop | Out-Null
    New-Item $userAuditDir -Type directory -ErrorAction stop | Out-Null
    
    foreach ($fileName in $logFileList){
        New-Item $fileName -Type file -force -ErrorAction stop | Out-Null
    }

    
$scriptUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Instrumentation\Parser\Parser.ps1"

. $scriptUnderTest

 
Import-Module Logger 


Describe "Parser.Tests.ps1 Test Cases" {
 

   
    Context "checking parser function" {
        
        Mock -ModuleName Logger Log-Message {}
             
        It "Should return true when both test-path and invoke-command true" {
        . $scriptUnderTest
        Mock Invoke-Command {$true }
        Mock Test-Path {$true}
     
        $status = StartParser
        $status | Should Be $true
    }
    
 
       It "Should return false when Invoke-Command failed " {
        
        Mock Test-Path {$true}
        Mock Invoke-Command { throw }
     
        $status = StartParser
        $status | Should Be $false
      }
   
    }

    Context "checking log directory function for test-path and New-Item fail" {
    
        
     Mock -ModuleName Logger Log-Message {}
     It "Should return false when test-path false" {
         
        Mock Test-Path { $false }
        Mock New-Item { }      
              
        $status = CheckLogDirs
        $status | Should Be $false
        
    }

    It "Should return false when New-Item throw exception" {
      
        Mock Test-Path { $false }
        Mock New-Item { throw }      
              
        $status = CheckLogDirs
        $status | Should Be $false
        
    }
}
    Context "checking log directory function for test-path pass" {

     # clean up to remove copied modules/scripts
    AfterEach {
        Remove-Item C:\Ericsson -Recurse -ErrorAction SilentlyContinue
        Remove-Item "C:\Program Files\TIBCO" -Recurse -ErrorAction SilentlyContinue

        
    }
     
             
     Mock -ModuleName Logger Log-Message {}
     It "Should return true when test-path true" {
 
        Mock Test-Path {$true}
        Mock New-Item {}
        $status = CheckLogDirs
        $status | Should Be $true
    }

    It "Should return true when Copy-LogFile test-path true" {
 
        Mock Test-Path {$true}
        Mock Copy-Item {}
        $status = Copy-LogFile
        $status | Should Be $true
    }

    It "Should return false when Copy-LogFile test-path false" {
 
        Mock Test-Path {$false}
         $status = Copy-LogFile
        $status | Should Be $false
    }

    It "Should return Null when Remove-oneDayOldFiles Invoke_command {}" {
 
        Mock Invoke-Command { }
        Remove-oneDayOldFiles | Should Be $NULL
    }

     It "Should return Null when Remove-oneDayOldFiles Invoke_command throws" {
 
        Mock Invoke-Command { throw }
        Remove-oneDayOldFiles | Should Be $NULL
    }
} 
}



