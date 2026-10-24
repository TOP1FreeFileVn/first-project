$ErrorActionPreference = 'Stop'
$batchRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$batchProfile = Join-Path $batchRoot 'output/gold-chest-batch-logic'
$batchAppData = Join-Path $batchProfile 'Roaming'
$batchLocalData = Join-Path $batchProfile 'Local'
New-Item -ItemType Directory -Path $batchAppData, $batchLocalData -Force | Out-Null
$batchPreviousAppData = $env:APPDATA
$batchPreviousLocalData = $env:LOCALAPPDATA
$batchGodot = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
$batchLog = Join-Path $PSScriptRoot 'logic-run.log'
$batchErrors = Join-Path $PSScriptRoot 'logic-errors.log'
try {
    $env:APPDATA = $batchAppData
    $env:LOCALAPPDATA = $batchLocalData
    $batchArguments = @('--headless', '--path', ('"' + $batchRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://tests/GoldChestBatchTest.tscn')
    $batchProcess = Start-Process -FilePath $batchGodot -ArgumentList $batchArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $batchLog -RedirectStandardError $batchErrors
    if (-not $batchProcess.WaitForExit(30000)) { Stop-Process -Id $batchProcess.Id; throw 'Gold chest logic test timed out.' }
    Get-Content $batchLog -Tail 12
    Get-Content $batchErrors
    if ($batchProcess.ExitCode -ne 0) { exit $batchProcess.ExitCode }
    if (-not (Select-String -Path $batchLog -Pattern '^GOLD_BATCH_START$' -Quiet)) { throw 'Gold chest logic test did not start.' }
    if (-not (Select-String -Path $batchLog -Pattern '^GOLD_BATCH_SUMMARY checks=\d+ failed=0$' -Quiet)) { throw 'Gold chest logic test did not complete successfully.' }
    if (Select-String -Path $batchErrors -Pattern 'SCRIPT ERROR|Parse Error|Compile Error' -Quiet) { throw 'Gold chest logic test reported a script error.' }
}
finally {
    $env:APPDATA = $batchPreviousAppData
    $env:LOCALAPPDATA = $batchPreviousLocalData
}
