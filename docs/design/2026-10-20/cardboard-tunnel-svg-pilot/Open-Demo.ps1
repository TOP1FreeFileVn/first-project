param([switch]$Tunnel)
$ErrorActionPreference = 'Stop'
$pilotFolder = $PSScriptRoot
$godotExecutable = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godotExecutable)) {
    throw 'Khong tim thay Godot 4.7.2 tai duong dan da ghi trong Open-Demo.ps1.'
}
$env:APPDATA = Join-Path $pilotFolder 'native/profile'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
# This is the interactive review window requested by the user.
$demoArguments = @('--path', ('"' + (Join-Path $pilotFolder 'native') + '"'), '--position', '24,24')
if (-not $Tunnel) { $demoArguments += @('--', '--bed') }
$demoProcess = Start-Process -FilePath $godotExecutable -ArgumentList $demoArguments -WindowStyle Normal -PassThru
Write-Output ('Opened SVG Lobby Pilot. Process ID: ' + $demoProcess.Id)
