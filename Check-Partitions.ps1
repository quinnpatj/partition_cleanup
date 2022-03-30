<# Check Disk Partitions - Patrick Quinn, 2021

==================================================== ABOUT: ===================================================

   Script to verify disk partition status on remote machines in preparation for MBR2GPT.exe tool:
   1. Checks if remote machine is online
   2. Starts WinRM service if not running
   3. Retrieves disk partition details

===============================================================================================================
#>

# Prompts user for computer name then verifies if remote machine is online and finds IP

Write-Host
$computerName = Read-Host "What is the computer name?"

$online = Test-Connection -ComputerName $computerName -BufferSize 16 -Count 1 -Quiet

If (-not $online) {
        
    $lastLogon = (Get-ADComputer $computerName -Properties LastLogonDate).LastLogonDate

    Write-Host
    Write-Host "$computerName is offline."
    Write-Host "$computerName was last online: $lastLogon"
    Exit
}

$IP = [System.Net.Dns]::GetHostAddresses($computerName).IPAddressToString

Write-Host
Write-Host "$computerName is online at $IP, searching for disk configuration..."


# Checks for WinRM service and starts it if stopped

$winRM = Get-Service –computername $computerName | where {$_.Name -eq 'WinRM'}
$winRMStat = $winRM.Status

if ($winRMStat -ne "Running") {
    
    $winRM | Start-Service
}


# Retrieves disk and partition details for remote machine

Invoke-Command -ComputerName $computerName -ScriptBlock {

    Write-Host
    Write-Host "Disks:" -BackgroundColor White -ForegroundColor DarkBlue
    Get-Disk | select Number,FriendlyName,@{Name="Size (GB)";Expression={$_.Size/1GB}},PartitionStyle,IsSystem,IsBoot

    Write-Host "Volumes:" -BackgroundColor White -ForegroundColor DarkBlue
    Get-Volume | select DriveLetter,FriendlyName,@{Name="Size (GB)";Expression={$_.Size/1GB}}

    Write-Host "Partitions:" -BackgroundColor White -ForegroundColor DarkBlue
    Get-Partition | select DiskNumber,PartitionNumber,DriveLetter,@{Name="Size (GB)";Expression={$_.Size/1GB}},Type,IsBoot,IsActive

    Write-Host "Active Partition:" -BackgroundColor Yellow -ForegroundColor DarkBlue
    $active = Get-Partition | Where-Object -FilterScript {$_.IsActive -Eq $true}
    $active | select DiskNumber,PartitionNumber,DriveLetter,@{Name="Size (GB)";Expression={$_.Size/1GB}},Type,IsBoot,IsActive

    Write-Host "Boot Partition:" -BackgroundColor Yellow -ForegroundColor DarkBlue
    $boot = Get-Partition | Where-Object -FilterScript {$_.IsBoot -Eq $true}
    $boot | select DiskNumber,PartitionNumber,DriveLetter,@{Name="Size (GB)";Expression={$_.Size/1GB}},Type,IsBoot,IsActive

    bcdedit
}