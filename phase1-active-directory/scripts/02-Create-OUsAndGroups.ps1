<#
.SYNOPSIS
    Creates the Contoso OU structure and one security group per department.

.DESCRIPTION
    Safe to re-run: existing OUs and groups are skipped.
    Run on DC01 as a Domain Admin.
#>

$DomainDN    = (Get-ADDomain).DistinguishedName
$BaseOU      = "OU=Contoso,$DomainDN"
$TopLevelOUs = 'Users', 'Computers', 'Groups', 'Disabled Users', 'Admin Accounts'
$Departments = 'IT', 'Sales', 'Finance', 'HR'

function New-OUIfMissing {
    param([string]$Name, [string]$Path)
    $dn = "OU=$Name,$Path"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'") {
        Write-Host "Exists:  $dn" -ForegroundColor Yellow
    }
    else {
        New-ADOrganizationalUnit -Name $Name -Path $Path
        Write-Host "Created: $dn" -ForegroundColor Green
    }
}

New-OUIfMissing -Name 'Contoso' -Path $DomainDN
foreach ($ou in $TopLevelOUs) { New-OUIfMissing -Name $ou -Path $BaseOU }

foreach ($dept in $Departments) {
    New-OUIfMissing -Name $dept -Path "OU=Users,$BaseOU"

    $group = "GRP-$dept"
    if (Get-ADGroup -Filter "Name -eq '$group'") {
        Write-Host "Exists:  $group" -ForegroundColor Yellow
    }
    else {
        New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path "OU=Groups,$BaseOU" -Description "Members of the $dept department"
        Write-Host "Created: $group" -ForegroundColor Green
    }
}
