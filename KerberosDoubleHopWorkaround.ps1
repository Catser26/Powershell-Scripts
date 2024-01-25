Add-WindowsFeature RSAT-AD-PowerShell

Import-Module ActiveDirectory

Get-Command -ParameterName PrincipalsAllowedToDelegateToAccount

# Set up variables for reuse            
$ServerA = $env:COMPUTERNAME  
$ServerB = Get-ADComputer -Identity CO1PD         
$ServerC = $ServerA            

# Notice the StartName property of the WinRM Service: NT AUTHORITY\NetworkService            
# This looks like the ServerB computer account when accessing other servers over the network.            
Get-WmiObject Win32_Service -Filter 'Name="winrm"' -ComputerName $ServerB.name | fl *


# Grant resource-based Kerberos constrained delegation            
Set-ADComputer -Identity $ServerC -PrincipalsAllowedToDelegateToAccount $ServerB            
            
# Check the value of the attribute directly            
$x = Get-ADComputer -Identity $ServerC -Properties msDS-AllowedToActOnBehalfOfOtherIdentity            
$x.'msDS-AllowedToActOnBehalfOfOtherIdentity'.Access            
            
# Check the value of the attribute indirectly            
Get-ADComputer -Identity $ServerC -Properties PrincipalsAllowedToDelegateToAccount

Invoke-Command -ComputerName $ServerB.name -ScriptBlock | { Add-DhcpServerInDC -DnsName "co1pd.pd19.fh.local" -IPAddress "10.23.19.3" }

Invoke-Command -ComputerName $ServerB.Name -Credential PD19\Administrator -ScriptBlock {            
    klist purge -li 0x3e7            
}



