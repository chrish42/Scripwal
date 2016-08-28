echo "I'm a custom profile"

# Create an alias for git
New-Alias -Name git -Value "$env:ProgramFiles\Git\bin\git.exe"

# Start the SSH Agent, to avoid repeated password prompts from SSH
Start-SshAgent #-Quiet