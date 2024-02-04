Invoke-Expression -Command "secedit /export /cfg c:\secpol.inf"

$secpol = Get-Content -Path "c:\secpol.inf"
$adminSID = ((Get-LocalGroup Administrators).sid).value
$19adminSID = ((Get-LocalGroup "19-Admins").sid).value
$19poweruserSID = ((Get-LocalGroup "19-PowerUser").sid).value
$0815SID = ((Get-LocalGroup "19-0815").sid).value

$duplicatePrevention = 0
foreach ( $line in $secpol ) {
  if ( $line.Contains("SeDenyRemoteInteractiveLogonRight"))
  { $duplicatePrevention = 1 }
}

foreach ( $line in $secpol )
{ 
  if ( $line.contains("Privilege Rights") -and $duplicatePrevention -eq 0) 
  { 
    $replacement = "SeDenyRemoteInteractiveLogonRight = *"+$0815SID
    $replacement = $line+"`n"+$replacement
    $secpol = $secpol.Replace($line, $replacement)
  }
  
  elseif ( $line.Contains($adminSID) -and -Not $line.Contains($19adminSID) -and -Not $line.Contains("19-Admins")) 
  {
    $replacement = $line+",*"+$19adminSID
    $secpol = $secpol.Replace($line, $replacement)
  }
  
  elseif ( ($line.Contains("SeNetworkLogonRight") -or $line.Contains("SeSystemtimePrivilege")) -and -Not $line.Contains($19poweruserSID) -and -Not $line.Contains("19-PowerUser") )
  {
    $replacement = $line+",*"+$19poweruserSID
    $secpol = $secpol.Replace($line, $replacement)
  }
}
# Replaces "Everyone" with "Authenticated Users"
$secpol = $secpol.Replace("S-1-1-0","S-1-5-11")

Set-Content -Path "c:\secpol.inf" $secpol

Invoke-Expression -Command "echo Y | secedit /configure /db c:\windows\security\database\local.sdb /cfg c:\secpol.inf /areas user_rights /overwrite"

Remove-Item -Path "c:\secpol.inf"