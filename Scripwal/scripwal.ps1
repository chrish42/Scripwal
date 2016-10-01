# Switches if the changes should be applied to the whole machine or only for the current user
# Default option is to apply changes only to the current user
param(
	[switch]$help           = $false,
	[switch]$systemwide     = $false,
	[switch]$registry       = $true,
	[switch]$custom_profile = $true
)

# Print the usage and help, if requested
if ($help)
{
	Write-Host "Usage: ./scripwal.ps1 [-h] [-s] [-r] [-c]"
	Write-Host ""
	Write-Host "Options:"
	Write-Host "            -help  Show help"
	Write-Host "      -systemwide  Apply the changes to the whole local machine (default: false)"
	Write-Host "        -registry  Apply some registry tweaks (default: true)"
	Write-Host "  -custom_profile  Add a custom PowerShell profile, which overrides the default profile (default: true)"
	exit
}

# Check if we have administrative privileges (we need those!)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Write-Host "Please run the script as an administrator."
	exit
}

# Current working directory
$cwd = $PSScriptRoot

# Import our common module forcefully to ensure that changes are loaded
$common_module_path = "$PSScriptRoot/common.psm1"
Import-Module $common_module_path -Force

# Registry tweaks
if ($registry)
{
	[ScriptBlock] $registry_tweaks =
	{
		param(
			[string]$common_module_path,
			[string]$cwd,
			[switch]$systemwide
		)

		Import-Module $common_module_path

		# Mount the HKEY_CLASSES_ROOT registry drive, so it can be accessed
		New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue | Out-Null

		# Choose the base registery depending on the $systemwide flag
		$breg = ({HKLM:},{HKCU:})[!$systemwide]

		# Copy the blank icon to System32
		CopyItem "$cwd/blank.ico" "C:/Windows/System32/"

		# Some modifications to different icons
		CreateItem "$breg/SOFTWARE/Microsoft/Windows/CurrentVersion/Explorer/Shell Icons/"
		ModifyItem "$breg/SOFTWARE/Microsoft/Windows/CurrentVersion/Explorer/Shell Icons/" "179" "blank.ico,0" # Removes compression indicator arrows
		ModifyItem "$breg/SOFTWARE/Microsoft/Windows/CurrentVersion/Explorer/Shell Icons/" "29" "blank.ico,0"  # Removes shortcut indicator arrows

		# The path to the folder that contains PowerShell profiles
		$profile_folder = "$env:USERPROFILE/Documents/WindowsPowerShell"

		# This is for easing the accessing of "Directory/Background/..." and "Directory/..." without having to re-type the commands.
		@("", "Background").ForEach({
			# This represents the current key for which to access the context menu items
			$key = $_

			# Add "Open PowerShell" option to the context menu
			CreateItem "HKCR:/Directory/$key/shell/powershell/"
			ModifyItem "HKCR:/Directory/$key/shell/powershell/" "(Default)" "Open PowerShell"
			ModifyItem "HKCR:/Directory/$key/shell/powershell/" "Icon" "`"$PSHOME/powershell.exe`",0"
			CreateItem "HKCR:/Directory/$key/shell/powershell/command/"
			ModifyItem "HKCR:/Directory/$key/shell/powershell/command/" "(Default)" "`"$PSHOME/powershell.exe`" -NoExit -NoProfile -ExecutionPolicy Unrestricted -File `"$profile_folder/custom.profile.ps1`" `"%V`""

			# Remove "Git GUI Here" and "Git Bash Here" from the context menu
			DeleteRegistryKey "HKCR:/Directory/$key/shell/git_gui"
			DeleteRegistryKey "HKCR:/Directory/$key/shell/git_shell"

			# Remove "Open command window here" from the context menu
			DeleteRegistryKey "HKCR:/Directory/$key/shell/cmd"
		})

		# Remove "Scan with Windows Defender..." from the context menu
		DeleteRegistryKey "HKCR:/CLSID/{09A47860-11B0-4DA5-AFA5-26D86198A780}"

		# Remove "Include in library" from the context menu
		DeleteRegistryKey "HKCR:/Folder/ShellEx/ContextMenuHandlers/Library Location"

		# Remove "Pin to Start" from the context menu
		DeleteRegistryKey "HKCR:/Folder/ShellEx/ContextMenuHandlers/PintoStartScreen"

		# Remove "Restore previous versions" from the context menu
		DeleteRegistryKey "HKCR:/CLSID/{450D8FBA-AD25-11D0-98A8-0800361B1103}/shellex/ContextMenuHandlers/{596AB062-B4D2-4215-9F74-E9109B0A8153}"
		DeleteRegistryKey "HKCR:/AllFilesystemObjects/shellex/ContextMenuHandlers/{596AB062-B4D2-4215-9F74-E9109B0A8153}"
		DeleteRegistryKey "HKCR:/Directory/shellex/ContextMenuHandlers/{596AB062-B4D2-4215-9F74-E9109B0A8153}"

		# Disable Aero Shake (shaking windows to minimize everything)
		ModifyItem "$breg/SOFTWARE/Microsoft/Windows/CurrentVersion/Explorer/Advanced/" "DisallowShaking" 1 "DWORD"

		# Show hidden files
		ModifyItem "$breg/SOFTWARE/Microsoft/Windows/CurrentVersion/Explorer/Advanced/" "Hidden" 1 "DWORD"

		# Show file extensions
		ModifyItem "$breg/SOFTWARE/Microsoft/Windows/CurrentVersion/Explorer/Advanced/" "HideFileExt" 0 "DWORD"

		# Allow use of built-in applications on the built-in administrator account
		ModifyItem "HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/Policies/System/" "FilterAdministratorToken" 1 "DWORD"
		ModifyItem "HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/Policies/System/UIPI/" "(Default)" "1"

		Write-Output "Registry tweaks applied successfully"
	}

	StartJob $registry_tweaks "Registry tweaks" @($common_module_path, $cwd, $systemwide)
}

# Custom PowerShell profile
if ($custom_profile)
{
	[ScriptBlock] $custom_profile =
	{
		param(
			[string]$common_module_path,
			[string]$cwd
		)

		Import-Module $common_module_path

		# The path to the folder that contains PowerShell profiles
		$profile_folder = "$env:USERPROFILE/Documents/WindowsPowerShell"

		# Copy our custom PowerShell profile to the appropriate folder
		CreateDirectory "$profile_folder/"
		CopyItem        "$cwd/custom.profile.ps1" "$profile_folder/"

		# Also copy the default profile that PowerShell executes on startup, so we can use our custom profile instead
		CopyItem        "$cwd/Microsoft.PowerShell_profile.ps1" "$profile_folder/"

		Write-Output "Successfully applied the custom profile"
	}

	StartJob $custom_profile "Apply custom profile" @($common_module_path, $cwd)
}

@(Get-Job).ForEach({
	# Wait for the job to finish, remove it and output its results
	Write-Host "$($_.Name) results:"
	Receive-Job -Job $_ -Wait -AutoRemoveJob | Write-Host
	Write-Host ""
})