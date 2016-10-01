# Creates an item
function CreateItem([string] $path, [string] $item_type)
{
	if (!(Test-Path -LiteralPath $path))
	{
		Write-Verbose "Creating item: $path"

		if ($item_type)
		{
			New-Item -ItemType $item_type -Path $path | Out-Null
		}
		else
		{
			New-Item -Path $path | Out-Null
		}
	}
}

# Creates a directory
function CreateDirectory([string] $path)
{
	CreateItem $path "Directory"
}

# Deletes an existing registry key. Also deletes all the children by default.
function DeleteRegistryKey([string] $path, [bool] $recurse = $true)
{
	if (Test-Path -LiteralPath $path)
	{
		Write-Verbose "Deleting registry key: $path"
		if ($recurse)
		{
			Remove-Item -LiteralPath $path -Recurse
		}
		else
		{
			Remove-Item -LiteralPath $path
		}
	}
}

# Creates a new registry entry if one doesn't exist already, otherwise modifies the already existing one
function ModifyItem([string] $path, [string] $name, $value, [string] $type = "String")
{
	$item = Get-ItemProperty -LiteralPath $path -Name $name -ErrorAction SilentlyContinue

	if (($item -eq $null) -and ($item.Length -eq 0))
	{
		Write-Verbose "Creating registry entry: $path$name $type ($value)"
		New-ItemProperty -LiteralPath $path -Name $name -PropertyType $type -Value $value | Out-Null
	}
	elseif ($item.$name -ne $value)
	{
		Write-Verbose "Modifying registry entry: $path$name $type ($value)"
		Set-ItemProperty -LiteralPath $path -Name $name -Value $value
	}
}

# Copies an item from $path to $destination
function CopyItem([string] $path, [string] $destination)
{
	Copy-Item -LiteralPath $path -Destination $destination
}

# Moves the item at $path to $destination
function MoveItem([string] $path, [string] $destination)
{
	if (Test-Path -LiteralPath $path)
	{
		Write-Verbose "Moving $path to $destination"
		Move-Item -LiteralPath $path -Destination $destination
	}
}

# Deletes an item at $path. Also deletes all the children by default.
function DeleteItem([string] $path, [bool] $recurse = $true)
{
	if (Test-Path -LiteralPath $path)
	{
		Write-Verbose "Deleting $path"

		if ($recurse)
		{
			Remove-Item -LiteralPath $path -Recurse
		}
		else
		{
			Remove-Item -LiteralPath $path
		}
	}
}

# Load the .NET library for unzipping files
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Extracts a zip archive to the specified destination
function Unzip([string] $zip_path, [string] $destination)
{
	Write-Verbose "Extracting $zip_path to $destination"
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zip_path, $destination)
}

# Downloads the file from $url and places it in $destination
function DownloadFile([string] $url, [string] $destination)
{
	Write-Verbose "Downloading file from $url to $destination"
	(New-Object System.Net.WebClient).DownloadFile($url, $destination)
}

# Downloads the file from $url asynchronously and places it in $destination. Upon completion runs the $action, if provided.
function DownloadFileAsync([string] $url, [string] $destination, [ScriptBlock] $action = $null)
{
	$web_client = New-Object System.Net.WebClient

	if ($action)
	{
		Register-ObjectEvent -InputObject $web_client -EventName DownloadFileCompleted -Action $action | Out-Null
	}

	Write-Verbose "Download file from $url to $destination asynchronously"
	$web_client.DownloadFileAsync($url, $destination)
}

# Starts $script as a job with the $name. Passes the $argument as an argument to the job.
function StartJob([ScriptBlock] $script, [string] $name, $argument_list = $null)
{
	Start-Job -ScriptBlock $script -Name $name -ArgumentList $argument_list | Out-Null
}