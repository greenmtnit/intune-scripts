<#
PowerShell script to deploy a desktop shortcut to a website via Intune.

# Marker 
Uses a registry key to mark that the script ran. Used for Intune app detection rules.

# Icon:
Put .ico file in a publicly available location such as a public Wasabi or S3 bucket. Change the link URL in the script as needed.
Tip: use https://redketchup.io/icon-converter to create custom icons

# INTUNE DEPLOYMENT

Wrap this as a .intunewin app using IntuneWinAppUtil.exe and deploy as an Intune Win32 app.

Install command:
%windir%\SysNative\WindowsPowershell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -File .\Create-DesktopShortcut.ps1

Install behavior: System

Detection Rules:
Registry Rule 1:
    Key Path: HKEY_LOCAL_MACHINE\SOFTWARE\Green Mountain IT Solutions\Scripts
    Value Name: WebsiteDesktopShortcutScriptRan
    Detection method: Integer comparision
    Operator: Equals
    Value: 1
    Associated with a 32-bit app on 64-bit clients: No
    
Assignments:
    Assign to devices device groups
    The shortcut is deployed on the Public desktop and will appear for all users, so per-user deployment doesn't make sense here.
    You could adapt the script to run in user context and only put on the user's desktop if desired.

#>

# CHANGE THESE
$shortcutPath = "C:\Users\Public\Desktop\Website.lnk"
$targetURLPath = "https://mywebsite.com"
$iconURL = "https://s3.us-east-1.wasabisys.com/gmits-public/Website.ico"
$iconFileDownloadPath = "C:\Program Files\Green Mountain IT Solutions\Scripts\Website.ico"


# Change these if you want (i.e. if deploying multiple shortcuts), 
# but don't forget to edit your Intune app detection rules accordingly
$parentKeyPath = "HKLM:\SOFTWARE\Green Mountain IT Solutions"
$subKeyPath = "$parentKeyPath\Scripts"
$registryValueName = "WebsiteDesktopShortcutScriptRan"
$value = 1 # set to 1 to indicate script ran


# Shouldn't need to edit below this line
# ------------------------------------------------ #

$existingValue = Get-ItemProperty -Path $subKeyPath -Name $registryValueName -ErrorAction SilentlyContinue

if ($existingValue -ne $null) {
    # Script already ran once
    Write-Host "Script already ran. Exiting."
    exit 0
}
    
if (-not (Test-Path -Path $parentKeyPath)) {
    New-Item -Path $parentKeyPath -Force | Out-Null
}

# Ensure the sub key exists
if (-not (Test-Path -Path $subKeyPath)) {
    New-Item -Path $subKeyPath -Force | Out-Null
}

# Set the registry value to indicate the script ran once
New-ItemProperty -Path $subKeyPath -Name $registryValueName -Value $value -PropertyType DWord -Force

# Create working directories
$baseDirectory = "C:\Program Files\Green Mountain IT Solutions"
$scriptsDirectory = Join-Path -Path $baseDirectory -ChildPath "Scripts"
$workingDirectory = Join-Path -Path $baseDirectory -ChildPath "RMM"
$toolsDirectory = Join-Path -Path $workingDirectory -ChildPath "Tools"

$directories = @($baseDirectory, $scriptsDirectory, $workingDirectory, $toolsDirectory)

foreach ($dir in $directories) {
    if (-not (Test-Path -Path $dir -PathType Container)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
    else {
    }
}

# Download icon file
$ProgressPreference = "SilentlyContinue"
Invoke-Webrequest -URI $iconURL -Outfile $iconFileDownloadPath

# Create the shortcut
$WshShell = New-Object -ComObject WScript.Shell
$shortcutObject = $WshShell.CreateShortcut($shortcutPath)
$shortcutObject.TargetPath = $targetURLPath
$shortcutObject.IconLocation = $iconFileDownloadPath
$shortcutObject.Save()

# Change permissions to allow deletion
$acl = Get-Acl -Path $shortcutPath
$readRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Read", "Allow")
$deleteRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Delete", "Allow")
$acl.AddAccessRule($readRule)
$acl.AddAccessRule($deleteRule)
Set-Acl -Path $shortcutPath -AclObject $acl