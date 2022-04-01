#patch.ps1

#Install-Module PSWindowsUpdate
#Install-Module PSWindowsUpdate in both App1 and SSAS server
#Invoke-Command -ComputerName $target -ScriptBlock {Set-ExecutionPolicy RemoteSigned -force}
#Invoke-Command -ComputerName $target -ScriptBlock {Import-Module PSWindowsUpdate; Enable-WURemoting}
# Now, you can easily share windows update details and actions among client computers

. C:\Users\-sysop-5427ek\Desktop\patching\utilities.ps1

#servers names
$app1 = "" #master server
#$app2 = ""
$ssas = "" #worker server

$logfile = "C:\Users\-sysop-5427ek\Desktop\New folder\LogFolder\logfile.log" #Logfile full address
$windows_logs = "C:\Users\-sysop-5427ek\Desktop\New folder\LogFolder" # Folder for storing windows updates logs

function start-updates-process()
{
    # Run this until both the servers are online
    Log-Write -LogFile $logfile -Text "Checking if server $ssas are online..." -Type "INFO"
    do
    {
        $pingtest1 = Test-Connection -ComputerName $ssas -Quiet  # Check if server is online
       
        $pingtest2 = Test-Connection -ComputerName $app1  # Check if server is online
    }while(-not ($pingtest1 -and $pingtest2))

    Log-Write -LogFile $logfile -Text "Server $app1 is online!" -Type "INFO"
    Log-Write -LogFile $logfile -Text "Server $ssas is online!" -Type "INFO"


    $updates_list_app1 = Get-WUList –ComputerName $app1 # If server is online, then get the updates list
    $updates_list_ssas = Get-WUList –ComputerName $ssas # If server is online, then get the updates list    

    if(($updates_list_ssas.count -gt 0) -or ($updates_list_app1.count -gt 0)) # Check if patches are available on both servers
    {
        $count_updates_app1 = $updates_list_app1.count
        $count_updates_ssas = $updates_list_ssas.count
        Log-Write -LogFile $logfile -Text "Server $app1 has $count_updates_app1 updates" -Type "INFO"
        Log-Write -LogFile $logfile -Text "Server $ssas has $count_updates_ssas updates" -Type "INFO"

        #Stop the services in order
        <# Log-Write -LogFile $logfile -Text "Stopping the service 'PROS PPSS All Nodes' in $app1 server" -Type "INFO"
        stop-services-in-order -computer $app1 -service "PROS PPSS All Nodes"
        Start-Sleep -Seconds 100
        Log-Write -LogFile $logfile -Text "Stopped the service 'PROS PPSS All Nodes' in $app1 server" -Type "INFO"
   

        Log-Write -LogFile $logfile -Text "Stopping the service 'PROS PPSS LauncherAgent' in $ssas server" -Type "INFO"
        stop-services-in-order -computer $ssas -service "PROS PPSS LauncherAgent"
        Start-Sleep -Seconds 100
        Log-Write -LogFile $logfile -Text "Stopped the service 'PROS PPSS LauncherAgent' in $ssas server" -Type "INFO"


        Log-Write -LogFile $logfile -Text "Stopping the service 'PROS PPSS LauncherAgent' in $app1 server" -Type "INFO"
        stop-services-in-order -computer $app1 -service "PROS PPSS LauncherAgent"
        Start-Sleep -Seconds 100
        Log-Write -LogFile $logfile -Text "Stopped the service PROS PPSS LauncherAgent' in $app1 server" -Type "INFO"
        #>

        # Take the backup of service logs
        Log-Write -LogFile $logfile -Text "Taking the service logs backup for $app1 server" -Type "INFO"
        take-remote-backup -computer $app1 -from "C:\Users\-sysop-5427ek\Desktop\New folder\testing_for_backup" -to "C:\Users\-sysop-5427ek\Desktop\New folder\testing_for_backup\logs_backup" -pattern "*.txt,*log,*.gz" # Should be able to take more than 1 pattersn
        Log-Write -LogFile $logfile -Text "Done!" -Type "INFO"
        Log-Write -LogFile $logfile -Text "Taking the service logs backup for $ssas server" -Type "INFO"
        take-remote-backup -computer $ssas -from "C:\Users\-sysop-5427ek\Desktop\New folder\testing_for_backup" -to "C:\Users\-sysop-5427ek\Desktop\New folder\testing_for_backup\logs_backup" -pattern "*.txt,*log,*.gz"
        Log-Write -LogFile $logfile -Text "Done!" -Type "INFO"


        # Install the updates
        Log-Write -LogFile $logfile -Text "Started installing windows updates!" -Type "INFO"
        Log-Write -LogFile $logfile -Text "Windows updates logs are stored separately in $windows_logs" -Type "INFO"
       

        if($count_updates_app1 -gt 0){
            Log-Write -LogFile $logfile -Text "Started installing windows updates on $app1 server" -Type "INFO"
            install-updates -computers $app1 -log_to $windows_logs -auto_restart $true
            Log-Write -LogFile $logfile -Text "Installed windows updates on $app1 server" -Type "INFO"
            }
        if($count_updates_ssas -gt 0){
            Log-Write -LogFile $logfile -Text "Started installing windows updates on $ssas server" -Type "INFO"
            install-updates -computers $ssas -log_to $windows_logs -auto_restart $true
            Log-Write -LogFile $logfile -Text "Installed windows updates on $ssas server" -Type "INFO"
            }

        # Check if any patches are still left
           # Code here

        Log-Write -LogFile $logfile -Text "Checking if the server $ssas requires a restart again" -Type "INFO"
        $ssas_restart_status = get-restart-status -computer $ssas
        if($ssas_restart_status)
        {
            Log-Write -LogFile $logfile -Text "Server $ssas requires a restart again" -Type "INFO"
            Log-Write -LogFile $logfile -Text "Restarting server $ssas..." -Type "INFO"
            restart-again -computer $ssas
        }
        else{Log-Write -LogFile $logfile -Text "Server $ssas doesnot require a restart again" -Type "INFO"}


        Log-Write -LogFile $logfile -Text "Checking if the server $app1 requires a restart again" -Type "INFO"
        $app1_restart_status = get-restart-status -computer $app1
        if($app1_restart_status)
        {
            Log-Write -LogFile $logfile -Text "Server $app1 requires a restart again" -Type "INFO"
            Log-Write -LogFile $logfile -Text "Restarting server $app1..." -Type "INFO"
            restart-again -computer $ssas
        }
        else{Log-Write -LogFile $logfile -Text "Server $app1 doesnot require a restart again" -Type "INFO"}


    }
    else{
        $ssas_count = $updates_list_ssas.count
        Log-Write -LogFile $logfile -Text "Server $ssas has $ssas_count updates left" -Type "INFO"

        $app1_count = $updates_list_app1.count
        Log-Write -LogFile $logfile -Text "Server $app1 has $app1_count updates left" -Type "INFO"
       
        return $true
       
        }
}



While ($true){
    $result = start-updates-process
   
    if ($result)
    {
        break
    }
}

Write-Host
Write-Host "UPDATE PROCESS COMPLETED!"


# Check if any restart required again!
Log-Write -LogFile $logfile -Text "Checking if the server $app1 requires a restart again" -Type "INFO"
$app1_restart_status = get-restart-status -computer $app1
if($app1_restart_status)
{
    Log-Write -LogFile $logfile -Text "Server $app1 requires a restart again" -Type "INFO"
    Log-Write -LogFile $logfile -Text "Restarting server $app1..." -Type "INFO"
    restart-again -computer $app1
}
else{Log-Write -LogFile $logfile -Text "Server $app1 doesnot require a restart again" -Type "INFO"}

Log-Write -LogFile $logfile -Text "Checking if the server $ssas requires a restart again" -Type "INFO"
$ssas_restart_status = get-restart-status -computer $ssas
if($ssas_restart_status)
{
    Log-Write -LogFile $logfile -Text "Server $ssas requires a restart again" -Type "INFO"
    Log-Write -LogFile $logfile -Text "Restarting server $ssas..." -Type "INFO"
    restart-again -computer $ssas
}
else{Log-Write -LogFile $logfile -Text "Server $ssas doesnot require a restart again" -Type "INFO"}



# Run this until both the servers are online
Log-Write -LogFile $logfile -Text "Checking if servers $app2 and $ssas are online..." -Type "INFO"
do
{
    $pingtest1 = Test-Connection -ComputerName $ssas # Check if server is online
    $pingtest2 = Test-Connection -ComputerName $app1  # Check if server is online
}while(-not ($pingtest1 -and $pingtest2))

Log-Write -LogFile $logfile -Text "Server $app1 is online!" -Type "INFO"
Log-Write -LogFile $logfile -Text "Server $ssas is online!" -Type "INFO"



# If restart is not required again, restart the services in correct order
#Log-Write -LogFile $logfile -Text "Restarting the services in order" -Type "INFO"

#Log-Write -LogFile $logfile -Text "Restaring the service PROS PPSS LauncherAgent in server $app1" -Type "INFO"
<#
start-services-in-order -computer $app1 -service "PROS PPSS LauncherAgent"
Start-Sleep -Seconds 100
Log-Write -LogFile $logfile -Text "Started the service PROS PPSS LauncherAgent in server $app1" -Type "INFO"

Log-Write -LogFile $logfile -Text "Restaring the service PROS PPSS LauncherAgent in server $ssas" -Type "INFO"
start-services-in-order -computer $ssas -service "PROS PPSS LauncherAgent"
Start-Sleep -Seconds 100
Log-Write -LogFile $logfile -Text "Started the service PROS PPSS LauncherAgent in server $ssas" -Type "INFO"

Log-Write -LogFile $logfile -Text "Restaring the service PROS PPSS All Nodes in server $app1" -Type "INFO"
start-services-in-order -computer $app1 -service "PROS PPSS All Nodes"
Start-Sleep -Seconds 100
Log-Write -LogFile $logfile -Text "Started the service PROS PPSS All Nodes in server $app1" -Type "INFO"
#>
# Send the email to support team
$BODY = "Patching activity has been completed for the app1 and ssas server. You can run all the servers and please find attacthed log file. Kindly check the health check on the PROS application."
$logfiles_arr = @()

foreach ($file in (Get-ChildItem -Path $windows_logs))
{
    $file = $windows_logs + '\' + $file
    $logfiles_arr += ($file)
}

(Send-MailMessage -From 'your_mail.com' -To 'someone_mail.com' -SmtpServer 'smtp-server' -Body $BODY -Subject 'INFO: COMPLETION OF PATCHING ACTIVITY' -Attachments $logfiles_arr)
Log-Write -LogFile $logfile -Text "Mail regarding the updates is sent!" -Type "INFO"


Write-Host
Write-Host "UPDATE PROCESS COMPLETED!"
Log-Write -LogFile $logfile -Text "Update process for $ssas server is completed!" -Type "INFO"
Log-Write -LogFile $logfile -Text "Update process for $app1 server is completed!" -Type "INFO"
