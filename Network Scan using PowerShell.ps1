# Link - https://www.linkedin.com/pulse/network-scan-using-powershell-aymen-el-jaziri-qnvle/?trackingId=CrtbUo98tRowuoo19MSa3g%3D%3D

 # if you dont specify IP Address here, the script will get automatically address from network card with DHCP attribute
$localIP = ''

# Obtain the IP address of the local machine
if($localIP -eq '')
{ 
    $localIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Dhcp' }).IPAddress
}

# List of common ports to be scanned
$portsToScan = @(20,21,22,23,25,53,80,110,123,143,161,443,445,993,995,3306,3389,5900,8080)

# Extract the first three bytes of the IP address
$networkPrefix = $localIP -replace "(\d+\.\d+\.\d+)\.\d+", '$1'

# Creating a runspace pool
$runspacePool = [runspacefactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 1)
$runspacePool.Open()


# Script Block will scan for connected machine and opned ports
$scriptBlock = {
    param($ip, $ports)
    #$ip = '192.168.50.153'
    #$ports = $portsToScan
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) 
    {
        try {
            $hostName = [System.Net.Dns]::GetHostEntry($ip).HostName
        } catch {
            $hostName = "N/A"
        }
        $macAddress = arp -a $ip | Select-String '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})' | ForEach-Object { $_.Matches.Value }
        #$openPorts = Test-Port -ip $ip -ports $ports

        # Get opned ports for connected machine
        $openPorts = @()
        foreach ($port in $ports) {
            $tcp = New-Object System.Net.Sockets.TcpClient
            try {
                $result = $tcp.BeginConnect($ip, $port, $null, $null)
                $wait = $result.AsyncWaitHandle.WaitOne(300,$false)
                if($wait) {
                    $openPorts += $port
                }
            } finally {
                $tcp.Close()
            }
        }
        
        return [PSCustomObject]@{
            "IP Address" = $ip
            "Hostname" = $hostName
            "MAC Address" = if ($macAddress) { $macAddress } else { "N/A" }
            "Open Ports" = $openPorts
        }
    }
}

# Create and start jobs
$jobs = 1..254 | ForEach-Object {
    $ip = "$networkPrefix.$_"
    $job = [powershell]::Create().AddScript($scriptBlock).AddArgument($ip).AddArgument($portsToScan)
    $job.RunspacePool = $runspacePool
    [PSCustomObject]@{
        Pipe = $job
        Result = $job.BeginInvoke()
    }
}

# Collecting results
$results = @()
$totalJobs = $jobs.Count
$completedJobs = 0

while ($completedJobs -lt $totalJobs) {
    $completedJobs = ($jobs | Where-Object { $_.Result.IsCompleted }).Count
    $percentComplete = ($completedJobs / $totalJobs) * 100
    Write-Progress -Activity "Scanning Network and Ports" -Status "Progress: $completedJobs / $totalJobs" -PercentComplete $percentComplete
    Start-Sleep -Milliseconds 100
}

foreach ($job in $jobs) {
    $result = $job.Pipe.EndInvoke($job.Result)
    if ($result) {
        $results += $result
    }
    $job.Pipe.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()

# Show results
$results | Format-Table -AutoSize

Write-Host "Scan Completed...." -ForegroundColor Green
