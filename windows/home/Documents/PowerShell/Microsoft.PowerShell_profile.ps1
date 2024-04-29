$HOSTNAME = [System.Net.Dns]::GetHostName()
$USERNAME = $env:USERNAME
$USERHOME = [System.Environment]::GetFolderPath("UserProfile")

$ESC = [char]27

function prompt {
    $prompt = ""
    $currentLocation = Get-Location

    # We do a little trolling
    $currentPath = $currentLocation.Path.Replace($USERHOME, "~").Replace("\", "/")

    $prompt += "$ESC[32m$HOSTNAME$ESC[0m"
    $prompt += "@$USERNAME $currentPath> "

    $prompt
}
