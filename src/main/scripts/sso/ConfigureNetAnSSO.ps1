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
# Name    : ConfigureNetAnSSO.ps1
# Date    : 12/10/2020
# Purpose : Enable, disable and re-enable SSO in NetAn server

Import-Module Logger -DisableNameChecking
$spofireVersion = (Get-ChildItem C:\Ericsson\NetAnServer\Server).Name
if ($spofireVersion.trim() -eq "7.11") {
	$configScriptPath = "C:\Ericsson\NetAnServer\Server\" + $spofireVersion + "\tomcat\bin\config.bat"
	$serviceSuffix = "7110"
} else {
	$configScriptPath = "C:\Ericsson\NetAnServer\Server\" + $spofireVersion + "\tomcat\spotfire-bin\config.bat"
	$restoreResourcesPath = "C:\Ericsson\NetAnServer\RestoreDataResources\"
	[xml]$xmlObj = Get-Content "$($restoreResourcesPath)\version\version_strings.xml"
	$platformVersionDetails = $xmlObj.SelectNodes("//platform-details")

	foreach ($platformVersionString in $platformVersionDetails)
	{
		if ($platformVersionString.'current' -eq 'y') {
				$version = $platformVersionString.'service-version'
			}
	}

	$serviceSuffix = $version
}
$krbFilePath = "C:\Ericsson\NetAnServer\Server\" + $spofireVersion + "\tomcat\spotfire-config\krb5.conf"
$krbOrigFile = "C:\Ericsson\netAnServer\Server\$spofireVersion\tomcat\spotfire-config\krb5.conf.orig"
$configFilePath = "C:\Ericsson\NetAnServer\Scripts\sso\sso-config.txt"
$configEnable = "C:\Ericsson\NetAnServer\Scripts\sso\sso-config-enable.txt"
$configReEnable = "C:\Ericsson\NetAnServer\Scripts\sso\sso-config-re-enable.txt"
$configDisable = "C:\Ericsson\NetAnServer\Scripts\sso\sso-config-disable.txt"
$kinitFile = "C:\Ericsson\NetAnServer\Server\" + $spofireVersion + "\tomcat\spotfire-bin\kinit.bat"
$keytabFile = "C:\Ericsson\NetAnServer\Server\" + $spofireVersion + "\tomcat\spotfire-config\spotfire.keytab"
$ssoLog = "C:\Ericsson\NetANServer\logs\sso\sso_Log.log"
$script:logger = Get-Logger("sso")
if ( -not (Test-Path "C:\Ericsson\NetANServer\logs\sso")) {
	New-Item -ItemType "directory" -Path "C:\Ericsson\NetANServer\logs\sso" | Out-Null
}
$logger.setLogDirectory("C:\Ericsson\NetANServer\logs\sso")
$logger.timestamp = 'sso'
$logger.setLogname('Log.log')

Function Get-NetanPwd([int]$count) {
	$platformPasswordEncrypted = Read-Host -AsSecureString "`nEnter Network Analytics Platform password"
	$pwd = (New-Object System.Management.Automation.PSCredential 'N/A', $platformPasswordEncrypted).GetNetworkCredential().Password
	$importGroupsOutput = cmd /C "$configScriptPath export-config -f -t $pwd"
	if ( $importGroupsOutput -match "Successfully exported the server configuration to file") {
		return @($True,$platformPasswordEncrypted)
	} else {
		$logger.logError($MyInvocation,"Incorrect password.", $True)
		$count = $count + 1
		if ( $count -eq 5) {
			Exit
		}
		Get-NetanPwd($count)
	}
}

Function Get-ServAccPwd {
	Param
    (
        [string]$servAcc,
        [string]$adFQDN,
		[int]$count
    )
	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	$servAccPasswordEncrypted = Read-Host -AsSecureString "`nEnter password for the user $servAcc" 
	$pwd = (New-Object System.Management.Automation.PSCredential 'N/A', $servAccPasswordEncrypted).GetNetworkCredential().Password
	$prinContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $adFQDN)
	if ($prinContext.ValidateCredentials($servAcc,$pwd)) {
		return @($True,$servAccPasswordEncrypted)
	} else {
		$logger.logError($MyInvocation, "Incorrect password.", $True)
		$count = $count + 1
		if ( $count -eq 5) {
			Exit
		}
		Get-ServAccPwd $servAcc $adFQDN $count
	}
}

Function Test-Kerberos {
	Param
    (
        [string]$netanFQDN,
        [string]$adDomain
    )
	$kinitString = "HTTP/" + $netanFQDN + "@" + $adDomain.ToUpper()
	$kinitOutput = cmd /C "$kinitFile -k -t $keytabFile $kinitString"
	$kinitOutput >>$ssoLog
	if ( $kinitOutput -match "New ticket is stored in cache file" ) {
		return $True	
	} else {
		return $False
	}
}
	
Function Enable-SSO {
	if (Test-Path $configEnable) {
		$adFQDN = (Get-Content $configEnable | Select-String "set AD_FQDN").Line.split("=")[1].replace("""","").trim()
		$adDomain = (Get-Content $configEnable | Select-String "set AD_DOMAIN").Line.split("=")[1].replace("""","").trim()
		$adHost = (Get-Content $configEnable | Select-String "set AD_HOSTNAME").Line.split("=")[1].replace("""","").trim()
		$adHostDomain = $adHost + "." + $adDomain
		if ($adFQDN -ne $adHostDomain) {
			$logger.logError($MyInvocation, "AD details don't match.`nPlease confirm that the correct AD details has been entered in $configEnable and retry.", $TRUE)
			Exit
		}
		if (-not (Test-Connection $adFQDN -Quiet -WarningAction SilentlyContinue)) {
			$logger.logError($MyInvocation, "Could not resolve $($adFQDN).`nPlease confirm that the correct AD details has been entered in $configEnable and retry.`nIf issue persists please contact your local network administrator.", $TRUE)
			Exit
		}
		if ( -not (Test-Path $configScriptPath)) {
			$logger.logError($MyInvocation,"The file $configScriptPath is missing.",$TRUE)
			Exit
		}
		$netanAccOutput = Get-NetanPwd(0)
		$platformPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $netanAccOutput[1]).GetNetworkCredential().Password
		$servAcc = (Get-Content $configEnable | Select-String "set SERVICE_ACCOUNT").Line.split("=")[1].replace("""","").trim()
		$netanFQDN = (Get-Content $configEnable | Select-String "set NETAN_FQDN").Line.split("=")[1].replace("""","").trim()
		$servAccOutput = Get-ServAccPwd $servAcc $adFQDN 0
		$servAccPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $servAccOutput[1]).GetNetworkCredential().Password
		$logger.logInfo("Enabling SSO.", $TRUE)
		if (Test-Path $krbFilePath) {
			if (Test-Path $kinitFile) {
				if (Test-Path $keytabFile) {
					if (Test-Path $krbOrigFile) {
						Remove-Item $krbFilePath
						cp $krbOrigFile $krbFilePath
					} else {
						cp $krbFilePath $krbOrigFile 
					}
					$text = Get-Content $krbFilePath
					$newText = $text.replace('MYDOMAIN',$adDomain.ToUpper()).replace('mydomain',$adDomain.ToLower()).replace('mydc',$adHost)
					Set-Content -Path $krbFilePath -Value $newText
					if (-not (Test-Kerberos $netanFQDN $adDomain)) {
						$logger.logError($MyInvocation,"Kerberos authentication is not working. Verify the $krbFilePath and $keytabFile file.",$TRUE)
						Exit
					} else {
						cp $configEnable $configFilePath
						Set-ItemProperty -Path $configFilePath -Name IsReadOnly -Value $false
						$oldText = Get-Content $configFilePath
						$updatedText = $oldText.replace("spotfire_ver",$spofireVersion).replace("config_tool_pwd",$platformPassword).replace("service_acc_pwd",$servAccPassword)
						Set-Content -Path $configFilePath -Value $updatedText
					}
				} else {
					$logger.logError($MyInvocation,"The file $keytabFile is missing.",$TRUE)
					Exit
				}
			} else {
				$logger.logError($MyInvocation,"The file $kinitFile is missing.",$TRUE)
				Exit
			}
		} else {
			$logger.logError($MyInvocation,"The file $krbFilePath is missing.",$TRUE)
			Exit
		}
	} else {
		$logger.logError($MyInvocation, "The file $configEnable is missing.", $TRUE)
		Exit
	}
	
	try {
		$logger.logInfo("Please wait. This may take few minutes.", $TRUE)
		cmd /C "$configScriptPath run $configFilePath" *>>$ssoLog
		Restart-Service Tss$serviceSuffix -WarningAction silentlyContinue
		try {
			$a= Invoke-WebRequest -Uri https://localhost
		}
		catch {
			$logger.logInfo("Tss$($serviceSuffix) has restarted successfully`n", $True)
		}

		$logger.logInfo("Importing groups. Please wait. This may take few minutes.", $TRUE)

		# wait for a minute to allow the ldap syncup to happen
		$forceLDAPsync = cmd /C "$configScriptPath list-users -f -t $platformPassword"
		Start-Sleep -s 60
		
		# attempt to import the groups x amount of times, break if successfull	
		$numberOfAttempts = 3
		for ($i = 0; $i -lt $numberOfAttempts; $i++){
			
			$importGroupsOutput = cmd /C "$configScriptPath import-groups -m true -t $platformPassword C:\Ericsson\NetAnServer\Resources\ssogroups.txt"
			if ($importGroupsOutput -match "Total number of errors: #0" ) {
				$logger.logInfo("Groups imported successfully.", $TRUE)
				break
			}
		}

		$importGroupsOutput >>$ssoLog
		if ( -not ($importGroupsOutput -match "Total number of errors: #0" )) {
			$logger.logError($MyInvocation,"Error in configuring SSO. Refer $ssoLog for details.",$TRUE)
			Exit
		}
		C:\Ericsson\NetAnServer\Scripts\User_Maintenance\CustomFolderCreation\CustomFolderTask.ps1 *>>$ssoLog
		Remove-Item $configFilePath
	} catch {
		$errorMessage = $_.Exception.Message
		$logger.logError($MyInvocation,"$errorMessage",$TRUE)
		Exit
	}
	$logger.logInfo("Completed.", $TRUE)
}

Function Disable-SSO {
	if (Test-Path $configDisable) {
		if ( -not (Test-Path $configScriptPath)) {
			$logger.logError($MyInvocation,"The file $configScriptPath is missing.",$TRUE)
			Exit
		}
		$netanAccOutput = Get-NetanPwd(0)
		$platformPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $netanAccOutput[1]).GetNetworkCredential().Password
		cp $configDisable $configFilePath
		Set-ItemProperty -Path $configFilePath -Name IsReadOnly -Value $false
		$oldText = Get-Content $configFilePath 
		$updatedText = $oldText.replace("config_tool_pwd",$platformPassword)
		Set-Content -Path $configFilePath -Value $updatedText
	} else {
		$logger.logError($MyInvocation,"The file $configDisable is missing.",$TRUE)
		Exit
	}
	try {
		$logger.logInfo("Disabling SSO.", $TRUE)
		cmd /C "$configScriptPath run $configFilePath" *>>$ssoLog
		Restart-Service Tss$serviceSuffix -WarningAction silentlyContinue
		try {
			$a= Invoke-WebRequest -Uri https://localhost
		}
		catch {
			$logger.logInfo("Tss$($serviceSuffix) has restarted successfully`n", $True)
		} 
		C:\Ericsson\NetAnServer\Scripts\User_Maintenance\CustomFolderCreation\CustomFolderTask.ps1 -Disable *>>$ssoLog
		Remove-Item $configFilePath
	} catch {
		$errorMessage = $_.Exception.Message
		$logger.logError($MyInvocation,"$errorMessage",$TRUE)
		Exit
	} 
	$logger.logInfo("Completed.", $TRUE)
}

Function Reenable-SSO {
	if (Test-Path $configReEnable) {
		if ( -not (Test-Path $configScriptPath)) {
			$logger.logError($MyInvocation,"The file $configScriptPath is missing.",$TRUE)
			Exit
		}
		$adFQDN = (Get-Content $configReEnable | Select-String "set AD_FQDN").Line.split("=")[1].replace("""","").trim()
		if ( -not (Test-Connection $adFQDN -Quiet -WarningAction SilentlyContinue)) {
			$logger.logError($MyInvocation, "Could not resolve $($adFQDN)`nPlease confirm that the correct AD details has been entered in $configReEnable and retry.`nIf issue persists please contact your local network administrator.", $TRUE)
			Exit
		}
		$netanAccOutput = Get-NetanPwd(0)
		$platformPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $netanAccOutput[1]).GetNetworkCredential().Password
		$servAcc = (Get-Content $configReEnable | Select-String "set SERVICE_ACCOUNT").Line.split("=")[1].replace("""","").trim()
		$servAccOutput = Get-ServAccPwd $servAcc $adFQDN 0
		$servAccPassword = (New-Object System.Management.Automation.PSCredential 'N/A', $servAccOutput[1]).GetNetworkCredential().Password
		cp $configReEnable $configFilePath
		Set-ItemProperty -Path $configFilePath -Name IsReadOnly -Value $false
		$oldText = Get-Content $configFilePath 
		$updatedText = $oldText.replace("spotfire_ver",$spofireVersion).replace("config_tool_pwd",$platformPassword).replace("service_acc_pwd",$servAccPassword)
		Set-Content -Path $configFilePath -Value $updatedText
	} else {
		$logger.logError($MyInvocation,"The file $configReEnable is missing.",$TRUE)
		Exit
	}
	try {
		$logger.logInfo("Re-enabling SSO.", $TRUE)
		cmd /C "$configScriptPath run $configFilePath" *>>$ssoLog
		Restart-Service Tss$serviceSuffix -WarningAction silentlyContinue 
		try {
			$a= Invoke-WebRequest -Uri https://localhost
		}
		catch {
			$logger.logInfo("Tss$($serviceSuffix) has restarted successfully`n", $True)
		}
		C:\Ericsson\NetAnServer\Scripts\User_Maintenance\CustomFolderCreation\CustomFolderTask.ps1 *>>$ssoLog
		Remove-Item $configFilePath
	} catch {
		$errorMessage = $_.Exception.Message
		$logger.logError($MyInvocation,"$errorMessage",$TRUE)
		Exit
	} 
	$logger.logInfo("Completed.", $TRUE)
}

#Main
if ($args -eq "enable") {
	Enable-SSO
} elseif ($args -eq "disable") {
	Disable-SSO
} elseif ($args -eq "re-enable"){
	Reenable-SSO
}
else {
	Write-Host "`nInvalid argument`n" -ForegroundColor red
	Exit
}

