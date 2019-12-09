<#

.SYNOPSIS
Wrapper script to create a snapshot of a VM.
Checks for a snapshot with the same name and gives you the option to "overwrite" it.

#>
Param(
    [String]$vmwareHost,
    [Parameter(Mandatory)]
    [String]$snapshotName,
    [Parameter(Mandatory)]
    [String]$vmName,
    [Parameter()]
    [switch]$overWrite
)

Set-Location $PSScriptRoot

if ($overWrite) {
    $snapshot = Get-Snapshot -VM $vmName -Name $snapshotName -ErrorAction Ignore
    if ($snapshot) {
        try {
            Write-Output "Deleting existing snapshot $snapshotName"
            $snapshot | Remove-Snapshot -confirm:$false
        } catch {
            Write-Output $error
            Write-Output "CRITICAL_ERROR"
            Exit 1
        }
        
    }
}

Write-Output "Creating snapshot $snapshotName"
try {
    New-Snapshot -VM $vmName -Name $snapshotName -confirm:$false
} catch {
    Write-Output $error
    Write-Output "CRITICAL_ERROR"
    Exit 1
}