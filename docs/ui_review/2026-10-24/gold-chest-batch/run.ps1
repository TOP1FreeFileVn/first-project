param([switch]$ImportAssets)

$ErrorActionPreference = 'Stop'
$goldRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$goldProfile = Join-Path $goldRoot 'output/gold-chest-batch-profile'
$goldAppData = Join-Path $goldProfile 'Roaming'
$goldLocalData = Join-Path $goldProfile 'Local'
New-Item -ItemType Directory -Path $goldAppData, $goldLocalData -Force | Out-Null
$goldPreviousAppData = $env:APPDATA
$goldPreviousLocalData = $env:LOCALAPPDATA
$goldGodot = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
try {
    $env:APPDATA = $goldAppData
    $env:LOCALAPPDATA = $goldLocalData
    if ($ImportAssets) {
        $goldImportArguments = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $goldRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
        $goldImport = Start-Process -FilePath $goldGodot -ArgumentList $goldImportArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-import.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-import-errors.log')
        if (-not $goldImport.WaitForExit(60000)) { Stop-Process -Id $goldImport.Id; throw 'Gold batch asset import timed out.' }
        if ($goldImport.ExitCode -ne 0) {
            Get-Content (Join-Path $PSScriptRoot 'godot-import-errors.log')
            exit $goldImport.ExitCode
        }
    }
    $goldArguments = @('--path', ('"' + $goldRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://tests/ui_review/GoldChestBatchIntegration.tscn')
    $goldProcess = Start-Process -FilePath $goldGodot -ArgumentList $goldArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    if (-not $goldProcess.WaitForExit(90000)) { Stop-Process -Id $goldProcess.Id; throw 'Gold batch native capture timed out.' }
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    $goldRunLog = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'godot-run.log'))
    if ($goldRunLog -notmatch '(?m)^GOLD_CHEST_BATCH_COMPLETE\s+checks=\d+\s+captures=\d+\s+failures=\[\]\s*$') {
        throw 'Gold batch review did not report successful completion with an empty failure list. Inspect the native logs.'
    }
    exit $goldProcess.ExitCode
}
finally {
    $env:APPDATA = $goldPreviousAppData
    $env:LOCALAPPDATA = $goldPreviousLocalData
}
