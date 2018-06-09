# Search EPS jobs for keyword
# Auth: ARB

Write-Host 'Make sure to run with an account that has access to EPS paths.'

$SearchString = Read-Host -Prompt 'Enter search string'
$EPSServers = "vwp-ep-eps001", "vwp-ep-eps002", "vwp-ep-eps003", "vwp-ep-eps004"
$EPSPath = "\c$\Epic\Jobs"

$Invocation = (Get-Variable MyInvocation).Value
$CurrentDir = Split-Path $invocation.MyCommand.Path
$OutputDir = $CurrentDir + "\Output\" + $SearchString

Write-Host 'Search for' $SearchString 'has started.  Please be patient.  See output in' $OutputDir'.'

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$StopWatch.Start()

If (!(Test-Path $OutputDir))
{
    New-Item $OutputDir -Type Directory | Out-Null
}

foreach($s in $EPSServers) 
{
    $UNCPath = "\\" + $s + $EPSPath
    Get-ChildItem -recurse -Path $UNCPath | Select-String -pattern $SearchString -list | Select path | Copy-Item -Destination $OutputDir
}

$StopWatch.Stop()

Write-Host 'Search for' $SearchString 'has completed in' $StopWatch.Elapsed.Minutes.ToString() 'minutes.  See output in' $OutputDir'.  Remember to remove output when done.'