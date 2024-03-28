# only worry about getting rid of wsl containers for now, not uninstalling WSL
wsl --shutdown
wsl --unregister Ubuntu-22.04
wsl --unregister alpine_docker
wsl --unregister alpine_data
