###########################################################################
##           SCCM Client Health check and Troubleshooting Script					
##           Author: Lokesh Agarwal
##           Date: 23-08-2017
##	     Input:- SCCM Client path, MP Address, Site Code
###########################################################################


############### Fill the details ##########################################
$path = "Path where SCCM client msi file is placed"
$mp_address = "FQDN MP"
$site_code = "Site code eg : PS1"


############################### Main Code ####################################
$machinename = hostname
$SMSCli = [wmiclass] "root\ccm:sms_client"

############################### Check if WMI is working #######################
if((Get-WmiObject -Namespace root\ccm -Class SMS_Client) -and (Get-WmiObject -Namespace root\ccm -Class SMS_Client))
{
	$WMI_Status = "Working"
}else
{
	Stop-Service -Force winmgmt -ErrorAction SilentlyContinue
   	cd  C:\Windows\System32\Wbem\
   	del C:\Windows\System32\Wbem\Repository.old -Force -ErrorAction SilentlyContinue
   	ren Repository Repository.old -ErrorAction SilentlyContinue
   	Start-Service winmgmt 
}

############################# Check if SCCM Client is installed ##################
If(Get-Service -Name CcmExec)
{
	$Client_Status = "Yes"
	
	########### Check if services are running ################################
	$CcmExec_Status = Get-Service -Name CcmExec | %{$_.status}
	$BITS_Status = Get-Service -Name BITS | %{$_.status}
	$wuauserv_Status = Get-Service -Name wuauserv | %{$_.status}
	$Winmgmt_Status = Get-Service -Name Winmgmt | %{$_.status}
	$RRegistry_Status = Get-Service -Name RemoteRegistry | %{$_.status}


	if($CcmExec_Status -eq "Stopped")
	{
		Get-Service -Name CcmExec | Start-Service
	}

	if($BITS_Status -eq "Stopped")
	{
		Get-Service -Name BITS | Start-Service
	}

	if($wuauserv_Status -eq "Stopped")
	{
		Get-Service -Name wuauserv | Start-Service
	}

	if($Winmgmt_Status -eq "Stopped")
	{
		Get-Service -Name Winmgmt | Start-Service
	}

	
	
	$MachinePolicyRetrievalEvaluation = "{00000000-0000-0000-0000-000000000021}"
	$SoftwareUpdatesScan = "{00000000-0000-0000-0000-000000000113}"
	$SoftwareUpdatesDeployment = "{00000000-0000-0000-0000-000000000108}"

	#################### check if Scan cycles are working ###################
	$machine_status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $MachinePolicyRetrievalEvaluation
	$software_status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $SoftwareUpdatesScan
	$softwaredeploy_Status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $SoftwareUpdatesDeployment

	if($machine_status -and $software_status -and $softwaredeploy_Status)
	{
		$machine_Rstatus = "Successful"
	}else
	{
		$repair = $SMSCli.RepairClient()
	}

}else
{
	############## Install SCCM Client ###############################
	$path\ccmsetup.exe /mp:$mp_address SMSSITECODE=$site_code	
}

####################################################################################################
