$ErrorActionPreference = 'Stop'
$standingRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$standingProfile = Join-Path $standingRoot 'output/troops-standing-formation-profile'
$standingAppData = Join-Path $standingProfile 'Roaming'
$standingLocalData = Join-Path $standingProfile 'Local'
New-Item -ItemType Directory -Path $standingAppData, $standingLocalData -Force | Out-Null
$standingPreviousAppData = $env:APPDATA
$standingPreviousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $standingAppData
    $env:LOCALAPPDATA = $standingLocalData
    $standingArguments = @('--path', ('"' + $standingRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://tests/ui_review/TroopsStandingFormationReview.tscn')
    $standingProcess = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $standingArguments -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    exit $standingProcess.ExitCode
}
finally {
    $env:APPDATA = $standingPreviousAppData
    $env:LOCALAPPDATA = $standingPreviousLocalData
}
