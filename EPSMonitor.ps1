# Runs on EPS servers and emails log of failed jobs
# auth: ARB

$FailedPath="C:\Epic\Jobs\Failed\8.2\Epic Print Service\"
$LocalServer=$env:computername
$FailedCount=0

If (Test-Path $FailedPath)
{
    Get-ChildItem $FailedPath -Filter *.log | 
    Foreach-Object {
    
        If (Test-Path $_.FullName -NewerThan (Get-Date).AddMinutes(-5))
        {
            
            $failedlogFile = $_.FullName

            $messageParameters = @{ 
                Subject = "Failed EPS Job on $LocalServer" 
                Body = "New failed Job.   Log attached."
                From = "EPSMonitor@company.org" 
                To = "arb@company.org"
                SmtpServer = "smtp.company.net" 
                Attachments = $FailedLogFile
            } 

            Send-MailMessage @messageParameters
            $FailedCount++
        }
    }
}
else
{
    write-host "$FailedPath does not exist!!"
}
write-host "There are $FailedCount new failed jobs!!"
