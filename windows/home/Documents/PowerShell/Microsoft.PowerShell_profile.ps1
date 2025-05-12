# Packages:
# Install-Module Microsoft.WinGet.Client
# winget install --id Schniz.fnm

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

# Tab Completion: pnpm
Register-ArgumentCompleter -CommandName 'pnpm' -ScriptBlock {
    param(
        $WordToComplete,
        $CommandAst,
        $CursorPosition
    )

    function __pnpm_debug {
        if ($env:BASH_COMP_DEBUG_FILE) {
            "$args" | Out-File -Append -FilePath "$env:BASH_COMP_DEBUG_FILE"
        }
    }

    filter __pnpm_escapeStringWithSpecialChars {
        $_ -replace '\s|#|@|\$|;|,|''|\{|\}|\(|\)|"|`|\||<|>|&', '`$&'
    }

    # Get the current command line and convert into a string
    $Command = $CommandAst.CommandElements
    $Command = "$Command"

    __pnpm_debug ""
    __pnpm_debug "========= starting completion logic =========="
    __pnpm_debug "WordToComplete: $WordToComplete Command: $Command CursorPosition: $CursorPosition"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CursorPosition location, so we need
    # to truncate the command-line ($Command) up to the $CursorPosition location.
    # Make sure the $Command is longer then the $CursorPosition before we truncate.
    # This happens because the $Command does not include the last space.
    if ($Command.Length -gt $CursorPosition) {
        $Command = $Command.Substring(0, $CursorPosition)
    }
    __pnpm_debug "Truncated command: $Command"

    # Prepare the command to request completions for the program.
    # Split the command at the first space to separate the program and arguments.
    $Program, $Arguments = $Command.Split(" ", 2)
    $RequestComp = "$Program completion-server"
    __pnpm_debug "RequestComp: $RequestComp"

    # we cannot use $WordToComplete because it
    # has the wrong values if the cursor was moved
    # so use the last argument
    if ($WordToComplete -ne "" ) {
        $WordToComplete = $Arguments.Split(" ")[-1]
    }
    __pnpm_debug "New WordToComplete: $WordToComplete"


    # Check for flag with equal sign
    $IsEqualFlag = ($WordToComplete -Like "--*=*" )
    if ( $IsEqualFlag ) {
        __pnpm_debug "Completing equal sign flag"
        # Remove the flag part
        $Flag, $WordToComplete = $WordToComplete.Split("=", 2)
    }

    if ( $WordToComplete -eq "" -And ( -Not $IsEqualFlag )) {
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __pnpm_debug "Adding extra empty parameter"
        # We need to use `"`" to pass an empty argument a "" or '' does not work!!!
        $Command = "$Command" + ' `"`"'
    }

    __pnpm_debug "Calling $RequestComp"

    $oldenv = ($env:SHELL, $env:COMP_CWORD, $env:COMP_LINE, $env:COMP_POINT)
    $env:SHELL = "pwsh"
    $env:COMP_CWORD = $Command.Split(" ").Count - 1
    $env:COMP_POINT = $CursorPosition
    $env:COMP_LINE = $Command

    try {
        #call the command store the output in $out and redirect stderr and stdout to null
        # $Out is an array contains each line per element
        Invoke-Expression -OutVariable out "$RequestComp" 2>&1 | Out-Null
    }
    finally {
        ($env:SHELL, $env:COMP_CWORD, $env:COMP_LINE, $env:COMP_POINT) = $oldenv
    }

    __pnpm_debug "The completions are: $Out"

    $Longest = 0
    $Values = $Out | ForEach-Object {
        #Split the output in name and description
        $Name, $Description = $_.Split("`t", 2)
        __pnpm_debug "Name: $Name Description: $Description"

        # Look for the longest completion so that we can format things nicely
        if ($Longest -lt $Name.Length) {
            $Longest = $Name.Length
        }

        # Set the description to a one space string if there is none set.
        # This is needed because the CompletionResult does not accept an empty string as argument
        if (-Not $Description) {
            $Description = " "
        }
        @{Name = "$Name"; Description = "$Description" }
    }


    $Space = " "
    $Values = $Values | Where-Object {
        # filter the result
        if (-not $WordToComplete.StartsWith("-") -and $_.Name.StartsWith("-")) {
            # skip flag completions unless a dash is present
            return
        }
        else {
            $_.Name -like "$WordToComplete*"
        }

        # Join the flag back if we have an equal sign flag
        if ( $IsEqualFlag ) {
            __pnpm_debug "Join the equal sign flag back to the completion value"
            $_.Name = $Flag + "=" + $_.Name
        }
    }

    # Get the current mode
    $Mode = (Get-PSReadLineKeyHandler | Where-Object { $_.Key -eq "Tab" }).Function
    __pnpm_debug "Mode: $Mode"

    $Values | ForEach-Object {

        # store temporary because switch will overwrite $_
        $comp = $_

        # PowerShell supports three different completion modes
        # - TabCompleteNext (default windows style - on each key press the next option is displayed)
        # - Complete (works like bash)
        # - MenuComplete (works like zsh)
        # You set the mode with Set-PSReadLineKeyHandler -Key Tab -Function <mode>

        # CompletionResult Arguments:
        # 1) CompletionText text to be used as the auto completion result
        # 2) ListItemText   text to be displayed in the suggestion list
        # 3) ResultType     type of completion result
        # 4) ToolTip        text for the tooltip with details about the object

        switch ($Mode) {

            # bash like
            "Complete" {

                if ($Values.Length -eq 1) {
                    __pnpm_debug "Only one completion left"

                    # insert space after value
                    [System.Management.Automation.CompletionResult]::new($($comp.Name | __pnpm_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")

                }
                else {
                    # Add the proper number of spaces to align the descriptions
                    while ($comp.Name.Length -lt $Longest) {
                        $comp.Name = $comp.Name + " "
                    }

                    # Check for empty description and only add parentheses if needed
                    if ($($comp.Description) -eq " " ) {
                        $Description = ""
                    }
                    else {
                        $Description = "  ($($comp.Description))"
                    }

                    [System.Management.Automation.CompletionResult]::new("$($comp.Name)$Description", "$($comp.Name)$Description", 'ParameterValue', "$($comp.Description)")
                }
            }

            # zsh like
            "MenuComplete" {
                # insert space after value
                # MenuComplete will automatically show the ToolTip of
                # the highlighted value at the bottom of the suggestions.
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __pnpm_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }

            # TabCompleteNext and in case we get something unknown
            Default {
                # Like MenuComplete but we don't want to add a space here because
                # the user need to press space anyway to get the completion.
                # Description will not be shown because that's not possible with TabCompleteNext
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __pnpm_escapeStringWithSpecialChars), "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }
        }

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

# Tab Completion: Set-CodeLocation
# Register argument completer for BaseDirectory parameter
Register-ArgumentCompleter -CommandName Set-CodeLocation -ParameterName BaseDirectory -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $codeDir = Join-Path $env:USERPROFILE "Code"
    if (-not (Test-Path $codeDir -PathType Container)) {
        return;
    }

    Get-ChildItem -Path $codeDir -Directory | ForEach-Object {
        if (-not $wordToComplete) {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
            return;
        }

        if ($_.Name -like "$wordToComplete*") {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
        }
    }
}

# Register argument completer for ProjectName parameter
Register-ArgumentCompleter -CommandName Set-CodeLocation -ParameterName ProjectName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    if (-not $fakeBoundParameter.BaseDirectory) {
        return;
    }

    $baseDir = Join-Path $env:USERPROFILE "Code" $fakeBoundParameter.BaseDirectory
    if (-not (Test-Path $baseDir -PathType Container)) {
        return 
    }

    Get-ChildItem -Path $baseDir -Directory | ForEach-Object {
        if (-not $wordToComplete) {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
            return;
        }

        if ($_.Name -like "$wordToComplete*") {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
        }
    }
}

function Get-Repository {
    param ([switch]$Open)

    if (-not (Test-Path -Path ".git" -PathType Container)) {
        Write-Host "Not a git repository."
        return
    }

    $remoteUrl = git config --get remote.origin.url

    if (-not $remoteUrl) {
        Write-Host "No remote URL found."
        return
    }

    Write-Host "Remote URL: $remoteUrl"

    if ($Open) {
        try {
            if ($remoteUrl -match "^git@") {
                $remoteUrl = $remoteUrl -replace ":", "/"
                $remoteUrl = $remoteUrl -replace "^git@", "https://"
            }
            
            if ($remoteUrl -notmatch "^https?://") {
                $remoteUrl = "https://$remoteUrl"
            }

            Start-Process $remoteUrl
        }
        catch {
            Write-Host "Failed to open the remote URL: $_"
        }
    }
}

function Clear-StaleBranches {
    git fetch --prune
    git branch -vv | Where-Object { $_ -match 'gone\]' } | ForEach-Object { $_.Trim().Split()[0] } | ForEach-Object { git branch -D $_ }
}

function Remove-NonAudio {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        [switch]$Recurse = $false
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "The specified folder '$FolderPath' does not exist."
        return
    }

    $audioExtensions = @(".flac", ".alac", ".wav", ".opus", ".ogg", ".mp3", ".m4a")

    $getParams = @{
        Path    = $FolderPath
        File    = $true
        Recurse = $Recurse
    }

    try {
        $filesToDelete = Get-ChildItem @getParams | Where-Object {
            $extension = [System.IO.Path]::GetExtension($_.Name).ToLower()
            $extension -notin $audioExtensions
        }

        $totalFiles = $filesToDelete.Count
        if ($totalFiles -eq 0) {
            Write-Host "No non-audio files found to delete in '$FolderPath'." -ForegroundColor Green
            return
        }
    
        Write-Host "Found $totalFiles non-audio files to delete in '$FolderPath'." -ForegroundColor Yellow
    
        $deletedCount = 0
        $errorCount = 0
    
        foreach ($file in $filesToDelete) {
            try {
                Remove-Item -Path $file.FullName -Force
                $deletedCount++
                Write-Host "Deleted: $($file.FullName)" -ForegroundColor DarkGray
            }
            catch {
                Write-Error "Failed to delete $($file.FullName): $_"
                $errorCount++
            }
        }
    
        Write-Host "`nOperation complete. $deletedCount files deleted." -ForegroundColor Green
        if ($errorCount -gt 0) {
            Write-Host "$errorCount files could not be deleted due to errors." -ForegroundColor Red
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# fnm support
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# Aliases
Set-Alias -Name cdcd -Value Set-CodeLocation
Set-Alias -Name repo -Value Get-Repository

function prompt {
    $currentLocation = Get-Location
    
    $currentPath += $currentLocation.Path.Replace($USERHOME, "$ESC[32m~$ESC[0m")
    $prompt = $currentPath

    if (Get-Command git -ErrorAction SilentlyContinue) {
        $branchName = git branch --show-current 2>$null
        if ($LASTEXITCODE -eq 0 -and $branchName) {
            $prompt += " $ESC[90m($branchName)$ESC[0m"
        }
    }

    $prompt += "> "
    $prompt
}

