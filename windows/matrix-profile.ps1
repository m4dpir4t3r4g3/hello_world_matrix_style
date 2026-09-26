# Matrix look for PowerShell: a burst of digital rain, then a green prompt.
# The "Matrix PowerShell" terminal profile dot-sources this file. To use it
# in every PowerShell window, add this line to your $PROFILE:
#     . "$env:LOCALAPPDATA\matrix-hello\matrix-profile.ps1"

$MatrixName = if ($env:MATRIX_HELLO_NAME) { $env:MATRIX_HELLO_NAME } else { 'Neo' }
$Host.UI.RawUI.WindowTitle = 'Matrix'

$pythonFile = Join-Path $PSScriptRoot 'python-path.txt'
if ($env:MATRIX_SPLASH -ne '0' -and (Test-Path -LiteralPath $pythonFile)) {
    $splash = if ($env:MATRIX_SPLASH) { $env:MATRIX_SPLASH } else { '2' }
    & (Get-Content -LiteralPath $pythonFile -Raw).Trim() (Join-Path $PSScriptRoot 'matrix_hello.py') --splash $splash
    Clear-Host
}

$e = [char]27
Write-Host "$e[1;38;5;46mWake up, $MatrixName...$e[0;38;5;34m The Matrix has you.$e[0m`n"

# neo@matrix C:\Users\you>
function global:prompt {
    $e = [char]27
    "$e[1;38;5;46m$($MatrixName.ToLower())@matrix$e[0;38;5;34m $($executionContext.SessionState.Path.CurrentLocation)$e[1;97m>$e[0m "
}

# Green syntax highlighting while you type (PSReadLine ships with Windows).
try {
    Set-PSReadLineOption -Colors @{
        Command = "$e[92m"; Parameter = "$e[32m"; String = "$e[97m"
        Operator = "$e[32m"; Variable = "$e[1;92m"; Number = "$e[97m"
        Member = "$e[32m"; Type = "$e[32m"; Keyword = "$e[1;92m"; Comment = "$e[2;32m"
    }
} catch { }
