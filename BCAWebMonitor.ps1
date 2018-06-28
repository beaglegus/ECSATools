# Sends email alert when users file is older than specified time.
# Auth: ARB

$UsersFile = "C:\Epic\Data\Epic BCA Client\_users_.emp"
$MaxDays = 3
$NotificationEmail = "arb@company.org", "ar2b@company.org"


If (Test-Path $UsersFile -OlderThan (Get-Date).AddDays(-$MaxDays)) 
{
    
    send-mailmessage -to $NotificationEmail -from "BCAWebMonitorScript@company.org" -subject "BCAWeb Server - Users file not getting updated." -Body "Server: $env:computername.   The _users_.emp file is older than $MaxDays days.  Could mean BCA Web server is in edit mode or that users batch is not running.  Please fix.  Thanks" -SmtpServer smtp.company.net

}
