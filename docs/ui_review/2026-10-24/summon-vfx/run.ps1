param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [switch]$ImportAssets,
    [switch]$Record,
    [string]$OutputDirectory = $PSScriptRoot,
    [string]$FramesPath = 'res://tmp/summon-vfx-frames',
    [switch]$PortalStrip
)

$ErrorActionPreference = 'Stop'
$summonRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$summonOutput = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $summonOutput.StartsWith(($summonRoot.TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Summon review output must stay inside the project.' }
New-Item -ItemType Directory -Path $summonOutput -Force | Out-Null
$summonOutputResource = 'res://' + $summonOutput.Substring($summonRoot.Length).TrimStart('\').Replace('\', '/')
$summonProfileRoot = Join-Path $summonRoot ('output/' + (Split-Path -Leaf $summonOutput) + '-review-profile')
$summonPreviousAppData = $env:APPDATA
$summonPreviousLocalData = $env:LOCALAPPDATA

try {
    foreach ($summonSize in @('450x800', '360x640')) {
        $summonProfile = Join-Path $summonProfileRoot $summonSize
        $summonRoaming = Join-Path $summonProfile 'Roaming'
        $summonLocal = Join-Path $summonProfile 'Local'
        New-Item -ItemType Directory -Path $summonRoaming, $summonLocal -Force | Out-Null
        $env:APPDATA = $summonRoaming
        $env:LOCALAPPDATA = $summonLocal
        if ($ImportAssets -and $summonSize -eq '450x800') {
            $summonImportArgs = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $summonRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
            $summonImport = Start-Process -FilePath $GodotExe -ArgumentList $summonImportArgs -WorkingDirectory $summonRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $summonOutput 'godot-import.log') -RedirectStandardError (Join-Path $summonOutput 'godot-import-errors.log')
            $summonImportHandle = $summonImport.Handle
            if (-not $summonImport.WaitForExit(55000)) { Stop-Process -Id $summonImport.Id -Force; throw 'Summon VFX import timed out.' }
            $summonImport.Refresh()
            if ($null -ne $summonImport.ExitCode -and $summonImport.ExitCode -ne 0) { throw ('Summon VFX import failed: ' + $summonImport.ExitCode) }
        }
        $summonLog = Join-Path $summonOutput ('godot-' + $summonSize + '.log')
        $summonErrors = Join-Path $summonOutput ('godot-' + $summonSize + '-errors.log')
        $summonArgs = @('--path', ('"' + $summonRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--resolution', $summonSize, 'res://tests/ui_review/SummonVfxReview.tscn', '--', ('--size=' + $summonSize), ('--out=' + $summonOutputResource), ('--frames=' + $FramesPath))
        if ($Record) { $summonArgs += '--record' }
        if ($PortalStrip) { $summonArgs += '--portal-strip' }
        $summonStarted = [DateTime]::UtcNow
        $summonProcess = Start-Process -FilePath $GodotExe -ArgumentList $summonArgs -WorkingDirectory $summonRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $summonLog -RedirectStandardError $summonErrors
        $summonProcessHandle = $summonProcess.Handle
        if (-not $summonProcess.WaitForExit(55000)) {
            Stop-Process -Id $summonProcess.Id -Force
            Get-Content -LiteralPath $summonErrors
            throw ('Summon VFX review timed out at ' + $summonSize)
        }
        $summonProcess.Refresh()
        Get-Content -LiteralPath $summonLog -Tail 12
        Get-Content -LiteralPath $summonErrors
        if ($null -ne $summonProcess.ExitCode -and $summonProcess.ExitCode -ne 0) { throw ('Summon VFX review failed at ' + $summonSize + ' with exit code ' + $summonProcess.ExitCode) }
        if (-not (Select-String -LiteralPath $summonLog -Pattern '^SUMMON_VFX_REVIEW_COMPLETE checks=\d+ captures=\d+ failures=0\s*$' -Quiet)) { throw ('Summon VFX review did not report successful completion at ' + $summonSize) }
        $summonReportPath = Join-Path $summonOutput ('manifest-' + $summonSize + '.json')
        if (-not (Test-Path -LiteralPath $summonReportPath -PathType Leaf)) { throw ('Missing native review report: ' + $summonReportPath) }
        if ((Get-Item -LiteralPath $summonReportPath).LastWriteTimeUtc -lt $summonStarted) { throw 'Native review report is stale.' }
        $summonReport = Get-Content -LiteralPath $summonReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($summonReport.failures -ne 0) { throw ('Summon VFX review reported ' + $summonReport.failures + ' failures') }
    }
}
finally {
    $env:APPDATA = $summonPreviousAppData
    $env:LOCALAPPDATA = $summonPreviousLocalData
}
