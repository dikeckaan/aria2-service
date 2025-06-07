@'
# if this file cannot run by execution policy, copy this line below and paste into powershell window then drag-drop this script into window and it will run
Set-ExecutionPolicy RemoteSigned -scope Process -Force

# for admin privileges if isn't running as an admin
if (!(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) 
{
	#elevate script and exit current non-elevated runtime
	Start-Process -FilePath 'powershell' -ArgumentList ('-File', $MyInvocation.MyCommand.Source, $args | %{ $_ }) -Verb RunAs
	exit
}

# Define variables
$aria2Version = "1.37.0"
$aria2Platform = "win-64bit"
$aria2Build = "build1"

$aria2Dir = "$env:SystemDrive\aria2"
$downloadDir = "$env:USERPROFILE\Downloads"
$downloadFileName = "aria2-$aria2Version-$aria2Platform-$aria2Build"
$aria2Url = "https://github.com/aria2/aria2/releases/latest/download/$downloadFileName.zip"
$aria2Zip = "$aria2Dir\aria2.zip"
$aria2ExePath = "$aria2Dir\aria2c.exe"
$sessionFile="$aria2Dir\.aria2.session"
$uriHandler="$aria2Dir\aria2-uri-handler.ps1"
$scheme = "aria2"
$command = "mshta vbscript:Execute(""CreateObject('Wscript.Shell').Run 'powershell -NoLogo -Command """"& ''$uriHandler'' ''%1''""""', 0 : window.close"")"


$nssmUrl = "https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip"
$nssmZip = "$aria2Dir\nssm.zip"
$nssmExePath = "$aria2Dir\nssm.exe"

$serviceName = "Aria2"
$configFile = "$aria2Dir\aria2.conf"

# Check if Aria2 service exists
$serviceExists = sc.exe query $serviceName | Select-String "STATE"

if ($serviceExists) {
    # Prompt for removal
    $confirmation = Read-Host "Aria2 is already installed. Do you want to remove it? (Y/N)"
    if ($confirmation -eq "Y" -or $confirmation -eq "y") {
	& $nssmExePath stop $serviceName confirm
        & $nssmExePath remove $serviceName confirm
        Write-Host "Aria2 service removed successfully."

        if (Test-Path $aria2Dir) {
            Remove-Item -Path $aria2Dir -Recurse -Force
            Write-Host "Aria2 files deleted successfully."
        }

	# Remove the registry keys
	Remove-Item -Path "HKCU:\Software\Classes\$scheme" -Recurse -Force -ErrorAction SilentlyContinue
	Write-Host "Unregistered ${scheme}:// URI scheme successfully!"
    } else {
        Write-Host "Aria2 installation remains unchanged."
    }
    Start-Sleep -Seconds 1  # Small delay to ensure completion
    Remove-Item -Path $MyInvocation.MyCommand.Path -Force
    exit
}

# Create directory if it doesn't exist
if (!(Test-Path $aria2Dir)) {
    New-Item -ItemType Directory -Path $aria2Dir | Out-Null
}

# Download NSSM
Write-Host "Downloading NSSM..."
Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip

# Extract only nssm.exe from the ZIP
Write-Host "Extracting NSSM..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
$nssmArchive = [System.IO.Compression.ZipFile]::OpenRead($nssmZip)

foreach ($entry in $nssmArchive.Entries) {
    if ($entry.Name -eq "nssm.exe") {
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $nssmExePath, $true)
        Write-Host "Extracted: $nssmExePath"
	break
    }
}

$nssmArchive.Dispose()

# Remove NSSM zip file after extraction
Remove-Item $nssmZip

# Download aria2c
Write-Host "Downloading Aria2..."
Invoke-WebRequest -Uri $aria2Url -OutFile $aria2Zip

# Extract only aria2c.exe from the ZIP
Write-Host "Extracting Aria2..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
$aria2Archive = [System.IO.Compression.ZipFile]::OpenRead($aria2Zip)

foreach ($entry in $aria2Archive.Entries) {
    if ($entry.Name -eq "aria2c.exe") {
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $aria2ExePath, $true)
        Write-Host "Extracted: $aria2ExePath"
    }
}

$aria2Archive.Dispose()

# Remove Aria2 zip file after extraction
Remove-Item $aria2Zip

# Create the aria2 uri handler
@"
param (
    [string]$uri
)

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public class UrlHelper {
    [DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
    public static extern int UrlUnescapeW(string pszUrl, StringBuilder pszUnescaped, ref int pcchUnescaped, int dwFlags);
    
    public static string UnescapeUrl(string url) {
        StringBuilder buffer = new StringBuilder(1024);
        int length = buffer.Capacity;
        UrlUnescapeW(url, buffer, ref length, 0);
        return buffer.ToString();
    }
}
'@ -Language CSharp

# Validate input
if (-not $uri) {
    Write-Host "No URI provided."
    exit
}

# Unescape the URL
$decodedPath = [UrlHelper]::UnescapeUrl(($uri -replace "^aria2://browse/path=", ""))

# Check if the file exists
if (Test-Path $decodedPath -PathType Leaf) {
    Start-Process -FilePath "explorer.exe" -ArgumentList "/select,`"$decodedPath`""
} else {
    Write-Host "File not found: $decodedPath"
}
"@ | Out-File -Encoding utf8 $uriHandler

# Create the configuration file
@"
###############################
# Motrix Windows Aria2 config file
#
# @see https://aria2.github.io/manual/en/html/aria2c.html
###############################

################ RPC ################
enable-rpc=true
rpc-allow-origin-all=true
rpc-listen-all=true

################ File system ################
auto-save-interval=10
disk-cache=64M
file-allocation=falloc
no-file-allocation-limit=64M
save-session-interval=10
input-file=.aria2.session
save-session=.aria2.session

################ Task ################
bt-detach-seed-only=true
check-certificate=false
max-file-not-found=10
max-tries=0
retry-wait=10
connect-timeout=10
timeout=10
min-split-size=1M
http-accept-gzip=true
remote-time=true
summary-interval=0
content-disposition-default-utf8=true
user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36

################ BT Task ################
bt-enable-lpd=true
bt-hash-check-seed=true
bt-max-peers=128
bt-prioritize-piece=head
bt-remove-unselected-file=true
bt-seed-unverified=false
bt-tracker-connect-timeout=10
bt-tracker-timeout=10
dht-entry-point=dht.transmissionbt.com:6881
dht-entry-point6=dht.transmissionbt.com:6881
enable-dht=true
enable-dht6=true
enable-peer-exchange=true
peer-agent=Transmission/3.00
peer-id-prefix=-TR3000-
"@ | Out-File -Encoding utf8 $configFile

"" | Out-File -Encoding utf8 $sessionFile

# Install Aria2 service via NSSM
Write-Host "Installing Aria2 as a service via NSSM..."
& $nssmExePath install $serviceName $aria2ExePath "--conf-path=$configFile --dir=$downloadDir"
& $nssmExePath set $serviceName AppDirectory $aria2Dir
& $nssmExePath set $serviceName DisplayName "Aria2 Download Manager"
& $nssmExePath set $serviceName Description "Aria2 running as a service"
& $nssmExePath set $serviceName Start SERVICE_AUTO_START

# Start the service
Start-Service -Name $serviceName
Write-Host "Aria2 service installed successfully using NSSM!"

# Create registry keys
New-Item -Path "HKCU:\Software\Classes\$scheme" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$scheme" -Name "(Default)" -Value "URL:$scheme Protocol"
Set-ItemProperty -Path "HKCU:\Software\Classes\$scheme" -Name "URL Protocol" -Value ""

New-Item -Path "HKCU:\Software\Classes\$scheme\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$scheme\shell\open\command" -Name "(Default)" -Value $command

Write-Host "Registered ${scheme}:// URI scheme successfully!"

Start-Sleep -Seconds 1  # Small delay to ensure completion
Remove-Item -Path $MyInvocation.MyCommand.Path -Force

'@ | Out-File -Encoding utf8 "$env:TEMP\aria2.ps1"

Start-Process -FilePath 'powershell' -ArgumentList ('-File', "$env:TEMP\aria2.ps1", $args | %{ $_ }) -Verb RunAs
exit
