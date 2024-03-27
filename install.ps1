# try to use script path but just use current directory if failed
$DIR = "$PWD"
$DIR = (Split-Path $MyInvocation.MyCommand.Path)

Push-Location $DIR
function Ensure-Download {
    param ($Url, $FileName)
    if (!(Test-Path $FileName)) {
        echo "Downloading $FileName"
        Invoke-WebRequest -Uri $Url -OutFile $FileName
    }
    return $FileName
}
# download files that admin script needs
$WSL_MSI = Ensure-Download https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi "wsl_update_x64.msi"

# run as admin
echo "Installing requirements for WSL"
Start-Process -Wait -Verb runas powershell "$DIR\00_install_admin.ps1"
echo "Setting WSL to use version 2"
wsl --set-default-version 2
echo "Updating WSL"
wsl --update --web-download
echo "Installing WSL distribution"
# this might seem silly, but if we do it this way then we can have the data vhdx mount automatically for the Ubuntu distro
# while still separating the OS from the data
$ALPINE_ZIP = Ensure-Download https://github.com/yuk7/AlpineWSL/releases/download/3.18.4-0/Alpine.zip "Alpine.zip"
Expand-Archive -force $ALPINE_ZIP
# if we use multiple Alpine distros then we can automount the disks
Push-Location Alpine
.\Alpine.exe
wsl -d Alpine mkdir -p /mnt/automount
mkdir -p ..\alpine-data
mkdir -p ..\alpine-docker
copy ext4.vhdx ..\alpine-data\alpine-data.vhdx
copy ext4.vhdx ..\alpine-docker\alpine-docker.vhdx
wsl --unregister Alpine
cd ..\alpine-data
wsl --import-in-place alpine-data alpine-data.vhdx
wsl -d alpine-data touch /mnt/automount/this_is_alpine_data
cd ..\alpine-docker
wsl --import-in-place alpine-docker alpine-docker.vhdx
wsl -d alpine-docker touch /mnt/automount/this_is_alpine_docker
Pop-Location

# might need to restart host after first attempt for wsl --install to work
# will prompt for default user but we don't need to know what gets entered
wsl --install -d Ubuntu-22.04 --web-download
wsl --set-default Ubuntu-22.04
wsl ./setup_automount.sh
wsl --shutdown
Pop-Location
