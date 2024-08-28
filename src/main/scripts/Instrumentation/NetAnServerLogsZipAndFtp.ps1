
#----------------------------------------------------------------------------------------------------------------------------
#   
#   Ftp script is used to ftp zipped log files from NetAnServer to EE co-ordinator at location /tmp/spotfire.
#   
#   1-> checks the Spotfire zip file path in windows machine.
#   2-> checks the Spotfire zip file exists at location C:\Ericsson\NetAnServer\logs\DDC . If exist , delete old one and 
#       creates new zip log file.
#   3-> copy logs from location C:\PerfLogs\System\Diagnostics to newly created zip log file at C:\Ericsson\NetAnServer\logs\DDC.
#   4-> Creates the Spotfire folder at location /tmp on EE coordinator 
#   5-> Ftp new zip log file from C:\Ericsson\NetAnServer\logs\DDC on window to EE co-ordinator at location /tmp/spotfire.
#
#   **NOTE: This script will collect the logs from folder ../../Diagnostics
#       and zip the logs file at location C:/Ericsson/NetAnServer/logs/DDC.
#       From Location C:/Ericsson/NetAnServer/logs/DDC , it will ftp zip file to co-ordinator at /tmp/spotfire.
#
#   Please review the log file (NetAnServerlogs.txt) at C:\Ericsson\NetAnServer\logs for any errors or warnings!
#
#---------------------------------------------------------------------------------------------------------------------------------
    param(
        [string]$rootDir,
        [string]$ServerIpAddress
    )
    $date = Get-Date
    $DateStr = $date.ToString("yyyyMMdd")
    $srcdir = $rootDir+'PerfLogs\System\Diagnostics'
    $zipFilename = "SpotfireLogs.zip"
    $zipFilepath = $rootDir+"Ericsson\NetAnServer\logs\DDC"
    $logsPath = $rootDir+"Ericsson\NetAnServer\logs\NetAnServerFtplogs_$DateStr.txt"
    $zipFile = "$zipFilepath"+"\"+"$zipFilename"
    $remoteFilePath = "ftp://"+$ServerIpAddress+"/tmp/spotfire/"
    $ftpuname = "root"
    $ftppassword = "shroot"
    $RemoteFile = $remoteFilePath +"$zipFilename"
    $folderNameExistOnEECoordinator = $remoteFilePath

    Function Main() {
    CheckZipFilePathFolderOnNetAnServer
    CheckAndDeleteZipFileOnNetAnServer
    PreparedZipFileForFTP
    CheckSpotfireFolderExistOnEECoordinator
    StartFtpFromNetAnServerToEECoordinator
    }
    
    
    #check the zip file path at window's machine
    Function CheckZipFilePathFolderOnNetAnServer(){
        if(-not (test-path($zipFilepath) )){
        Write-Output $date" DDC Folder does not exist . Creating the DDC folder" | Out-File $logsPath -Append;
        $fso = new-object -ComObject scripting.filesystemobject
        $fso.CreateFolder($zipFilepath) | Out-File $logsPath -Append;
        Write-Output $date" DDC folder created successfully" | Out-File $logsPath -Append;
        }
    }
        
    #Delete the zip file If exists in window server
    Function CheckAndDeleteZipFileOnNetAnServer(){
    try{
        if(test-path($zipFile)){
            Write-Output $date" $zipFile File exist.Delete it" | Out-File $logsPath -Append;
            Remove-Item $zipFile
            Write-Output $date" $zipFile Delete successfully" | Out-File $logsPath -Append;
        }
    }
    catch [exception]{
        Write-Output $date" $_.Exception.Message" | Out-File $logsPath -Append;
        }
    }
 
    #Prepare zip file
    
    Function PreparedZipFileForFTP(){
        try{
            if(-not (test-path($zipFile))) {
            set-content $zipFile ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
            (dir $zipFile).IsReadOnly = $false  
            Write-Output $date" $zipFile create successfully" | Out-File $logsPath -Append;
            }
        }
        catch [exception]{
            Write-Output $date" $_.Exception.Message" | Out-File $logsPath -Append;
        }
        try{
            $shellApplication = new-object -com shell.application
            $zipPackage = $shellApplication.NameSpace($zipFile)
            $files = Get-ChildItem -Path $srcdir 

            # Get the log files and copy into zip 
            foreach($file in $files) { 
                $zipPackage.CopyHere($file.FullName)
                
            #this 'while' loop checks each file is added before moving to the next
                while($zipPackage.Items().Item($file.name) -eq $null){
                    Start-sleep -seconds 1
                }
            }
        }
        catch [exception]{
            Write-Output $date" $_.Exception.Message" | Out-File $logsPath -Append;
        }
    }

    # Create the FtpWebRequest.
    # Create or check Spotfire folder at location /tmp on EE Co-ordinator.
    Function CheckSpotfireFolderExistOnEECoordinator(){
        try
        {
                $makeDirectory = [System.Net.WebRequest]::Create($folderNameExistOnEECoordinator);
                $makeDirectory.Credentials = New-Object System.Net.NetworkCredential($ftpuname,$ftppassword);
                $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory;
                $response = $makeDirectory.GetResponse();
                $date,$response | Out-File $logsPath -Append;
                Write-Output $date" Spotfire folder created successfully at location /tmp" | Out-File $logsPath -Append;
                 
        }catch [Net.WebException]{
            try     
            {
     
                    #if there was an error returned, check if folder already existed on server
                    $checkDirectory = [System.Net.WebRequest]::Create($folderNameExistOnEECoordinator);
                    $checkDirectory.Credentials = New-Object System.Net.NetworkCredential($ftpuname,$ftppassword);
                    $checkDirectory.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory;
                    $response = $checkDirectory.GetResponse();
                    Write-Output $date" Folder already exist at /tmp" | Out-File $logsPath -Append;
                    $date,$response | Out-File $logsPath -Append;
                     
                    #folder already exists!
            }
            catch [Net.WebException] {
            Write-Output $date "  Exception occurred during checking spotfire folder exist on EE coordinator.
                                  below are the reasons: 
                                  1) file permission issue.
                                  2) incorrect credentials.
                                  3) incorrect server name." | Out-File $logsPath -Append;
            
            }
        } 
    }

    # Ftp the logs zip file to EE co-ordinator at location /tmp/spotfire.
    Function StartFtpFromNetAnServerToEECoordinator(){
        
         try {
                    $ftp = [System.Net.FtpWebRequest]::Create("$RemoteFile")
                    $ftp = [System.Net.FtpWebRequest]$ftp
                    $ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
                    $ftp.Credentials = new-object System.Net.NetworkCredential($ftpuname,$ftppassword)
                    $ftp.UseBinary = $true
                    $ftp.UsePassive = $true
                    $ftp.KeepAlive = $false
                    # read in the file to upload as a byte array
                    $content = gc -en byte $zipFile
                    $ftp.ContentLength = $content.Length

                    # get the request stream, and write the bytes into it
                    $rs = $ftp.GetRequestStream()
                    $rs.Write($content, 0, $content.Length)
                    $rs.Close()
                    $rs.Dispose()

                    Write-Output $date" FtpFile: $zipFile size: $($content.Length) successfully" | Out-File $logsPath -Append;
                }
                catch [System.Net.WebException] {
                if ($_.Exception.InnerException) {
                    Write-Error $_.Exception.InnerException.Message | Out-File $logsPath -Append;
            } else {
                 Write-Error $_.Exception.Message | Out-File $logsPath -Append;
              }
        }
    }
    Main