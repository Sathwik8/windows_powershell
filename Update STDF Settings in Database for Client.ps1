$dbMCPMain = $OctopusParameters["ClientData.CadenceDBName"]
$SQLServer = $OctopusParameters["ClientData.ElcSqlServerValue"]
$SQLUserName = $OctopusParameters["ClientData.DatabaseReadWriteUser"]
$SQLUserPw = $OctopusParameters["ClientData.DatabaseReadWritePassword"]


Try {
  if($StdfConfiguration -eq "Azure"){
      $sqlUpdateCommand = "UPDATE stdfConfiguration SET IsActive = 1 WHERE AssemblyName LIKE '%Azure%';"
      $sqlValidationCommand = "SELECT COUNT(*) from stdfConfiguration WHERE IsActive = 1 AND AssemblyName LIKE '%Azure%';"
  }
  elseif($StdfConfiguration -eq "OnPrem"){
      $sqlUpdateCommand = "UPDATE stdfConfiguration SET IsActive = 1 WHERE AssemblyName LIKE '%SQLVault%';"
      $sqlValidationCommand = "SELECT COUNT(*) from stdfConfiguration WHERE IsActive = 1 AND AssemblyName LIKE '%SQLVault%';"
  }
  elseif($StdfConfiguration -eq "None"){
      $sqlUpdateCommand = "UPDATE stdfConfiguration SET IsActive = 0;"
      $sqlValidationCommand = "SELECT COUNT(*) from stdfConfiguration WHERE IsActive = 0" 
  }
  else {
      Write-Host "STDF Client Database Configuation was not modified. Please try again"
      Break
  }

  Write-Host "Attempting to set DB Connection.."
  $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
  $sqlConnection.ConnectionString = "Server=$SQLServer;Database=$dbMCPMain;Integrated Security=False;User Id=$SQLUserName;password=$SQLUserPw"

  $sqlCommand = New-Object System.Data.SqlClient.SqlCommand
  $sqlCommand.Connection = $sqlConnection
  $sqlCommand.CommandText = $sqlUpdateCommand

  $sqlConnection.Open()
  Write-Host "$dbMCPMain Connected"
  $sqlCommand.ExecuteNonQuery()
  Write-Host "STDF Configuration has been set for $StdfConfiguration in $dbMCPMain"
  
  #execute validation statement
  $sqlCommand.CommandText = $sqlValidationCommand
  $dtValidationQuery = $sqlCommand.BeginExecuteReader()
  $sqlConnection.Close() 
  If (($dtValidationQuery.count) -eq 1) {$sqlSTDFcheck = $true; Write-Host "STDF Configuration has been validated for $StdfConfiguration in $dbMCPMain"}
  Else {$sqlSTDFcheck = $false; Throw "Non-specific error - $($dtValidationQuery.count) ::: $sqlSTDFcheck "}
} 
Catch {
  Write-Host "Failed to Set STDF Configuration for Azure"
}
