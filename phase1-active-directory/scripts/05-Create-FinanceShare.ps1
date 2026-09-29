<#
.SYNOPSIS
    Creates the Finance file share with share and NTFS permissions for GRP-Finance.

.DESCRIPTION
    Share permission: GRP-Finance - Change
    NTFS permission:  GRP-Finance - Modify, inherited by subfolders and files
    Effective access is the more restrictive of the two.

    Lab note: in production, file shares belong on a dedicated file server, not a domain controller.
#>

$SharePath = 'C:\Shares\Finance'
$ShareName = 'Finance'
$Group     = 'CONTOSO\GRP-Finance'

New-Item -Path $SharePath -ItemType Directory -Force | Out-Null

if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $ShareName -Path $SharePath -ChangeAccess $Group | Out-Null
    Write-Host "Created share \\$env:COMPUTERNAME\$ShareName" -ForegroundColor Green
}

# (OI)(CI) = inherit to files and subfolders, M = Modify
icacls $SharePath /grant "${Group}:(OI)(CI)M" | Out-Null

Get-SmbShareAccess -Name $ShareName
icacls $SharePath
