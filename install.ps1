$WSL_DISTRO = "Ubuntu-22.04"
$DIR = "$PWD"
# use script directory if there is one
if ($null -ne $MyInvocation.MyCommand.Path) {
    $DIR = (Split-Path $MyInvocation.MyCommand.Path)
}
echo "Using directory $DIR to install WSL automounted VHDXs"
$DIR_DOWNLOAD = "$DIR\download"
$DIR_SCRIPTS = "$DIR\scripts"
$DIR_VHDX = "$DIR\vhdx"
$FILE_VHDX = "$DIR_VHDX\ext4.vhdx"

Push-Location $DIR
function Ensure-Download {
    param ($Url, $FileName)
    $Path = "$DIR_DOWNLOAD\$FileName"
    if (!(Test-Path $Path)) {
        New-Item -Force $DIR_DOWNLOAD -ItemType Directory
        echo "Downloading $FileName"
        Invoke-WebRequest -Uri $Url -OutFile "$Path"
    }
    return "$Path"
}

function Setup-Automount {
    param ($Distro)
    $Path = "$DIR_VHDX\$Distro"
    echo "Setting up alpine distro in $Path"
    if (!(Test-Path $FILE_VHDX)) {
        New-Item -Force "$DIR_VHDX" -ItemType Directory
        Push-Location "$DIR_VHDX"
        echo "Setting up alpine to host shared data using VHDX files"
        $ALPINE_ZIP = Ensure-Download https://github.com/yuk7/AlpineWSL/releases/download/3.18.4-0/Alpine.zip "Alpine.zip"
        Expand-Archive -force $ALPINE_ZIP
        # if we use multiple Alpine distros then we can automount the disks
        Push-Location Alpine
        echo "continue" | .\Alpine.exe
        copy ext4.vhdx "$FILE_VHDX"
        Pop-Location
        wsl --shutdown
        wsl --unregister Alpine
    }
    $FILE_DISTRO = "$Path\$distro.vhdx"
    echo "Copying alpine base image to $FILE_DISTRO"
    New-Item -Force "$Path" -ItemType Directory
    copy "$FILE_VHDX" "$FILE_DISTRO"
    Push-Location "$Path"
    wsl --import-in-place "$Distro" "$FILE_DISTRO"
    wsl -d "$Distro" mkdir -p /mnt/automount
    wsl -d "$Distro" touch "/mnt/automount/this_is_$Distro"
    Pop-Location
    Pop-Location
    return "$Path"
}

# run as admin
echo "Installing requirements for WSL"
echo "You will be prompted to run as an admin"
Start-Process -Wait -Verb runas powershell "$DIR_SCRIPTS\00_install_admin.ps1"
echo "Setting WSL to use version 2"
wsl --set-default-version 2
echo "Updating WSL"
wsl --update --web-download
wsl --shutdown
echo "Installing WSL distribution $WSL_DISTRO"

# this might seem silly, but if we do it this way then we can have the data vhdx mount automatically for the Ubuntu distro
# while still separating the OS from the data
Setup-Automount alpine_data
Setup-Automount alpine_docker

# might need to restart host after first attempt for wsl --install to work
# will prompt for default user but we don't need to know what gets entered
echo "Installing $WSL_DISTRO will prompt for a default user name and end at a prompt"
echo "When you get to the prompt, just type `exit` to leave it and continue the installation"
wsl --install -d $WSL_DISTRO --web-download
wsl --set-default $WSL_DISTRO
Push-Location $DIR_SCRIPTS
echo "Enter password for user you just created for $WSL_DISTRO when prompted"
wsl ./setup_automount.sh
Pop-Location
wsl --shutdown
Pop-Location
