<#
.SYNOPSIS
    Creates and links the department GPOs and exports HTML reports of every GPO used in Phase 1.

.DESCRIPTION
    Configured by this script:
      - "Finance - Drive Map"   created and linked to the Finance OU
      - "Sales - Restrictions"  created, linked to the Sales OU, Control Panel blocked

    Configured in the Group Policy Management Editor (no native cmdlet exists for these):
      - Default Domain Policy: minimum password length 12, complexity enabled,
        lockout threshold 5, lockout duration and reset counter 10 minutes,
        Administrator account lockout allowed
      - Finance - Drive Map:   User Configuration > Preferences > Windows Settings > Drive Maps
                               Action Update, \\DC01\Finance, drive F:, label "Finance"
#>

$UsersOU   = "OU=Users,OU=Contoso,$((Get-ADDomain).DistinguishedName)"
$ReportDir = 'C:\Lab\gpo-reports'

function New-LinkedGPO {
    param([string]$Name, [string]$Target)

    try   { Get-GPO -Name $Name -ErrorAction Stop | Out-Null; Write-Host "Exists:  $Name" -ForegroundColor Yellow }
    catch { New-GPO -Name $Name | Out-Null;                   Write-Host "Created: $Name" -ForegroundColor Green }

    $linked = (Get-GPInheritance -Target $Target).GpoLinks | Where-Object DisplayName -eq $Name
    if (-not $linked) {
        New-GPLink -Name $Name -Target $Target | Out-Null
        Write-Host "Linked:  $Name -> $Target" -ForegroundColor Green
    }
}

New-LinkedGPO -Name 'Finance - Drive Map'  -Target "OU=Finance,$UsersOU"
New-LinkedGPO -Name 'Sales - Restrictions' -Target "OU=Sales,$UsersOU"

# "Prohibit access to Control Panel and PC settings"
Set-GPRegistryValue -Name 'Sales - Restrictions' `
    -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
    -ValueName 'NoControlPanel' -Type DWord -Value 1 | Out-Null

# Export readable reports for documentation.
New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null
'Default Domain Policy', 'Finance - Drive Map', 'Sales - Restrictions' | ForEach-Object {
    $file = Join-Path $ReportDir (($_ -replace '[^\w]+', '-') + '.html')
    Get-GPOReport -Name $_ -ReportType Html -Path $file
    Write-Host "Exported report: $file"
}
