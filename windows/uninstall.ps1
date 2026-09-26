# Removes matrix-hello from Windows. Leaves Python and windows-curses alone.
$ErrorActionPreference = 'SilentlyContinue'

Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Startup')) 'Matrix Hello.lnk')
Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Programs')) 'Matrix Terminal.lnk')
Remove-Item -LiteralPath (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\matrix-hello') -Recurse
Remove-Item -LiteralPath (Join-Path $env:LOCALAPPDATA 'matrix-hello') -Recurse
Write-Host "matrix-hello removed. The Matrix no longer has you."
