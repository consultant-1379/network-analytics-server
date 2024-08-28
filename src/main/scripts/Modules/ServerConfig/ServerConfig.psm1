# ********************************************************************
# Ericsson Radio Systems AB                                     Module
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
# Name    : ServerConfig.psm1
# Date    : 20/08/2020
# Purpose : Updates Server.xml for HTTPS config


Import-Module Logger
Import-Module NetAnServerUtility

$configKeys = @(
    'serviceNetAnServer',
    'serverCertInstall',
    'certPassword', 
    'serverConfInstallXml', 
    'serverConfig' 
    )




### Function: ConfigurationUpdater($installParams) ###
#
#    Update configuration files for the Server, and Web Player service.
#
# Arguments:
#       $installParams - install parameters
#
# Return Values:
#       [boolean]$true|$false
# Throws:
#       [none]
#
Function Update-ServerConfigurations(){
    param (
            [Parameter(Mandatory=$true)]
            [hashtable]$installParams
    )


    $logger.logInfo("Verifying default configuration parameters", $True)
    $validParams = Test-MapForKeys $installParams $configKeys

    if($validParams[0] -eq $True) {
        $logger.logInfo($validParams[1], $True)
    } else {
        $logger.logError($MyInvocation, $validParams[1], $True)
        return $False
    }
	
    try{
        $logger.logInfo("Updating Server configuration files....", $True)
		
        $serverXmlTest=Test-ServerXml($installParams)
        $serverXmlUpdate=$True
        If (-not $serverXmlTest) {
		    $serverXmlUpdate=$False
		    $logger.logInfo("Updating Config files for Network Analytics Server", $False)
			$serverStopped = Stop-SpotfireService($installParams.serviceNetAnServer)

            if(-not $serverStopped) {
                $logger.logError($MyInvocation," Updating configuration file for the server failed:  Server stop failed", $True) 
                return $False
            }

            $serverXmlUpdate=Update-ServerXml($installParams)
        }
		If (-not $serverXmlUpdate) {
			return $False
		}
        If ($serverXmlUpdate) {
            $serverStarted = Start-SpotfireService($installParams.serviceNetAnServer)
            if($serverStarted) {
                try {
                    $a= Invoke-WebRequest -Uri https://localhost
                }
                catch {
                    $errorMessage = $_.Exception.Message
                    $logger.loginfo(" Server is up now:  $errorMessage ", $False)
                }
            } else {
                $logger.logError($MyInvocation," Updating configuration file for the server failed:  Server start failed", $True) 
                return $False
            }         
        }
        return $True

    } catch {
        $errorMessage = $_.Exception.Message
        $logger.logError($MyInvocation," Updating configuration file for the server failed:  $errorMessage ", $True)
        return $False
    }
}



### Function: Update-ServerXml ###
#
#   Updates Server configuration file.
#
#
# Arguments:
#   [hashtable] $installParams
#
# Return Values:
#   [boolean]$true|$false
#
Function Update-ServerXml() {

    param(
        [hashtable] $installParams
    )


	if((Test-Path($installParams.serverCertInstall))){
        try {
	
        $certFileName=Get-ChildItem $installParams.serverCertInstall | Where-Object { $_.Name -match '.p12' }
		$certName = $certFileName.Name


        $certificateDir=$installParams.serverCertInstall+$certName
		
        $certutil='certutil -f -p $installParams.certPassword -importpfx $certificateDir'
        $certResult=Invoke-Expression $certutil -ErrorAction SilentlyContinue | out-string

        while ($certResult -match "not correct") {
            $certPass=Show-host("Certificate password error. Please enter the correct certificate password:`n")
            $installParams.certPassword=$certPass
            $certResult=Invoke-Expression $certutil -ErrorAction SilentlyContinue | out-string
        }
		
        $serverxml=[xml](Get-Content $installParams.serverConfInstallXml)
        $jvmRoute=$serverxml.Server.Service.Engine.getAttribute("jvmRoute")

        $serverxml=[xml](Get-Content $installParams.serverConfig)
        $serverxml.Server.Service.Engine.SetAttribute("jvmRoute",$jvmRoute)

        $keystore=$serverxml.Server.Service.Connector.SSLHostConfig.Certificate
        $keystore.SetAttribute("certificateKeystoreFile","./certs/"+$certName)
        $keystore.SetAttribute("certificateKeystorePassword",$installParams.certPassword)

        Set-ItemProperty $installParams.serverConfig -name IsReadOnly -value $false
        $serverxml.Save($installParams.serverConfig)

        Copy-Item -Path $installParams.serverConfig -Destination $installParams.serverConfInstallXml -Force

        $logger.logInfo("Network Analytics server configuration file updated.", $True)

        return $True
    } catch {
        $errorMessage = $_.Exception.Message
        $logger.logError($MyInvocation," Updating server configuration file failed:  $errorMessage ", $True)
        return $False
    }
	}
	else{
	$logger.logInfo("Network Analytics server is Upgrading.", $False)
	return $True
	}
}


### Function: Test-ServerXml ###
#
#   Verifies if the server.xml has been updated.
#
#
# Arguments:
#   [hashtable] $installParams
#
# Return Values:
#   [boolean]$true|$false
#
Function Test-ServerXml() {

    param(
        [hashtable] $installParams
    )

    $xml=[xml](Get-Content $installParams.serverConfInstallXml)
    $certValueTest=$xml.Server.Service.Connector.SSLHostConfig.Certificate
    if($certValueTest)
    {
    $certTest=$certValueTest.GetAttribute("certificateKeystorePassword")
    If ($certTest -eq 'keystorePassword') {
        return $False
    }
    else 
    {
        return $True
    }
    }
    else 
    {
        return $False
    }
    
}

Function Show-host($text) {
  Write-Host $text -ForegroundColor White -NoNewline
  Read-Host
}