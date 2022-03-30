
<# Cleanup Disk Partitions - Patrick Quinn, 2021

==================================================== ABOUT: ===================================================

   Script to clean up disk partitions in preparation for MBR2GPT.exe tool:
   1. Removes 'HP Tools' recovery partition
   2. Removes 'Unknown' partitions
   3. Removes 'Recovery' partitions
   4. Expands C: drive with any reclaimed space from above steps

   Can be deployed remotely through ConfigMgr or run locally with elevated permissions

===============================================================================================================
#>

$ErrorActionPreference= 'SilentlyContinue'

# Find "HP Tools" drive letter

$vol = Get-Volume | Where-Object {$_.FileSystemLabel -eq "HP_TOOLS" -or $_.FileSystemLabel -eq "HP TOOLS"}

if ($vol -ne $null) {

    $dLet = $vol.DriveLetter
    Write-Host
    Write-Host "Found '$dLet - HP Tools' partition"

    # Remove extra disk partition

    $hpPart = Get-Partition | Where-Object -FilterScript {$_.DriveLetter -Eq $dLet}

    if ($hpPart.IsBoot -ne $true -and $dLet -ne "C") {
        $hpPart | Remove-Partition -Confirm:$false
        Write-Host "'HP Tools' partition removed"
    }

    else {

        Write-Host "'HP Tools' partition set as boot partition, not removed"
    }
}

else {

    Write-Host
    Write-Host "No 'HP Tools' partition found"
}

# Find "Unknown" partitions

$uPart = Get-Partition | Where-Object -FilterScript {$_.Type -Eq "Unknown"}

if ($uPart -ne $null) {

    Write-Host
    Write-Host "Found 'Unknown' partition"

    # Remove extra disk partition

    if ($uPart.IsBoot -ne $true -and $uPart.DriveLetter -ne "C") {
        $uPart | Remove-Partition -Confirm:$false
        Write-Host "'Unknown' partition removed"
    }
    
    else {
    
        Write-Host "'Unknown' partition set as boot partition, not removed"
    }
}

else {

    Write-Host
    Write-Host "No 'Unknown' partitions found"
}

#Find "Recovery" partitions

$rPart = Get-Partition | Where-Object -FilterScript {$_.Type -Eq "Recovery"}

if ($rPart -ne $null) {

    Write-Host
    Write-Host "Found 'Recovery' partition"

    # Remove extra disk partition

    if ($rPart.IsBoot -ne $true -and $rPart.DriveLetter -ne "C") {
        $rPart | Remove-Partition -Confirm:$false
        Write-Host "'Recovery' partition removed, clearing recovery GUID in BCD"
        bcdedit /deletevalue recoverysequence
    }
    
    else {

        Write-Host "'Recovery' partition set as boot partition, not removed"
    }
}

else {

    Write-Host
    Write-Host "No 'Recovery' partitions found, clearing recovery GUID in BCD"
    bcdedit /deletevalue recoverysequence
}

# Expand C: drive with freed space

$cPart = Get-Partition -DriveLetter C
$maxSize = ($cPart | Get-PartitionSupportedSize).SizeMax
$cPart | Resize-Partition -Size $maxSize


Write-Host
Write-Host "Disk reconfiguration complete"