<#

.SYNOPSIS
This script creates a snapshot of a HyperV VM in a remote hyperV server

#>
Param(
    [String]$snapshotName,
    [Parameter(Mandatory)]
    [String]$virtualMachineName,
    [Parameter(Mandatory)]
    [String]$overWrite
)

Set-Location $PSScriptRoot

$createSnapshotScriptBlock = {
    if ($overWrite -eq "yes") {
        $error.clear()
        try {
        Get-VMSnapshot -VMName $virtualMachineName | `
            Where-Object { $_.Name -eq $snapshotName } | `
            Remove-VMSnapshot -ErrorAction Stop
        } catch {
            Write-Output $error
            Write-Output "CRITICAL_ERROR"
            Exit 1
        }
    }

    $error.clear()
    try {
    Checkpoint-VM `
        -Name $virtualMachineName `
        -SnapshotName $snapshotName `
        -Confirm:$false `
        -ErrorAction Stop
    } catch {
        Write-Output $error
        Write-Output "CRITICAL_ERROR"
        Exit 1
    }
}
Write-Output "Creating snapshot to $snapshotName"
$job = Invoke-Command -ScriptBlock $createSnapshotScriptBlock -AsJob
$jobOutput = ""
Write-Host "`r`nJob Name: $($job.name) State: $($job.State)"
$Timer = 0
$TimerLimit = 600
$TimerIncrement = 15
while ($job.State -eq "Running" -And $Timer -lt $TimerLimit) {
    $jobOutputIncremental = Receive-Job -Job $job
    if ($jobOutputIncremental) {
        Write-Host $jobOutputIncremental
        $jobOutput += $jobOutputIncremental
    }
    Start-Sleep $TimerIncrement
    $Timer += $TimerIncrement
}
$jobOutputIncremental = Receive-Job -Job $job
if ($jobOutputIncremental) {
    Write-Host $jobOutputIncremental
    $jobOutput += $jobOutputIncremental
}
Write-Host "`r`nJob Name: $($job.name) State: $($job.State)"
if ($job.State -ne "Completed") {
    Write-Host "Job State not Completed"
    $STATUS = 1
} elseif ($([string]$jobOutput).contains("CRITICAL_ERROR")) {
    Write-Host "ERROR FOUND"
    $STATUS = 1
} elseif ($Timer -ge $TimerLimit) {
    Write-Host "TIMED OUT"
    $STATUS = 1
} else {
    $STATUS = 0
}

Exit $STATUS