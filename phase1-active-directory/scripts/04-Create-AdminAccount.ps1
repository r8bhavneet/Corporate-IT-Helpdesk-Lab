<#
.SYNOPSIS
    Creates a named administrator account in the Admin Accounts OU and adds it to Domain Admins.

.DESCRIPTION
    Used for administration instead of the built-in Administrator account (least privilege,
    per-person audit trail). Prompts for the password at runtime.

.EXAMPLE
    .\04-Create-AdminAccount.ps1 -SamAccountName adm-bhavneet -GivenName Bhavneet -Surname Rajpal
#>

param(
    [string]$SamAccountName = 'adm-bhavneet',
    [string]$GivenName      = 'Bhavneet',
    [string]$Surname        = 'Rajpal'
)

$Domain  = Get-ADDomain
$AdminOU = "OU=Admin Accounts,OU=Contoso,$($Domain.DistinguishedName)"
$name    = "$GivenName $Surname (Admin)"

if (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'") {
    Write-Host "$SamAccountName already exists" -ForegroundColor Yellow
}
else {
    $password = Read-Host -AsSecureString "Password for $SamAccountName"
    New-ADUser -Name $name -DisplayName $name -GivenName $GivenName -Surname $Surname `
        -SamAccountName $SamAccountName -UserPrincipalName "$SamAccountName@$($Domain.DNSRoot)" `
        -Path $AdminOU -AccountPassword $password -Enabled $true
    Write-Host "Created $SamAccountName" -ForegroundColor Green
}

Add-ADGroupMember -Identity 'Domain Admins' -Members $SamAccountName
Get-ADGroupMember -Identity 'Domain Admins' | Select-Object Name, SamAccountName
