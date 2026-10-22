$ErrorActionPreference = 'Stop'
$railRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$railProfile = Join-Path $railRoot 'output/lobby-mask-integration-profile'
$railAppData = Join-Path $railProfile 'Roaming'
$railLocalData = Join-Path $railProfile 'Local'
New-Item -ItemType Directory -Path $railAppData, $railLocalData -Force | Out-Null
$railPreviousAppData = $env:APPDATA
$railPreviousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $railAppData
    $env:LOCALAPPDATA = $railLocalData
    $railStarted = [DateTime]::UtcNow
    $railArguments = @('--path', ('"' + $railRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--quit-after', '6000', 'res://tests/ui_review/LobbyMaskIntegrationReview.tscn')
    $railProcess = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $railArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    Write-Output "LobbyMaskIntegrationReview PID: $($railProcess.Id)"
    $railProcess.WaitForExit()
    $railProcess.Refresh()
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    $railManifestPath = Join-Path $PSScriptRoot 'manifest.json'
    if (-not (Test-Path -LiteralPath $railManifestPath) -or (Get-Item -LiteralPath $railManifestPath).LastWriteTimeUtc -lt $railStarted) { throw 'The review did not write a fresh manifest.' }
    $railManifest = Get-Content -LiteralPath $railManifestPath -Raw | ConvertFrom-Json
    if ($railManifest.failures -gt 0) { exit 1 }
    if ($null -ne $railProcess.ExitCode -and $railProcess.ExitCode -ne 0) { exit $railProcess.ExitCode }
    exit 0
}
finally {
    $env:APPDATA = $railPreviousAppData
    $env:LOCALAPPDATA = $railPreviousLocalData
}
