# patch_utils.ps1

# This is the utilities file for main.ps1

# Create Custom Function for further log operations
Function Log-Write($LogFile, $Text, $type)
{
   $current_date = Get-Date
   $text = "($current_date):[$type]::"+$text+"`n"
   Add-Content $LogFile -Value $Text
}

Function install-updates($computers, $log_to, $auto_restart)
{
    #Download and install all the available updates for windows device from Windows Update Servers instead of local WSUS, then save the updates logs to a log file
    $log_to = $log_to + "\$(get-date -f yyyy-mm-dd)-Windows-Update.log"
    #Install-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -AutoReboot -ComputerName $computers| Out-File $log_to -Force
    if($auto_restart)
    {
        Install-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -AutoReboot -ComputerName $computers| Out-File $log_to -Force
        #Invoke-WUJob -ComputerName $computers -Script {ipmo PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -AutoReboot | Out-File $log_to -Force} -RunNow -Confirm:$false -Verbose -ErrorAction Ignore
    }
    else
    {
        Install-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -ComputerName $computers| Out-File $log_to -Force
        #Invoke-WUJob -ComputerName $computers -Script {ipmo PSWindowsUpdate; Install-WindowsUpdate -AcceptAll | Out-File $log_to -Force} -RunNow -Confirm:$false -Verbose -ErrorAction Ignore        
    }
}

Function get-restart-status($computer)
{
    $status = Get-WURebootStatus -ComputerName $computer
    return $status.RebootRequired
}

Function restart-again($computer)
{
    Restart-Computer -ComputerName $computer
}

Function stop-services-in-order($computer, $service)
{
     #code here
     Write-Host "Stopping the services"
     (get-service -ComputerName $computer -Name $service).Stop()

}

Function start-services-in-order($computer, $service)
{
   
 $services_started = $false
 do
    {
        $pingtest = Test-Connection -ComputerName $computer  # Check if server is online
        if($pingtest)
        {
           (get-service -ComputerName $computer -Name $service).Start()
           $services_started = $true
        }
   
    }while($pingtest -and $services_started)
}

Function take-remote-backup($computer, $from, $to, $pattern)
{
   
    $ScriptBlock = {
    Param (
        [string]$from,
        [string]$to,
        [string]$pattern
    )
    #$LogPath = 'd:\Program Files\Exchange\Logging\RPC Client Access\*.LOG'
    $today = (Get-Date).AddHours($NumberofHours)
    $patterns = $pattern -split ","

    # Create directory if it doesn't exists
                   
                    if(Test-Path $to)
                    {
                        Write-Host "Destination folder exists!"
                        #Start-Sleep -Seconds 5
                    }
                    else
                    {
                        Write-Host "Destination folder doesn't exist!"
                        Write-Host "Creating destination folder"
                        #Start-Sleep -Seconds 5
                        New-Item $to -ItemType Directory
                        Write-Host "Created destination folder successfully!"
                        #Start-Sleep -Seconds 5
        }

        # Grab all the files from the target folder
        $all_files = @()
        foreach($pattern in $patterns)
        {
           $all_files += Get-Item "$from\$pattern"
        }
       
        foreach($file in $all_files)
        {
            $filename = "$file".Replace("$From\", "")
            $dest = $to + "\$filename"
            Write-Host "Taking the logs backup for [$filename] from [$file] to [$dest]"
            Move-Item -Path $file -Destination $to
            Write-Host "Backup taken!"
            Write-Host
            #Start-Sleep -Seconds 5
        }
        Write-Host "Successfully moved all items!"
}
   
    Invoke-Command -ComputerName $computer -ScriptBlock $ScriptBlock -ArgumentList $from,$to,$pattern
}