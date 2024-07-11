# Define the input file path and CSV output file path
$inputFilePath = "C:\Users\Default\Desktop\serverlist.txt"
$outputFilePath = "C:\Users\Default\Desktop\ChromeRemovalResults.csv"

<#$regPaths = 
"HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall",
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

$Chromepath = 
"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
"C:\Program Files\Google\Chrome\Application\chrome.exe" #>
 
# Create an empty array to store the results
$results = @()
 
# Read the server names from the input file
$servers = Get-Content -Path $inputFilePath
 
# Loop through each server
foreach ($server in $servers) {
<#
$regPaths = 
"HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall",
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

$Chromepath = 
"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
"C:\Program Files\Google\Chrome\Application\chrome.exe"

    # Create a new PSObject to store the results for this server
    $serverResult = [PSCustomObject]@{
        ServerName = $server
        ChromeInstalled = $false
        ChromeUninstalled = $false
        ChromeFolderDeleted = $false
    } #>
 
    # Use the ScriptBlock command to run the script on the remote server
    $scriptBlock = {

    $regPaths = 
"HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall",
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

$Chromepath = 
"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
"C:\Program Files\Google\Chrome\Application\chrome.exe"

        $serverResult = [PSCustomObject]@{
        ServerName = $server
        ChromeInstalled = $false
        ChromeUninstalled = $false
        ChromeFolderDeleted = $false
    }
        # Check if Chrome is installed using the registry
        $chromeInstalled = $regPaths | Foreach-Object {Get-ItemProperty -Path "${_}\*" | Where-Object {
      $_.DisplayName -eq 'Google Chrome'} } -ErrorAction SilentlyContinue
        if ($chromeInstalled) {
            $serverResult.ChromeInstalled = $true
            Get-Process -Name "chrome" -EA Ignore | Stop-Process -Force -Verbose
            # Uninstall Chrome
                 $productCodes = @( $regPaths | Foreach-Object {
                    Get-ItemProperty "${_}\*" | Where-Object {
                      $_.DisplayName -eq 'Google Chrome'
                    }
                  } ).PSPath
                  Write-Host "Found Chrome at Registry $productCodes"

                  $productCodes | ForEach-Object {
                  $uninstallString = "$(( Get-ItemProperty $_).UninstallString )  --force-uninstall"
                  cmd /c $uninstallString
                  }
                  #& "$uninstallString"
                  #Start-Process -FilePath $uninstallString -ArgumentList "/S" -Wait

            if ($uninstallString.ExitCode -eq 0) {
                $serverResult.ChromeUninstalled = $true

                Write-Host "Chrome is uninstalled successfully from $server"
            }
        }
 
        # Check if the Chrome folder exists in Program Files and Program Files (x86)
        $chromeFolderPaths = @(
            "C:\Program Files\Google\Chrome"
            "C:\Program Files (x86)\Google\Chrome"
        )
      #  foreach ($folderPath in $chromeFolderPaths) {
      #      if (Test-Path -Path $folderPath) {
      #          Remove-Item -Path $folderPath -Recurse -Force
      #          $serverResult.ChromeFolderDeleted = $true
      #      }
     #   }
    }
 
    # Run the script block on the remote server
    Invoke-Command -ComputerName $server -ScriptBlock $scriptBlock
 
    # Add the server result to the results array
    $results += $serverResult
}
 
# Export the results to a CSV file
$results | Export-Csv -Path $outputFilePath -NoTypeInformation
