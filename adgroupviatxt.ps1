<#
#### requires ps-version 3.0 ####
<#
.SYNOPSIS
adds users from txt files to active directory groups
.DESCRIPTION
adds users from txt files to active directory groups
.PARAMETER
no parameters allowed
.INPUTS
logpath, groupprefixes
.OUTPUTS
logfiles with date
.NOTES
   Version:        0.1
   Author:         Alexander Koehler
   Creation Date:  Friday, October 18th 2019, 7:03:46 pm
   File: ad-group-fill-txt.ps1
   Copyright (c) 2019 blog.it-koehler.com
HISTORY:
Date      	          By	Comments
----------	          ---	----------------------------------------------------------

.LINK
   https://blog.it-koehler.com/en/

.COMPONENT
 Required Modules: ActiveDirectory

.LICENSE
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the Software), to deal
in the Software without restriction, including without limitation the rights
to use copy, modify, merge, publish, distribute sublicense and /or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 
.EXAMPLE
none


#>
$path1 = "\\dc01\adgroup\*.txt"
$logpath = "C:\temp\group-log-"
$adgroupprefix = "g-demo-"
####################################################
#convert date and time to string
$date=((Get-Date).ToString('yyyy-MM-dd-HH-mm-ss'))
$Logfile = $logpath+$date+".log"


#---------------------------------------------------------[Functions]--------------------------------------------------------
Function Write-Log
{
  Param ([string]$logstring)

  Add-content $Logfile -value $logstring
}
#checking module if its installed
function Get-InstalledModule {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$modulename
    )
    Write-Verbose "Checking if module $modulename is installed correctly"
    if (Get-Module -ListAvailable -Name $modulename) {
      $Script:moduleavailable = $true
      Write-Verbose "Module $modulename found successfully!"
      Write-Log "Module $modulename found successfully!"
    } 
    else {
      Write-Verbose "Module $modulename not found!"
      Write-Log "Module $modulename not found! Script terminated!"
      throw "Module $modulename is not installed or does not exist, please install and retry.
      In an administrative Powershell console try typing: Install-Module $modulename"
    }
  
  }
#checking if module is imported, if not; load it
function Get-ImportedModule {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$modulename
    )
         #check if module is imported, otherwise try to import it
         if (Get-Module -Name $modulename) {
            Write-Verbose "Module $modulename already loaded"
            Write-Verbose "Getting cmdlets from module"
            #write output to variable to get all cmdlets
            $global:commands = Get-Command -Module $modulename | Format-Table -AutoSize -Wrap
            Write-Verbose "Cmdlets stored in variable commands"

        }
        else {
            Write-Verbose "Module found but not imported, import starting"
            Import-Module $modulename -force
            Write-Verbose "Module $modulename loaded successfully"
            Write-Log "Module $modulename loaded successfully"
            #write output to variable to get all cmdlets
            Write-Verbose "Getting cmdlets from module"
            $global:commands = Get-Command -Module $modulename | Format-Table -AutoSize -Wrap
            Write-Verbose "Cmdlets stored in variable commands"
           
        }
  }
  ### check if ad users exists, returns variable exists which is true or false
  function Check-ADUser{
  [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$aduser
    )
  $User = $(try {Get-ADUser $aduser} catch {$null})
  Write-Verbose "Trying to find user in active directory..."
  
  If ($User -ne $Null)
   
   {
    "Usercheck for $aduser successful!"
    $global:exists = $true 
    Write-Log "Usercheck for $aduser successful!"
    Write-Verbose "Usercheck for $aduser successful!"
     } 
Else 
    {
    
    Write-Host "User $aduser not found, please check username!" -ForegroundColor Red
    $global:exists = $false
    Write-Log "User $aduser not found, please check username!"
    Write-Verbose "User $aduser not found, please check username!"
    }
  }

  function Check-ADGroup{
    [CmdletBinding()]
      param(
        [Parameter(Mandatory = $true)]
        [string]$groupinad
      )
    $group = $(try {Get-ADGroup $groupinad} catch {$null})
    Write-Verbose "Trying to find ad group in active directory..."
    
    If ($group -ne $Null)
     
     {
      "groupcheck for $groupinad successful!"
      $global:groupexists = $true 
      Write-Log "Groupcheck for $groupinad  successful!"
      Write-Verbose "Groupcheck for $groupinad successful!"
       } 
  Else 
      {
      
      Write-Host "AD Group $groupinad  not found, please check groupname!" -ForegroundColor Red
      $global:groupexists = $false
      Write-Log "AD Group $groupinad not found, please check groupname!"
      Write-Verbose "AD Group $groupinad not found, please check groupname!"
      }
    }
  ### getting all files in path
  function Get-Files{
  [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$filepath
    )

    $global:files = Get-ChildItem -Path $filepath -Recurse
    Write-Log "Searching for files in path: $filepath "

    }
  #call functions for module
    Get-InstalledModule -modulename ActiveDirectory
    Get-ImportedModule -modulename ActiveDirectory 
  ### get all files stored 
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


