# Install DHCP Server feature
Invoke-Command -ComputerName $ServerB.name -ScriptBlock { 
    Install-WindowsFeature -Name DHCP -IncludeManagementTools 
    netsh dhcp add securitygroups
    Restart-Service dhcpserver

    # Configure DHCP Server
    Import-Module -Name DHCPServer
}

Invoke-Command -ComputerName $ServerB.name -ScriptBlock { Add-DhcpServerInDC -DnsName "co1pd.pd19.fh.local" -IPAddress "10.23.19.3" }

Invoke-Command -ComputerName $ServerB.Name -Credential PD19\Administrator -ScriptBlock {            
    klist purge -li 0x3e7            
}

Invoke-Command -ComputerName $ServerB.name -ScriptBlock {
    # Configure DHCP Server
    $serverDNSName = "co1pd.pd19.fh.local"
    $scopeName = "PD19-DHCP-SCOPE"
    $range = "10.23.19.1", "10.23.19.254"
    $excludedAddresses = "10.23.19.1", "10.23.19.2", "10.23.19.3"
    $subnetMask = "255.255.255.0"
    $defaultGateway = "10.23.19.1"
    $dnsServer = "10.23.19.1", "10.23.19.3"
    $leaseDuration = "2.00:00:00"

    Add-DhcpServerv4Scope -Name $scopeName -StartRange $range[0] -EndRange $range[1] -SubnetMask $subnetMask -State Active -LeaseDuration $leaseDuration
    $scope = Get-DhcpServerv4Scope
    $scopeId = $scope.ScopeId

    Set-DhcpServerv4OptionValue -OptionId 3 -Value $defaultGateway -ScopeId $scopeId
    Set-DhcpServerv4OptionValue -OptionId 6 -Value $dnsServer -ScopeId $scopeId -Force

    # NetBios Ausschalten
    Set-DhcpServerv4OptionValue -OptionId 1 -VendorClass "Microsoft Windows 2000 Options" -Value 2 -ScopeId $scopeId
    
    # Exkludieren von bereits statisch Vergebenen Addressen
    Add-DhcpServerv4ExclusionRange -ScopeId $scopeId -StartRange $excludedAddresses[0] -EndRange $excludedAddresses[2]

    # Der Server Manager muss informiert werden, dass die Post-Installation-Konfiguration abgeschlossen wurde
    Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2

    # Dynamische Updates vom DHCP Server aktivieren
    Set-DhcpServerv4DnsSetting -ComputerName "CO1PD.pd19.fh.local" -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True
}