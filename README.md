# Scripwal
## Usage  
scripwal.ps1 [-help] [-systemwide] [-registry] [-custom_profile]  
-help: Displays help  
-systemwide: Apply registry tweaks system-wide (default: false)  
-registry: Apply registry tweaks (default: true)  
-custom_profile: Apply custom profile (default: true)

## Features
Scripwal is my customization script for Windows that does the following:
* Hides shortcut and compression indicators on files and folders
* Removes the following from right-click context menu:
  * Option to open Command Prompt
  * Git GUI and Git Bash
  * "Scan with Windows Defender..."
  * "Include in library"
  * "Pin to Start"
  * "Restore previous versions"
* Adds right click context option to open PowerShell in the targeted folder
* Disables Aero Shake
* Shows hidden files
* Shows file extensions
* Allows use of built-in applications on the built-in administrator account
* Adds a custom PowerShell profile which does the following:
  * Adds *git* as a command and adds Git folders to envrionment variables
  * Enables posh-git prompts
  * Start SSH-agent and adds *id_ed25519* key from *$env:USERPROFILE/.ssh/* with lifetime of 6 hours