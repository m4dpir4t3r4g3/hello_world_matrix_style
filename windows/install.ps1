# Installs matrix-hello on Windows 10/11:
#   - runs it fullscreen every time you log in (Startup folder shortcut)
#   - adds "Matrix PowerShell" and "Matrix CMD" profiles to Windows Terminal
#   - adds "Matrix Terminal" to the Start menu
#
# Run it by double-clicking install.cmd, or from PowerShell:
#   powershell -ExecutionPolicy Bypass -File windows\install.ps1
#   ... -NoAutostart   to skip the login autostart
param([switch]$NoAutostart)
$ErrorActionPreference = 'Stop'

$Src = Split-Path -Parent $PSScriptRoot
$Dest = Join-Path $env:LOCALAPPDATA 'matrix-hello'
$utf8 = New-Object System.Text.UTF8Encoding $false   # no BOM

# Runs a program, returns its output and leaves the exit code in
# $LASTEXITCODE. Windows PowerShell would otherwise turn anything the program
# prints to stderr (like pip's warnings) into a fatal error.
function Invoke-Quiet($exe, [string[]]$arguments) {
    $ErrorActionPreference = 'Continue'
    & $exe @arguments 2>$null
}

# 1) Python 3.8+. Each candidate prints its own path. The Microsoft Store
#    "python" placeholder prints nothing and fails, so it gets skipped.
$python = $null
foreach ($candidate in 'py -3', 'python', 'python3') {
    $parts = $candidate -split ' '
    if (-not (Get-Command $parts[0] -ErrorAction SilentlyContinue)) { continue }
    $check = @($parts | Select-Object -Skip 1) + '-c', 'import sys; assert sys.version_info >= (3, 8); print(sys.executable)'
    $out = Invoke-Quiet $parts[0] $check
    if ($LASTEXITCODE -eq 0 -and $out) { $python = "$out".Trim(); break }
}
if (-not $python) {
    Write-Host "Python 3 was not found. Install it, then run this again:" -ForegroundColor Red
    Write-Host "    winget install -e --id Python.Python.3.12"
    Write-Host "(or download it from https://www.python.org/downloads/)"
    exit 1
}
Write-Host "Using Python: $python"

# 2) curses isn't built into Python on Windows; windows-curses provides it.
Invoke-Quiet $python '-c', 'import curses' | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing windows-curses..."
    Invoke-Quiet $python '-m', 'pip', 'install', '--user', '--quiet', 'windows-curses' | Out-Null
    Invoke-Quiet $python '-c', 'import curses' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not install windows-curses. Try:  `"$python`" -m pip install windows-curses" -ForegroundColor Red
        exit 1
    }
}

# 3) Files
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -LiteralPath (Join-Path $Src 'matrix_hello.py') -Destination $Dest -Force
foreach ($f in 'matrix-hello-launch.ps1', 'matrix-profile.ps1', 'matrix-cmd.cmd', 'uninstall.ps1') {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $f) -Destination $Dest -Force
}
[IO.File]::WriteAllText((Join-Path $Dest 'python-path.txt'), $python, $utf8)
Write-Host "Installed to $Dest"

# 4) Windows Terminal profiles + colour scheme, as a "fragment": Windows
#    Terminal picks it up without touching your settings.json.
$scheme = [ordered]@{
    name = 'Matrix'; background = '#000000'; foreground = '#00FF41'
    cursorColor = '#00FF41'; selectionBackground = '#005F00'
    black = '#000000'; red = '#008F11'; green = '#00FF41'; yellow = '#B8FF7A'
    blue = '#00AF00'; purple = '#39FF14'; cyan = '#7CFC00'; white = '#C8FFC8'
    brightBlack = '#005F00'; brightRed = '#00CC33'; brightGreen = '#5CFF7A'
    brightYellow = '#D4FF9A'; brightBlue = '#00D000'; brightPurple = '#66FF66'
    brightCyan = '#AAFFAA'; brightWhite = '#FFFFFF'
}
function New-MatrixProfile($name, $commandline) {
    [ordered]@{
        name = $name; commandline = $commandline; colorScheme = 'Matrix'
        startingDirectory = '%USERPROFILE%'; tabTitle = 'Matrix'
        cursorShape = 'filledBox'; font = @{ face = 'Cascadia Mono' }
    }
}
$psCommand = "powershell.exe -NoLogo -NoExit -ExecutionPolicy Bypass -Command `". '$Dest\matrix-profile.ps1'`""
$cmdCommand = "cmd.exe /k `"$Dest\matrix-cmd.cmd`""
$fragment = [ordered]@{
    profiles = @(
        (New-MatrixProfile 'Matrix PowerShell' $psCommand),
        (New-MatrixProfile 'Matrix CMD' $cmdCommand)
    )
    schemes = @($scheme)
}
$fragDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\matrix-hello'
New-Item -ItemType Directory -Force -Path $fragDir | Out-Null
[IO.File]::WriteAllText((Join-Path $fragDir 'matrix.json'), ($fragment | ConvertTo-Json -Depth 5), $utf8)
Write-Host "Added 'Matrix PowerShell' and 'Matrix CMD' to Windows Terminal"

# 5) Shortcuts
$shell = New-Object -ComObject WScript.Shell
$powershell = (Get-Command powershell.exe).Source

$wt = Get-Command wt.exe -ErrorAction SilentlyContinue
$lnk = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Programs')) 'Matrix Terminal.lnk'))
if ($wt) {
    $lnk.TargetPath = $wt.Source
    $lnk.Arguments = '-p "Matrix PowerShell"'
} else {
    $lnk.TargetPath = $powershell
    $lnk.Arguments = $psCommand.Substring('powershell.exe '.Length)
}
$lnk.Description = 'Follow the white rabbit'
$lnk.Save()
Write-Host "Added 'Matrix Terminal' to the Start menu"

if (-not $NoAutostart) {
    $lnk = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Startup')) 'Matrix Hello.lnk'))
    $lnk.TargetPath = $powershell
    $lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Dest\matrix-hello-launch.ps1`""
    $lnk.WindowStyle = 7   # start minimized, so no console flashes up
    $lnk.Save()
    Write-Host "matrix-hello will run every time you log in"
}

Write-Host ""
Write-Host "Try it now:" -ForegroundColor Green
Write-Host "    powershell -ExecutionPolicy Bypass -File `"$Dest\matrix-hello-launch.ps1`""
Write-Host "or open 'Matrix Terminal' from the Start menu."
