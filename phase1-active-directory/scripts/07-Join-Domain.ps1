<#
.SYNOPSIS
    Joins CLIENT01 to corp.contosolabs.com and places it in the Contoso\Computers OU.

.DESCRIPTION
    Run on CLIENT01 in an elevated PowerShell session. Prompts for domain admin credentials,
    then restarts the computer.

    Check the adapter name first with Get-NetAdapter if it is not "Ethernet".
#>

$InterfaceAlias = 'Ethernet'
$DnsServer      = '10.10.10.10'
$DomainName     = 'corp.contosolabs.com'
$ComputersOU    = 'OU=Computers,OU=Contoso,DC=corp,DC=contosolabs,DC=com'

Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DnsServer

Add-Computer -DomainName $DomainName -OUPath $ComputersOU `
    -Credential (Get-Credential -Message 'Domain admin credentials' -UserName 'CONTOSO\adm-bhavneet') `
    -Restart
