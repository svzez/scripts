# newvmcopy.ps1
A powershell script that creates HyperV VMs from a base disk.  
Accepts multiple arguments from command line.

## Pre requisites
* HyperV server
* Windows 2012 R2 +

## Usage
```sh
SYNOPSIS
    Creates copies of Windows VMs from a base disk. It returns the VM's IP address.  It runs on a local Hyper-V server.
    
    
SYNTAX
    C:\Users\Administrator\Desktop\newvmcopy.ps1 [-pathToBaseVHD] <String> [-pathToWorkingDir] <String> [[-virtualMachineName] <String>] [-virtualSwitch] <String> [[-vmCpus] <Int32>] [[-vmRam] <Int64>] [[-generation] <Int32>] [[-logFile] <String>] 
    [<CommonParameters>]
    
    
DESCRIPTION
    It works based on a base VHD or VHDX disk.  The base disk is copied to $pathToWorkingDir and it's used to create a new Virtual Machine.
    The VM is started and it waits until it can get an IP address from a DHCP server.
    

PARAMETERS
    -pathToBaseVHD <String>
        Location to the Base VHD or VHDX
        
    -pathToWorkingDir <String>
        Location for the new Hyper-V Virtual Machine Virtual disk
        
    -virtualMachineName <String>
        Virtual Machine Name to be created and exported
        
    -virtualSwitch <String>
        Virtual Switch to connect the VM in order to get an IP address
        
    -vmCpus <Int32>
        Number of CPUs to be configured in the Virtual Machine
        
    -vmRam <Int64>
        Amount of RAM to be configured in the Virtual Machine
        
    -generation <Int32>
        Generation for the new Virtual Machine
        
    -logFile <String>
        Log file.  If not there, it will write the output to the console
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 

```

## Example

Full tests with plot, saving and reading info from/to specified paths
```sh
C:\PS>.\NewVMCopy.ps1 -virtualMachineName NewVMCopy -pathToBaseVHD C:\BaseVHDs\WindowsServer2012R2.vhdx -pathToWorkingDir -virtualSwitch Network1 C:\temp -logFile logfile.txt
```