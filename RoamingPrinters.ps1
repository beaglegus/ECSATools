<# 
Auth: ARB
Printer mgmt for roaming VDI
Last updated: 
2016-11-10 - added Get-RegValue function
2016-11-09 - added logging option and error handling for printer actions
2017-01-18 - Lots of changes - see previousVersions dir if needed
#>

#Functions:
function LogWrite
{
    param([string]$logstring)

    If ($EnableLogging)
    {
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $Line = "$Stamp $logstring"
        Add-content -PassThru $Logfile -value $Line
    }
}

# Borrowed/modified SQL function from: https://github.com/Tervis-Tumbler/InvokeSQL/blob/master/InvokeSQL.psm1
function Invoke-SQL {
    param(
        [string]$dataSource = ".\SQLEXPRESS",
        [string]$database = "MasterData",
        [string]$sqlCommand = $(throw "Please specify a query.")
    )

    $connectionString = "Server=$dataSource;Database=$database;User Id=WTSROUser;Password=*********;"
    
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    
    $connection.Close()
    $dataSet.Tables 
}

# Returns Regkey value
function Get-RegValue([String] $KeyPath, [String] $ValueName) 
{  
    If ((Get-ItemProperty -LiteralPath $KeyPath -Name $ValueName).$ValueName -ne "")
    {
        $KeyValue = (Get-ItemProperty -LiteralPath $KeyPath -Name $ValueName).$ValueName
    }
    Else
    {
        write-host "HKCU:\Volatile Environment\ViewClient_Machine_Name is null"
        Exit
    }

    return $KeyValue
}
# End Functions


# Logging - leave off (0) unless needed for troubleshooting - Log path is defined further down script
$EnableLogging = 1

$Endpoint = "NoEndpoint"
$CurrentPrinters = Get-wmiobject win32_printer
$DefaultPrinter = ""
$BackupPrinter = ""
$DefaultExists = 0
$BackupExists = 0

# Assign Endpoint name and exit on error
If (Test-Path "HKCU:\Volatile Environment")
{
    $Endpoint = Get-RegValue -KeyPath "HKCU:\Volatile Environment" -ValueName "ViewClient_Machine_Name"
}
Else
{
    Write-Host "No RegKey found for HKCU:\Volatile Environment"
    Exit
}

# Assign log file now that we have Endpoint name
$Logfile = "\\midmichigan.net\epic\Scripts\RoamingPrinters\Logs\$Endpoint.log"

# Gets default printer for $Endpoint
$EndpointInfo = Invoke-SQL -dataSource "vwp-it-sql008.midmichigan.net" -database "WTSProd" -sqlCommand "SELECT WinDefaultPrinter FROM Locations WHERE ClientName='$Endpoint'"
$DefaultPrinter = $EndpointInfo.WinDefaultPrinter
# Convert arr to str and remove space
$DefaultPrinter = [string]$DefaultPrinter
$DefaultPrinter = $DefaultPrinter.Replace(' ','')


# Gets backup printer for $Endpoint
$EndpointInfo2 = Invoke-SQL -dataSource "vwp-it-sql008.midmichigan.net" -database "WTSProd" -sqlCommand "SELECT WinBackupPrinter FROM Locations WHERE ClientName='$Endpoint'"
$BackupPrinter = $EndpointInfo2.WinBackupPrinter
# Convert arr to str and remove space
$BackupPrinter = [string]$BackupPrinter
$BackupPrinter = $BackupPrinter.Replace(' ','')


# If no default printer or backup defined, exit.   
If ($DefaultPrinter)
{
    LogWrite "$DefaultPrinter is the default printer"

    If ($BackupPrinter)
    {
        LogWrite "$BackupPrinter is the backup printer"
    }
    Else
    {
        LogWrite "No backup printer defined"
    }
}
Else
{
    LogWrite "No default printer defined"
    If ($BackupPrinter)
    {
        LogWrite "$BackupPrinter is the backup printer"
    }
    Else
    {
        LogWrite "No Default or Backup printer defined. Exiting script"
        # Not removing any printers if nothing is defined - Not sure if thats what we want
        Exit
    }
}


# Check if default and backup printers already exist

foreach ($p in $CurrentPrinters)
{
    If ($p.Name -eq $DefaultPrinter)
    {        
        $DefaultExists = 1
        LogWrite "Default printer $DefaultPrinter already exists"

        #Set as default in case it isn't already
        try
        {
            (New-Object -ComObject WScript.Network).SetDefaultPrinter("$DefaultPrinter")
            LogWrite "$DefaultPrinter set to default"
        }
        catch
        {
            LogWrite "ERROR: Failed to set $DefaultPrinter to default"
        }
    }
    
    If ($p.Name -eq $BackupPrinter)
    {
        $BackupExists = 1
        LogWrite "Backup printer $BackupPrinter already exists"
    }

    # Remove all network printers except for Default and Backup
    If ($p.Network -and $p.Name -ne $DefaultPrinter -and $p.Name -ne $BackupPrinter)
    {
        try
            {         
                (New-Object -ComObject Wscript.Network).RemovePrinterConnection($p.Name)           
                LogWrite "$($p.Name) was removed"
            }
            catch
            {
                LogWrite "ERROR: Failed to remove $($p.Name)"
            }
    }
}


If ($DefaultPrinter -and $DefaultExists -ne 1) 
{
    # Install Printer
    try 
    {
        (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection("$DefaultPrinter")
        LogWrite "Default printer $DefaultPrinter added"
    }
    catch
    {
        LogWrite "ERROR: Failed to add default printer $DefaultPrinter"
    }

    # Set as Default
    try
    {
        (New-Object -ComObject WScript.Network).SetDefaultPrinter("$DefaultPrinter")
        LogWrite "$DefaultPrinter set to default"
    }
    catch
    {
        LogWrite "ERROR: Failed to set $DefaultPrinter to default"
    }
}


If ($BackupPrinter -and $BackupExists -ne 1)
{
    # Install Printer
    try
    {
        (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection("$BackupPrinter")
        LogWrite "Backup printer $BackupPrinter added"
    }
    catch
    {
        LogWrite "ERROR: Failed to add backup printer $BackupPrinter"
    }
}






<#

# SQL queries saved for reference/reuse:
# Note change DB name to "WTSProd" in below queries

Invoke-SQL -dataSource "IRSQL01.midmichigan.net" -database "WtsLocation_copy" -sqlCommand "select @@version"

Invoke-SQL -dataSource "IRSQL01.midmichigan.net" -database "WtsLocation_copy" -sqlCommand "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES"

# Gets all columns
Invoke-SQL -dataSource "IRSQL01.midmichigan.net" -database "WtsLocation_copy" -sqlCommand "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Locations'"

# Gets all endpoint names
Invoke-SQL -dataSource "IRSQL01.midmichigan.net" -database "WTSProd" -sqlCommand "SELECT ClientName FROM Locations"

# Gets all rows for endpoint
Invoke-SQL -dataSource "IRSQL01.midmichigan.net" -database "WtsLocation_copy" -sqlCommand "SELECT * FROM Locations WHERE ClientName='$Endpoint'"

# Gets default printer for $Endpoint
Invoke-SQL -dataSource "IRSQL01.midmichigan.net" -database "WtsLocation_copy" -sqlCommand "SELECT Default_Printer FROM Locations WHERE ClientName='$Endpoint'"

#>
