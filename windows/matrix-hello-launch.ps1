# Opens matrix_hello.py fullscreen in Windows Terminal (or a maximized
# console window if Windows Terminal isn't installed). The installer puts a
# shortcut to this script in your Startup folder, so it runs at every login.
#
# Env: MATRIX_HELLO_DELAY  seconds to wait for the desktop (default 3)
#      MATRIX_HELLO_NAME   who to wake up (default Neo)
$ErrorActionPreference = 'Stop'

$python = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'python-path.txt') -Raw).Trim()
$script = Join-Path $PSScriptRoot 'matrix_hello.py'
$delay = if ($env:MATRIX_HELLO_DELAY) { [double]$env:MATRIX_HELLO_DELAY } else { 3 }
Start-Sleep -Seconds $delay

$wt = Get-Command wt.exe -ErrorAction SilentlyContinue
if ($wt) {
    # One quoted string: Windows PowerShell doesn't quote array arguments,
    # which breaks paths with spaces in them.
    $wtArgs = "--fullscreen new-tab --title matrix-hello --colorScheme Matrix `"$python`" `"$script`""
    Start-Process -FilePath $wt.Source -ArgumentList $wtArgs
} else {
    Start-Process -FilePath $python -ArgumentList "`"$script`"" -WindowStyle Maximized
}
