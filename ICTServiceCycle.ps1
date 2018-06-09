# Restarts interconnect services to address issue with not reconnecting to cache after downtime.
# Auth: ARB

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

# Assign log file location
$Logfile = "\\share\epic\Scripts\ICTServiceCycle\Logs\$env:computername.log"
$EnableLogging = 1

LogWrite "Starting service restarts."

$instanceList = Get-Service | where Name –like “*interconnect*”
Foreach ($instance in $instanceList)
{
    #LogWrite "Restarting service"
    Restart-Service $instance -Force -Verbose *>> $Logfile
        
}

LogWrite "Finished."

