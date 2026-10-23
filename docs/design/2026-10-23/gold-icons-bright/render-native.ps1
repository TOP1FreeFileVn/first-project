$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$profile = Join-Path $projectRoot 'output/gold-bright-native-profile'
New-Item -ItemType Directory -Force $profile | Out-Null
$env:APPDATA = $profile
$env:LOCALAPPDATA = $profile
$godotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
$process = Start-Process -FilePath $godotExe -WindowStyle Hidden -PassThru -Wait -WorkingDirectory $projectRoot -ArgumentList @('--headless', '--path', '.', '--script', 'res://docs/design/2026-10-23/gold-icons-bright/RenderGold.gd') -RedirectStandardOutput (Join-Path $profile 'render.log') -RedirectStandardError (Join-Path $profile 'render.err')
Get-Content -LiteralPath (Join-Path $profile 'render.log')
if ($process.ExitCode -ne 0) { Get-Content -LiteralPath (Join-Path $profile 'render.err'); throw 'Native bright-gold rendering failed.' }
