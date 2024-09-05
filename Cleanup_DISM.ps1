
Function Cleanup

    {
        ## Stops the windows update service. 
        Get-Service -Name wuauserv | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue
        ## Windows Update Service has been stopped successfully!

        ## Deletes the contents of windows software distribution.
        Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
        Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } |
        remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
        ## The Contents of Windows SoftwareDistribution have been removed successfully!

        ## Deletes the contents of the Windows Temp folder.
        Get-ChildItem "C:\Windows\Temp\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
        Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } |
        remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
        ## The Contents of Windows Temp have been removed successfully!

        ## Delets all files and folders in user's Temp folder. 
        Get-ChildItem "C:\users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
        remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
        ## The contents of C:\users\$env:USERNAME\AppData\Local\Temp\ have been removed successfully!

        ## Remove all files and folders in user's Temporary Internet Files. 
        Get-ChildItem "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" `
        -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
        Where-Object {($_.CreationTime -le $(Get-Date).AddDays(-$DaysToDelete))} |
        remove-item -force -recurse -ErrorAction SilentlyContinue
        ## All Temporary Internet Files have been removed successfully!

        ## Cleans IIS Logs if applicable.
        Get-ChildItem "C:\inetpub\logs\LogFiles\*" -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { ($_.CreationTime -le $(Get-Date).AddDays(-60)) } |
        Remove-Item -Force -Verbose -Recurse -ErrorAction SilentlyContinue
        ## All IIS Logfiles over x days old have been removed Successfully!

        ## deletes the contents of the recycling Bin.
        ## The Recycling Bin is now being emptied!
        $objFolder.items() | ForEach-Object { Remove-Item $_.path -ErrorAction Ignore -Force -Verbose -Recurse }
        ## The Recycling Bin has been emptied!

        ## Starts the Windows Update Service
        ##Get-Service -Name wuauserv | Start-Service -Verbose
    }

Function AfterSize

    {
        $After =  Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName,
        @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
        @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
        @{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } },
        @{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } |
        Format-Table -AutoSize | Out-String

        "Hostname:`t$env:COMPUTERNAME"; Get-Date | Select-Object DateTime
        Write-Verbose "`r`nAfter:`r`n$After"
        Write-Verbose $sizen
    }
  
Function Win2008R2

    {
        copy C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe C:\Windows\System32\
        copy C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui C:\Windows\System32\en-US\

        Cleanup

        Write-host "`r`nDISM (Deployment Image Servicing and Management)`r`n`r`n(1) Initiate DISM Component Cleanup`r`n(2) Initiate DISM SP Superseded`r`n(3) Initiate DISM Component Cleanup and SP Superseded`r`n(4) Initiate Disk Cleanup`r`n`r`nHit any other key to proceed with none of the above`r`n" -ForegroundColor Yellow 
        $Readhost = Read-Host
        Switch ($ReadHost) 
        {
                1 {Write-host "`r`nInitiating DISM Component Cleanup"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase}
                2 {Write-host "`r`nInitiating DISM SPSuperseded"; dism.exe /online /Cleanup-Image /SPSuperseded}
                3 {Write-host "`r`nInitiating DISM Component Cleanup and SP Superseded"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase; dism.exe /online /Cleanup-Image /SPSuperseded}
                4 {Write-Host "`r`nInitiating Disk Cleanup"; cleanmgr.exe}
                Default {Write-Host "`r`nNone of the above actions will be initiated`r`n"} 
        }
    }

Function Win2012

    {
        Cleanup

        Write-host "`r`nDISM (Deployment Image Servicing and Management)`r`n`r`n(1) Initiate DISM Component Cleanup`r`n(2) Initiate DISM SP Superseded`r`n(3) Initiate DISM Component Cleanup and SP Superseded`r`n`r`nHit any other key to proceed with none of the above`r`n" -ForegroundColor Yellow
        $Readhost = Read-Host
        Switch ($ReadHost)
        {
                1 {Write-host "`r`nInitiating DISM Component Cleanup"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase}
                2 {Write-host "`r`nInitiating DISM SPSuperseded"; dism.exe /online /Cleanup-Image /SPSuperseded}
                3 {Write-host "`r`nInitiating DISM Component Cleanup and SP Superseded"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase; dism.exe /online /Cleanup-Image /SPSuperseded}
                Default {Write-Host "`r`nNone of the above actions will be initiated`r`n"}
        }
    }

Function Win2012R2

    {
        Cleanup

        Write-host "`r`nDISM (Deployment Image Servicing and Management)`r`n`r`n(1) Initiate DISM Component Cleanup`r`n(2) Initiate DISM SP Superseded`r`n(3) Initiate DISM Component Cleanup and SP Superseded`r`n`r`nHit any other key to proceed with none of the above`r`n" -ForegroundColor Yellow
        $Readhost = Read-Host
        Switch ($ReadHost)
        {
                1 {Write-host "`r`nInitiating DISM Component Cleanup"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase}
                2 {Write-host "`r`nInitiating DISM SPSuperseded"; dism.exe /online /Cleanup-Image /SPSuperseded}
                3 {Write-host "`r`nInitiating DISM Component Cleanup and SP Superseded"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase; dism.exe /online /Cleanup-Image /SPSuperseded}
                Default {Write-Host "`r`nNone of the above actions will be initiated`r`n"}
        }
    }

Function Win2016

    {
        Cleanup

        Write-host "`r`nDISM (Deployment Image Servicing and Management)`r`n`r`n(1) Initiate DISM Component Cleanup`r`n(2) Initiate DISM SP Superseded`r`n(3) Initiate DISM Component Cleanup and SP Superseded`r`n(4) Initiate Disk Cleanup`r`n`r`nHit any other key to proceed with none of the above`r`n" -ForegroundColor Yellow
        $Readhost = Read-Host
        Switch ($ReadHost)
        {
                1 {Write-host "`r`nInitiating DISM Component Cleanup"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase}
                2 {Write-host "`r`nInitiating DISM SPSuperseded"; dism.exe /online /Cleanup-Image /SPSuperseded}
                3 {Write-host "`r`nInitiating DISM Component Cleanup and SP Superseded"; dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase; dism.exe /online /Cleanup-Image /SPSuperseded}
                4 {Write-Host "`r`nInitiating Disk Cleanup"; cleanmgr.exe}
                Default {Write-Host "`r`nNone of the above actions will be initiated`r`n"}
        }
    }

Clear-Host

Start-Transcript -Path C:\Windows\Temp\$LogDate.log

function global:Write-Verbose ( [string]$Message )

# check $VerbosePreference variable, and turns -Verbose on
{ if ( $VerbosePreference -ne 'SilentlyContinue' )
{ Write-Host " $Message" -ForegroundColor 'Yellow' } }

$VerbosePreference = "Continue"
$DaysToDelete = 7
$LogDate = get-date -format "MM-d-yy-HH"
$objShell = New-Object -ComObject Shell.Application 
$objFolder = $objShell.Namespace(0xA)
$ErrorActionPreference = "silentlycontinue"

$size = Get-ChildItem C:\Users\* -Include *.iso, *.vhd -Recurse -ErrorAction SilentlyContinue | 
Sort Length -Descending | 
Select-Object Name, Directory,
@{Name="Size (GB)";Expression={ "{0:N2}" -f ($_.Length / 1GB) }} |
Format-Table -AutoSize | Out-String

$Before = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName,
@{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
@{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
@{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } },
@{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } |
Format-Table -AutoSize | Out-String 

#Checking OS Version
$OSver=Get-WmiObject Win32_OperatingSystem

    If($(Test-Path "$env:systemdrive\Program Files (x86)") -eq "True")
        {
            $OSarch="64-bit"
        }
    Else
        {
            $OSarch="32-bit"
        }

    #Calling OS Version function
    Switch -Wildcard ($OSver.version)
        {
        "10.0*" {Win2016}
        "6.3*" {Win2012R2}
        "6.2*" {Win2012}
        "6.1*" {Win2008R2}
        }

"`r`nHostname:`t$env:COMPUTERNAME`r`n"
Write-Verbose "Before:`r`n$Before"
Write-Verbose $sizen

AfterSize

Stop-Transcript
