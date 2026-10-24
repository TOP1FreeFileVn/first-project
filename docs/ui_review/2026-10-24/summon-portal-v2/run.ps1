param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [switch]$ImportAssets,
    [switch]$Record
)

$ErrorActionPreference = 'Stop'
$portalRunner = Join-Path $PSScriptRoot '../summon-vfx/run.ps1'
& $portalRunner -GodotExe $GodotExe -ImportAssets:$ImportAssets -Record:$Record -OutputDirectory $PSScriptRoot -FramesPath 'res://tmp/summon-portal-v2-frames' -PortalStrip
