<#

.SYNOPSIS
This script logs you in to vSphere

#>
Param(
    [Parameter(Mandatory)]
    [string]$vmwareUserName,
    [Parameter(Mandatory)]
    [String]$vmwarePassword,
    [Parameter(Mandatory)]
    [String]$vmwareHost
)

Set-Location $PSScriptRoot
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

Write-Output "`r`nConnecting to vSphere API on: $vmwareHost as $vmwareUserName"
$Error.clear()
try {
    Connect-VIServer `
        -Server $vmwareHost `
        -User $vmwareUserName `
        -Password $vmwarePassword `
        -ErrorAction Stop | Out-Null
} catch {
    Write-Output "Error connecting to vSphere API on: $vmwareHost as $vmwareUserName"
    Write-Output $Error
    $retries = 0
    While ($Error -and $retries -lt 10) {
        $retries += 1
        Start-Sleep 10
        $Error.clear()
        try {
            Connect-VIServer `
                -Server $vmwareHost `
                -User $vmwareUserName `
                -Password $vmwarePassword `
                -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Output "Error connecting to vSphere API on: $vmwareHost as $vmwareUserName"
            Write-Output $Error
        }
    }
    if ($retries -ge 10) {
        Write-Output "Timed out when trying to connect to vSphere API on: $vmwareHost as $vmwareUserName"
        Exit 1
    }
}