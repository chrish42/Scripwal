param([string]$working_directory)

# Set the location to the intended working directory that's passed in as an argument
Set-Location -LiteralPath $working_directory

# Alias git
New-Alias -Name git -Value "$env:ProgramFiles/Git/bin/git.exe"

# Also add git directory to the PATH, so we can use all Git tools
$env:Path += ";$env:ProgramFiles/Git/bin/;$env:ProgramFiles/Git/usr/bin/"

# Import posh-git
Import-Module "$env:USERPROFILE/Documents/WindowsPowerShell/posh-git"

# Override the prompt to use the custom posh-git prompt
function global:prompt
{
    $realLASTEXITCODE = $LASTEXITCODE

    Write-Host($pwd.ProviderPath) -nonewline
    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}

# Start the SSH-agent, to avoid repeated password prompts from SSH
Start-SshAgent -Quiet

## Add my key to the SSH-agent (Doesn't seem to be needed, as ssh-agent by default asks for the key first time on startup. Oh fuck me.)
#$ssh_add = "$env:ProgramFiles/Git/usr/bin/ssh-add.exe"
#$ssh_keygen = "$env:ProgramFiles/Git/usr/bin/ssh-keygen.exe"
#$my_key_path = "$env:USERPROFILE/.ssh/id_rsa"

## Get my key and already added SSH keys
#$my_key = & $ssh_keygen -lf $my_key_path
#$ssh_keys = & $ssh_add -l

#Write-Host "my_key: $my_key"

## Split my key only into the part after the colon and before the e-mail (ie. "4096 SHA256:blablabla email@email.com" becomes "blablabla")
#$my_key = $my_key.Substring($my_key.IndexOf(":") + 1)
#$my_key = $my_key.Substring(0, $my_key.IndexOf(" "))

#if (!(Select-String -Pattern $my_key -InputObject $ssh_keys -SimpleMatch -Quiet))
#{
#	& $ssh_add -t 5h $my_key_path
#}