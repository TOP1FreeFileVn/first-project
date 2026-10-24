param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [switch]$Open,
    [switch]$Framed
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$reviewProfile = Join-Path $projectRoot 'output/hero-surface-review-profile'
New-Item -ItemType Directory -Force -Path $reviewProfile | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $reviewProfile
    $env:LOCALAPPDATA = $reviewProfile
    $scene = if ($Framed) { 'HeroInfoReview.tscn' } elseif ($Open) { 'HeroOpenReview.tscn' } else { 'HeroSurfaceReview.tscn' }
    $arguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', ('res://docs/design/2026-10-24/hero-surface-review/' + $scene))
    $started = [DateTime]::UtcNow
    $process = Start-Process -FilePath $GodotExe -WindowStyle Hidden -PassThru -WorkingDirectory $projectRoot -ArgumentList $arguments -RedirectStandardOutput (Join-Path $reviewProfile 'review.log') -RedirectStandardError (Join-Path $reviewProfile 'review.err')
    $processHandle = $process.Handle
    if (-not $process.WaitForExit(55000)) {
        Stop-Process -Id $process.Id -Force
        Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err')
        throw 'Hero surface review timed out.'
    }
    $process.Refresh()
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.log')
    Get-Content -LiteralPath (Join-Path $reviewProfile 'review.err')
    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) { throw ('Hero surface review failed with exit code ' + $process.ExitCode) }
    if (-not (Select-String -LiteralPath (Join-Path $reviewProfile 'review.log') -Pattern '^HERO_(SURFACE|OPEN|FRAMED)_REVIEW_COMPLETE checks=\d+ captures=\d+ failures=0\s*$' -Quiet)) { throw 'Hero surface review did not finish successfully.' }
    $reportName = if ($Framed) { 'native/framed-review.json' } elseif ($Open) { 'native/open-review.json' } else { 'native/review.json' }
    $reportPath = Join-Path $taskRoot $reportName
    if ((Get-Item -LiteralPath $reportPath).LastWriteTimeUtc -lt $started) { throw 'Hero surface review report is stale.' }
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
