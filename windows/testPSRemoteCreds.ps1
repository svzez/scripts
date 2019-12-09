<#

.SYNOPSIS
This script tests windows credentials trying to use a PS Remote connection to a winRM endpoint listening on SSL (5986)

#>
Param(
    [Parameter(Mandatory)]
    [string]$windowsAdminUser,
    [Parameter(Mandatory)]
    [String]$windowsAdminPassword,
    [Parameter(Mandatory)]
    [String]$windowsHost
)

Set-Item wsman:\localhost\Client\TrustedHosts -value '*' -Confirm:$false -Force

Write-Host "`r`nTesting Windows credentials"
$windowsAdminPassword_secure_string = $windowsAdminPassword | ConvertTo-SecureString -AsPlainText -Force
$windowsAdminCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList "$windowsHost\$windowsAdminUser", $windowsAdminPassword_secure_string
$psOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
$testSession = New-PSSession -Computer $windowsHost -Credential $windowsAdminCredentials -UseSSL -SessionOption $psOptions
if (-not($testSession)) {
    Write-Host "Cannot establish a powershell session to $windowsHost"
    Write-Host "please verify that the user $windowsAdminUser can log in as administrator"
    Exit 1
}
else {
    Write-Host "User: $windowsAdminUser is able to connect to $windowsHost successfully"
    Remove-PSSession $testSession
}
return 0