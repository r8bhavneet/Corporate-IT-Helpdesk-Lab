<#
.SYNOPSIS
    Configures DC01 and promotes it to the first domain controller of corp.contosolabs.com.

.DESCRIPTION
    The server restarts during this process, so the work is split into stages.
    Run each stage in order from an elevated Windows PowerShell session on DC01.

.EXAMPLE
    .\01-Configure-DomainController.ps1 -Stage Rename
    .\01-Configure-DomainController.ps1 -Stage Prepare
    .\01-Configure-DomainController.ps1 -Stage Promote
    .\01-Configure-DomainController.ps1 -Stage PostConfig
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Rename', 'Prepare', 'Promote', 'PostConfig')]
    [string]$Stage
)

$ComputerName   = 'DC01'
$InterfaceAlias = 'Ethernet'
$IPAddress      = '10.10.10.10'
$PrefixLength   = 24
$Gateway        = '10.10.10.1'
$DnsForwarder   = '1.1.1.1'
$DomainName     = 'corp.contosolabs.com'
$NetbiosName    = 'CONTOSO'

switch ($Stage) {
    'Rename' {
        # Server restarts after the rename.
        Rename-Computer -NewName $ComputerName -Restart
    }
    'Prepare' {
        # Static IP, temporary public DNS, and the AD DS role.
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $Gateway
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DnsForwarder
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    }
    'Promote' {
        # Creates the forest with integrated DNS. Prompts for the DSRM password, then restarts.
        Install-ADDSForest -DomainName $DomainName -DomainNetbiosName $NetbiosName -InstallDns
    }
    'PostConfig' {
        # Point DNS at this DC and forward external lookups.
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses 127.0.0.1
        Add-DnsServerForwarder -IPAddress $DnsForwarder
        Get-ADDomain | Select-Object DNSRoot, NetBIOSName, PDCEmulator
    }
}
