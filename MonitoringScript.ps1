$name = "Collector_DC1PD_MS1PD"

# Credentials findet aus irgendeinem Grund die Domäne nicht -> Manuell eingeben
#$credentials = Get-Credential -Credential PD19\NewAdmin

$datacollectorset = New-Object -COM Pla.DataCollectorSet
$datacollectorset.DisplayName = $name;
$datacollectorset.Description = "Collector Set für DC1PD und MS1PD";
#$datacollectorset.SetCredentials($credentials.UserName, $credentials.Password)
#$datacollectorset.Duration = 50400 ;
$datacollectorset.SubdirectoryFormat = 1 ;
$datacollectorset.SubdirectoryFormatPattern = "yyyy\-MM";
$datacollectorset.RootPath = "%systemdrive%\PerfLogs\Admin\" + $name ;

$DataCollector1 = $datacollectorset.DataCollectors.CreateDataCollector(0) 
$DataCollector1.Name = $name;
$DataCollector1.FileName = $name;
$DataCollector1.FileNameFormat = 0x1 ;
#$DataCollector1.FileNameFormatPattern = "yyyy\-MM\-dd";
$DataCollector1.SampleInterval = 15
$DataCollector1.LogAppend = $true;

# Alle Referenzeen wurden mit dem Befehl "TypePerf.exe -q" ermittelt
$counters = @(
    "\\DC1PD\Memory\Available MBytes", 
    "\\DC1PD\Processor(_Total)\% Processor Time", 
    "\\DC1PD\PhysicalDisk\Avg. Disk Sec/Read",
    "\\MS1PD\Memory\Available MBytes", 
    "\\MS1PD\Processor(_Total)\% Processor Time", 
    "\\MS1PD\PhysicalDisk\Avg. Disk Sec/Read"
) ;

$DataCollector1.PerformanceCounters = $counters

$StartDate = [DateTime](Get-Date -Format "yyyy-MM-dd HH:mm:ss");

$NewSchedule = $datacollectorset.schedules.CreateSchedule()
#$NewSchedule.Days = 127
$NewSchedule.StartDate = $StartDate
$NewSchedule.StartTime = $StartDate

$datacollectorset.DataCollectors.Add($DataCollector1) 
$datacollectorset.Commit("$name" , $null , 0x0003) | Out-Null
#$datacollectorset.start($true);



# Das Alert-Set erstellen
$alertName = "Alert_DC1PD"
$alertcollectorset = New-Object -COM Pla.DataCollectorSet
$alertcollectorset.DisplayName = $alertName;
$alertcollectorset.Description = "Alert für DC1PD";
$alertcollectorset.SubdirectoryFormat = 1 ;
$alertcollectorset.SubdirectoryFormatPattern = "yyyy\-MM";
$alertcollectorset.RootPath = "%systemdrive%\PerfLogs\Admin\" + $name ;

# Value 3 creates an AlertDataCollector (https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-pla/4775398e-3e1c-470e-a704-94d6a2ef7ce0)
$AlertDataCollector = $alertcollectorset.DataCollectors.CreateDataCollector(3)

$alertName = "Alert_" + $alertName
$AlertDataCollector.TriggerDataCollectorSet = $name
$AlertDataCollector.Name = $alertName
$AlertDataCollector.FileName = $alertName
$AlertDataCollector.FileNameFormat = 0x1
$AlertDataCollector.SampleInterval = 15
$AlertDataCollector.LogAppend = $true



# Cool idea, doesnt work
# mby try using copilot to force utf-8

[xml]$alertCollectorXml = New-Object Xml
$alertCollectorXml = $AlertDataCollector.Xml



$thresholds = @(
    "\\DC1PD\Network Interface(Intel[R] 82574L Gigabit Network Connection)\Bytes Total/sec>50",
    "\\DC1PD\Network Interface(Intel[R] 82574L Gigabit Network Connection _2)\Bytes Total/sec>50"
)

# Es gibt eine Thresholds methode aber die ist weniger zuverlässig als einfach das xml um die gewünschten elemente zu erweitern.
foreach ($threshold in $thresholds) {
    <# $threshold is the current item #>
    $alertElement = $alertCollectorXml.CreateElement("Alert")
    $alertDisplayNameElement = $alertCollectorXml.CreateElement("AlertDisplayName")
    $alertElement.InnerText = $threshold
    $alertDisplayNameElement.InnerText = $threshold
    $alertCollectorXml.AlertDataCollector.AppendChild($alertElement)
    $alertCollectorXml.AlertDataCollector.AppendChild($alertDisplayNameElement)
}

$AlertDataCollector.SetXml($alertCollectorXml.OuterXml)

$AlertDataCollector.EventLog = $true

$alertcollectorset.DataCollectors.Add($AlertDataCollector)
$alertcollectorset.Commit("$alertName" , $null , 0x0003) | Out-Null
$alertcollectorset.start($false);