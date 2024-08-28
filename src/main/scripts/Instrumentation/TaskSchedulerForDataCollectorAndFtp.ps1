#--------------------------------------------------------------------------------------
#   
#   Windows Task Scheduler script to schedule the Data collector script and Ftp script.  
#   
#   1-> Schedule a task to invoke the Data collector script immediate after 2 min once this script run.
#   2-> Schedule a task to invoke the Data collector script when ever system restarted.
#   3-> Schedule a task to invoke the Ftp  script immediate after 4 min once this script run 
#    on every 15 min interval to collect the logs from data collector and ftp to EE co-ordinator .

#-----------------------------------------------------------------------------------------
    param(
    [string]$ServerIpAddress
    )
    $date = Get-Date
    $DateStr = $date.ToString("yyyyMMdd_hhmmss")
    $temp = Get-Location
    $rootDir = (get-item $temp).parent.parent.parent.parent.FullName
    
    $dataCollectorScriptPath = $rootDir + "Ericsson\NetAnServer\Scripts\Network_Analytics_Create_Data_Collector.ps1"
    $ftpToEECoordinatorScriptPath = $rootDir + "Ericsson\NetAnServer\Scripts\NetAnServerLogsZipAndFtp.ps1 "
    $powershellExecutionPolicyVar = "powershell "
    $fullPathForDataCollectorScript = $powershellExecutionPolicyVar + $dataCollectorScriptPath
    $fullPathForFtpScript = $powershellExecutionPolicyVar + $ftpToEECoordinatorScriptPath + $rootDir +" "+$ServerIpAddress
    $logFilePath = $rootDir +"Ericsson\NetAnServer\Logs\NetAnServerTaskSchedulerLog_$DateStr.txt"
    
    $dataCollectorTaskName = "Data_Collector_Start_Up"
    $dataCollectorTaskNameOnSystemStart = "Data_Collector_StartUp_On_System_Start"
    $dataCollectorTaskNameForEveryDay = "Data_Collector_Startup_EveryDay"
    $FTPTaskName = "Ftp_Zip_To_EE_Coordinator"
   
    $AddTwoMinToStartDataCollector = $date.AddMinutes(2)
    $AddFourMinToStartFtp = $date.AddMinutes(4)
    $timeStampForDataCollector = $AddTwoMinToStartDataCollector.ToShortTimeString()
    $timeStampForFTPScript = $AddFourMinToStartFtp.ToShortTimeString()
    $Status ="False"
    
    Function Main() {
    CheckEECoordinatorServerStatus    
    CheckDataCollectorAndFTPFilePath    
    CheckTasksInTaskScheduler
    AddTasksInTaskScheduler
    $Status ="True"
    $Status
    }

    #-----------------------------------------------------------------------
    #   Check the status of EE Coordinator server .
    #-----------------------------------------------------------------------

    Function CheckEECoordinatorServerStatus() {
        if([bool]$ServerIpAddress ){
            $serverStatus = Test-Connection -ComputerName $ServerIpAddress -Quiet
            if($serverStatus){
            Log "Ftp Server $ServerIpAddress is Up and Running "
        }
        else{
            Log "Ftp Server $ServerIpAddress is either wrong or not in Running State. Check the server name and status .Exit"
            $Status
            Exit
        }
    }
        else{
            Log "Server Ip Address argument is missing. Please provide Server Ip. Exit"
            $Status
            Exit
        }
    }
    
    #-----------------------------------------------------------------------
    #   Check the Data Collector and FTP file path . If it is not existing,
    #    Exit the script with proper Error Message.
    #-----------------------------------------------------------------------
    
    Function CheckDataCollectorAndFTPFilePath() {
    
        if(-not (test-path($dataCollectorScriptPath) )){
            Log "Error : Data Collector script missing At location $dataCollectorScriptPath . Exit"
            $Status
            Exit
        }
        if(-not (test-path($ftpToEECoordinatorScriptPath) )){
            Log "Error : Ftp script missing at location $ftpToEECoordinatorScriptPath . Exit"
            $Status
            Exit
        }
    }
    
        
    #-----------------------------------------------------------------------
    #   Check the information of tasks in task scheduler. If they are already
    #    existing, Exit the script.
    #-----------------------------------------------------------------------
    
    Function CheckTasksInTaskScheduler (){
        $schedule = new-object -com("Schedule.Service") 
        $schedule.connect() 
        $tasks = $schedule.getfolder("\").gettasks(0)
        foreach ($t in $tasks){
            $taskName=$t.Name
            if($taskName -eq $dataCollectorTaskNameForEveryDay -or $taskName -eq $dataCollectorTaskName -or $taskName -eq $dataCollectorTaskNameOnSystemStart -or $taskName -eq $FTPTaskName ){
            Log "Task $taskName is already added to the task scheduler Exit"
            $Status
            Exit
            }
        }
    }
   
    #-----------------------------------------------------------------------
    #   Add All tasks to task scheduler 
    #-----------------------------------------------------------------------
    
    Function AddTasksInTaskScheduler() {
        # Schedule a task to start the Data collector to collect the system counters.
        try {
            schtasks /create /ru system /sc once /tn $dataCollectorTaskName /tr $fullPathForDataCollectorScript /rl highest /st $timeStampForDataCollector | Out-File $logFilePath -Append;
            Log "Task $dataCollectorTaskName added successfully"
        }
        catch [exception]{
            Log "$_.Exception.Message"
        }
        # Schedule a task to start the Data collector to collect the system counters when ever system restart.
        try {
            schtasks /create /ru system /tn $dataCollectorTaskNameOnSystemStart /tr $fullPathForDataCollectorScript /rl highest /sc onstart | Out-File $logFilePath -Append;
            Log "Task $dataCollectorTaskNameOnSystemStart added successfully"
        }
        catch [exception]{
            Log "$_.Exception.Message"
        }
         
        # Schedule a task to invoke Data collector on every day at 00:00.
        try {
            schtasks /create /ru system /sc daily /tn $dataCollectorTaskNameForEveryDay /tr $fullPathForDataCollectorScript /rl highest /st 00:00 | Out-File $logFilePath -Append;
            Log "Task $dataCollectorTaskNameForEveryDay added successfully"
        }
        catch [exception]{
            Log "$_.Exception.Message"
        }
        # Schedule a task to invoke the Ftp script on every 15 min
        try {
            SchTasks /Create /ru system /sc minute /mo 15 /tn $FTPTaskName /tr $fullPathForFtpScript /rl highest /st $timeStampForFTPScript | Out-File $logFilePath -Append;
            Log "Task $FTPTaskName added successfully"
        }
        catch [exception]{
        Log "$_.Exception.Message"
        }
    }
        
    #----------------------------------------------------------------------------------    
    #  Generic function to write Logs to the Log file.
    #----------------------------------------------------------------------------------    
    Function Log($string) {
        $date,$string | Out-File -FilePath $logFilePath -Append
    }
    
    Main

   

