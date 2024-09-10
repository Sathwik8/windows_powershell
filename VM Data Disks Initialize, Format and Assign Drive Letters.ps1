function Get-MCNextAvailableDriveLetter {

    # Ref: https://www.reddit.com/r/PowerShell/comments/9xof8x/alphabet_to_array/
    $driveLetters = [char[]]('D'[0]..'Y'[0])
    $nextAvailableDriveLetter = $driveLetters[0]

    $assignedVolumeLetters = (Get-Volume).DriveLetter
    foreach($letter in $driveLetters) {
    
        if($letter -notin $assignedVolumeLetters) {
            $nextAvailableDriveLetter = $letter
            break
        }
    }

    $nextAvailableDriveLetter
}

function Initialize-MCDataDisks {
<#
    .SYNOPSIS

    .DESCRIPTION

#>

    $fn = $MyInvocation.MyCommand.Name

    $VMName = $env:COMPUTERNAME
    $useMaximumSize = $true
    $rawDisks = Get-Disk | Where-Object -Property 'PartitionStyle' -EQ RAW # Gets all unpartitioned disks
    
    $isCDRomPresent = (Get-WmiObject -Class Win32_volume -Filter 'DriveType=5') -ne $null

    if($isCDRomPresent) {
        Write-output "[$fn] CD-ROM drive found...Moving it to Z: ..."
        Get-WmiObject -Class Win32_volume -Filter 'DriveType=5' | Select-Object -First 1 | Set-WmiInstance -Arguments @{DriveLetter = 'Z:' } | Out-Null
    }

    foreach($disk in $rawDisks) {
        
        try {
            Write-Output "[$fn] Initializing disk $($disk.Number) as GPT PartitionStyle"
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT  # Initializes the specified disk (4 for example) and makes it available for further actions

            $diskLabel = "DataDisk_{0}" -f $disk.Number 

            Write-Output "Stopping Hardware detection service (ShellHWDetection) to prevent GUI popups when formatting..."
            Stop-Service -Name ShellHWDetection -Force

            Write-Output "Creating new partition and formating..."
            $driveLetter = Get-MCNextAvailableDriveLetter
            New-Partition -DiskNumber $disk.DiskNumber -DriveLetter $driveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel $diskLabel
                       
            Write-Output "Re-starting HW Detection service (ShellHWDetection) ..."
            Start-Service -Name ShellHWDetection

            Write-Output "[$fn] Disk $($disk.Number) was formatted and assigned drive letter '$driveLetter'"
        }
        catch {
        
            $_
        }    
    }   
}

Initialize-MCDataDisks
