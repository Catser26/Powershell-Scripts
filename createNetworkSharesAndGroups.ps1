# Run Script on CO1vn
# Dict erstellen für zugriffsrechte etc.
$initials = "PD"
$number = "19"
$domainNetBIOS = $initials + $number
$domain = "DC=$domainNetBIOS,DC=FH,DC=LOCAL"
$baseOU = "OU=Firma"
$treeLocation = "$baseOU,$domain"

$helpdeskDeclaration = "Helpdesk" #alternativ HD
$mitarbeiterDeclaration = "Mitarbeiter" #alternativ MA
$abteilungen = @(
    @{ 
        "Name" = "Handel"; 
        "Full" = @("Domain Admins", "Handel-$helpdeskDeclaration");
        "Modify" = @("Handel-$mitarbeiterDeclaration");
        "ReadAndExecute" = @("-$helpdeskDeclaration")
    }, 
    @{ 
        "Name" = "Verwaltung";
        "Full" = @("Domain Admins", "Verwaltung-$helpdeskDeclaration");
        "Modify" = @("Verwaltung.-$mitarbeiterDeclaration");
        "ReadAndExecute" = @("-$helpdeskDeclaration")
    }, 
    @{ 
        "Name" = "Produktion";
        "Full" = @("Domain Admins", "Produktion-$helpdeskDeclaration");
        "Modify" = @("Produktion-$mitarbeiterDeclaration");
        "ReadAndExecute" = @("-$helpdeskDeclaration")
    }, 
    @{ 
        "Name" = "IT-Admin";
        "Full" = @("Domain Admins", "IT-Admin");
        "Modify" = @();
        "ReadAndExecute" = @("-$helpdeskDeclaration")
    }
)



foreach ($abteilung in $abteilungen) {
    $name = $abteilung.Name
    $fullAccessGroup = "FullAccess-$name-Share"
    $modifyGroup = "Modify-$name-Share"
    $readExecuteGroup = "ReadAndExecute-$name-Share"
    $pathToSubOU = "OU=$name,$treeLocation"
    $pathToGroupOU = "OU=Gruppen,$pathToSubOU"

    # Create new Domain Local Groups for Access Control / Skip if already exists
    $accessGroups = @(
        $fullAccessGroup, 
        $modifyGroup, 
        $readExecuteGroup
    )

    foreach ($group in $accessGroups) {
            try {
                New-ADGroup -Name $group -GroupCategory Security -GroupScope DomainLocal -Path $pathToGroupOU
            } catch {
                Write-Host "An error occurred while creating the AD group: $_"
            }
    }

    $adGroups = Get-ADGroup -Filter {Name -like "G-*" -and Name -notlike "DL-*"}
    foreach ($group in $abteilung.Full) {
        if (-NOT $group.Equals("Domain Admins")) 
        {
            $resolvedGroupName = ($adGroups | ? {$_.Name.Contains($group)}).Name
        } 
        else {$resolvedGroupName = $group}
        Add-ADGroupMember -Identity $fullAccessGroup -Members $resolvedGroupName
    }
    foreach ($group in $abteilung.Modify) {
        if (-NOT $group.Equals("Domain Admins")) 
        {
            $resolvedGroupName = ($adGroups | ? {$_.Name.Contains($group)}).Name
        } 
        else {$resolvedGroupName = $group}
        Add-ADGroupMember -Identity $modifyGroup -Members $resolvedGroupName
    }
    foreach ($group in $abteilung.ReadAndExecute) {
        if (-NOT $group.Equals("Domain Admins")) 
        {
            $resolvedGroupName = ($adGroups | ? {$_.Name.Contains($group) -and -not $_.Name.Contains($name)}).Name
        } 
        else {$resolvedGroupName = $group}
        Add-ADGroupMember -Identity $readExecuteGroup -Members $resolvedGroupName
    }

    $folder = "share_" + $abteilung.Name
    $path = "c:\" + $folder

    # Network Share
    New-Item -Path "c:\" -Name $folder -ItemType "directory"
    New-SmbShare -Name $abteilung.Name -Path $path -FullAccess "NT AUTHORITY\Authenticated Users"
    
    # NTFS Permissions
    # Disable NTFS Inheritance
    Disable-NTFSAccessInheritance -Path $path -RemoveInheritedAccessRules
    
    # Add AccessRights
    Add-NTFSAccess -Path $path -Account "$domainNetBIOS\$fullAccessGroup" -AccessRights Full
    Add-NTFSAccess -Path $path -Account "$domainNetBIOS\$modifyGroup" -AccessRights Modify
    Add-NTFSAccess -Path $path -Account "$domainNetBIOS\$readExecuteGroup" -AccessRights ReadAndExecute
}