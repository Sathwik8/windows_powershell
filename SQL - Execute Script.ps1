$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $OctopusParameters['ConnectionString']
$continueOnError = $($($OctopusParameters['ContinueOnError']).ToLower() -eq 'true')
Register-ObjectEvent -inputobject $connection -eventname InfoMessage -action {
    write-host $event.SourceEventArgs
} | Out-Null

function Execute-SqlQuery($query) {
    $queries = [System.Text.RegularExpressions.Regex]::Split($query, "^\s*GO\s*`$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)

    $queries | ForEach-Object {
        $q = $_
        if ((-not [String]::IsNullOrWhiteSpace($q)) -and ($q.Trim().ToLowerInvariant() -ne "go")) {            
            $command = $connection.CreateCommand()
            $command.CommandText = $q
            $command.CommandTimeout = $OctopusParameters['CommandTimeout']
            $command.ExecuteNonQuery() | Out-Null
        }
    }

}

$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Verbose $event.Message }

try {
	
    Write-Host "Attach InfoMessage event handler"
	$connection.add_InfoMessage($handler)
    
	Write-Host "Connecting"
    $connection.Open()

    Write-Host "Executing script"
    Execute-SqlQuery -query $OctopusParameters['SqlScript']
}
catch {
	if ($continueOnError) {
		Write-Host $_.Exception.Message
	}
	else {
		throw
	}
}
finally {
	
    Write-Host "Detach InfoMessage event handler"
	$connection.remove_InfoMessage($handler)
    Write-Host "Closing connection"
    $connection.Dispose()
}
