# @('mmcc\denzil.brown', 'mmcc\anthony.ross') | ForEach {
Write-Host "Adding users to group: $RemoteDesktopGroup"
$Users.Split(",") | ForEach {
  try
  {
    Write-Host "Current user: $_"
    Add-LocalGroupMember -Group $RemoteDesktopGroup -Member $_  
    Write-Host "User $_ added successfully."
  }
  catch [Microsoft.PowerShell.Commands.MemberExistsException] {
    Write-Host "[$($_.Exception.Message)]"
	}	
  catch 
  {  #ensuring this snippet doesnt break the build, just because a user hasn't been added. Issue a warning.
      Write-Warning "[$($_.Exception.Message)]"  
  }
}
