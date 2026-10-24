param([switch]$ImportAssets)

$ErrorActionPreference = 'Stop'
$sectionsRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$sectionsProfile = Join-Path $sectionsRoot 'output/shop-sections-profile'
$sectionsAppData = Join-Path $sectionsProfile 'Roaming'
$sectionsLocalData = Join-Path $sectionsProfile 'Local'
New-Item -ItemType Directory -Path $sectionsAppData, $sectionsLocalData -Force | Out-Null
$sectionsPreviousAppData = $env:APPDATA
$sectionsPreviousLocalData = $env:LOCALAPPDATA
$sectionsGodot = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
try {
    $env:APPDATA = $sectionsAppData
    $env:LOCALAPPDATA = $sectionsLocalData
    if ($ImportAssets) {
        $sectionsImportArguments = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $sectionsRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
        $sectionsImport = Start-Process -FilePath $sectionsGodot -ArgumentList $sectionsImportArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-import.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-import-errors.log')
        $null = $sectionsImport.Handle
        if (-not $sectionsImport.WaitForExit(60000)) { Stop-Process -Id $sectionsImport.Id; throw 'Shop sections asset import timed out.' }
        if ($sectionsImport.ExitCode -ne 0) {
            Get-Content (Join-Path $PSScriptRoot 'godot-import-errors.log')
            exit $sectionsImport.ExitCode
        }
    }
    $sectionsArguments = @('--path', ('"' + $sectionsRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://tests/ui_review/ShopSectionsIntegration.tscn')
    $sectionsProcess = Start-Process -FilePath $sectionsGodot -ArgumentList $sectionsArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    $null = $sectionsProcess.Handle
    if (-not $sectionsProcess.WaitForExit(90000)) { Stop-Process -Id $sectionsProcess.Id; throw 'Shop sections native capture timed out.' }
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    $sectionsRunLog = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'godot-run.log'))
    if ($sectionsRunLog -notmatch '(?m)^SHOP_SECTIONS_INTEGRATION_COMPLETE\s+checks=\d+\s+captures=\d+\s+failures=\[\]\s*$') {
        throw 'Shop sections review did not report successful completion with an empty failure list. Inspect the native logs.'
    }
    exit $sectionsProcess.ExitCode
}
finally {
    $env:APPDATA = $sectionsPreviousAppData
    $env:LOCALAPPDATA = $sectionsPreviousLocalData
}
