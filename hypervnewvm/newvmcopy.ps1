<#

.SYNOPSIS
Creates copies of Windows VMs from a base disk. It returns the VM's IP address.  It runs on a local Hyper-V server.

.DESCRIPTION
It works based on a base VHD or VHDX disk.  The base disk is copied to $pathToWorkingDir and it's used to create a new Virtual Machine.
The VM is started and it waits until it can get an IP address from a DHCP server.


.PARAMETER pathToBaseVHD
Location to the Base VHD or VHDX

.PARAMETER pathToWorkingDir
Location for the new Hyper-V Virtual Machine Virtual disk

.PARAMETER virtualMachineName
Virtual Machine Name to be created and exported

.PARAMETER virtualSwitch
Virtual Switch to connect the VM in order to get an IP address

.PARAMETER vmCpus
Number of CPUs to be configured in the Virtual Machine

.PARAMETER vmRam
Amount of RAM to be configured in the Virtual Machine

.PARAMETER generation
Generation for the new Virtual Machine

.PARAMETER logFile
Log file.  If not there, it will write the output to the console

.EXAMPLE
.\NewVMCopy.ps1 -virtualMachineName NewVMCopy -pathToBaseVHD C:\BaseVHDs\WindowsServer2012R2.vhdx -pathToWorkingDir -virtualSwitch Network1 C:\temp -logFile logfile.txt 

#>

[CmdletBinding(DefaultParametersetName='None')]
Param(
    [Parameter(Mandatory=$True)]
    [string]$pathToBaseVHD,

    [Parameter(Mandatory=$True)]
    [string]$pathToWorkingDir,

    [Parameter(Mandatory=$False)]
    [string]$virtualMachineName="NewVM",

    [Parameter(Mandatory=$True)]
    [string]$virtualSwitch,

    [Parameter(Mandatory=$False)]
    [int]$vmCpus=4,

    [Parameter(Mandatory=$False)]
    [int64]$vmRam=8GB,

    [Parameter(Mandatory=$False)]
    [ValidateSet(1,2)]
    [int]$generation=1,

    [Parameter(Mandatory=$False)]
    [string]$logFile

)

# Helper function
Function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
        [String]$level = "INFO",

        [Parameter(Mandatory=$True)]
        [string]$message,

        [Parameter(Mandatory=$False)]
        [string]$logFile
    )
    $timeStamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $line = "$timeStamp $level $message"
    If ($logfile) {
        Add-Content $logFile -Value $line
    } Else {
        Write-Output $line
    }
}

#MAIN
Write-Log -Message "Starting Script" -logfile $logFile

# Checks pre requisites for a New VM

$fileExt = [System.IO.Path]::GetExtension($pathToBaseVHD)
$pathToNewVHD = "{0}\{1}{2}" -f $pathToWorkingDir,$virtualMachineName,$fileExt
If (Test-Path $pathToNewVHD) {
    Write-Log -Level ERROR -Message "$pathToNewVHD already exists.  Delete or rename the file and try again." -logfile $logFile
    Exit
}
If (Get-VM -name $virtualMachineName -ErrorAction Ignore ) {
    Write-Log -Level ERROR -Message "$virtualMachineName already exists.  Delete or Rename the VM and try again." -logfile $logFile
    Exit
}

#Create New VM

Write-Log -Message "Copying $pathToBaseVHD to $pathToNewVHD" -Level INFO -logfile $logFile
$error.clear()
try {
    Copy-Item -literalPath $pathToBaseVHD -destination $pathToNewVHD -ErrorAction Stop
    Write-Log -Message "Base VHD $pathToBaseVHD copied successfully to $pathToNewVHD" -logfile $logFile
}
Catch {
    Write-Log -Message "Could not copy base VHD $pathToBaseVHD to $pathToNewVHD" -Level ERROR -logfile $logFile
    Write-Log -Message $error -Level ERROR -logfile $logFile
    Exit
}

Write-Log -Message "Creating Virtual Machine $virtualMachineName with VHD $pathToNewVHD" -logfile $logFile
$error.clear() 
try {
    New-VM -Name $virtualMachineName -VHDPath $pathToNewVHD -MemoryStartupBytes $vmRam -Generation $generation -Switchname $virtualSwitch -ErrorAction Stop | Set-VM -ProcessorCount $vmCpus -ErrorAction Stop
    Write-Log -Message "VM $virtualMachineName created successfully" -logfile $logFile
} Catch {
    Write-Log -Message "Could not create Virtual Machine $virtualMachineName with VHD $literalPathToNewVHD" -Level ERROR -logfile $logFile
    Write-Log -Message $error -Level ERROR -logfile $logFile
    Exit
}

Write-Log -Message "Enabling Guest Service Interface Integration Service on $virtualMachineName" -logfile $logFile
$error.clear()
try {
    Enable-VMIntegrationService –Name "Guest Service Interface" -VMName $virtualMachineName -ErrorAction Stop
    Write-Log -Message "Guest Service Interface Integration Service on $virtualMachineName enabled successfully" -logfile $logFile
} Catch {
    Write-Log -Message "Could not enable Guest Service Interface Integration Service on $virtualMachineName" -Level ERROR -logfile $logFile
    Write-Log -Message $error -Level ERROR -logfile $logFile
    Exit
}

Write-Output "Starting up $virtualMachineName"
$error.clear()
try { 
    # Check HeartBeat
    $timer = 0
    $timerLimit = 600
    $timerIncrement = 20
    ($startResult = Start-VM –Name $virtualMachineName -ErrorAction Stop) | out-null
    $vmStatus = Get-VMIntegrationService -VMName $virtualMachineName -Name Heartbeat
    while ($vmStatus.PrimaryStatusDescription -ne "OK" -And $timer -lt $timerLimit)
    {
        sleep $timerIncrement
        $timer = $timer + $timerIncrement
        Write-Log -Message "Waiting for $virtualMachineName HeartBeat" -Level INFO -logfile $logFile
        $vmStatus = Get-VMIntegrationService -VMName $virtualMachineName -Name Heartbeat       
    }
    If ($timer -ge $timerLimit) {
        Write-Log -Message "HeartBeat timed out while starting up $virtualMachineName" -Level ERROR -logfile $logFile
        Write-Log -Message $error -Level ERROR -logfile $logFile
        Exit 1
    }
    Write-Log -Message "HeartBeat is UP on $virtualMachineName" -logfile $logFile
} catch {
    Write-Log -Message "HeartBeat is DOWN on $virtualMachineName" -Level ERROR -logfile $logFile
    Write-Log -Message $error -Level ERROR -logfile $logFile
    Exit 1
}

# Check IP Address
($vmIPAddress = (Get-VMNetworkAdapter -VMName $virtualMachineName -Name 'Network Adapter').IPAddresses | where { $_ -match "\." } ) | out-null
$timer = 0
$timerLimit = 600
$timerIncrement = 20
while ( !$vmIPAddress -And $timer -lt $timerLimit)
{
    sleep $timerIncrement
    $timer = $timer + $timerIncrement
    Write-Log -Message "Waiting for $VirtualMachineName IP Address" -Level INFO -logfile $logFile
    ($vmIPAddress = (Get-VMNetworkAdapter -VMName $virtualMachineName -Name 'Network Adapter').IPAddresses | where { $_ -match "\." } ) | out-null
}
If ($timer -ge $timerLimit) {
    Write-Log -Message "$virtualMachineName get IP Address timed out" -Level ERROR -logfile $logFile
    Exit
}
Write-Log -Message "IP Address obtained for $virtualMachineName is: $vmIPAddress" -Level INFO -logfile $logFile
Return $vmIPAddress