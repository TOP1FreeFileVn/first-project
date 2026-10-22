param([switch]$ImportAssets, [switch]$GoldOnly)

$ErrorActionPreference = 'Stop'
$chestRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$chestProfile = Join-Path $chestRoot 'output/chest-integration-profile'
$chestAppData = Join-Path $chestProfile 'Roaming'
$chestLocalData = Join-Path $chestProfile 'Local'
New-Item -ItemType Directory -Path $chestAppData, $chestLocalData -Force | Out-Null
$chestPreviousAppData = $env:APPDATA
$chestPreviousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $chestAppData
    $env:LOCALAPPDATA = $chestLocalData
    if ($ImportAssets) {
        $chestImportArguments = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $chestRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
        $chestImport = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $chestImportArguments -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-import.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-import-errors.log')
        if ($chestImport.ExitCode -ne 0) {
            Get-Content (Join-Path $PSScriptRoot 'godot-import-errors.log')
            exit $chestImport.ExitCode
        }
    }
    $chestArguments = @('--path', ('"' + $chestRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://tests/ui_review/ChestIntegrationReview.tscn')
    if ($GoldOnly) { $chestArguments += @('--', '--gold-only') }
    $chestProcess = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $chestArguments -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'godot-run.log') -RedirectStandardError (Join-Path $PSScriptRoot 'godot-errors.log')
    Get-Content (Join-Path $PSScriptRoot 'godot-run.log') -Tail 8
    Get-Content (Join-Path $PSScriptRoot 'godot-errors.log')
    exit $chestProcess.ExitCode
}
finally {
    $env:APPDATA = $chestPreviousAppData
    $env:LOCALAPPDATA = $chestPreviousLocalData
}
