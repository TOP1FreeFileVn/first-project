$ErrorActionPreference = 'Stop'
$equipmentRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
$equipmentProfile = Join-Path $equipmentRoot 'output/hero-centered-icons-profile'
$equipmentAppData = Join-Path $equipmentProfile 'Roaming'
$equipmentLocalData = Join-Path $equipmentProfile 'Local'
New-Item -ItemType Directory -Path $equipmentAppData, $equipmentLocalData -Force | Out-Null
$equipmentPreviousAppData = $env:APPDATA
$equipmentPreviousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $equipmentAppData
    $env:LOCALAPPDATA = $equipmentLocalData
    $equipmentArguments = @('--path', ('"' + $equipmentRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://tests/ui_review/EquipmentIconLayout.tscn')
    $equipmentProcess = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $equipmentArguments -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    exit $equipmentProcess.ExitCode
}
finally {
    $env:APPDATA = $equipmentPreviousAppData
    $env:LOCALAPPDATA = $equipmentPreviousLocalData
}
