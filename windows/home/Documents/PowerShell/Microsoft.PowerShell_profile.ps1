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

function prompt {
    $prompt = ""
    $currentLocation = Get-Location

    # We do a little trolling
    $currentPath = $currentLocation.Path.Replace($USERHOME, "~").Replace("\", "/")

    $prompt += "$ESC[32m$HOSTNAME$ESC[0m"
    $prompt += "@$USERNAME $currentPath> "

    $prompt
}
