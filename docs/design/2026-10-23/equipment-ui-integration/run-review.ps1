param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$reviewOutput = $taskRoot
if ($OutputDirectory) {
    if ($OutputDirectory.StartsWith('res://')) {
        $reviewOutput = [IO.Path]::GetFullPath((Join-Path $projectRoot $OutputDirectory.Substring(6)))
    }
    elseif ([IO.Path]::IsPathRooted($OutputDirectory)) {
        $reviewOutput = [IO.Path]::GetFullPath($OutputDirectory)
    }
    else {
        $reviewOutput = [IO.Path]::GetFullPath((Join-Path $projectRoot $OutputDirectory))
    }
}
$reviewProfile = Join-Path $projectRoot 'output/equipment-ui-native-profile'
New-Item -ItemType Directory -Force -Path $reviewProfile | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $reviewProfile
    $env:LOCALAPPDATA = $reviewProfile
    # A rendering window is needed for viewport screenshots; keep it hidden.
    $runArguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', 'res://docs/design/2026-10-23/equipment-ui-integration/ReviewEquipmentIntegration.tscn')
    if ($OutputDirectory) { $runArguments += @('--', ('--output-directory="' + $reviewOutput + '"')) }
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
    if (-not (Select-String -LiteralPath (Join-Path $reviewProfile 'review.log') -Pattern '^EQUIPMENT_INTEGRATION_REVIEW_COMPLETE checks=\d+ captures=\d+ failures=0\s*$' -Quiet)) { throw 'Native equipment integration review did not finish successfully.' }
    $reportPath = Join-Path $reviewOutput 'review.json'
    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw 'Review did not produce a completion report.' }
    if ((Get-Item -LiteralPath $reportPath).LastWriteTimeUtc -lt $reviewStarted) { throw 'Review did not produce a new completion report.' }
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    if ($report.failures -ne 0) { throw ('Native equipment integration review reported ' + $report.failures + ' failures') }
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
