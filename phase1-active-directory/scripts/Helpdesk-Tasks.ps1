<#
.SYNOPSIS
    Reusable functions for common helpdesk account tasks.

.DESCRIPTION
    Load the functions into your session by dot-sourcing this file on DC01:

        . .\Helpdesk-Tasks.ps1

    Then run, for example:

        Get-LockedOutUser
        Unlock-ContosoUser -Username jlee
        Reset-ContosoPassword -Username psharma
        Start-ContosoOffboarding -Username jlee
#>

function Get-LockedOutUser {
    # Lists every account that is currently locked out.
    Search-ADAccount -LockedOut -UsersOnly |
        Select-Object Name, SamAccountName, LastLogonDate
}

function Unlock-ContosoUser {
    param([Parameter(Mandatory)][string]$Username)

    Unlock-ADAccount -Identity $Username
    Write-Host "Unlocked $Username" -ForegroundColor Green
}

function Reset-ContosoPassword {
    # Sets a temporary password, forces a change at next sign-in, and clears any lockout.
    param([Parameter(Mandatory)][string]$Username)

    $temp = Read-Host -AsSecureString "Temporary password for $Username"
    Set-ADAccountPassword -Identity $Username -Reset -NewPassword $temp
    Set-ADUser -Identity $Username -ChangePasswordAtLogon $true
    Unlock-ADAccount -Identity $Username
    Write-Host "Password reset for $Username; change required at next sign-in" -ForegroundColor Green
}

function Start-ContosoOffboarding {
    # Disables the account, removes group memberships (listed for the ticket notes),
    # stamps the offboarding date, and moves the account to Disabled Users.
    param([Parameter(Mandatory)][string]$Username)

    $disabledOU = "OU=Disabled Users,OU=Contoso,$((Get-ADDomain).DistinguishedName)"
    $user = Get-ADUser -Identity $Username -Properties MemberOf

    Disable-ADAccount -Identity $user

    foreach ($groupDN in $user.MemberOf) {
        Remove-ADGroupMember -Identity $groupDN -Members $user -Confirm:$false
        Write-Host "Removed from $((Get-ADGroup $groupDN).Name)"
    }

    Set-ADUser -Identity $user -Description "Offboarded $(Get-Date -Format 'yyyy-MM-dd')"
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU

    Write-Host "$Username disabled and moved to Disabled Users" -ForegroundColor Green
}
