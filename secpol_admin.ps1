$adminGroupName = "Admins"



$adminSID = ((Get-LocalGroup Administrators).sid).value
$newAdminGroupSID = ((Get-LocalGroup $adminGroupName).sid).value

if ($newAdminGroupSID -eq $null) {
    echo "Gruppe Existiert nicht -> Script wird beendet"
} else {
    Invoke-Expression -Command "secedit /export /cfg c:\secpol.inf"
    $secpol = Get-Content -Path "c:\secpol.inf"

    foreach ( $line in $secpol )
    { 
        if ( $line.Contains($adminSID) -and -Not $line.Contains($newAdminGroupSID) -and -Not $line.Contains($adminGroupName)) 
        {
            $replacement = $line+",*"+$newAdminGroupSID
            $secpol = $secpol.Replace($line, $replacement)
        }
    }
    # Replaces "Everyone" with "Authenticated Users"
    # $secpol = $secpol.Replace("S-1-1-0","S-1-5-11")

    Set-Content -Path "c:\secpol.inf" $secpol

    Invoke-Expression -Command "echo Y | secedit /configure /db c:\windows\security\database\local.sdb /cfg c:\secpol.inf /areas user_rights /overwrite"

    Remove-Item -Path "c:\secpol.inf"
}