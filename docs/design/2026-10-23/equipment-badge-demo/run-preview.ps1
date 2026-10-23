param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [string]$OutputDirectory = '',
    [string]$BootsGlyph = ''
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$previewProfile = Join-Path $projectRoot 'output/equipment-badge-preview-profile'
New-Item -ItemType Directory -Force -Path $previewProfile | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $previewProfile
    $env:LOCALAPPDATA = $previewProfile
    $runArguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', 'res://docs/design/2026-10-23/equipment-badge-demo/BadgePreview.tscn')
    if ($OutputDirectory -or $BootsGlyph) { $runArguments += '--' }
    if ($OutputDirectory) { $runArguments += "--output-directory=$OutputDirectory" }
    if ($BootsGlyph) { $runArguments += "--boots-glyph=$BootsGlyph" }
    $previewProcess = Start-Process -FilePath $GodotExe -WindowStyle Hidden -PassThru -WorkingDirectory $projectRoot -ArgumentList $runArguments -RedirectStandardOutput (Join-Path $previewProfile 'preview.log') -RedirectStandardError (Join-Path $previewProfile 'preview.err')
    $previewHandle = $previewProcess.Handle
    if (-not $previewProcess.WaitForExit(45000)) {
        Stop-Process -Id $previewProcess.Id -Force
        Get-Content -LiteralPath (Join-Path $previewProfile 'preview.err')
        throw 'Badge preview timed out.'
    }
    Get-Content -LiteralPath (Join-Path $previewProfile 'preview.log')
    Get-Content -LiteralPath (Join-Path $previewProfile 'preview.err')
    if (-not (Select-String -LiteralPath (Join-Path $previewProfile 'preview.log') -Pattern 'BADGE_PREVIEW_COMPLETE' -Quiet)) { throw 'Badge preview did not finish.' }
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
