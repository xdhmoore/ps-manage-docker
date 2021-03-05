
## PowerShell Functions for Starting/Stopping Docker & WSL

This is a collection of semi-hacky functions for starting/stopping Docker and/or WSL.

## Requirements

* Tested only in PowerShell Core
* Requires AutoHotkey to be installed in order to shutdown docker desktop via the system tray. I did say "semi-hacky"...
* Modify the variables at the top of Manage-DockerWsl.ps1 as needed.
* Run the following or add to your PowerShell profile:
`Import-Module ./path/to/Manage-DockerWsl.ps1`

## Some of the Functions:

### Start/Stop things:
These are non-blocking, but can be made to wait with the `-Wait` flag. Some debug info is available with the `-Debug` flag.
* Stop-Docker
* Stop-Wsl
* Start-Docker
* Start-Wsl
* Restart-Docker
* Restart-Wsl

### Is Docker "running", "stopped", or "unknown"?
* Get-DockerStatus

### Display/Watch a meter of the Wsl Swap file size:
This is a little compute-heavy. There are probably better ways:
* Watch-Swap
* Show-Swap


