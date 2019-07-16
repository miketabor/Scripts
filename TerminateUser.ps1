<#
.Synopsis
TerminateUser is used to secure terminated employees user accounts.

.Description

Actions:
- Exports AD Group Memberships to CSV file.
- Move user to "DisabledUsers" OU.
- Remove user from all security groups.
- Reset to random 16-40 character long password.
- Disable AD account.
- Set description to "Disabled CURRENT DATE - USER"

.Parameter TermUser
User Logon Name of User-Object to be terminated

.Example
TerminateUser.ps1 -TermUser Peter.Parker
or
TerminateUser.ps1 'peter.parker'

#>

## PARAMETERS ##
Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [String]$TermUser
)

## MODULES ##
import-module ActiveDirectory


## FUNCTIONS ##
function exportGroupsToCSV
{
    #Exports User Group Memberships to CSV File.
    $target = "\\FILE_SHARE\archived-users\" + $TermUser + ".csv"
    Get-ADPrincipalGroupMembership $TermUser | select name | Export-Csv -path $target
	Write-Host "* " $TermUser "group memberships archived to" $target
}

function moveToDisabledOU
{
    #Move user to DisabledUsers OU.
    Get-ADUser $TermUser| Move-ADObject -TargetPath 'OU=DisabledUsers,DC=DOMAIN,DC=COM'
    Write-Host "* " $TermUser "moved to DisabledUsers OU"
}

function removeFromGroups
{
	#Remove user from all AD User Groups.
    try
    {
        $ADgroups = Get-ADPrincipalGroupMembership -Identity $TermUser | where {$_.Name -ne "Domain Users"}
        #Write-Host "Groups: $ADgroups"

        if ($ADgroups -ne $null)
        {
            #"Removing from groups"
            Remove-ADPrincipalGroupMembership -Identity $TermUser -MemberOf $ADgroups  -Confirm:$false
			Write-Host "* " $TermUser "removed from all AD user groups"
        }
    }
    catch
    {
        Write-Host "$TermUser is not in AD, or script is not functioning properly"
    }
}

function resetPassword
{
	#Set a random 16-40 character password for terminiated user account.
    $ASCI = [char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126))
	$randomString = (1..$(Get-Random -Minimum 16 -Maximum 40) | % {$ASCI | get-random}) -join “”
	$Password = ConvertTo-SecureString -String $randomString -AsPlainText –Force
    Set-ADAccountPassword $TermUser -NewPassword $Password –Reset
	Write-Host "* " $TermUser "password changed to random password"
}

function disableAccount
{
    # Disable User AD Account.
    Disable-ADAccount -Identity $TermUser
	Write-Host "* " $TermUser "AD account disabled"
}

function setTermDescription
{
    #Change Description to "Disabled MM-DD-YYYY - CURRENT USER".
    $terminatedby = $env:username
    $termDate = get-date -uformat "%m-%d-%Y"
    $termUserDesc = "Disabled " + $termDate + " - " + $terminatedby
    set-ADUser $TermUser -Description $termUserDesc 
    Write-Host "* " $TermUser "description set to" $termUserDesc
}

# START ACTIONS, do something already.

exportGroupsToCSV
moveToDisabledOU
removeFromGroups
resetPassword
disableAccount
setTermDescription
Write-Host "##############################################"
Write-Host "#                                            #"
Write-Host "#               User Terminated!             #"
Write-Host "#                                            #"
Write-Host "##############################################"
Write-Host " "
