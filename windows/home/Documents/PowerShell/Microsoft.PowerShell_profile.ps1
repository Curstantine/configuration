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

    $relPath = Join-Path $BaseDirectory $ProjectName
    $promptMessage = "Directory '$relPath' not found under '~/Code/'. Do you want to clone it from Git? (Y/N)"
    $response = Read-Host -Prompt $promptMessage

    if ($response -eq "Y" -or $response -eq "y") {
        $gitUrl = Read-Host "Enter the Git URL:"
        git clone $gitUrl $targetPath
        Set-Location $targetPath
    } else {
        Write-Host "Operation canceled. Directory not cloned from Git."
    }
}

# Aliases
Set-Alias -Name cdcd -Value Set-CodeLocation
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

