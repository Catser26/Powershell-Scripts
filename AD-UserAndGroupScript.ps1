# Run the script and type the password (empty line at the bottom of the powershell)
$userpassword = Read-Host -AsSecureString

$number = "19"
$groupmembers = @{ Groupname = "Admins"; Member = "NewAdmin" }, @{ Groupname = "PowerUser"; Member = "NewPowerUser" }, @{ Groupname = "0815"; Member = "NewUser" }

foreach ($pair in $groupmembers)
{
    $username = $pair.Member
    $groupname = $pair.Groupname
    New-ADGroup -Name $number"-"$groupname -GroupCategory Security -GroupScope Global
    New-ADUser -Name $username -SamAccountName $username -UserPrincipalName "$username@pd19.fh.local" -GivenName $username -Surname "User" -AccountPassword $userpassword -Enabled $true -PasswordNeverExpires $true
    Add-ADGroupMember -Identity $number"-"$groupname -Members $username
}

# Add the group 19-Admins to the Domain Admins group
$domainAdminsGroup = "Domain Admins"
$groupToAdd = $number + "-Admins"
Add-ADGroupMember -Identity $domainAdminsGroup -Members $groupToAdd

# Die Domänenlokale Gruppe "Vollzugriff is23" wird erstellt
New-ADGroup -Name "Vollzugriff is23" -GroupCategory Security -GroupScope DomainLocal

# Die Gruppen 19-Admins und 19-PowerUser werden zu der Gruppe "Vollzugriff is23" hinzugefügt
Add-ADGroupMember -Identity "Vollzugriff is23" -Members "19-PowerUser"
Add-ADGroupMember -Identity "Vollzugriff is23" -Members "Domain Admins"


# Die Domänenlokale Gruppe Vollzugriff is23 in die SMB-Freigabe einfügen
Invoke-Command -ComputerName MS1PD -ScriptBlock {
    $path = "D:\is23"
    $dlGroup = "PD19\Vollzugriff is23"

    Grant-SmbShareAccess -Name is23 -AccountName $dlGroup -AccessRight Full -Force

    # SMB Rechte für Lokale Gruppen entfernen (eventuell unnötig)
    #$otherSMBPermissions = ((Get-SmbShareAccess -Name is23).AccountName -notlike "*Vollzugriff is23*") 
    #foreach ( $permission in $otherSMBPermissions ) {
    #    Revoke-SmbShareAccess -Name "is23" -AccountName $permission -Force
    #}

    # NTFS Rechte
    $acl = Get-Acl -Path $path
    $groups = $acl.Access

    # NTFS Rechte werden bereinigt
    foreach ($group in $groups) {
        $acl.RemoveAccessRule($group)
    }

    # Variabeln um den "New-Object" command kurz zu halten
    $aclType = "System.Security.AccessControl.FileSystemAccessRule"
    $ArgumentList = $dlGroup, "FullControl", "Allow"

    $newAclObject = New-Object -TypeName $aclType -ArgumentList $ArgumentList
    $acl.SetAccessRule($newAclObject)

    Set-Acl -Path $path -AclObject $acl
    (Get-Acl -Path $path).Access
}

# Einen Drucker hinzufügen
#IP Adresse von der Vergabe exkludieren
$IPAddress = "10.23.19.200"
Invoke-Command -ComputerName CO1PD -ArgumentList $IPAddress -ScriptBlock {
    param($IPAddress)
    $scope = Get-DhcpServerv4Scope
    $scopeId = $scope.ScopeId
    Add-DhcpServerv4ExclusionRange -ScopeId $scopeId -StartRange $IPAddress -EndRange $IPAddress   
} 

$printerName = "Fiktiver Drucker"
$driver = "Generic / Text Only"
$IPAddress = "10.23.19.200"

Add-Printer -Name $printerName -DriverName $driver -PortName $IPAddress 
Add-PrinterPort -Name $IPAddress -PrinterHostAddress $IPAddress

# Der Parameter -Shared wirft bei der Erstellung des Druckers einen Fehler
Set-Printer -Name $printerName -Shared $true

$groupName = "Druckerzugriff PD19"
New-ADGroup -Name $groupName -GroupCategory Security -GroupScope DomainLocal
Add-ADGroupMember -Identity $groupName  -Members "19-0815"

# Printer Rollen im GUI einrichten, da es ohne template schwer umzusetzen ist.
# Das erstellte Template kann jedoch mittels folgender Befehle exportiert werden um eventuell auf weiteren Druckern implementiert zu werden.
# $printerPermissions = (Get-Printer -Name $printerName -Full).PermissionSDDL