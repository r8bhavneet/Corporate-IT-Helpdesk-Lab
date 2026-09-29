<#
.SYNOPSIS
    Bulk-provisions employees from a CSV file.

.DESCRIPTION
    - Validates that the CSV has the required columns before making any changes.
    - Creates each user in their department OU and adds them to GRP-<Department>.
    - Skips users that already exist, so it is safe to re-run after adding new hires.
    - Prompts for the initial password instead of storing it in the script.
    - Forces a password change at first sign-in.

    Required CSV columns: First, Last, Username, Department, Title
    Department values must match an OU under Contoso\Users (IT, Sales, Finance, HR).

.EXAMPLE
    .\03-Import-Users.ps1 -CsvPath C:\Lab\users.csv
#>

param(
    [string]$CsvPath = 'C:\Lab\users.csv'
)

$Domain  = Get-ADDomain
$UsersOU = "OU=Users,OU=Contoso,$($Domain.DistinguishedName)"

$rows = Import-Csv -Path $CsvPath
$required = 'First', 'Last', 'Username', 'Department', 'Title'
$missing  = $required | Where-Object { $_ -notin $rows[0].PSObject.Properties.Name }
if ($missing) { throw "CSV is missing required column(s): $($missing -join ', ')" }

$initialPassword = Read-Host -AsSecureString 'Initial password for new users'

foreach ($row in $rows) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($row.Username)'") {
        Write-Host "Skipping $($row.Username) - already exists" -ForegroundColor Yellow
    }
    else {
        $displayName = "$($row.First) $($row.Last)"
        $userParams = @{
            Name                  = $displayName
            DisplayName           = $displayName
            GivenName             = $row.First
            Surname               = $row.Last
            SamAccountName        = $row.Username
            UserPrincipalName     = "$($row.Username)@$($Domain.DNSRoot)"
            Department            = $row.Department
            Title                 = $row.Title
            Path                  = "OU=$($row.Department),$UsersOU"
            AccountPassword       = $initialPassword
            ChangePasswordAtLogon = $true
            Enabled               = $true
        }
        New-ADUser @userParams
        Write-Host "Created  $($row.Username) in $($row.Department)" -ForegroundColor Green
    }

    Add-ADGroupMember -Identity "GRP-$($row.Department)" -Members $row.Username
}

Get-ADUser -Filter * -SearchBase $UsersOU -Properties Department |
    Sort-Object Department, Name |
    Format-Table Name, SamAccountName, Department -AutoSize
