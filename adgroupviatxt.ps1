Get-Files -filepath $path1
## get content of every file and its name 
foreach($file in $files){
$name = ($file).Name.ToString()
$noextension = ($name.Substring(0,$name.Length-4))
$path = ($file).FullName
$adgroup = $adgroupprefix+$noextension
$samaccounts = Get-Content "$path"
Write-Log " " 
Write-Log "### $adgroup ###"
Check-ADGroup "$adgroup"
if($groupexists -eq $true){
Write-Host "### $adgroup ###"
### get all user from ad group and remove them
$tempmembers = Get-ADGroupmember -Identity $adgroup 
foreach($tempmember in $tempmembers){
    $name = ($tempmember).name
    Write-Host "Removing user: $name" -ForegroundColor Green
    Write-Log "Removing user: $name"
    Remove-ADGroupMember -Identity $adgroup -Members $tempmember -Confirm:$false
}
### adding all users from txt files 
foreach ($newmember in $samaccounts){
  #use function to test if ad user exists  
  Check-ADUser $newmember
    if($exists -eq $true)
    {
    Write-host "Adding $newmember to $adgroup" -ForegroundColor Green
    Write-Log "Adding $newmember to $adgroup"
    Add-ADGroupMember -Identity $adgroup -Members $newmember 
    }
    else
    {
    Write-host "Can not add User $newmember because not found in ActiveDirectory" -ForegroundColor Red
    Write-Log "Can not add User $newmember because not found in ActiveDirectory"   
    }
   }
  }
}
