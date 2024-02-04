# Get the Interface Index with the command Get-NetIPInterface
$InterfaceAlias = "Ethernet0"
$DefaultGateway4 = "10.23.19.1"
$DefaultGateway6 = "FD23:19::10.23.19.1"
$SecondaryDNS4 = "10.23.19.3"
$SecondaryDNS6 = "FD23:19::10.23.19.3"

$IPv4 = "10.23.19.5"
$Prefixv4 = 24

$IPv6 = "FD23:19::10.23.19.5"
$Prefixv6 = 64

# Set IP Addresses
New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPv4 -PrefixLength $Prefixv4 -DefaultGateway $DefaultGateway4
New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPv6 -PrefixLength $Prefixv6 -DefaultGateway $DefaultGateway6

# Poke holes in the Firewall
New-NetFirewallRule -DisplayName "ICMP Allow Ping V4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow
New-NetFirewallRule -DisplayName "ICMP Allow Ping V6" -Direction Inbound -Protocol ICMPv6 -IcmpType 128 -Action Allow


Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ($DefaultGateway4, $SecondaryDNS4)
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ($DefaultGateway6, $SecondaryDNS6)

#Set-DnsClient -InterfaceAlias $InterfaceAlias -ConnectionSpecificSuffix "pd19.fh.local" -UseSuffixWhenRegistering $True

# Verify the success of the Previous two commands:
Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias

Rename-Computer -NewName MS2PD -Restart