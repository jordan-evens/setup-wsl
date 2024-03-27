dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
# dism is supposed to work with newer versions of windows and Enable-WindowsOptionalFeature with older versions
# but Enable-WindowsOptionalFeature seems to still work in newer versions so stick to that
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
