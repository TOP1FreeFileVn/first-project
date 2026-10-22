param([switch]$Capture)
$ErrorActionPreference = 'Stop'
$maskRepo = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$maskProfile = Join-Path $maskRepo 'output/lobby-mask-shortcuts-profile'
New-Item -ItemType Directory -Force -Path $maskProfile | Out-Null
$maskPreviousAppData = $env:APPDATA
$maskPreviousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $maskProfile 'Roaming'
    $env:LOCALAPPDATA = Join-Path $maskProfile 'Local'
    $maskArguments = @('--path', ('"' + $maskRepo + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://docs/design/2026-10-22/lobby-mask-shortcuts/MaskShortcutPreview.tscn')
    if ($Capture) { $maskArguments += @('--', '--capture') }
    $maskWindowStyle = if ($Capture) { 'Hidden' } else { 'Normal' }
    $maskProcess = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $maskArguments -PassThru -Wait -WindowStyle $maskWindowStyle -RedirectStandardOutput (Join-Path $maskProfile 'godot.log') -RedirectStandardError (Join-Path $maskProfile 'godot-errors.log')
    Get-Content (Join-Path $maskProfile 'godot.log') -Tail 5
    Get-Content (Join-Path $maskProfile 'godot-errors.log')
    exit $maskProcess.ExitCode
}
finally {
    $env:APPDATA = $maskPreviousAppData
    $env:LOCALAPPDATA = $maskPreviousLocalData
}
