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


function Ensure-Name {
    param (${Name})
    wsl sudo sed -i "/${Name}/d" /etc/hosts
    ((Resolve-DnsName ${Name} -Type A) | ForEach-Object {
        $ip=$_.IpAddress
        echo "${ip} ${Name}"
    })  | wsl sudo tee -a /etc/hosts
}

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

${searcher} = [adsisearcher]"(samaccountname=${env:USERNAME})"
${username} = ${env:USERNAME}
${email} = ${searcher}.FindOne().Properties.mail
${surname} = ${searcher}.FindOne().Properties.sn
${givenname} = ${searcher}.FindOne().Properties.givenname
${name} = "$givenname $surname"
echo "User detected as:
$name
$email
"

# might need to restart host after first attempt for wsl --install to work
# will prompt for default user but we don't need to know what gets entered
echo "Installing $WSL_DISTRO will prompt for a default user name and end at a prompt"
echo "When you get to the prompt, just type ""exit"" to leave it and continue the installation"
wsl --install -d $WSL_DISTRO --web-download
wsl --set-default $WSL_DISTRO

echo "Turning password for sudo off for now"
wsl --user root sed -i 's/\(%sudo[\t ]*ALL.*\)/# \1\n%sudo ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers

Push-Location $DIR_SCRIPTS
wsl ./setup_automount.sh
Pop-Location
wsl --shutdown

# was having a lot of issues with SSL certificates in docker and WSL
echo "Copying windows certificates into WSL distro"

echo "Exporting certificates"
$DIR_CERTS = "$DIR\certs"
New-Item -Force "$DIR_CERTS" -ItemType Directory
&"$DIR_SCRIPTS\export_certs.ps1"

echo "Importing certificates into WSL"
Push-Location "$DIR_CERTS"
wsl "../scripts/import_certs.sh"
Pop-Location

echo "Turning metadata on in WSL so file permissions work"
wsl --user root bash -c "printf '[automount]\nmetadata=true\n' >> /etc/wsl.conf"

wsl --shutdown

# even after everything, apt-get isn't seeing some servers when updating
echo "Resolving hostnames so WSL can see them for sure"
Ensure-Name security.ubuntu.com
Ensure-Name archive.ubuntu.com
Ensure-Name download.docker.com

Push-Location "$DIR_SCRIPTS"
echo "Setting up docker in WSL"
wsl ./setup_docker.sh
wsl docker run --rm hello-world
Pop-Location

echo "Setting up user account in WSL for github with '""${name}"" <${email}>'"
wsl git config --global user.name "$name"
wsl git config --global user.email "$email"
wsl git config --global init.defaultBranch main
# DNS is broken in general right now?
Ensure-Name github.com

wsl ./scripts/setup_user.sh

echo "Turning off /etc/resolv.conf generation in WSL so /etc/hosts stays"
wsl --user root bash -c "printf '[network]\ngenerateResolvConf=false\n' >> /etc/wsl.conf"
echo "Adding nameservers to /etc/resolv.conf"
(powershell.exe -Command '(Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses | ForEach-Object { echo "$_" }') | wsl --user root /bin/bash -c "tr -d '\\r' | sed 's/\(.*\)/nameserver \1/g' | tee -a /etc/resolv.conf"


echo "Turning password for sudo back on"
wsl --user root sed -i '/^%sudo[\t ]*ALL.*/d;/^# \(%sudo[\t ]*ALL.*\)/{s/^# //g}' /etc/sudoers

# exit $DIR
Pop-Location
