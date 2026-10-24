param([string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe')

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$reviewProfile = Join-Path $projectRoot 'output/hero-inventory-spacing-profile'
$reviewOutput = Join-Path $taskRoot 'native'
New-Item -ItemType Directory -Force -Path $reviewProfile | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $reviewProfile
    $env:LOCALAPPDATA = $reviewProfile
    $runArguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', 'res://docs/design/2026-10-24/hero-inventory-spacing/HeroInventorySpacing.tscn')
    $reviewStarted = [DateTime]::UtcNow
    $process = Start-Process -FilePath $GodotExe -WindowStyle Hidden -PassThru -WorkingDirectory $projectRoot -ArgumentList $runArguments -RedirectStandardOutput (Join-Path $reviewProfile 'review.log') -RedirectStandardError (Join-Path $reviewProfile 'review.err')
    $processHandle = $process.Handle
    if (-not $process.WaitForExit(55000)) {
        Stop-Process -Id $process.Id -Force
        Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err')
        throw 'Native hero/inventory spacing review timed out.'
    }
    $process.Refresh()
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.log')
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err')
    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) { throw ('Spacing review failed with exit code ' + $process.ExitCode) }
    if (-not (Select-String -LiteralPath (Join-Path $reviewProfile 'review.log') -Pattern '^HERO_INVENTORY_SPACING_COMPLETE checks=\d+ captures=\d+ failures=0\s*$' -Quiet)) { throw 'Spacing review did not finish successfully.' }
    $reportPath = Join-Path $reviewOutput 'review.json'
    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw 'Review did not produce a completion report.' }
    if ((Get-Item -LiteralPath $reportPath).LastWriteTimeUtc -lt $reviewStarted) { throw 'Review did not produce a new completion report.' }
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    if ($report.failures -ne 0) { throw ('Spacing review reported ' + $report.failures + ' failures') }
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
