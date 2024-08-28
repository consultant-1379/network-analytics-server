<#
#
# This test creates a Datacollector, starts it, stops it and confirms it can be deleted.
#
#
#
#
#>




$pwd = $PSScriptRoot

$scriptUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\Instrumentation\DataCollector\Create_Data_Collector.ps1"
$dataCollectorLogDir = "C:\Ericsson\Instrumentation\DataCollectorLogs"
$testXml = "$((Get-Item $pwd).Parent.FullName)\resources\DataCollector_Template.xml"
$tempxmlLoc = 'C:\Ericsson\NetAnServer\Scripts\Instrumentation\DataCollector\DataCollector_Template.xml'
$dataColDir = "C:\Ericsson\NetAnServer\Scripts\Instrumentation\DataCollector\"
$logDir = "C:\Ericsson\Instrumentation"

$name = 'Network_Analytics_Server_Data_Collector_Set'
$datacollectorset = new-Object -COM Pla.DataCollectorSet
Import-Module Logger 

Function Remove-TempDir {
    If (Test-Path $dataCollectorLogDir ) {
        
        Remove-Item $dataCollectorLogDir -Recurse -Force
       
    }
}
Function Create-Folders {

    If (!(Test-Path  $dataColDir)) {
        
        New-Item $dataColDir -Type directory
       
    }
}

Function Delete-Folders {

    If (Test-Path  $dataColDir) {
        
        Remove-Item $dataColDir -Recurse -Force      
    }
    If (Test-Path  $logDir) {
        
        Remove-Item $logDir -Recurse -Force       
    }
}

Function Move-Xml {
    If (!(Test-Path  $tempxmlLoc)) {
        Copy-Item $testXml $tempxmlLoc -Force
    }
}
Function Remove-Xml {
    If ((Test-Path  $tempxmlLoc)) {
        Remove-Item $tempxmlLoc -Recurse -Force
    }
}
Try {
    Describe "Start Datacollector from script" {

        BeforeEach {
            Remove-TempDir
            Create-Folders
            Move-Xml 
        
        }
    
       It "Should be true, datacollector running"{
            &$scriptUnderTest 
            $datacollectorset = New-Object -COM Pla.DataCollectorSet
            $datacollectorset.Commit($name,$null,0x0003) | Out-Null
            $datacollectorset.Query($name,$server)
            $status = $datacollectorset.Status
            $status |should be $true
        }
      }
    Describe "Start Datacollector from script, Then remove it" {

        BeforeEach {
            Remove-TempDir
            Create-Folders
            Move-Xml 
        
        }

           It "Should be False, Datacollector not runnning"{
            &$scriptUnderTest 
            $datacollectorset = New-Object -COM Pla.DataCollectorSet
            $datacollectorset.Commit($name,$null,0x0003) | Out-Null
            $datacollectorset.Query($name,$server)
            $datacollectorset.Stop($true)
            Start-Sleep -s 5
            $status = $datacollectorset.Status
            $datacollectorset.Delete()
            $status |should be $False
        }

    }
}Finally{
    Remove-TempDir
    Delete-Folders
    
}