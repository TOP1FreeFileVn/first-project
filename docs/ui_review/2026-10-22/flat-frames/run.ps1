$ErrorActionPreference = 'Stop'
$frameRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$frameProfile = Join-Path $frameRoot 'output/flat-frames-profile'
$frameAppData = Join-Path $frameProfile 'Roaming'
$frameLocalData = Join-Path $frameProfile 'Local'
New-Item -ItemType Directory -Path $frameAppData, $frameLocalData -Force | Out-Null
$framePreviousAppData = $env:APPDATA
$framePreviousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $frameAppData
    $env:LOCALAPPDATA = $frameLocalData
    $frameStarted = [DateTime]::UtcNow
    $frameArguments = @('--path', ('"' + $frameRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--quit-after', '6000', 'res://tests/ui_review/FlatFrameReview.tscn')
    $frameProcess = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $frameArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    Write-Output "FlatFrameReview PID: $($frameProcess.Id)"
    $frameProcess.WaitForExit()
    $frameProcess.Refresh()
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    $frameManifestPath = Join-Path $PSScriptRoot 'manifest.json'
    if (-not (Test-Path -LiteralPath $frameManifestPath) -or (Get-Item -LiteralPath $frameManifestPath).LastWriteTimeUtc -lt $frameStarted) {
        throw 'The native review did not write a fresh manifest.'
    }
    $frameManifest = Get-Content -LiteralPath $frameManifestPath -Raw | ConvertFrom-Json
    if ($frameManifest.failures -gt 0) { exit 1 }
    if ($null -ne $frameProcess.ExitCode -and $frameProcess.ExitCode -ne 0) { exit $frameProcess.ExitCode }
    exit 0
}
finally {
    $env:APPDATA = $framePreviousAppData
    $env:LOCALAPPDATA = $framePreviousLocalData
}
