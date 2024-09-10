function Add-MCUsersToWindowsGroup {
    [CmdletBinding()]    
    param(
        [string] $DomainUsers,
        [string] $Group
    )
    
    $Users = $DomainUsers.Split(',')
    ForEach ($user in $Users) {
      try {
        Write-Host "Adding user: $user"
        Add-LocalGroupMember -Group $Group -Member $user  
        Write-Host "User $user added successfully."
        Start-Sleep -Seconds 7
      }
      catch [Microsoft.PowerShell.Commands.MemberExistsException] {
        Write-Host "[$($_.Exception.Message)]"
	  }	
      catch {  
        #ensuring this snippet doesnt break the build, just because a user hasn't been added. Issue a warning.
        Write-Warning "[$($_.Exception.Message)]"  
      }
    }
}

Add-MCUsersToWindowsGroup -DomainUsers $Users -Group $AdministratorsGroup
