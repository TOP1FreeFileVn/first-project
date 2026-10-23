param([switch]$Capture, [switch]$ImportAssets)
$ErrorActionPreference = 'Stop'
$demoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$demoProfile = Join-Path $demoRoot 'output/shop-clarity-demo-profile'
$demoAppData = Join-Path $demoProfile 'Roaming'
$demoLocalData = Join-Path $demoProfile 'Local'
New-Item -ItemType Directory -Path $demoAppData, $demoLocalData -Force | Out-Null
$demoOldAppData = $env:APPDATA
$demoOldLocalData = $env:LOCALAPPDATA
$demoGodot = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
try {
    $env:APPDATA = $demoAppData
    $env:LOCALAPPDATA = $demoLocalData
    if ($ImportAssets) {
        $demoImportArgs = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $demoRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
        $demoImport = Start-Process -FilePath $demoGodot -ArgumentList $demoImportArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'import.log') -RedirectStandardError (Join-Path $PSScriptRoot 'import-errors.log')
        if (-not $demoImport.WaitForExit(60000)) { Stop-Process -Id $demoImport.Id; throw 'Demo import timed out.' }
    }
    $demoArgs = @('--path', ('"' + $demoRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://docs/design/2026-10-24/shop-clarity-demo/ShopDemo.tscn')
    if ($Capture) {
        $demoArgs += @('--', '--capture')
        $demoProcess = Start-Process -FilePath $demoGodot -ArgumentList $demoArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'errors.log')
        Set-Content -LiteralPath (Join-Path $PSScriptRoot 'capture.pid') -Value $demoProcess.Id
        if (-not $demoProcess.WaitForExit(75000)) { Stop-Process -Id $demoProcess.Id; throw 'Demo capture timed out.' }
        Get-Content (Join-Path $PSScriptRoot 'run.log') -Tail 6
        Get-Content (Join-Path $PSScriptRoot 'errors.log')
        exit $demoProcess.ExitCode
    }
    else {
        $demoProcess = Start-Process -FilePath $demoGodot -ArgumentList $demoArgs -PassThru -WindowStyle Normal -RedirectStandardOutput (Join-Path $PSScriptRoot 'live.log') -RedirectStandardError (Join-Path $PSScriptRoot 'live-errors.log')
        Write-Output ('SHOP_DEMO_PID=' + $demoProcess.Id)
    }
}
finally {
    $env:APPDATA = $demoOldAppData
    $env:LOCALAPPDATA = $demoOldLocalData
}
