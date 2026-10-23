param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [switch]$SkipGif
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$reviewProfile = Join-Path $projectRoot 'output/chest-light-review-profile'
New-Item -ItemType Directory -Force -Path $reviewProfile | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $reviewProfile
    $env:LOCALAPPDATA = $reviewProfile
    # A native rendering window is required for screenshots. No asset import or
    # editor startup: use the project's existing imported production resources.
    $runArguments = @('--path', ('"' + $projectRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://docs/design/2026-10-23/chest-light-polish/ReviewChestLight.tscn')
    $reviewStarted = [DateTime]::UtcNow
    $process = Start-Process -FilePath $GodotExe -WindowStyle Hidden -PassThru -WorkingDirectory $projectRoot -ArgumentList $runArguments -RedirectStandardOutput (Join-Path $reviewProfile 'review.log') -RedirectStandardError (Join-Path $reviewProfile 'review.err')
    $processHandle = $process.Handle
    if (-not $process.WaitForExit(120000)) {
        Stop-Process -Id $process.Id -Force
        Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err') -Tail 100
        throw 'Native chest light review timed out.'
    }
    $process.Refresh()
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.log') -Tail 30
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err') -Tail 100
    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) { throw ('Native chest light review failed with exit code ' + $process.ExitCode) }
    $reportPath = Join-Path $taskRoot 'review.json'
    if (-not (Test-Path -LiteralPath $reportPath)) { throw 'Review did not produce a completion report.' }
    if ((Get-Item -LiteralPath $reportPath).LastWriteTimeUtc -lt $reviewStarted) { throw 'Review did not produce a new completion report.' }
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    if ($report.failures -ne 0) { throw ('Native chest light review reported ' + $report.failures + ' failures') }
    if (-not $SkipGif) {
        & python (Join-Path $taskRoot 'make-preview.py')
        if ($LASTEXITCODE -ne 0) { throw 'Preview GIF/contact sheet conversion failed.' }
    }
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
