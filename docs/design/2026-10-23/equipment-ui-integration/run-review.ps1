param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$reviewProfile = Join-Path $projectRoot 'output/equipment-ui-native-profile'
New-Item -ItemType Directory -Force -Path $reviewProfile | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $reviewProfile
    $env:LOCALAPPDATA = $reviewProfile
    # A rendering window is needed for viewport screenshots; keep it hidden.
    $runArguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', 'res://docs/design/2026-10-23/equipment-ui-integration/ReviewEquipmentIntegration.tscn')
    $reviewStarted = [DateTime]::UtcNow
    $process = Start-Process -FilePath $GodotExe -WindowStyle Hidden -PassThru -WorkingDirectory $projectRoot -ArgumentList $runArguments -RedirectStandardOutput (Join-Path $reviewProfile 'review.log') -RedirectStandardError (Join-Path $reviewProfile 'review.err')
    $processHandle = $process.Handle
    if (-not $process.WaitForExit(90000)) {
        Stop-Process -Id $process.Id -Force
        Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err')
        throw 'Native equipment integration review timed out.'
    }
    $process.Refresh()
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.log')
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err')
    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) { throw ('Native equipment integration review failed with exit code ' + $process.ExitCode) }
    $reportPath = Join-Path $taskRoot 'review.json'
    if ((Get-Item -LiteralPath $reportPath).LastWriteTimeUtc -lt $reviewStarted) { throw 'Review did not produce a new completion report.' }
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    if ($report.failures -ne 0) { throw ('Native equipment integration review reported ' + $report.failures + ' failures') }
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
