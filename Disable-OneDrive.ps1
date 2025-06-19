<#
Disable-OneDrive.ps1

Disables OneDrive startup for the current user and removes OneDrive from File Explorer.

# INTUNE DEPLOYMENT
Wrap this as a .intunewin app using IntuneWinAppUtil.exe and deploy as an Intune Win32 app.

Install command:
%windir%\SysNative\WindowsPowershell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -File .\Disable-OneDrive.ps1 -LogOutput

Install behavior: user

Detection Rules:
Registry Rule 1:
    Key Path: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
    Value Name: OneDrive
    Detection method: Value does not exist
    
Registry Rule 2:
    Key Path: HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}
    Value Name: [blank]
    Detection method: Key does not exist

Assignments:
    Assign to Users or User groups

#>

param(
    [switch]$LogOutput
)

# START LOGGING
if ($LogOutput) {
    ## Define the log directory and log file path
    $logDirectory = "C:\!TECH\DisableOneDriveScriptLogs" # change name if desired
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = "$logDirectory\DisableOneDriveScript_$timestamp.txt"

    # Create the log directory if it does not exist
    if (-not (Test-Path -Path $logDirectory -ErrorAction SilentlyContinue)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }

    # Start logging to a transcript
    Start-Transcript -Path $logFile -Append
    Write-Output "Logging output to: $logFile"
}

# MAIN SCRIPT ACTION

# Disable Startup
$StartupRegKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$StartupRegValue = "OneDrive"
if (Get-ItemProperty -Name $StartupRegValue -LiteralPath $StartupRegKey -ErrorAction SilentlyContinue) {
    Remove-ItemProperty -Path $StartupRegKey -Name $StartupRegValue -Verbose
}
else {
    Write-Output "Value $StartupRegValue not found in key $StartupRegKey."
}

#Remove From File Explorer
$ExplorerRegKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path -Path $ExplorerRegKey) {
    Remove-Item -Path $ExplorerRegKey -Force -Verbose
    Write-Output "Removed OneDrive File Explorer reg key $ExplorerRegKey."
} else {
    Write-Output "OneDrive File Explorer reg key does not exist at $ExplorerRegKey."
}

#Stop OneDrive process
Stop-Process -ProcessName OneDrive -Verbose

# END LOGGING
if ($LogOutput) {
    Stop-Transcript
}