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

