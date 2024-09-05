<#
   .Synopsis
    This does that 

   .Example 1
    
   .Example 2

   .Parameter Name
    The parameter

   .Notes
    AUTHOR: David Hiemer


#Requires -Version 3.0
#> 

Add-Type -AssemblyName presentationframework, presentationcore #Used for Get-XamlObject
Add-Type -AssemblyName System.Windows.Forms
Import-Module vmware.vimautomation.core

try{ Import-Module ITAPPSModule -DisableNameChecking -Force -ErrorAction Stop }
catch{
    Write-Host -ForegroundColor White -BackgroundColor Red "ERROR: ITAPPSModule Not Loaded. Please ensure ITAPPS Module exists here: [C:\Windows\System32\WindowsPowerShell\v1.0\Modules\ITAPPSModule]"
    Read-Host "ERROR: ITAPPSModule Not Loaded. Terminating Utility. Press Enter to Continue..."
    exit
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false |Out-Null

Write-Host "Loading Management Utility..."

$MyScriptRoot = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])

$VersionPath="$PSScriptRoot\Resources\Version.txt"
$UtilityVersion=GC $VersionPAth
$UtilityVersionTime=(GCI $VersionPAth).lastwritetime
$ModuleVersion="$((get-module ITAPPSModule).Version)"


#Set Relative Path Variables
$ManagementUtilityPath =        $PSScriptRoot
$GUIPath =                      "$PSScriptRoot\Resources\GUI\Xaml"

#Static Paths
$DeploymentAutomationPath=      "\\xfselc\elc_data\ITAPPS\Scripts-PS\DeploymentAutomation"
$ELCVersionsPath=               "\\xfselc\elc_data\ITAPPS\Scripts-PS\DeploymentAutomation\ELCVersions.csv"
$DRXMLs=                        "\\xfselc\elc_data\ITAPPS\Scripts-PS\DRFailoverAutomation\XMLs"
$ClientConfigurationPath=       "\\xfselc\elc_data\ITAPPS\Scripts-PS\ClientConfiguration"
$ClientConfigurationCreatePath= "\\xfselc\elc_data\ITAPPS\Scripts-PS\ClientConfiguration\Create"
$VMPathspath =                  "\\xfselc\elc_data\ITAPPS\Scripts-PS\ClientConfiguration\VMPaths.xml"
$GenerateVMPathsPath=           "\\xfselc\elc_data\ITAPPS\Scripts-PS\ClientConfiguration\Scripts\GetVMPaths.ps1"
$PRTGXMLPath =                  "\\xfselc\elc_data\ITAPPS\Scripts-PS\PRTG\Data\table.xml"
$BackupRestorePath =            "\\xfselc\elc_data\ITAPPS\Scripts-PS\BackupRestore"
$PatchingPath=                  "\\xfselc\elc_data\ITAPPS\Scripts-PS\Patching"
$PatchingPhasesCsv=             "\\xfselc\elc_data\ITAPPS\Patching\Phases.csv"
$PatchingvDisksCsv=             "\\xfselc\elc_data\ITAPPS\Patching\vDisks.csv"
$PatchingStoresCsv=             "\\xfselc\elc_data\ITAPPS\Patching\Stores.csv"

#Read Configutation Settings XML Files
[xml]$Script:ConfigurationXML = Get-Content -Path "$PSScriptRoot\ConfigutationSettings.xml"

#Set Configutation Settings Variables
$ClientConfigurationXMLPath=    $ConfigurationXML.ManagementUtilityConfig.ClientConfiguration
$DRPairingPath =                $ConfigurationXML.ManagementUtilityConfig.DRPairingPath
$ScriptPSPath=                  $ConfigurationXML.ManagementUtilityConfig.ScriptPSPath
$ELCIOFPath=                    $ConfigurationXML.ManagementUtilityConfig.ELCIOFPath
$ITAPPSConfigServer =           $ConfigurationXML.ManagementUtilityConfig.ITAPPSConfigServer
$ITAPPSConfigDB =               $ConfigurationXML.ManagementUtilityConfig.ITAPPSConfigDB
$PRTGUser =                     $ConfigurationXML.ManagementUtilityConfig.PRTGUser
$PRTGpasshash =                 $ConfigurationXML.ManagementUtilityConfig.PRTGpasshash
$GeneratedXMLBRPath=            $ConfigurationXML.ManagementUtilityConfig.GeneratedXMLBRPath
$GeneratedXMLPath=              $ConfigurationXML.ManagementUtilityConfig.GeneratedXMLPath
$DeltaLogPath=                  $ConfigurationXML.ManagementUtilityConfig.DeltaLogPath
$XMLArchivePath=                $ConfigurationXML.ManagementUtilityConfig.XMLArchivePath
$PrimaryLouPVSServer=           $ConfigurationXML.ManagementUtilityConfig.PrimaryLouPVSServer
$PrimaryDenPVSServer=           $ConfigurationXML.ManagementUtilityConfig.PrimaryDenPVSServer
$PrimaryLouDDCServer=           $ConfigurationXML.ManagementUtilityConfig.PrimaryLouDDCServer
$PrimaryDenDDCServer=           $ConfigurationXML.ManagementUtilityConfig.PrimaryDenDDCServer
$PrimaryLouPersonalityServer=   $ConfigurationXML.ManagementUtilityConfig.PrimaryLouPersonalityServer
$PrimaryLouPersonalityDB=       $ConfigurationXML.ManagementUtilityConfig.PrimaryLouPersonalityDB
$PrimaryDenPersonalityServer=   $ConfigurationXML.ManagementUtilityConfig.PrimaryDenPersonalityServer
$PrimaryDenPersonalityDB=       $ConfigurationXML.ManagementUtilityConfig.PrimaryDenPersonalityDB
$DeploymentEmailTo=             $ConfigurationXML.ManagementUtilityConfig.DeploymentEmailTo
$DeploymentEmailFrom=           $ConfigurationXML.ManagementUtilityConfig.DeploymentEmailFrom
$DeploymentEmailToSupport=      $ConfigurationXML.ManagementUtilityConfig.DeploymentEmailToSupport

# Read ClientConfig XML
[xml]$Script:XMLClientConfig =  Get-Content -Path $ClientConfigurationXMLPath

# Build GUI  
. "$PSScriptRoot\Resources\GUI\Functions\Get-XamlObject.ps1"
$wpf = Get-ChildItem -Path $GUIPath -Filter *.xaml -file | Where-Object { $_.Name -ne 'App.xaml' } | Get-XamlObject

################# [Populate Fields] #######################
$ELCVersions=Import-Csv -Path $ELCVersionsPath -Header Version,DeltaPath,ThinappPath
$ELCVersions | ForEach-Object { $WPF.comboUpgradeVersion.Items.Add($_.Version) | Out-Null }

$ClientENVs = ($XMLClientConfig | Select-XML -XPath "//Environment" | Select-Object -ExpandProperty Node ).name | ForEach-Object { $WPF.cbClientEnv.Items.Add($_) | Out-Null } 

Get-Content "$PSScriptRoot\Resources\GUI\Functions\Services.txt" | ForEach-Object { $WPF.cbService.Items.Add($_) | out-null }
Get-ChildItem $GeneratedXMLPath   | Where-Object { ! $_.PSIsContainer }| ForEach-Object { $WPF.comboGenXML.Items.Add($_.FullName) | Out-Null }
Get-ChildItem $GeneratedXMLBRPath | Where-Object { ! $_.PSIsContainer }| ForEach-Object { $WPF.comboBRXML.Items.Add($_.FullName) | Out-Null }
Get-ChildItem $DRXMLs | Where-Object { ! $_.PSIsContainer }| ForEach-Object { $WPF.comboDRXML.Items.Add($_.FullName) | Out-Null }

($XMLClientConfig | Select-XML -XPath "//Client" | Select-Object -ExpandProperty Node).name | ForEach-Object {
    $ClientName = $_
    $WPF.comboClient.Items.Add($ClientName) | Out-Null
    $WPF.comboClientCFG.Items.Add($ClientName) | Out-Null
    $WPF.comboClientBR.Items.Add($ClientName) | Out-Null
    $WPF.comboClientDR.Items.Add($ClientName) | Out-Null
}

$Phases=Import-Csv $PatchingPhasesCsv -Header Phase,Collection | Sort-Object Phase -Unique
$Phases | ForEach-Object {
    $Phasename = $_.Phase
    $WPF.comboCycle.Items.Add($Phasename) | Out-Null
}

Get-ChildItem "$ManagementUtilityPath\Resources\SQL\Resets"  | ForEach-Object { $WPF.comboExecuteSQLResets.Items.Add($_.FullName) | out-null }
Get-ChildItem "$ManagementUtilityPath\Resources\SQL\Selects" | ForEach-Object { $WPF.comboExecuteSQLSelects.Items.Add($_.FullName) | out-null }
Get-ChildItem "$ManagementUtilityPath\Resources\SQL\Updates" | ForEach-Object { $WPF.comboExecuteSQLUpdates.Items.Add($_.FullName) | out-null }

###################################################

$WriteInformation='continue'
$script:WriteVerbose=$false
$Script:VerboseOutput=$false

###########################################################
#Set BackgroundImage
$WPF.BackImage.Source="\\xfselc\elc_data\ITAPPS\Software\ITAPPS_Utils\ManagementUtility\BackImages\simplefade.jpg"
$WPF.BackImage.Stretch="Fill"

#Dot Source All Scripts
$Scripts=@()
$Scripts+=(Get-ChildItem "$PSScriptRoot\Resources" -recurse | Where-Object{$_.Extension -match 'ps1'}).FullName 
$Scripts+=(Get-ChildItem "$PSScriptRoot\Tabs" -recurse | Where-Object{$_.Extension -match 'ps1'}).FullName 
ForEach($Script in $Scripts){ . $Script }

# Load Main Menu in main frame
$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.MainMenuPage) | Out-Null


try{
    #Load Main Menu in main frame
    $wpf.DeployWindow.Showdialog() | Out-Null

}
catch{
    $ErrorMessage = $error[0].Exception.Message
    Write-Error "Exception caught: $ErrorMessage"
    write-host "Utility Reached a Terminating Error. Press any Key to continue" -backgroundcolor Red -foreground white
    read-host "..."

}
