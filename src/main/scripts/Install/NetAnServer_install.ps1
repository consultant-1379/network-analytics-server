# ********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
# ********************************************************************
#
#
# (c) Ericsson Inc. 2020 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Inc. The programs may be used and/or copied only with
# the written permission from Ericsson Inc. or in accordance with the
# terms and conditions stipulated in the agreement/contract under
# which the program(s) have been supplied.
#
# ********************************************************************
# Name    : NetAnServerConfig.ps1
# Date    : 20/08/2020
# Purpose : #  Installation script for Ericsson Network Analytic Server
#               1. Create logs and directories
#               2. Request input parameters from user
#               3. Check that the perquisites are installed and configured
#               4. Create the PostgreSQL server database
#               5. Install the NetAnServer server software
#               6. Configure the NetAnServer server
#               7. Start NetAnServer
#
# Usage   : NetAnServer_install
#
#

#---------------------------------------------------------------------------------

#----------------------------------------------------------------------------------
#  Following parameters must not be modified
#----------------------------------------------------------------------------------
$loc = Get-Location
$drive = (Get-ChildItem Env:SystemDrive).value
$netanserver_media_dir = (get-item $PSScriptRoot).parent.parent.FullName

$Script:stage=0
$Script:instBuild
$Script:major=$FALSE
$install_date = get-date -format "yyyyMMdd_HHmmss"
$serverIP = "127.0.0.1"

# get platform current version num
[xml]$xmlObj = Get-Content "$($netanserver_media_dir)\Resources\version\version_strings.xml"
$platformVersionDetails = $xmlObj.SelectNodes("//platform-details")

foreach ($platformVersionString in $platformVersionDetails)
{
    if ($platformVersionString.'current' -eq 'y') {
            $version = $platformVersionString.'version'
            $serviceVersion = $platformVersionString.'service-version'
            $versionType = $platformVersionString.'release-type'
        }
}

$installParams = @{}
$installParams.Add('currentPlatformVersion', $version)
$installParams.Add('netAnServerIP', $serverIP)
$installParams.Add('installDir', $drive + "\Ericsson\NetAnServer")
$installParams.Add('analystDir', $drive + "\Ericsson\Analyst")
$installParams.Add('languagepack', $drive + "\Ericsson")
$installParams.Add('migrationDir', $drive + "\Ericsson\Migration")
$installParams.Add('installResourcesDir', $installParams.installDir+"\Resources")
$installParams.Add('automationServicesDir', $installParams.installDir+"\AutomationServices\"+$version)
$installParams.Add('installServerDir', $installParams.installDir + "\Server\"+$version)
$installParams.Add('mediaDir', $netanserver_media_dir +"\Software")
$installParams.Add('resourcesDir', $netanserver_media_dir +"\Resources")
$installParams.Add('featureInstallerDir', $installParams.resourcesDir +"\FeatureInstaller\*")
$installParams.Add('featureInstallationDir', $installParams.installDir +"\feature_installation")
$installParams.Add('logDir', $installParams.installDir + "\Logs")
$installParams.Add('tomcatDir', $installParams.installServerDir + "\tomcat\bin\")
$installParams.Add('customFilterDestination', $installParams.installServerDir + "\tomcat\webapps\spotfire\WEB-INF\lib")
$installParams.Add('jConnDir', $installParams.installServerDir + "\tomcat\lib\")
$installParams.Add('PSModuleDir', $installParams.installDir + "\Modules")
$installParams.Add('setLogName', 'NetAnServer.log')
$installParams.Add('createDBLog', $installParams.logDir + "\" + $install_date + "_postgres_db.log")
$installParams.Add('createActionLogDBLog', $installParams.logDir + "\" + $install_date + "actionlog_postgres_db.log")
$installParams.Add('updatedbDBLog', $installParams.logDir + "\" + $install_date + "_postgres_db_update.log")
$installParams.Add('serverLog', $installParams.logDir + "\" + $install_date + "_Server_Component.log")
$installParams.Add('deploymentLog', $installParams.logDir + "\" + $install_date + "_NetAnServer_deployment.log")
$installParams.Add('databaseLog', $installParams.resourcesDir + "\sql\log.txt")
$installParams.Add('spotfirebin', $installParams.installServerDir + "\tomcat\spotfire-bin\") ## added for spotfire-bin dir in tomcat
$installParams.Add('configTool', $installParams.spotfirebin + "config.bat")     ## Cahanged config path
$installParams.Add('createDBScript', $installParams.resourcesDir + "\sql\create_databases.bat")   # Changed path for PostgreSQL
$installParams.Add('createActionLogDBScript', $installParams.resourcesDir + "\sql\actionlog\create_actionlog_db.bat") 
$installParams.Add('updateDBScript', $installParams.resourcesDir +"\hotfix\update_database.bat")
$installParams.Add('updateDBScriptTarget', $installParams.mediaDir + "\HotFix\Server\HF-015\database\mssql\update_database.bat")
$installParams.Add('moduleDir', $netanserver_media_dir + "\Scripts\Modules")
$installParams.Add('instrumentationDir', $netanserver_media_dir + "\Scripts\Instrumentation\*")
$installParams.Add('ssoDir', $netanserver_media_dir + "\Scripts\sso\*")
$installParams.Add('userMaintenanceDir', $netanserver_media_dir + "\Scripts\User_Maintenance\*")
$installParams.Add('backupRestoreScriptsDir', $installParams.installDir + "\Scripts\backup_restore")
$installParams.Add('nfsShareLogDir', $drive + "\Ericsson\Instrumentation\DDC")
$installParams.Add('instrumentationScriptsDir', $installParams.installDir + "\Scripts\Instrumentation")
$installParams.Add('ssoScriptsDir', $installParams.installDir + "\Scripts\sso")
$installParams.Add('userMaintenanceScriptsDir', $installParams.installDir + "\Scripts\User_Maintenance")
$installParams.Add('dataCollectorScriptPath', $installParams.instrumentationScriptsDir  + "\DataCollector\Create_Data_Collector.ps1")
$installParams.Add('parserScriptPath', $installParams.instrumentationScriptsDir  + "\Parser\Parser.ps1")
$installParams.Add('userAuditScriptPath', $installParams.instrumentationScriptsDir  + "\UserAudit\UserAudit.ps1")
$installParams.Add('customFolderCreationScriptPath', $installParams.userMaintenanceScriptsDir  + "\CustomFolderCreation\CustomFolderCreation.ps1")
$installParams.Add('serverSoftware', $installParams.mediaDir + "\Server\setup-win64.exe")
$installParams.Add('jConnSrcDir', $installParams.resourcesDir + "\jconn")
$installParams.Add('jConnSrc', $installParams.jConnSrcDir + "\jconn-4.jar")
$installParams.Add('netAnServerDataSource', $installParams.resourcesDir + "\config\datasource_template.xml")
$installParams.Add('netanserverDeploy', $installParams.mediaDir + "\deployment\Spotfire.Dxp.sdn")
$installParams.Add('nodeManagerDeploy', $installParams.mediaDir + "\deployment\Spotfire.Dxp.NodeManagerWindows.sdn")
$installParams.Add('pythonDeploy', $installParams.mediaDir + "\deployment\Spotfire.Dxp.PythonServiceWindows.sdn")  # Python Deploymnet
$installParams.Add('TERRDeploy', $installParams.mediaDir + "\deployment\Spotfire.Dxp.TerrServiceWindows.sdn")  # TERR Deploymnet
$installParams.Add('serverHF', $installParams.mediaDir + "\HotFix\Server\HF-015\Spotfire.Dxp.NodeManagerWindows.sdn")
$installParams.Add('applicationHF', $installParams.mediaDir + "\HotFix\Application\HF-016\Distribution\Spotfire.Dxp.sdn")
$installParams.Add('netanserverBranding', $installParams.resourcesDir + "\cobranding\NetAnServerBranding.spk")
$installParams.Add('colorPalette', $installParams.resourcesDir + "\colorPalette\Medium.Color.Palette.dxpcolor")
$installParams.Add('filterSrc', $installParams.resourcesDir + "\custom_filter\CustomAuthentication.jar")
$installParams.Add('jobSenderConfig', $installParams.resourcesDir + "\automationServices\Spotfire.Dxp.Automation.ClientJobSender.exe.config")
$installParams.Add('jobSenderTool', $installParams.resourcesDir + "\automationServices\Spotfire.Dxp.Automation.ClientJobSender.exe")
$installParams.Add('netanserverGroups', $installParams.resourcesDir + "\groups\groups.txt")
$installParams.Add('netanserverSSOGroups', $installParams.resourcesDir + "\groups\ssogroups.txt")
$installParams.Add('sqlAdminUser', 'postgres')  # changed adminuser to postgres
$installParams.Add('dbName', "netanserver_db")
$installParams.Add('actionLogdbName', "netanserveractionlog_db")
$installParams.Add('repDbDumpFile', $installParams.resourcesDir + "\sql\create_netanserver_repdb.sql")
$installParams.Add('platformVersionDir', $installParams.resourcesDir + "\version\")
$installParams.Add('repDbName', "netanserver_repdb")
$installParams.Add('dbUser', "netanserver")
$installParams.Add('connectIdentifer', "localhost")
$installParams.Add('serviceNetAnServer', "Tss" + $serviceVersion)
$installParams.Add('dbDriverClass', "org.postgresql.Driver ")  # changed the driver class
$installParams.Add('dbURL', "jdbc:postgresql://localhost:5432/"+$installParams.dbName)
$installParams.Add('actiondbURL', "jdbc:postgresql://localhost:5432/"+$installParams.actionLogdbName)
$installParams.Add('configName', "Network Analytics Server Default Configuration "+$version)
$installParams.Add('osVersion2012', 'Microsoft Windows Server 2012 R2 Standard')
$installParams.Add('osVersion2016', 'Microsoft Windows Server 2016 Standard')
$installParams.Add('osVersion2019', 'Microsoft Windows Server 2019 Standard')
$installParams.Add('serverPort', 443)
$installParams.Add('serverRegistrationPort', 9080)
$installParams.Add('serverCommunicationPort', 9443)
$installParams.Add('libraryLocation', $installParams.resourcesDir +  "\library\LibraryStructure.part0.zip")
$installParams.Add('installNodeManagerDir', $installParams.installDir + "\NodeManager\"+$version)
$installParams.Add('nodeManagerSoftware', $installParams.mediaDir + "\NodeManager\nm-setup.exe")
$installParams.Add('nodeRegistrationPort', 9081)
$installParams.Add('nodeCommunicationPort', 9444)
$installParams.Add('nodeManagerLog', $installParams.logDir + "\" + $install_date + "_Node_Manager.txt")
$installParams.Add('nodeServiceName',"WpNmRemote" + $serviceVersion)    # Changes Node Manager service name
$installParams.Add('nodeManagerConfigDir',$installParams.installNodeManagerDir + "\nm\config\")
$installParams.Add('nodeManagerConfigFile',$installParams.resourcesDir + "\NodeManager\default.conf")
$installParams.Add('nodeManagerConfigDirFile',$installParams.nodeManagerConfigDir + "\default.*")
$installParams.Add('backupRestoreDir', $netanserver_media_dir + "\Scripts\backup_restore\")
$installParams.Add('serverCertInstall', $installParams.installServerDir + "\tomcat\certs\")
$installParams.Add('serverConfInstall', $installParams.installServerDir + "\tomcat\conf")
$installParams.Add('serverConfInstallXml', $installParams.serverConfInstall + "\server.xml")
$installParams.Add('serverConfig', $installParams.resourcesDir + "\serverConfig\server.xml")
$installParams.Add('webConfigLog4net', $installParams.resourcesDir + "\webConfig\log4net.config")
$installParams.Add('webConfigWeb', $installParams.resourcesDir + "\webConfig\Spotfire.Dxp.Worker.Web.config")
$installParams.Add('webConfigHost', $installParams.resourcesDir + "\webConfig\Spotfire.Dxp.Worker.Host.exe.config")
$installParams.Add('nodeManagerServices', $installParams.installNodeManagerDir + "\nm\services\")
$installParams.Add('webWorkerDir', $installParams.nodeManagerServices)
$installParams.Add('ericssonDir', $drive + "\temp\media\netanserver\")
$installParams.Add('scheduledUpdateUser', 'scheduledupdates@SPOTFIRESYSTEM')
$installParams.Add('automationServicesUser', 'automationservices@SPOTFIRESYSTEM')
$installParams.Add('analystLog', $installParams.logDir + "\" + $install_date + "_Analyst_Install.txt")
$installParams.Add('confignode', $installParams.logDir + "\" + "confignode.txt")
$installParams.Add('analystSoftware', $installParams.mediaDir + "\Analyst\setup.exe")
$installParams.Add('languagepackmedia', $installParams.mediaDir + "\languagepack")
$installParams.Add('tomcatServerLogDir', $installParams.installServerDir + "\tomcat\logs")
$installParams.Add('netanserverServerLogDir', $drive + "\Ericsson\NetAnServer\Logs")
$installParams.Add('nodeManagerLogDir', $installParams.installNodeManagerDir + "\nm\logs")
$installParams.Add('instrumentationLogDir', $drive + "\Ericsson\Instrumentation")
$installParams.Add('javaPath', $installParams.installServerDir + "\jdk\bin")
$installParams.Add('keytabfile', $installParams.installServerDir + "\jdk\jre\lib\security\spotfire.keytab")
$installParams.Add('serverHFJar', $installParams.mediaDir + "\HotFix\Server\HF-015\hotfix.jar")
$installParams.Add('groupLibName', "Library Administrator")
$installParams.Add('groupSAName', "Script Author")
$installParams.Add('groupAutoServiceName', "Automation Services Users")
$installParams.Add('PSQL_PATH', "C:\Program Files\PostgreSQL\14\bin")
$installParams.Add('restoreDataPath', $installParams.installDir + "\RestoreDataResources")
$installParams.Add('housekeepingDir', $installParams.installDir + "\Housekeeping")
$installParams.Add('housekeepingScript', $netanserver_media_dir + "\Resources\Housekeeping\Housekeeping.ps1")
$installParams.Add('folderResourceDir', "$PSScriptRoot\resources\")
$installParams.Add('groupTemplate', $installParams.resourcesDir +"\adhoc_resources\adhocgroups.txt")
$installParams.Add('featureVersion', $installParams.installDir +"\Features\Ad-HocEnabler")
$installParams.Add('customLib', $installParams.resourcesDir +"\adhoc_resources\custom.part0.zip")
$installParams.Add('adhocLogDir', $installParams.installDir + "\Logs\AdhocEnabler")
$installParams.Add('adhoc_xml', $installParams.resourcesDir +"\adhoc_resources\meta-data.xml")
$installParams.Add('adhoc_user_lib',$installParams.installDir + "\Features\Ad-HocEnabler\resources\folder")

$TestHostAndDomainStatus=$false

foreach ($platformVersionString in $platformVersionDetails)
{
    if ($platformVersionString.'current' -eq 'n')
    {
        $previousVersion = $platformVersionString.'version'
        if (Test-Path ("C:\Ericsson\NetAnServer\Server\" + $previousVersion))
        {
            $oldVersion = $previousVersion
            $oldServiceVersion = $platformVersionString.'service-version'
            $oldAnalystinstallerExt = $platformVersionString.'analystinstaller-ext'
            $oldStatisticalServicesExt = $platformVersionString.'statistical-services-ext'
            $installParams.Add('previousPlatformVersion', $oldVersion)
        }
    }
}
# if there is an old version to replace or back up directories, set variables
if ($oldVersion){
    $installParams.Add("backupDir", $drive + "\Ericsson\Backup\")
    $installParams.Add('OldNetAnServerDir',$drive + "\Ericsson\NetAnServer\Server\" + $oldVersion)
    $installParams.Add('serviceNetAnServerOld', "Tss" + $oldServiceVersion)
    $installParams.Add('nodeServiceNameOld',"WpNmRemote" + $oldServiceVersion)
    $installParams.Add('statsServiceNameOld',"TSSS" + $oldStatisticalServicesExt +"StatisticalServices" + $oldStatisticalServicesExt)
    $installParams.Add('automationServicesDirectoryOld',$installParams.installDir + '\AutomationServices\' + $oldVersion)
    $installParams.Add('statsServicesDirectoryOld',$installParams.installDir + '\StatisticalServices' + $oldStatisticalServicesExt)
    $installParams.Add('analystinstallerExeOld',$installParams.analystDir + '\setup' + $oldAnalystinstallerExt +'.exe')

    #params used for backup 7.9/7.11 to 10.10
    $installParams.Add('hotfixesDirectory',$installParams.installDir +'\Server\hotfixes')
    $installParams.Add('serverCertInstallOldXml', $installParams.OldNetAnServerDir + "\tomcat\conf\server.xml")
    $installParams.Add("backupDirRepdb", $installParams.backupDir + "repdb_backup\")
    $installParams.Add("backupDirPmdb", $installParams.backupDir + "pmdb_backup\")
    $installParams.Add("backupDirLibData", $installParams.backupDir + "library_data_backup\")
    $installParams.Add("backupDirLibAnalysisData", $installParams.backupDirLibData + "libraries\")
    $installParams.Add("tempConfigLogFile", $installParams.logDir + "\command_output_temp.temp.log")
}



#----------------------------------------------------------------------------------
#  Set PSModulePath and Copy modules
#----------------------------------------------------------------------------------

if(-not $env:PSModulePath.Contains($installParams.PSModuleDir)){
    $PSPath = $env:PSModulePath + ";"+$installParams.PSModuleDir
    [Environment]::SetEnvironmentVariable("PSModulePath", $PSPath, "Machine")
    $env:PSModulePath = $PSPath
}

try {
    if( -not (Test-Path($installParams.installDir))){
        New-Item $installParams.installDir -type directory | Out-Null
    }

    if( -not (Test-Path($installParams.featureInstallationDir))){
            New-Item $installParams.featureInstallationDir -type directory | Out-Null
    }

    if( -not (Test-Path($installParams.instrumentationScriptsDir))){
        New-Item $installParams.instrumentationScriptsDir -type directory | Out-Null
    }

    if( -not (Test-Path($installParams.userMaintenanceScriptsDir))){
            New-Item $installParams.userMaintenanceScriptsDir -type directory | Out-Null
    }

    if( -not (Test-Path($installParams.backupRestoreScriptsDir))){
        New-Item $installParams.backupRestoreScriptsDir -type directory | Out-Null
    }

    if( -not (Test-Path($installParams.installResourcesDir))){
        New-Item $installParams.installResourcesDir -type directory | Out-Null
    }

    if( -not (Test-Path($installParams.analystDir))){
        New-Item $installParams.analystDir -type directory | Out-Null
    }
    if( -not (Test-Path($installParams.languagepack))){
        New-Item $installParams.languagepack -type directory | Out-Null
    }
    if( -not (Test-Path($installParams.automationServicesDir))){
        New-Item $installParams.automationServicesDir -type directory | Out-Null
    }
	if( -not (Test-Path($installParams.ssoScriptsDir))){
        New-Item $installParams.ssoScriptsDir -type directory | Out-Null
    }

    if ( -not (Test-Path $installParams.adhocLogDir)) {
        New-Item $installParams.adhocLogDir -Type Directory | Out-Null
    }
    if ( -not (Test-Path $installParams.featureVersion)) {
        New-Item $installParams.featureVersion -Type Directory -ErrorAction SilentlyContinue| Out-Null
    }

    Copy-Item -Path $installParams.moduleDir -Destination $installParams.installDir -Recurse -Force
    Copy-Item -Path $installParams.featureInstallerDir -Destination $installParams.featureInstallationDir -Recurse -Force
    Copy-Item -Path $installParams.instrumentationDir -Destination $installParams.instrumentationScriptsDir -Recurse -Force
    Copy-Item -Path $installParams.userMaintenanceDir -Destination $installParams.userMaintenanceScriptsDir -Recurse -Force
    Copy-Item -Path $installParams.backupRestoreDir -Destination $installParams.backupRestoreScriptsDir -Recurse -Force
    Copy-Item -Path $installParams.colorPalette -Destination $installParams.installResourcesDir -Recurse -Force
    Copy-Item -Path $installParams.netanserverSSOGroups -Destination $installParams.installResourcesDir -Recurse -Force
    Copy-Item -Path $installParams.filterSrc -Destination $installParams.installResourcesDir -Recurse -Force
    Copy-Item -Path $installParams.jobSenderConfig -Destination $installParams.automationServicesDir -Recurse -Force
    Copy-Item -Path $installParams.jobSenderTool -Destination $installParams.automationServicesDir -Recurse -Force
	Copy-Item -Path $installParams.ssoDir -Destination $installParams.ssoScriptsDir -Recurse -Force



} catch {
    $fileErrorMessage = "ERROR creating and transferring directories:" +
        "`n$($installParams.moduleDir) -> $($installParams.installDir)" +
        "`n$($installParams.featureInstallerDir) -> $($installParams.featureInstallationDir)" +
        "`n$($installParams.instrumentationDir) -> $($installParams.instrumentationScriptsDir)" +
        "`n$($installParams.userMaintenanceDir) -> $($installParams.userMaintenanceScriptsDir)" +
        "`n$($installParams.backupRestoreDir) -> $($installParams.backupRestoreScriptsDir)"
    Write-Host $fileErrorMessage -ForegroundColor Red
}

Import-Module Logger
Import-Module NetAnServerUtility
Import-Module NetAnServerConfig
Import-Module -DisableNameChecking NetAnServerDBBuilder
Import-Module NetAnServerServerInstaller
Import-Module NfsShareConfig
Import-Module InstallLibrary
Import-Module ManageUsersUtility -DisableNameChecking
Import-Module PlatformVersionController -DisableNameChecking
Import-Module NetAnServerNodeManagerInstaller -DisableNameChecking
Import-Module ConfigurationUpdater -DisableNameChecking
Import-Module AnalystInstaller
Import-Module ServerConfig


$global:logger = Get-Logger($LoggerNames.Install)
$initalinstall="Initial Install"
$Upgrade="Upgrade"

Function Main() {

    InitiateLogs $initalinstall
    SetAutomationFilePermission
    InputParameters
    CheckPrerequisites
    CreateDB
    InstallServerSoftware
    AddCertificate $installParams.ericssonDir
    ConfigureServer
    ConfigureHTTPS
    InstallNodeManagerSoftware
    StartNodeManager
    ConfigureNodeManager
    InstallLibrary
    UpdatePlatformVersion
    InstallAnalyst
    ConfigNfsShare
    UpdateConfigurations
    SetLogPermission
    SetupAdhoc
    FinalCleanup
    $logger.logInfo("You have successfully completed the automated installation of Network Analytics Server.", $True)

}

Function MainUpgrade() {

    InitiateLogs $upgrade
    SetAutomationFilePermission

    if ($versionType -eq "version-change") { # check for versions previous to 10.10.2 (7.11 etc.)
        if($oldVersion -eq '7.11'){
            PreviousPlatformUpgradeToNew_711
        }
        else{
            PreviousPlatformUpgradeToNew
        }
    }else{
        CheckVersion
        if($Script:major -eq $TRUE){
            ServicePackUpgrade # e.g. 10.10.2 - 10.10.3....
        }else{
            MinorCodeChangesUpgrade # 10.10.2 - code changes etc.
        }
    }
    
    $logger.logInfo("You have successfully completed the automated Upgrade of Network Analytics Server.", $True)

}

Function PreviousPlatformUpgradeToNew_711(){
    $Script:major=$TRUE
    InputParametersUpgrade
    StopNetAnServer $($installParams.nodeServiceNameOld)
    StopNetAnServer $($installParams.serviceNetAnServerOld)
    StopNetAnServer $($installParams.statsServiceNameOld)
    CheckPrerequisites
    CreateDB
    InstallServerSoftware
    AddCertificate $installParams.ericssonDir
    ConfigureServer
    ConfigureHTTPS
    InstallNodeManagerSoftware
    StartNodeManager
    RemoveConfigNodeLogFile
    ConfigureNodeManager
    InstallLibrary
    UpdatePlatformVersion
    InstallAnalyst
    ConfigNfsShare
    UpdateConfigurations
    SetLogPermission
    RestoreBackupDatabaseTables
    RestoreBackupLibraryData
    SetupAdhoc
    FinalCleanup

}

Function PreviousPlatformUpgradeToNew(){
    InputParametersUpgrade
    CheckPrerequisites
    StopNetAnServer $($installParams.nodeServiceNameOld)
    StopNetAnServer $($installParams.serviceNetAnServerOld) 
    InstallServerSoftware
    UpgradeServer
    AddCertificate $installParams.ericssonDir
    ConfigureServerUpgrade
    ConfigureHTTPS
    InstallNodeManagerSoftware
    StartNodeManager
    RemoveConfigNodeLogFile
    ConfigureNodeManager
    UpdateConfigurations
    UpdateNodemanager # this will delete out the old node from previous version
    InstallAnalyst
    UpdatePlatformVersion
    SetLogPermission
    SetupAdhoc
    UpdateUserPassword
    FinalCleanup
     
}

Function ServicePackUpgrade(){
    InputParametersServiceOrMinorUpgrade
    StopNetAnServer $($installParams.nodeServiceNameOld)
    StopNetAnServer $($installParams.serviceNetAnServerOld)
    InstallServerSoftware
    UpgradeServer
    AddCertificate $installParams.ericssonDir
    ConfigureServerUpgrade
    ConfigureHTTPS
    InstallNodeManagerSoftware
    StartNodeManager
    RemoveConfigNodeLogFile
    ConfigureNodeManager
    UpdateConfigurations
    UpdateNodemanager # this will delete out the old node from previous version
    InstallAnalyst
    UpdatePlatformVersion
    SetLogPermission
    SetupAdhoc
    FinalCleanup

}

Function MinorCodeChangesUpgrade(){
    InputParametersServiceOrMinorUpgrade
    MinorUpgrade
    UpdateConfigurations
    UpdatePlatformVersion
    SetupAdhoc
    FinalCleanup
}

#----------------------------------------------------------------------------------
#  Create Log file directory structure
#----------------------------------------------------------------------------------
Function InitiateLogs($message) {

    $creationMessage = $null
	$installParams.Add('installReason', $message)

    if ( -not (Test-FileExists($installParams.logDir))) {
        New-Item $installParams.logDir -ItemType directory | Out-Null
        $creationMessage = "Creating new log directory $($installParams.logDir)"
    }

    $logger.setLogDirectory($installParams.logDir)
    $logger.setLogName($installParams.setLogName)

    $logger.logInfo("Starting the $message of Ericsson Network Analytics Server.", $True)

    if ($creationMessage) {
        $logger.logInfo($creationMessage, $true)
    }

    $logger.logInfo("$message log created $($installParams.logDir)\$($logger.timestamp)_$($installParams.setLogName)", $True)
    Set-Location $loc
}


#----------------------------------------------------------------------------------
#  Change Automation services configuration file permission
#----------------------------------------------------------------------------------
Function SetAutomationFilePermission() {

    $file = $installParams.automationServicesDir + "\*.config"
   Get-ChildItem -Path $file  | Where-Object {$_.IsReadOnly} |
   ForEach-Object{
      try {
          $_.IsReadOnly = $false
          }
      catch {
            $errorMessage = $_.Exception.Message
            $logger.logError($MyInvocation, "Could not Set Permission for $installParams.automationServicesDir . `n $errorMessage", $True)
            }
    }
}


#----------------------------------------------------------------------------------
#  Check Version
#----------------------------------------------------------------------------------
Function CheckVersion() {
	$platformReleaseXml = Get-Item "$($installParams.platformVersionDir)\platform-release.*xml"
	if(-not $platformReleaseXml) {
		$logger.logError($MyInvocation, "The platform-release.xml was not detected in media. Media is not complete", $True)
		MyExit($MyInvocation.MyCommand)
	}

#are there more than one platform-release files
	if($platformReleaseXml.Count -gt 1) {
		$logger.logError($MyInvocation, "There are duplicate plaform-release.xml files detected. Media is not correct", $True)
		MyExit($MyInvocation.MyCommand)
	}

#does it contain a build/rstate
	$newBuildNumber = ($platformReleaseXml.Name).Split('.')[-2]

	if(-not ($newBuildNumber -Match "^R")) {
		$logger.logError($MyInvocation, "The platform-release.xml file is not named correctly. It does not contain a valid Build number", $True)
		MyExit($MyInvocation.MyCommand)
	}
	$logger.logInfo("Testing for installed platform versions...", $True)
	$envVar = (New-Object System.Management.Automation.PSCredential 'N/A', $(Get-EnvVariable "NetAnVar")).GetNetworkCredential().Password
	$platformDetails = Get-PlatformVersionsFromDB $envVar
	if(-not $platformDetails[0]) {
		$logger.logError($MyInvocation, $platformDetails[1])
		$logger.logError($MyInvocation, "An error has occured in upgrade. Please refer to the upgrade log. Exiting upgrade", $True)
		MyExit($MyInvocation.MyCommand)
	}

	$installedPlatformRecord = Get-PlatformVersions | Where-Object -FilterScript { $_.'PRODUCT-ID'.trim() -eq 'CNA4032940' }

	if(($installedPlatformRecord | Measure-Object).Count -gt 1) {
		$logger.logWarning("Aborting upgrade. netAnserver_repdb is inconsistent. There are multiple versions of the platform installed", $True)
		Exit
	}

	$installedBuild = ($installedPlatformRecord).BUILD
	$Script:instBuild=$installedBuild

	if(-not $installedBuild) {
		$logger.logWarning("No previous installation detected. Please verify installation of Network Analytics Server before commencing upgrade", $True)
		Exit
	}
	$installedBuild = $installedBuild.trim()
	$logger.logInfo("Existing platform found...", $True)
	$logger.logInfo("Build: $($installedBuild)", $True)
	$logger.logInfo("Testing upgrade media build: $($newBuildNumber) against installed build: $($installedBuild)", $True)
	$shouldUpgrade = Test-BuildIsGreaterThan $newBuildNumber $installedBuild

	if(-not $shouldUpgrade) {
		$logger.logWarning("The platform will not be upgraded. Build: $($installedBuild) is already installed", $True)
		Exit
	}
    [int]$newBuildNumberRelease = $newBuildNumber -replace "^R(\d+).+", '$1'
    [int]$installedBuildRelease = $installedBuild -replace "^R(\d+).+", '$1'
	if($newBuildNumberRelease -gt $installedBuildRelease) {
	    $checkAnalystInstance = $False
        $logger.logInfo("Checking if any Instance of Analyst Client is open...", $True)
        $checkAnalystProcess = Get-Process -Name Spotfire.Dxp -ErrorAction SilentlyContinue
		if($checkAnalystProcess) {
			$checkAnalystInstance = $True
		}
		if($checkAnalystInstance) {
			$logger.logWarning("Instance of Analyst Client is open", $True)
			$logger.logInfo("Please close the Analyst and Re-run the Upgrade. Exiting the script now...", $True)
			Exit
		}
		else {
			$logger.logInfo("No open Instance of Analyst found. Proceeding with Upgrade...", $True)
		}
        $Script:major=$TRUE

    }
}


#----------------------------------------------------------------------------------
#  Minor Upgrade
#----------------------------------------------------------------------------------
Function MinorUpgrade() {

	$netanserver_upgrade_backup_dir = "C:\Ericsson\NetAnServer\Backup"

################################################
#                                              #
#               Perform Backups                #
#                                              #
################################################
	try {
		$moduleBackups = "$netanserver_upgrade_backup_dir\modules-$($Script:instBuild.trim())"
		$backupRestoreScript = "$netanserver_upgrade_backup_dir\backup_restore-$($Script:instBuild.trim())"
		$logger.logInfo("Backing up Network Analytics Server Modules and Backup Restore script", $True)
		Copy-Item -Path $installParams.PSModuleDir -Destination $moduleBackups/ -Recurse -Force  -ea Stop
		if(Test-Path $installParams.backupRestoreScriptsDir) {
            Copy-Item -Path $installParams.backupRestoreScriptsDir -Destination $backupRestoreScript/ -Recurse -Force  -ea Stop
            if(Add-NetAnServerConfigMinorUpgrade($installParams)) {
                $logger.logInfo("Network Analytics Server upgrade successfully configured.", $True)
            }
            else {
                $logger.logError($MyInvocation, "Configuration of the Network Analytics Server failed.", $True)
                MyExit($MyInvocation.MyCommand)
            }
		}
		$logger.logInfo("Backup complete", $True)
	} catch {
		$logger.logWarning("Backup of modules and backup restore script failed, exiting upgrade", $True)
		$logger.logError($MyInvocation, $_.Exception.Message, $True)
		MyExit($MyInvocation.MyCommand)
	}
################################################
#                                              #
#                Start Upgrade                 #
#                                              #
################################################
	try {

    $logger.logInfo("Starting Minor upgrade of Network Analytics Server", $True)
    $logger.logInfo("Transferring NetAnServer modules and backup restore script", $True)

    Robocopy $installParams.moduleDir $installParams.PSModuleDir /E | Out-Null
    Robocopy $installParams.backupRestoreDir $installParams.backupRestoreScriptsDir /E | Out-Null
    $logger.logInfo("Transfer Complete", $True)

    ##########################################################################################
    # NOTE: If Modules have external dependencies e.g. resources dir, ensure transferred now #
    ##########################################################################################

    } catch {
        $logger.logWarning("A problem was detected during upgrade", $True)
        $logger.logError($MyInvocation, $_.Exception.Message)
        $logger.logWarning("Restoring modules and backup restore script from backup", $True)
        Remove-Item $installParams.PSModuleDir -Force -Recurse -Confirm:$False
        Robocopy $moduleBackups $installParams.PSModuleDir /E | Out-Null
        if(Test-Path $installParams.backupRestoreScriptsDir) {
            Remove-Item $installParams.backupRestoreScriptsDir -Force -Recurse -Confirm:$False
            Robocopy $backupRestoreScript $installParams.backupRestoreScriptsDir /E | Out-Null
        }
        $logger.logWarning("Module and Backup restore script restoration completed", $True)
        $logger.logError($MyInvocation, "The upgrade of the Network Anaytics Server was unsuccessful", $True)
	} finally {
		$logger.logInfo("Removing backups of platform modules and backup restore script", $True)

			if(Test-Path $moduleBackups) {
				Remove-Item $moduleBackups -Force -Recurse -Confirm:$False
			}
			if(Test-Path $backupRestoreScript) {
				Remove-Item $backupRestoreScript -Force -Recurse -Confirm:$False
			}
			if(Test-Path $netanserver_upgrade_backup_dir) {
				Remove-Item $netanserver_upgrade_backup_dir -Force -Recurse -Confirm:$False
			}

		$logger.logInfo("Removal complete", $True)
		}


}

#----------------------------------------------------------------------------------
#    Remove config node file for node manager config for 79 or 711 to 1010 upgrade
#----------------------------------------------------------------------------------


Function RemoveConfigNodeLogFile(){
    stageEnter($MyInvocation.MyCommand)
    try {
        $configNodeFile = $installParams.netanserverServerLogDir + "\confignode.txt"
        if((Test-Path($configNodeFile))){
            Remove-Item   $configNodeFile -Recurse -Force -ErrorAction SilentlyContinue
            $logger.logInfo("Previous node config file cleanup completed.", $True)
        }
        else{
            $logger.logInfo("No cleanup required.", $True)
        }
    }
    catch {

        $errorMessageConfigFileRemove = $_.Exception.Message
        $logger.logError($MyInvocation, "`n $errorMessageConfigFileRemove", $True)
        Exit
    }

    stageExit($MyInvocation.MyCommand)

}

#----------------------------------------------------------------------------------
#    Restore libraries for 7.9/7.11 to 1010 upgrade
#----------------------------------------------------------------------------------

Function RestoreBackupLibraryData(){
    stageEnter($MyInvocation.MyCommand)
    If(test-path $installParams.backupDirLibData){
        try {
            $libraryFileName = $installParams.backupDirLibAnalysisData + "library_content_all.part0.zip"
            # need to be ran in correct order
            $commandMap = [ordered]@{
                "import users" = "import-users $($installParams.backupDirLibData)users.txt -i true -t $($installParams.configToolPassword)";
                "import groups" = "import-groups $($installParams.backupDirLibData)groups.txt -t $($installParams.configToolPassword) -m true -u true";
                "import library" = "import-library-content --file-path=$($libraryFileName) --conflict-resolution-mode=KEEP_OLD --user=$($installParams.administrator) -t $($installParams.configToolPassword)";
                "import rules" = "import-rules -p $($installParams.backupDirLibData)rules.json -t $($installParams.configToolPassword)";
                "trust scripts" = "find-analysis-scripts -t  $($installParams.configToolPassword) -d true --library-parent-path=`"/Ericsson Library/`" -n"
            }

            foreach ($stage in $commandMap.GetEnumerator()) {
                if ($stage) {

                    $params = @{}
                    $params.spotfirebin = $installParams.spotfirebin
                    $logger.logInfo("Executing Stage $($stage.key)", $true)
                    $command = $stage.value
                    
                    $successful = Use-ConfigTool $command $params $installParams.tempConfigLogFile

                    if ($successful) {
                        $logger.logInfo("Stage $($stage.key) executed successfully", $true)
                        continue
                    } else {
                        $logger.logError($MyInvocation, "Error while executing Stage $($stage.key)", $True)
                        return $False
                    }
                }
            }

        }
        catch {

            $errorMessageLibraryImport = $_.Exception.Message
            $logger.logError($MyInvocation, "`n $errorMessageLibraryImport", $True)
            Exit
        }
}

    stageExit($MyInvocation.MyCommand)


}

#----------------------------------------------------------------------------------
#    Restore databases for 7.9/7.11 to 1010 upgrade
#----------------------------------------------------------------------------------

Function RestoreBackupDatabaseTables(){
    stageEnter($MyInvocation.MyCommand)
    try {
        $paramList = @{}
        $paramList.Add('database', 'netanserver_db')
        $paramList.Add('serverInstance', 'localhost')
        $paramList.Add('username', 'netanserver')
        $envVariable = "NetAnVar"
        $password = (New-Object System.Management.Automation.PSCredential 'N/A', $(Get-EnvVariable $envVariable)).GetNetworkCredential().Password

        # check if repdb files are available and need to be restored

        if (test-path $installParams.backupDirRepdb){

            $logger.logInfo("Restoring netanserver_repdb backup data...", $True)

            #import repdb tables (only the network analytics feature table required for 7.11 to 10.10 upgrade)
            $paramList.Add('repDatabase', 'netanserver_repdb')
            $importREPDBTablesQuery = "COPY netanserver_repdb.public.network_analytics_feature FROM '$($installParams.backupDirRepdb)network_analytics_feature.csv' DELIMITER ',' CSV HEADER;"
            $result = Invoke-UtilitiesSQL -Database "netanserver_repdb" -Username $paramList.username -Password $password -ServerInstance $paramList.serverInstance -Query $importREPDBTablesQuery -Action insert

            $logger.logInfo("netanserver_repdb data restored.", $True)

        }
        else {
            $logger.logInfo("netAnServer_repdb backup files not found. Nothing to restore.", $True)
        }

	}

    catch {

        $errorMessageDBImport = $_.Exception.Message
        $logger.logError($MyInvocation, "`n $errorMessageDBImport", $True)
        Exit
    }

    stageExit($MyInvocation.MyCommand)
}


#----------------------------------------------------------------------------------
#  This Function prompts the user for the necessary input parameters required to
#  install Network Analytics Server:
#----------------------------------------------------------------------------------
Function InputParameters() {
    $confirmation = 'n'
    customWrite-host "You have initiated the installation of Network Analytics Server, NetAnServer."
    customWrite-host "Please refer to the Network Analytics Server Installation Instructions for an explanation of each parameter required.`n`n"

    while ($confirmation -ne 'y') {

		while($TestHostAndDomainStatus -ne $true) {
			$hostAndDomain = customRead-host("Network Analytics Server Host-And-Domain:`n")
			$TestHostAndDomainStatus = Test-hostAndDomainURL $hostAndDomain
		}$TestHostAndDomainStatus = $false
		$hostAndDomainURL= "https://"+($hostAndDomain)

        while ($PassMatchedmssql -ne 'y') {
            $sqlAdminPassword = hide-password("PostgreSQL Administrator Password:`n")
            $resqlAdminPassword = hide-password("Confirm PostgreSQL Administrator Password:`n")
            $PassMatchedmssql = confirm-password $sqlAdminPassword $resqlAdminPassword
        }$PassMatchedmssql = 'n'

        while ($PassMatchedplat -ne 'y') {
            $platformPassword = Fetch-Password("Network Analytics Server Platform Password:`n")
            $replatformPassword = hide-Password("Confirm Network Analytics Server Platform Password:`n")
            $PassMatchedplat = confirm-password $platformPassword $replatformPassword
        }$PassMatchedplat = 'n'

        $adminUser = customRead-host("Network Analytics Server Administrator User Name:`n")

        while ($PassMatchedserver -ne 'y') {
            $adminPassword = Fetch-Password("Network Analytics Server Administrator Password:`n")
            $readminPassword = hide-Password("Confirm Network Analytics Server Administrator Password:`n")
            $PassMatchedserver = confirm-password $adminPassword $readminPassword
        }$PassMatchedserver = 'n'

        while ($PassMatchedCert -ne 'y') {
            $certPassword = hide-password("Network Analytics Server Certificate Password:`n")
            $recertPassword = hide-password("Confirm Network Analytics Server Certificate Password:`n")
            $PassMatchedCert = confirm-password $certPassword $recertPassword
        }$PassMatchedCert = 'n'

        $eniqCoordinator = check-IP
        $confirmation = customRead-host "`n`nPlease confirm that all of the above parameters are correct. (y/n)`n"

        if ($confirmation -ne 'y') {
            customWrite-host "`n`nPlease re-enter the parameters.`n"
        }
    }

    $installParams.Add('sqlAdminPassword', $sqlAdminPassword)
    $installParams.Add('dbPassword', $platformPassword)
    $installParams.Add('configToolPassword', $platformPassword)
    $installParams.Add('administrator', $adminUser)
    $installParams.Add('adminPassword', $adminPassword)
    $installParams.Add('certPassword', $certPassword)
    $installParams.Add('hostAndDomainURL', $hostAndDomainURL)
    $installParams.Add('eniqCoordinator', $eniqCoordinator)
    Set-EnvVariable $platformPassword "NetAnVar"
    $logger.logInfo("Parameters confirmed, proceeding with the installation.", $True)
}

#----------------------------------------------------------------------------------
#  This Function prompts the user for the necessary input parameters required to
#  install Network Analytics Server:
#----------------------------------------------------------------------------------
Function InputParametersUpgrade() {
    $eniqCoordinator = check-IP
    $envVariable = "NetAnVar"
    $platformPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $(Get-EnvVariable $envVariable)).GetNetworkCredential().Password

    $confirmation = 'n'
    customWrite-host "You have initiated the upgrade of Network Analytics Server."
    customWrite-host "Please refer to the Network Analytics Server Installation Instructions for an explanation of each parameter required.`n`n"

    while ($confirmation -ne 'y') {

		 while($TestHostAndDomainStatus -ne $true) {
    	    $hostAndDomain = customRead-host("Network Analytics Server Host-And-Domain: `n")
			$TestHostAndDomainStatus = Test-hostAndDomainURL $hostAndDomain
		}$TestHostAndDomainStatus = $false
        $hostAndDomainURL= "https://"+($hostAndDomain)

        $username = customRead-host("Network Analytics Server Administrator User Name:`n")

         while ($PassMatchedAdmin -ne 'y') {
            $adminPassword = Fetch-Password("Network Analytics Server Administrator user("+$username+") Password: `n")
            $readminPassword = hide-Password("Confirm Network Analytics Server Administrator user("+$username+") Password: `n")
            $PassMatchedAdmin = confirm-password $adminPassword $readminPassword
        }$PassMatchedAdmin = 'n'

        while ($PassMatchedmssql -ne 'y') {
            $sqlAdminPassword = hide-password("PostgreSQL Administrator Password:`n")
            $resqlAdminPassword = hide-password("Confirm PostgreSQL Administrator Password:`n")
            $PassMatchedmssql = confirm-password $sqlAdminPassword $resqlAdminPassword
        }$PassMatchedmssql = 'n'

        while ($PassMatchedCert -ne 'y') {
            $certPassword = hide-password("Network Analytics Server Certificate Password:`n")
            $recertPassword = hide-password("Confirm Network Analytics Server Certificate Password:`n")
            $PassMatchedCert = confirm-password $certPassword $recertPassword
        }$PassMatchedCert = 'n'

        $confirmation = customRead-host "`n`nPlease confirm that all of the above parameters are correct. (y/n)`n"

        if ($confirmation -ne 'y') {
            customWrite-host "`n`nPlease re-enter the parameters.`n"
        }
    }
    $installParams.Add('sqlAdminPassword', $sqlAdminPassword)
    $installParams.Add('administrator', $username)
    $installParams.Add('dbPassword', $platformPassword)
    $installParams.Add('configToolPassword', $platformPassword)
    $installParams.Add('adminPassword', $adminPassword)
    $installParams.Add('certPassword', $certPassword)
    $installParams.Add('spn', "HTTP/"+$hostAndDomain)
    $installParams.Add('hostAndDomainURL', $hostAndDomainURL)
    $installParams.Add('eniqCoordinator', $eniqCoordinator)
    Set-EnvVariable $platformPassword "NetAnVar"
    $logger.logInfo("Parameters confirmed, proceeding with the installation.", $True)


}


Function InputParametersServiceOrMinorUpgrade() {
    $eniqCoordinator = check-IP
    $envVariable = "NetAnVar"
    $platformPassword=(New-Object System.Management.Automation.PSCredential 'N/A', $(Get-EnvVariable $envVariable)).GetNetworkCredential().Password

    $username = (Get-Users -all |% { if($_.Group -eq "Administrator" -and $_.USERNAME -ne "scheduledupdates") {return $_} } |Select-Object -first 1).USERNAME
    $confirmation = 'n'
    customWrite-host "You have initiated the upgrade of Network Analytics Server."
    customWrite-host "Please refer to the Network Analytics Server Installation Instructions for an explanation of each parameter required.`n`n"

    while ($confirmation -ne 'y') {

		 while($TestHostAndDomainStatus -ne $true) {
    	    $hostAndDomain = customRead-host("Network Analytics Server Host-And-Domain: `n")
			$TestHostAndDomainStatus = Test-hostAndDomainURL $hostAndDomain
		}$TestHostAndDomainStatus = $false
		$hostAndDomainURL= "https://"+($hostAndDomain)

         while ($PassMatchedAdmin -ne 'y') {
            $adminPassword = Fetch-Password("Network Analytics Server Administrator user("+$username+") Password: `n")
            $readminPassword = hide-Password("Confirm Network Analytics Server Administrator user("+$username+") Password: `n")
            $PassMatchedAdmin = confirm-password $adminPassword $readminPassword
        }$PassMatchedAdmin = 'n'

        if($Script:major -eq $TRUE){ # only required by service pack upgrade as needs cert during server config upgrade
            while ($PassMatchedCert -ne 'y') {
                $certPassword = hide-password("Network Analytics Server Certificate Password:`n")
                $recertPassword = hide-password("Confirm Network Analytics Server Certificate Password:`n")
                $PassMatchedCert = confirm-password $certPassword $recertPassword
            }$PassMatchedCert = 'n'

            $installParams.Add('certPassword', $certPassword)
        }


        $confirmation = customRead-host "`n`nPlease confirm that all of the above parameters are correct. (y/n)`n"

        if ($confirmation -ne 'y') {
            customWrite-host "`n`nPlease re-enter the parameters.`n"
        }
    }
    $installParams.Add('administrator', $username)
    $installParams.Add('dbPassword', $platformPassword)
    $installParams.Add('configToolPassword', $platformPassword)
    $installParams.Add('adminPassword', $adminPassword)
    $installParams.Add('spn', "HTTP/"+$hostAndDomain)
    $installParams.Add('hostAndDomainURL', $hostAndDomainURL)
    $installParams.Add('eniqCoordinator', $eniqCoordinator)
    $logger.logInfo("Parameters confirmed, proceeding with the installation.", $True)


}

#----------------------------------------------------------------------------------
#  Validate ENIQ coordinator blade IP
#----------------------------------------------------------------------------------
Function check-IP (){
    $ip = [Environment]::GetEnvironmentVariable("LSFORCEHOST","User")

    if([string]::IsNullOrEmpty($ip)) {

         $logger.logError($MyInvocation, "LSFORCEHOST environment variable is not set as IP address of the ENIQ coordinator blade", $True)
         MyExit($MyInvocation.MyCommand)
    }

    if(Test-Connection -ComputerName $ip -Quiet) {
          $logger.logInfo("Ping to ENIQ coordinator blade successful.", $False)
          return $ip
      }else {
          $logger.logError($MyInvocation, "Ping to ENIQ coordinator blade failed", $True)
          MyExit($MyInvocation.MyCommand)
    }
}

#----------------------------------------------------------------------------------
#     Check that the Prerequisites are installed and configured
#      - postgresql Server, .NET, JCONN
#----------------------------------------------------------------------------------
Function CheckPrerequisites() {

    stageEnter($MyInvocation.MyCommand)
    # Check that installation is on the correct OS version
    if (Test-OS($installParams)) {
        $logger.logInfo("Operating System prerequisite passed.", $True)
    }
    else {
        $logger.logError($MyInvocation, "This Operating System is not supported.", $True)
        MyExit($MyInvocation.MyCommand)
    }
	# Check that installation is on the correct Framework version
    if (Test-FrameWork) {
        $logger.logInfo(".Net Framework prerequisite passed.", $True)
    }
    else {
        $logger.logError($MyInvocation, "Installed .Net Framework is not supported.", $True)
        MyExit($MyInvocation.MyCommand)
    }
    $postgres_service = "postgresql-x64-" +(((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Postgres*).MajorVersion) | measure -Maximum).Maximum
    # Check that the postgres server is installed and running
    if (Get-ServiceState($postgres_service) -eq 'running') {
        $logger.logInfo("PostgreSQL installed and running.", $True)
    }
    else {
        $logger.logError($MyInvocation, "PostgreSQL is not running.", $True)
        $logger.logWarning("Please start PostgreSQL and restart the installation.", $True)
        MyExit($MyInvocation.MyCommand)
    }

    stageExit($MyInvocation.MyCommand)
}

#----------------------------------------------------------------------------------
#    Creating postgresql Server NetAnServer database
#----------------------------------------------------------------------------------
Function CreateDB() {
    stageEnter($MyInvocation.MyCommand)

    $status = Create-Databases $installParams
    if($status -ne $True) {
        $logger.logError($MyInvocation, "Creating the PostgreSQL databases failed", $True) # changed name to PostgreSQL
        MyExit($MyInvocation.MyCommand)
    }

    stageExit($MyInvocation.MyCommand)
}


#----------------------------------------------------------------------------------
#    Install the NetAnServer Server software
#----------------------------------------------------------------------------------
Function InstallServerSoftware() {
    stageEnter($MyInvocation.MyCommand)

    if(Install-NetAnServerServer($installParams)) {
        stageExit($MyInvocation.MyCommand)
    }
    else {
        $logger.logError($MyInvocation, "Installing the NetAnServer server component failed.", $True)
        MyExit($MyInvocation.MyCommand)
    }


}
#----------------------------------------------------------------------------------
#    Upgrade the NetAnServer Server software
#----------------------------------------------------------------------------------
Function UpgradeServer() {
    stageEnter($MyInvocation.MyCommand)

    if(Update-Server($installParams)) {
        stageExit($MyInvocation.MyCommand)
    }
    else {
        $logger.logError($MyInvocation, "Installing the NetAnServer server component failed.", $True)
        MyExit($MyInvocation.MyCommand)
    }


}

#----------------------------------------------------------------------------------
#    Copy the Server Certificate
#----------------------------------------------------------------------------------
Function AddCertificate($certdir) {
    stageEnter($MyInvocation.MyCommand)

    $logger.logInfo("Fetching the server certificate.", $True)
    Set-Location $certdir
    $certName=Get-ChildItem . | Where-Object { $_.Name -match '.p12' }
    Set-Location $loc

    while(!($certName -match ".p12")) {
        $certificateConfirmation='n'
        while ($certificateConfirmation -ne 'y') {
            $certificateConfirmation = customRead-host "`n`nPlease confirm that the server certificate has been placed in $($installParams.ericssonDir) (y/n)`n"
        }
        Set-Location $certdir
        $certName=Get-ChildItem . | Where-Object { $_.Name -match '.p12' }
        Set-Location $loc
    }

    $serverCert=$certdir+$certName

    $logger.logInfo("Moving the server certificate.", $True)
    $installParams.Add('serverCert',$serverCert)
    Copy-Item -Path $installParams.serverCert -Destination $installParams.serverCertInstall -Force

    $certTest=$installParams.serverCertInstall+$certName

    If (Test-Path $certTest) {
        stageExit($MyInvocation.MyCommand)
    } Else {
        $logger.logError($MyInvocation, "Moving the server certificate failed.", $True)
        MyExit($MyInvocation.MyCommand)
    }
}


#----------------------------------------------------------------------------------
#    Configure the NetAnServer Server
#----------------------------------------------------------------------------------
Function ConfigureServer() {
    stageEnter($MyInvocation.MyCommand)

    if(Add-NetAnServerConfig($installParams)) {
        $logger.logInfo("Network Analytics Server successfully configured.", $True)
    }
    else {
        $logger.logError($MyInvocation, "Configuration of the Network Analytics Server failed.", $True)
        MyExit($MyInvocation.MyCommand)
    }

    stageExit($MyInvocation.MyCommand)
}




#----------------------------------------------------------------------------------
#    Configure the NetAnServer Server
#----------------------------------------------------------------------------------
Function ConfigureServerUpgrade() {
    stageEnter($MyInvocation.MyCommand)

    if(Add-NetAnServerConfigUpgrade($installParams)) {
        $logger.logInfo("Network Analytics Server successfully configured.", $True)
    }
    else {
        $logger.logError($MyInvocation, "Configuration of the Network Analytics Server failed.", $True)
        MyExit($MyInvocation.MyCommand)
    }

    stageExit($MyInvocation.MyCommand)
}


#----------------------------------------------------------------------------------
#    Start the NetAnServer Server Service
#----------------------------------------------------------------------------------
Function ConfigureHTTPS() {
    stageEnter($MyInvocation.MyCommand)

    If (Update-ServerConfigurations($installParams)) {
        stageExit($MyInvocation.MyCommand)
    } Else {
        MyExit($MyInvocation.MyCommand)
    }
}
#----------------------------------------------------------------------------------
#    Stop the NetAnServer Server Service
#----------------------------------------------------------------------------------
Function StopNetAnServer($service) {
    stageEnter($MyInvocation.MyCommand)
	
    $stopSuccess = Stop-SpotfireService($service)

    if ($stopSuccess) {       
        stageExit($MyInvocation.MyCommand)

    } else {
        $logger.logError($MyInvocation, "Could not stop $service service.", $True)
        MyExit($MyInvocation.MyCommand)
    }
}
Function HotFixes() {
    stageEnter($MyInvocation.MyCommand)

    $ScriptBlockHF = {
            StopNetAnServer($installParams.serviceNetAnServer)
            $installArgs = "" + $installParams.connectIdentifer + " " +
            $installParams.dbName +" "+ $installParams.dbUser + " " + $installParams.dbPassword
            $workingDir = Split-Path $installParams.updateDBScriptTarget
            try {
                $process = Start-Process -FilePath $installParams.updateDBScriptTarget -ArgumentList $installArgs -WorkingDirectory $workingDir -Wait -PassThru -RedirectStandardOutput $installParams.updatedbDBLog -ErrorAction Stop
            } catch {
                $logger.logInfo($MyInvocation, "Error Updating Database $netAnServerDB", $False)
                return $False
            }
            if ($process.ExitCode -eq 0) {
                $logger.logInfo("MS SQL Server database $netAnServerDB updated successfully.", $False)
                } else {
                $errorMessage = $_.Exception.Message
                $logger.logError($MyInvocation, "Creating the MS SQL Server database $netAnServerDB failed. $errorMessage", $True)
                return $False
            }
            Set-Location $installParams.javaPath
            Start-Process .\java.exe  -ArgumentList "-jar $($installParams.serverHFJar) /console $($installParams.installServerDir) -NoExit -wait"  -Wait
            $serverStarted = Start-SpotfireService($installParams.serviceNetAnServer)

            if($serverStarted) {
                try {
                    $a= Invoke-WebRequest -Uri https://localhost
                }
                catch {
                    $logger.logInfo("$($installParams.serviceNetAnServer) has started successfully`n", $True)
                }
            } else {
                $logger.logError($MyInvocation, "Error starting server", $True)
                return $False
            }
            

            Set-Location $loc
        }
    try {
            if((Test-Path($installParams.updatedbDBLog))){

                $logger.logInfo("HotFixes already installed", $True)

            } else{
            $logger.logInfo("Installing HotFixes", $True)
            Invoke-Command -ScriptBlock $ScriptBlockHF -ErrorAction Stop
            $logger.logInfo("HotFixes installed", $True)
            }
        }catch {
            $errorMessage = $_.Exception.Message
            $logger.logError($MyInvocation," HotFixes installation failed :  $errorMessage ", $True)
        }
    stageExit($MyInvocation.MyCommand)
}

#------------------------------------------------------------------------------------------------------
#    Install Node Manager
#------------------------------------------------------------------------------------------------------

Function InstallNodeManagerSoftware() {
    stageEnter($MyInvocation.MyCommand)

    if(Install-NetAnServerNodeManager($installParams)) {
		if($installParams.installReason -eq 'Upgrade') {
			try {
				$configNodeFile = $installParams.netanserverServerLogDir + "\confignode.txt"
				if((Test-Path($configNodeFile))){
					Remove-Item   $configNodeFile -Recurse -Force -ErrorAction SilentlyContinue
					$logger.logInfo("Previous node config file cleanup completed.", $True)
				}
				else{
					$logger.logInfo("No cleanup required.", $True)
				}
			}
			catch {
				$errorMessageConfigFileRemove = $_.Exception.Message
				$logger.logError($MyInvocation, "`n $errorMessageConfigFileRemove", $True)
			}
		}
		if ( -not (Test-FileExists($installParams.confignode))) {
			if((Test-Path($installParams.nodeManagerConfigDirFile))){
				$logger.logInfo("File $($installParams.nodeManagerConfigDirFile) Already Present", $True)
				$logger.logInfo("Proceeding to Cleanup File $($installParams.nodeManagerConfigDirFile)", $True)
				Remove-Item   $installParams.nodeManagerConfigDirFile -Recurse -Force -ErrorAction SilentlyContinue
				$logger.logInfo("File $($installParams.nodeManagerConfigDirFile) Cleanup Completed.", $True)
			
			}
			else {
				$logger.logInfo("File $($installParams.nodeManagerConfigDirFile) Not Found", $True)
				$logger.logInfo("No Cleanup Required.", $True)
			}
			Create-Services $installParams
		}
		else{
            $logger.logInfo("Node manager config file already exists. Skipping procedure to Create Services ", $True)
        }
        stageExit($MyInvocation.MyCommand)
    }
    else {
        MyExit($MyInvocation.MyCommand)
    }
}
#------------------------------------------------------------------------------------------------------
#    Update Node Manager
#------------------------------------------------------------------------------------------------------

Function UpdateNodemanager() {
    stageEnter($MyInvocation.MyCommand)

    if(Delete-Node($installParams)) {
        stageExit($MyInvocation.MyCommand)
    }
    else {
        MyExit($MyInvocation.MyCommand)
    }
}

#----------------------------------------------------------------------------------
#    Start the NetAnServer Node Manager Service
#----------------------------------------------------------------------------------

Function StartNodeManager() {
    stageEnter($MyInvocation.MyCommand)

    $logger.logInfo("Preparing to start Node Manager", $True)
    $startSuccess = Start-SpotfireService($installParams.nodeServiceName)

    if ($startSuccess) {
        $isRunning = Test-ServiceRunning "$($installParams.nodeServiceName)"

        if ($isRunning) {
            $logger.logInfo("Node Manager is already running....", $True)
        } else {

            try {
                $logger.logInfo("Starting service....", $True)
                Start-Service -Name "$($installParams.nodeServiceName)" -ErrorAction stop -WarningAction SilentlyContinue
				while(!$isRunning){
				Start-Sleep -s 10
				$isRunning = Test-ServiceRunning "$($installParams.nodeServiceName)"

				}
            } catch {
                $errorMessage = $_.Exception.Message
                $logger.logError($MyInvocation, "Could not start service. `n $errorMessage", $True)
            }
        }

        stageExit($MyInvocation.MyCommand)

    }  else {
        $logger.logError($MyInvocation, "Could not start $($installParams.nodeServiceName) service.", $True)
        MyExit($MyInvocation.MyCommand)
    }
}


#----------------------------------------------------------------------------------
#    Configure the NetAnServer Node Manager
#----------------------------------------------------------------------------------
Function ConfigureNodeManager() {

        stageEnter($MyInvocation.MyCommand)

        if ( -not (Test-FileExists($installParams.confignode))) {

            $logger.logInfo("Start procedure to trust node", $True)
            $logger.logInfo("This procedure can take up to 10 mins. Please wait...", $True)

			if(Get-NodeStatus $installParams){
                $logger.logInfo("Successfully Trusted New Node", $True)
                Touch-File $installParams.confignode
                stageExit($MyInvocation.MyCommand)
            }
            else {
                $logger.logError($MyInvocation, "Configuring the Node Manager failed", $True)
            }
        }else{
            $logger.logInfo("Node manager config file already exists. Skipping Configuring Node Manager", $True)
            stageExit($MyInvocation.MyCommand)
        }

}


#------------------------------------------------------------------------------------------------------
#    Install Library Sructure
#------------------------------------------------------------------------------------------------------

Function InstallLibrary(){
    stageEnter($MyInvocation.MyCommand)

    $install = Install-LibraryStructure $installParams

    if($install -ne $True) {
        $logger.logError($MyInvocation, "The library structure was not installed", $True)
        MyExit($MyInvocation.MyCommand)
   }

    stageExit($MyInvocation.MyCommand)

}


#------------------------------------------------------------------------------------------------------
#    Configure the Platform Version in REPDB
#------------------------------------------------------------------------------------------------------
Function UpdatePlatformVersion() {
    if($Script:stage -gt 0){
    stageEnter($MyInvocation.MyCommand)
	}
    $logger.logInfo("Updating platform version information", $True)
    $versionXmlFile = Get-PlatformVersionFile "$($installParams.platformVersionDir)"


    if($versionXmlFile[0]) {
        $platformInfo = Get-PlatformDataFromFile $versionXmlFile[1]
    } else {
        $logger.logWarning($versionXmlFile[1], $true)
        return
    }

    if($platformInfo[0]) {
        $isInstalled = Test-IsPlatformInstalled $platformInfo[1]['product_id'] "$($installParams.'dbPassword')"
        if($isInstalled[0]){
            $update = Update-PlatformStatus $isInstalled[1] "$($installParams.'dbPassword')"
        }
        $isUpdated = Invoke-InsertPlatformVersionInformation $platformInfo[1] "$($installParams.'dbPassword')"
    } else {
        $logger.logWarning($platformInfo[1], $true)
        return
    }

    if($isUpdated[0]) {
        $logger.logInfo("Platform version information updated", $true)
    } else {
        $logger.logWarning("Platform version information not updated correctly", $true)
        $logger.logWarning($isUpdated[1], $False)
        return
    }

    if($Script:stage -gt 0){
    stageExit($MyInvocation.MyCommand)
    }
}


#----------------------------------------------------------------------------------
#    Install NetanServer Analyst
#----------------------------------------------------------------------------------
Function InstallAnalyst() {
		if($Script:major -eq $TRUE){
		$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Tibco Spotfire Analyst'"
		if($app){
		$result=$app.uninstall()
		$logger.logInfo("Tibco Spotfire Analyst Uninstall completed.", $False)
		}else{
			$logger.logInfo("Unable to find Tibco Spotfire Analyst to Uninstall", $False)
		}
		}
    stageEnter($MyInvocation.MyCommand)
    $logger.logInfo("Installing Network Analytics Server Analyst component", $True)
    $installAnalyst = Install-NetAnServerAnalyst $installParams

    If($installAnalyst){
         stageExit($MyInvocation.MyCommand)
     }else{
        $logger.logWarning("Network Analytics Server Analyst component did not install successfully", $true)
        MyExit($MyInvocation.MyCommand)
     }
}


#------------------------------------------------------------------------------------------------------
#    Configure the NFS Share NetAnServer Server Instrumentation log directory to ENIQ coordinator blade
#------------------------------------------------------------------------------------------------------
Function ConfigNfsShare() {
   stageEnter($MyInvocation.MyCommand)

   $status = Install-NFS $installParams

   if($status -ne $True) {
        $logger.logError($MyInvocation, "NFS Share configuration of Network Analytics Server Instrumentation Log Directory to" + $installParams.eniqCoordinator +" failed", $True)
        MyExit($MyInvocation.MyCommand)
   }

   stageExit($MyInvocation.MyCommand)
}


#----------------------------------------------------------------------------------
#    Update the Server and Web Player Service configuration files
#----------------------------------------------------------------------------------

Function UpdateConfigurations() {
    stageEnter($MyInvocation.MyCommand)

    If (Update-Configurations($installParams)) {
        stageExit($MyInvocation.MyCommand)
    } Else {
        MyExit($MyInvocation.MyCommand)
    }
}

#------------------------------------------------------------------------------------------------------
#    Set Log permission for netanserver logs
#------------------------------------------------------------------------------------------------------
Function SetLogPermission() {

   stageEnter($MyInvocation.MyCommand)
   $flag = $true


   $folderList = @($installParams.tomcatServerLogDir,
                   $installParams.netanserverServerLogDir,
                   $installParams.nodeManagerLogDir,
                   $installParams.instrumentationLogDir
                   )

   $logger.logInfo("Setting access to NetAnServer Log files for Windows administrators only.", $true)

        foreach ($folderName in $folderList) {

            try {
                $acl = Get-Acl $folderName
                $acl.SetAccessRuleProtection($True, $False)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($rule)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($rule)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("CREATOR OWNER","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($rule)
                Set-Acl $folderName $acl
            } catch {
                $flag = $false
                $errorMessage = $_.Exception.Message
                $logger.logError($MyInvocation, "Could not Set Permission for $folderName . `n $errorMessage", $True)
            }
        }

    if ($flag) {
        $logger.logInfo("NetAnServer Log Files permission access for Windows Server administrators done.", $true)
    } else {
        $logger.logInfo("NetAnServer Log Files permission access for Windows Server administrators Failed.", $True)
    }


   stageExit($MyInvocation.MyCommand)
}


Function SetupAdhoc(){

    stageEnter($MyInvocation.MyCommand)
    $childcreated=Invoke-ImportLibraryElement -element $installParams.customLib -username $installParams.administrator -password $installParams.configToolPassword -conflict "KEEP_NEW" -destination "/"


    $logger.logInfo("Creating Business Author and Business Analyst groups", $True)
    $isCreated = Add-Groups $installParams.groupTemplate  $installParams.configToolPassword
    if ($isCreated[0]) {
        $logger.logInfo("Setting up licences for Business Author and Business Analyst groups", $True)
        $isSet=Set-Licence $installParams.configToolPassword

        if ($isSet[0]) {
        $logger.logInfo("Business Author and Business Analyst licences set successfully", $True)
        } else {
            MyExit($isSet[1])
        }
        $logger.logInfo("Business Author and Business Analyst Groups created successfully", $True)

    }else{
        $logger.logError($MyInvocation, "Failed to create Business Author and Business Analyst Groups due to $errorString", $True)
        MyExit($MyInvocation.MyCommand)
    }

    stageExit($MyInvocation.MyCommand)
}

#------------------------------------------------------------------------------------------------------
#    Updating Adminsitrator User Password 
#------------------------------------------------------------------------------------------------------

Function UpdateUserPassword() {
stageEnter($MyInvocation.MyCommand)
     
     $userPassword = $installParams.adminPassword
     $username = $installParams.administrator
     $userPassword = $userPassword.Replace('"','""')
     $platformPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $(Get-EnvVariable "NetAnVar")).GetNetworkCredential().Password


     $passwordmap = $global:map.Clone()
     $passwordmap.Add('username', $username)
     $passwordmap.Add('platformPassword', $platformPassword)
     $passwordmap.Add('userPassword', $userPassword)
     $passwordmap.Add('configToolPassword', $platformPassword)

     $passwordArguments =  Get-Arguments set-user-password $passwordmap

     If($passwordArguments) {
         $UpdateUserPassword = Use-ConfigTool $passwordArguments $passwordmap
         If(!($UpdateUserPassword)) {

             $logger.logError($MyInvocation, "Error updating the password for User $($passwordmap.username)", $True)
         }
     } Else {
         $logger.logError($MyInvocation, "Command arguments not returned to update password for User $($passwordmap.username)", $True)
     }
    stageExit($MyInvocation.MyCommand)
 }


#----------------------------------------------------------------------------------
#    Cleanup - deletion of the install software, scripts and modules
#----------------------------------------------------------------------------------
Function FinalCleanup() {
    stageEnter("Performing cleanup.")
    try{

        Copy-Item -Path $installParams.analystSoftware -Destination $installParams.analystDir  -Force
        Copy-Item -Path $installParams.languagepackmedia -Destination $installParams.languagepack -Recurse -Force
	    Set-Location $installParams.installDir

        # copy required files for restore and version number
        if( -not (Test-Path($installParams.restoreDataPath))){
            New-Item $installParams.restoreDataPath -type directory | Out-Null
        }

        if( -not (Test-Path($installParams.housekeepingDir))){
            New-Item $installParams.housekeepingDir -type directory | Out-Null
        }

        if( -not (Test-Path($installParams.adhoc_user_lib))){
            New-Item $installParams.adhoc_user_lib -type directory | Out-Null
        }


        Copy-Item -Path $installParams.platformVersionDir -Destination $installParams.restoreDataPath -Recurse -Force
        Copy-Item -Path $installParams.housekeepingScript -Destination $installParams.housekeepingDir -Recurse -Force
        Copy-Item -Path $installParams.adhoc_xml -Destination $installParams.adhoc_user_lib -Recurse -Force


        Get-ChildItem $netanserver_media_dir -Recurse | Remove-Item -Force -Recurse

        #remove old software
        if ($oldVersion){

            $Software_List = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "Tibco Spotfire Node Manager $oldVersion*"}
			$Uninstall_String = $Software_List.QuietUninstallString
            if($Uninstall_String){
                $result=Invoke-Command -ScriptBlock { & cmd /c $Uninstall_String /norestart }
                $logger.logInfo("Tibco Spotfire Node Manager $oldVersion Uninstall completed.", $True)
            }else{
                $logger.logInfo("Unable to find Tibco Spotfire Node Manager $oldVersion  to Uninstall", $True)
            }

            $Software_List = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "Tibco Spotfire Server $oldVersion*"}
			$Uninstall_String = $Software_List.QuietUninstallString
            if($Uninstall_String){
                $result=Invoke-Command -ScriptBlock { & cmd /c $Uninstall_String /norestart }
                $logger.logInfo("Tibco Spotfire Server $oldVersion Uninstall completed.", $True)
            }else{
                $logger.logInfo("Unable to find Tibco Spotfire Server $oldVersion to Uninstall", $True)
            }

            if ((Test-Path("$($installParams.statsServicesDirectoryOld)\Uninstall_SplusServer\"))){
                try {
                    Invoke-Expression '$($installParams.statsServicesDirectoryOld)\Uninstall_SplusServer\Uninstall_SplusServer.exe -i silent'
                    $logger.logInfo("Tibco Spotfire Statistics Server $oldVersion Uninstall completed.", $True)
                }
                catch {
                    $logger.logInfo("Unable to remove Tibco Spotfire Statistics Server $oldVersion", $False)
                }

            }else{
                $logger.logInfo("Unable to find Tibco Spotfire Statistics Server $oldVersion to Uninstall", $True)
            }

            # Remove old directories
            if((Test-Path($installParams.OldNetAnServerDir))){
                Get-ChildItem $installParams.OldNetAnServerDir -Recurse | Remove-Item -Force -Recurse
                Remove-Item $installParams.OldNetAnServerDir -Recurse
                $logger.logInfo("Previous Tomcat directory cleanup completed.", $True)
            }

            if((Test-Path($installParams.automationServicesDirectoryOld))){
                Get-ChildItem $installParams.automationServicesDirectoryOld -Recurse | Remove-Item -Force -Recurse
                Remove-Item $installParams.automationServicesDirectoryOld -Recurse

            }

            if((Test-Path($installParams.statsServicesDirectoryOld))){
                Get-ChildItem $installParams.statsServicesDirectoryOld -Recurse | Remove-Item -Force -Recurse
                Remove-Item $installParams.statsServicesDirectoryOld -Recurse

            }

            if((Test-Path($installParams.hotfixesDirectory))){
                Get-ChildItem $installParams.hotfixesDirectory -Recurse | Remove-Item -Force -Recurse
                Remove-Item $installParams.hotfixesDirectory -Recurse

            }

            if((Test-Path($installParams.migrationDir))){
                Get-ChildItem $installParams.migrationDir -Recurse | Remove-Item -Force -Recurse
                Remove-Item $installParams.migrationDir -Recurse

            }

            # delete the 7.x version of the analyst tool. 10.10 and above are always called setup.exe and are replaced - no need to delete
            if((Test-Path($installParams.analystinstallerExeOld)) -and ($installParams.analystinstallerExeOld -like "*setup-7*") ){
                Remove-Item $installParams.analystinstallerExeOld -Recurse

            }

        }

        $logger.logInfo("Performing cleanup completed.", $True)
    } catch {
        $logger.logError($MyInvocation, "Performing cleanup failed", $True)
    }
    stageExit("Performing cleanup.")
}

Function Touch-File
{
    $file = $args[0]
    if($file -eq $null) {
        throw "No filename supplied"
    }

    if(Test-Path $file)
    {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    }
    else
    {
        echo $null > $file
    }
}



#----------------------------------------------------------------------------------
#  Exit Function to Log error and terminate.
#----------------------------------------------------------------------------------
Function MyExit($errorString) {
    $logger.logError($MyInvocation, "Installation of NetAnServer failed in method: $errorString", $True)
    Exit
}


Function stageEnter([string]$myText) {
    $Script:stage=$Script:stage+1
    $logger.logInfo("------------------------------------------------------", $True)
    $logger.logInfo("|         Entering Stage $($Script:stage) - $myText", $True)
    $logger.logInfo("|", $True)
    $logger.logInfo("", $True)
}

Function stageExit([string]$myText) {
    $logger.logInfo("", $True)
    $logger.logInfo("|", $True)
    $logger.logInfo("|         Exiting Stage $($Script:stage) - $myText", $True)
    $logger.logInfo("------------------------------------------------------`n", $True)
}

Function customWrite-host($text) {
      Write-Host $text -ForegroundColor White
 }

Function customRead-host($text) {
      Write-Host $text -ForegroundColor White -NoNewline
      Read-Host
 }

Function Test-hostAndDomainURL([string]$value){
    try{
        if(!$TestHostAndDomainStatus){
	        if(Test-Connection $value -Quiet -WarningAction SilentlyContinue){
	            return $True
            }
	        else {
	            $logger.logError($MyInvocation, "Could not resolve $($value)`nPlease confirm that the correct host-and-domain has been entered and retry.`nIf issue persists please contact your local network administrator", $True)
		        Exit
            }
        }
    }
    catch{
        $logger.logError($MyInvocation, "Could not resolve $($value). Please contact your local network administrator", $False)
		Exit
    }

}
    if( $MyInvocation.PSCommandPath -ne 'C:\Ericsson\tmp\Scripts\Install\NetAnServer_upgrade.ps1'){
        Main
}
