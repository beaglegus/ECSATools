$LogPath = "\\share\epic\Prod\BCAProdRoot\Logs" 
$maxDaystoKeep = -30 
$outputPath = "c:\Cleanup_Old_BCA-WBS-logs.log" 
  
$itemsToDelete = dir $LogPath -Recurse -File *.txt | Where LastWriteTime -lt ((get-date).AddDays($maxDaystoKeep)) 

  
if ($itemsToDelete.Count -gt 0){ 
    ForEach ($item in $itemsToDelete){ 
        "$($item.BaseName) is older than $((get-date).AddDays($maxDaystoKeep)) and will be deleted" | Add-Content $outputPath 
        Write-Output $item
        $fullPath = 
        Get-item $item.PSPath | Remove-Item -Verbose 
    } 
} 
ELSE{ 
    "No items to be deleted today $($(Get-Date).DateTime)" | Add-Content $outputPath 
    } 
   
Write-Output "Cleanup of log files older than $((get-date).AddDays($maxDaystoKeep)) completed..." 
start-sleep -Seconds 10