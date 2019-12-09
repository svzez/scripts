<#

.SYNOPSIS
Snapshot reports.
Parameter -Name to enter the VM name to get the report from or a comma separated string
Alternative, the parameter -Like accepts a wildcard expression

Output is a json filein the same directory: results.json

It needs to run after login to the esxi host or vCenter server.

.EXAMPLE
.\SnapshotReport.ps1 -Name "MyVM"
Output: Report for MyVM

.\SnapshotReport.ps1 -Name "MyVM,YourVM,HerVM"
Output: Report for MyVM, YourVM and HerVM

.\SnapshotReport.ps1 -Like "*"
Output: Report for all the VMs in the given scope

.\SnapshotReport.ps1 -Like "MyApp*"
Output: Report for all the VMs matching the expression in the given scope

#>

Param(
    [Parameter()]
    [String]$Name,
    [Parameter()]
    [String]$Like
)

$vmList = @()
$results= @{
    "VMs" = @{};
    "TotalStorage" = 0;
    "totalSnapshotStorage" = 0;
    "totalSnapshotCount" = 0;
    "TotalVMsCount" = 0
}
if ($Name) {
    $Name -split "," | `
        ForEach-Object { 
            $vm = $null 
            $vm = Get-VM -Name $_ -ErrorAction SilentlyContinue
            if (!$vm) {
                Write-Host "VM $_ not found"
            } else {
                $vmList += $vm
            }
        }
} elseif ($Like) {
    $vmList = Get-VM | Where-Object { $_.Name -like $Like }
} else {
    Write-Host "VM names list or expression missing"
    Exit 1
}
if (!$vmList) {
    Write-Host "VM search for $Name$Like returned empty results"
    Exit 1
}

$totalStorage = 0
$totalSnapshotStorage = 0
$totalSnapshotCount = 0
$vmList | ForEach-Object {
    $totalVmSnapshotGB = 0
    Write-Host "`r`nProcessing VM: $($_.Name)"
    $totalStorage += $_.UsedSpaceGB
    $results['VMs'].Add($_.Name, @{})
    $results['VMs'][$_.Name].Add("UsedStorage", [math]::Round($_.UsedSpaceGB,2))
    $snapshots = $_ | Get-Snapshot
    if (!$snapshots) {
        Write-Host "No Snapshots Found"
    } else {
        $snapshotsList = @()
        $snapshots | ForEach-Object {
            $snapshotsList += @{
                "Name" = $_.Name ;
                "CreationDate" = $_.Created.ToString("yyyy/MM/dd");
                "Size" = [math]::Round($($_.sizegb),2)
            }
            $totalVmSnapshotGB += $_.sizegb
        }
        $results['VMs'][$_.Name].Add("Snapshots", $snapshotsList)
        $results['VMs'][$_.Name].Add("TotalSnapshotStorage", [math]::Round($totalVmSnapshotGB,2))
        $results['VMs'][$_.Name].Add("TotalSnapshotCount", $snapshots.count)
        $totalSnapshotStorage += $totalVmSnapshotGB
        $totalSnapshotCount += $snapshots.count
    }
}
$results['TotalStorage'] = [math]::Round($totalStorage,2)
$results['totalSnapshotStorage'] = [math]::Round($totalSnapshotStorage,2)
$results['totalSnapshotCount'] = $totalSnapshotCount
$results['TotalVMsCount'] = $vmList.count
$results | ConvertTo-Json -Depth 4 | Out-File -FilePath ./results.json -encoding ascii 

