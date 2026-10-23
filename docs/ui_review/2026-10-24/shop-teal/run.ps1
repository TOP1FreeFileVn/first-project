param([switch]$ImportAssets)

$ErrorActionPreference = 'Stop'
$shopRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$shopProfile = Join-Path $shopRoot 'output/shop-teal-integration-profile'
$shopAppData = Join-Path $shopProfile 'Roaming'
$shopLocalData = Join-Path $shopProfile 'Local'
New-Item -ItemType Directory -Path $shopAppData, $shopLocalData -Force | Out-Null
$shopPreviousAppData = $env:APPDATA
$shopPreviousLocalData = $env:LOCALAPPDATA
$shopGodot = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
try {
    $env:APPDATA = $shopAppData
    $env:LOCALAPPDATA = $shopLocalData
    if ($ImportAssets) {
        $shopImportArguments = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $shopRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
        $shopImport = Start-Process -FilePath $shopGodot -ArgumentList $shopImportArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-import.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-import-errors.log')
        if (-not $shopImport.WaitForExit(60000)) { Stop-Process -Id $shopImport.Id; throw 'Shop teal asset import timed out.' }
        if ($shopImport.ExitCode -ne 0) {
            Get-Content (Join-Path $PSScriptRoot 'godot-import-errors.log')
            exit $shopImport.ExitCode
        }
    }
    $shopArguments = @('--path', ('"' + $shopRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://tests/ui_review/ShopTealIntegration.tscn')
    $shopProcess = Start-Process -FilePath $shopGodot -ArgumentList $shopArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    if (-not $shopProcess.WaitForExit(90000)) { Stop-Process -Id $shopProcess.Id; throw 'Shop teal native integration capture timed out.' }
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    exit $shopProcess.ExitCode
}
finally {
    $env:APPDATA = $shopPreviousAppData
    $env:LOCALAPPDATA = $shopPreviousLocalData
}
