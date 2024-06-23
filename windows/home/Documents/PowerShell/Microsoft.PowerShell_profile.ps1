# Packages:
# Install-Module Sensation-Snagger
# Install-Module Microsoft.WinGet.Client

$HOSTNAME = [System.Net.Dns]::GetHostName()
$USERNAME = $env:USERNAME
$USERHOME = [System.Environment]::GetFolderPath("UserProfile")

$ESC = [char]27

# Tab Completion: handle menus
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Tab Completion: winget
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

function Set-CodeLocation {
    param([string]$BaseDirectory, [string]$ProjectName)

    $relPath = Join-Path $BaseDirectory $ProjectName
    $targetPath = Join-Path $env:USERPROFILE "Code" $relPath

    if (Test-Path $targetPath -PathType Container) {
        return Set-Location $targetPath
    }

    $response = Read-Host -Prompt "Directory '$relPath' not found under '~/Code/'. Do you want to clone it from Git? (Y/N)"
    if (-not ($response -eq "Y" -or $response -eq "y")) {
        return Write-Host "Operation canceled. Directory not cloned from Git."
    }

    $baseDirPath = Split-Path $targetPath -Parent
    if (-not (Test-Path -Path $baseDirPath)) {
        New-Item -Path $baseDirPath -ItemType Directory
    }

    $gitUrl = Read-Host "Enter the Git URL"
    git clone $gitUrl $targetPath
    Set-Location $targetPath
}

function Get-Repository {
    param ([switch]$Open)

    if (-not (Test-Path -Path ".git" -PathType Container)) {
        Write-Host "Not a git repository."
        return
    }

    # Get the remote URL
    $remoteUrl = git config --get remote.origin.url

    if (-not $remoteUrl) {
        Write-Host "No remote URL found."
        return
    }

    # Display the remote URL
    Write-Host "Remote URL: $remoteUrl"

   # Open the remote URL in the default browser if the -Open flag is provided
    if ($Open) {
        try {
            # Adjust the URL if it uses the SSH format
            if ($remoteUrl -match "^git@") {
                $remoteUrl = $remoteUrl -replace ":", "/"
                $remoteUrl = $remoteUrl -replace "^git@", "https://"
            }
            # Ensure the URL starts with https:// or http://
            if ($remoteUrl -notmatch "^https?://") {
                $remoteUrl = "https://$remoteUrl"
            }

            Start-Process $remoteUrl
        } catch {
            Write-Host "Failed to open the remote URL: $_"
        }
    }
}


# Aliases
Set-Alias -Name cdcd -Value Set-CodeLocation
Set-Alias -Name repo -Value Get-Repository
Set-Alias -Name cobalt -Value Sensation-Snagger

function prompt {
    $prompt = ""
    $currentLocation = Get-Location

    # We do a little trolling
    $currentPath = $currentLocation.Path.Replace($USERHOME, "~").Replace("\", "/")

    $prompt += "$ESC[32m$HOSTNAME$ESC[0m"
    $prompt += "@$USERNAME $currentPath> "

    $prompt
}

