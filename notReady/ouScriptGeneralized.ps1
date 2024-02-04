
#string Structure:
# MainOU/subou1/subsubou1/subsubsubOU3&subsubou2\subou2/subsubou1&subsubou2\subou3/subsubou1&subsubou2
$ouString = "MainOU/subou1/subsubou1/subsubsubOU3&subsubou2\subou2/subsubou1&subsubou2\subou3/subsubou1&subsubou2"

# script work in progress, DO NOT USE IN EXAM :) pls NO

$initials = "PD"
$number = "19"
$baseOU = "Firma"
$basePw = Read-Host -AsSecureString "Password"
$domain = "DC=PD19,DC=FH,DC=LOCAL"

$ouTree = @{
    "Name" = "MainOU";
    "groups" = $null; "users" = $null; 
    "subOUs" = @(
        @{ "Name" = "subou1"; "groups" = $null; "users" = $null; 
            "subOUs" = @(
                @{ "Name" = "subsubou1"; "groups" = $null; "users" = @("Template subsubou1-MA", "Template subsubou1-HD"); 
                    "subOUs" = @(
                        @{ "Name" = "subsubou1"; "groups" = $null; "users" = @("Template subsubsubOU3-MA", "Template subsubsubOU3-HD"); "subOUs" = $null; },
                        @{ "Name" = "subsubou2"; "groups" = $null; "users" = @("Template subsubou2-MA", "Template subsubou2-HD"); "subOUs" = $null; }
                    ); 
                },
                @{ "Name" = "subsubou2"; "groups" = $null; "users" = @("Template subsubou2-MA", "Template subsubou2-HD"); "subOUs" = $null; }
            ); 
        },
        @{ "Name" = "subou2"; "groups" = $null; "users" = @("Template subou2-MA", "Template subou2-HD"); 
            "subOUs" = @(
                @{ "Name" = "subsubou1"; "groups" = $null; "users" = @("Template subsubou1-MA", "Template subsubou1-HD"); "subOUs" = $null; },
                @{ "Name" = "subsubou2"; "groups" = $null; "users" = @("Template subsubou2-MA", "Template subsubou2-HD"); "subOUs" = $null; }
            ); 
        },
        @{ "Name" = "subou3"; "groups" = $null; "users" = @("Template subou3-MA", "Template subou3-HD"); 
            "subOUs" = @(
                @{ "Name" = "subsubou1"; "groups" = $null; "users" = @("Template subsubou1-MA"); "subOUs" = $null; }
            );
    }
    )
}

New-ADOrganizationalUnit -Name $baseOU -Path $domain

foreach ($OU in "subOUs") {
    $OUName = $OU.Name
    $path = "OU=" + $baseOU + "," + $domain
    New-ADOrganizationalUnit -Name $OUName -Path $path

    $specificpath = "OU=" + $OUName + "," + $path
    New-ADOrganizationalUnit -Name "Benutzer" -Path $specificpath
    New-ADOrganizationalUnit -Name "Gruppen" -Path $specificpath
    New-ADOrganizationalUnit -Name "Computer" -Path $specificpath

    $ouPathGroups = "OU=Gruppen," + $specificpath
    $ouPathUsers = "OU=Benutzer," + $specificpath
    $templateUserMA = "Template " + $OUName + "-MA"

    New-ADOrganizationalUnit -Name "Mitarbeiter" -Path $ouPathUsers
    $ouPathUsersMA = "OU=Mitarbeiter," + $ouPathUsers
    if ($templateUserMA.Length -gt 19) {
        $userNameMA = "tmp " + $OUName.Substring(0, 3) + "-MA"
    } else {
        $userNameMA = $templateUserMA
    }
    
    New-ADUser -Name $userNameMA -DisplayName $templateUserMA -Path $ouPathUsersMA -AccountPassword $basePw -Enabled $false -PasswordNeverExpires $true

    $groupName =  $initials + "-" + $OUName + "-Mitarbeiter"
    $dlGroup = "DL-" + $groupName 
    $gGroup = "G-" + $groupName

    New-ADGroup -Name $dlGroup -Path $ouPathGroups -GroupCategory Security -GroupScope DomainLocal
    New-ADGroup -Name $gGroup -Path $ouPathGroups -GroupCategory Security -GroupScope Global

    Add-ADGroupMember -Identity $gGroup -Members $userNameMA
    Add-ADGroupMember -Identity $dlGroup -Members $gGroup

    if ($OU.hasHelpdesk) {
        $templateUserHD = "Template " + $OUName + "-HD"
        New-ADOrganizationalUnit -Name "HelpDesk" -Path $ouPathUsers
        $ouPathHD = "OU=Helpdesk,OU=Benutzer," + $specificpath

        if ($templateUserHD.Length -gt 20) {
            $userNameHD = "tmp " + $OUName.Substring(0, 3) + "-HD"
        } else {
            $userNameHD = $templateUserHD
        }
        New-ADUser -Name $userNameHD -DisplayName $templateUserHD -Path $ouPathHD -AccountPassword $basePw -Enabled $false -PasswordNeverExpires $true

        $groupNameHD =  $initials + "-" + $OUName + "-Helpdesk"
        $dlGroupHD = "DL-" + $groupNameHD
        $gGroupHD = "G-" + $groupNameHD

        New-ADGroup -Name $dlGroupHD -Path $ouPathGroups -GroupCategory Security -GroupScope DomainLocal
        New-ADGroup -Name $gGroupHD -Path $ouPathGroups -GroupCategory Security -GroupScope Global

        Add-ADGroupMember -Identity $gGroupHD -Members $userNameHD
        Add-ADGroupMember -Identity $dlGroupHD -Members $gGroupHD
    }
}

