<# 
    Windows Updates

    -listonly will get the list of available updates
    -DefaultUsername and -DefaultPassword will schedule a reboot and a re-run (if needed).
    -logPath to specify the path to the logfile
#>

 param (
    [switch]$listonly = $false,
    [string]$DefaultUsername,
    [string]$DefaultPassword,
    [string]$logPath
 )


function Clean-WinLogon {

    $RegistryWinLogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
   
    #setting registry values
    Set-ItemProperty $RegistryWinLogonPath "AutoAdminLogon" -Value "0" -type String  
    Set-ItemProperty $RegistryWinLogonPath "DefaultUsername" -Value "" -type String  
    Set-ItemProperty $RegistryWinLogonPath "DefaultPassword" -Value "" -type String
    Set-ItemProperty $RegistryWinLogonPath "AutoLogonCount" -Value "0" -type DWord

}

function Write-Log {
    $timestamp = get-date
    $line = "{0}: {1}" -f $timestamp,$args[0]
    if (Test-Path $logfilename) {
        Write-Output $line >> $logfilename
    } else {
        Write-Output $line > $logfilename
    }
}

function Next-Reboot {

    $Invocation = $script:MyInvocation.MyCommand.Path
    $RegistryWinLogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $RegistryRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    $RunOnceCommandLine = "powershell -File `"$Invocation`" -DefaultUsername $DefaultUsername -DefaultPassword $DefaultPassword"

    #setting registry values
    Write-Log "Next run: $RunOnceCommandLine"
    Set-ItemProperty $RegistryWinLogonPath "AutoAdminLogon" -Value "1" -type String  
    Set-ItemProperty $RegistryWinLogonPath "DefaultUsername" -Value "$DefaultUsername" -type String  
    Set-ItemProperty $RegistryWinLogonPath "DefaultPassword" -Value "$DefaultPassword" -type String
    Set-ItemProperty $RegistryWinLogonPath "AutoLogonCount" -Value "1" -type DWord
    Set-ItemProperty $RegistryRunOncePath "(Default)" -Value "$RunOnceCommandLine" -type String
}
if ($logPath) {
    $logfilename = "$logPath\WindowsUpdates-log$(get-date -f yyyyMMdd_HHmm).txt"
} else {
    $logfilename = ".\WindowsUpdates-log$(get-date -f yyyyMMdd_HHmm).txt"
}

$updatesDone = $false
$reboot = $false

Write-Log "Script started"

#Check for available updates
Write-Log "Creating Update Session"
$Session = New-Object -com "Microsoft.Update.Session" 
Write-Log "Searching for updates..."
if ($listonly) {
    Write-Log "Updates will be listed only"
}
$Search = $Session.CreateUpdateSearcher() 
$SearchResults = $Search.Search("type='software' and IsInstalled=0 and IsHidden=0") 
$AvailableUpdates = $SearchResults.Updates 
$totalCount = $AvailableUpdates.count
if($totalCount -lt 1) { 
    Write-Log "No available updates"
    $updatesDone = $true
} else {
    Write-Log "There are $totalCount updates available."
    $count = 1 
    $AvailableUpdates | ForEach-Object {
        $UpdateTitle =  $_.Title
        Write-Log "$UpdateTitle found"
        if (!$listonly) {
            if ($_.InstallationBehavior.CanRequestUserInput -ne $TRUE) {
                if (!($_.EulaAccepted)) {
                    $_.AcceptEula()
                }
                $DownloadCollection = New-Object -com "Microsoft.Update.UpdateColl"
                $InstallCollection = New-Object -com "Microsoft.Update.UpdateColl"
                $DownloadCollection.Add($_) | Out-Null
                Write-Log "Downloading update ($count/$totalCount): $UpdateTitle"
                $Downloader = $Session.CreateUpdateDownloader() 
                $Downloader.Updates = $DownloadCollection 
                $Downloader.Download() | Out-Null
                if ($_.IsDownloaded) {
                    Write-Log "Download complete"
                    Write-Log "Installing update ($count/$totalCount): $UpdateTitle" 
                    $InstallCollection.Add($_) | Out-Null
                    $Installer = $Session.CreateUpdateInstaller() 
                    $Installer.Updates = $InstallCollection 
                    $Results = $Installer.Install()
                    Write-Log "Installation finished"
                } else {
                    Write-Log "Problem downloading $UpdateTitle"
                }
                $count = $count + 1
                if ($Results.RebootRequired) {
                    $reboot = $true
                }
            } else {
                Write-Log "$UpdateTitle requires user input.  It will not be installed "
            }

        }
    }
}
# Reboot if needed
if ($reboot) { 
    try {
        if ($DefaultUsername -and $DefaultPassword) {
            Next-Reboot
        } else {
            Write-Log "No credentials provided.  After the next reboot, the script needs to be run again."
        }
    }
    catch {
        Write-Log "An error had occured while setting registry items for next reboot"
    }
    Write-Log "Reboot required.  Restarting..."
    Restart-Computer -Force
} else { 
    Write-Log "No reboot required."
    $updatesDone = $true
}

if ($updatesDone) {
    Clean-WinLogon
}
