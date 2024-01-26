# Create Printers and Access-Groups
# IP Addresses are automatically excluded from the DHCP Range

# Set the values for your environment
$number = "19"
$initials = "PD"

$abteilungen = @(
    @{
        "Name" = "Handel"
        "IP" = "10.23.$number.201"
    },
    @{
        "Name" = "Verwaltung"
        "IP" = "10.23.$number.202"
    },
    @{
        "Name" = "Produktion"
        "IP" = "10.23.$number.203"
    },
    @{
        "Name" = "IT-Admin"
        "IP" = "10.23.$number.204"
    }
)

# variables for Address Reservation
$dhcpServer = "CO1PD"
$rangeStart = "10.23.$number.201"
$rangeEnd = "10.23.$number.204"

# Exclude the IP Addresses from the DHCP Range
Invoke-Command -ComputerName $dhcpServer -ArgumentList $rangeStart, $rangeEnd -ScriptBlock {
    param($rangeStart, $rangeEnd)
    $scope = Get-DhcpServerv4Scope
    $scopeId = $scope.ScopeId
    Add-DhcpServerv4ExclusionRange -ScopeId $scopeId -StartRange $rangeStart -EndRange $rangeEnd
}


# Gets all Groups in the AD for filtering later
$adGroups = Get-ADGroup -Filter *

# Install the Printer Driver if it isn't already installed
$driver = "Generic / Text Only"
Add-PrinterDriver -Name $driver

# This loop installs two printers for each department (2 Printers mapped on the same Printer-Port)
foreach ($abteilung in $abteilungen) {
    $abteilungsName = $abteilung.Name
    $ouPath = "OU=Gruppen,OU=$abteilungsName,OU=Firma,DC=$initials$number,DC=FH,DC=LOCAL"
    $IPAddress = $abteilung.IP
    $printerNameInternal = $abteilungsName + "-Drucker-Intern"
    $printerNameExternal = $abteilungsName + "-Drucker-Extern"
 
    echo "Attempting to add printer"
    # Create the Printer Port (only one has to be Created for each Department)
    Add-PrinterPort -Name $IPAddress -PrinterHostAddress $IPAddress
    # Creates the Internal Printer and sets it's Priority to 99
    Add-Printer -Name $printerNameInternal -DriverName $driver -PortName $IPAddress
    Set-Printer -Name $printerNameInternal -Shared $true -Priority 99
    # Creates the External Printer and sets it's Priority to 1
    Add-Printer -Name $printerNameExternal -DriverName $driver -PortName $IPAddress
    Set-Printer -Name $printerNameExternal -Shared $true -Priority 1

    echo "Attempting to create groups"
    $groupNameInternal = "DruckerAccess-" + $abteilungsName + "-Intern"
    $groupNameExternal = "DruckerAccess-" + $abteilungsName + "-Extern"
    # Create new Domain Local Groups that will be used for access control later
    New-ADGroup -Name $groupNameInternal -GroupCategory Security -GroupScope DomainLocal -Path $ouPath
    New-ADGroup -Name $groupNameExternal -GroupCategory Security -GroupScope DomainLocal -Path $ouPath

    echo "Attempting to add members to group"
    # Puts the Groups of the Departments in the $internal variable
    $internal = ($adGroups | ? {$_.Name -like "G-*" -and $_.Name.Contains($abteilungsName)}).Name

    # Puts the Groups of the other Departments in the $external variable
    $external = ($adGroups | ? {$_.Name -like "G-*" -and -not $_.Name.Contains($abteilungsName)}).Name

    echo "Attempting to add members to group"
    # Adds the Groups to the Domain Local Groups
    Add-ADGroupMember -Identity $groupNameInternal -Members $internal
    Add-ADGroupMember -Identity $groupNameExternal -Members $external
}
