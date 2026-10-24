param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [switch]$ImportAssets
)

$ErrorActionPreference = 'Stop'
$integrationRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$integrationOutput = Join-Path $PSScriptRoot 'review'
$integrationProfileRoot = Join-Path $integrationRoot 'output/carton-summon-integration-profile'
$integrationPreviousAppData = $env:APPDATA
$integrationPreviousLocalData = $env:LOCALAPPDATA
New-Item -ItemType Directory -Path $integrationOutput -Force | Out-Null
try {
    foreach ($integrationSize in @('450x800', '360x640')) {
        $integrationProfile = Join-Path $integrationProfileRoot $integrationSize
        $integrationRoaming = Join-Path $integrationProfile 'Roaming'
        $integrationLocal = Join-Path $integrationProfile 'Local'
        New-Item -ItemType Directory -Path $integrationRoaming, $integrationLocal -Force | Out-Null
        $env:APPDATA = $integrationRoaming
        $env:LOCALAPPDATA = $integrationLocal
        if ($ImportAssets -and $integrationSize -eq '450x800') {
            $integrationImportArgs = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $integrationRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
            $integrationImport = Start-Process -FilePath $GodotExe -ArgumentList $integrationImportArgs -WorkingDirectory $integrationRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $integrationOutput 'godot-import.log') -RedirectStandardError (Join-Path $integrationOutput 'godot-import-errors.log')
            $integrationImportHandle = $integrationImport.Handle
            if (-not $integrationImport.WaitForExit(55000)) { Stop-Process -Id $integrationImport.Id -Force; throw 'Carton integration import timed out.' }
            $integrationImport.Refresh()
            if ($null -ne $integrationImport.ExitCode -and $integrationImport.ExitCode -ne 0) { throw ('Carton integration import failed: ' + $integrationImport.ExitCode) }
        }
        $integrationLog = Join-Path $integrationOutput ('godot-' + $integrationSize + '.log')
        $integrationErrors = Join-Path $integrationOutput ('godot-' + $integrationSize + '-errors.log')
        $integrationArgs = @('--path', ('"' + $integrationRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--resolution', $integrationSize,
            'res://tests/ui_review/CartonSummonIntegration.tscn', '--', ('--size=' + $integrationSize))
        $integrationStarted = [DateTime]::UtcNow
        $integrationProcess = Start-Process -FilePath $GodotExe -ArgumentList $integrationArgs -WorkingDirectory $integrationRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $integrationLog -RedirectStandardError $integrationErrors
        $integrationHandle = $integrationProcess.Handle
        if (-not $integrationProcess.WaitForExit(55000)) {
            Stop-Process -Id $integrationProcess.Id -Force
            Get-Content -LiteralPath $integrationErrors
            throw ('Carton integration timed out at ' + $integrationSize)
        }
        $integrationProcess.Refresh()
        Get-Content -LiteralPath $integrationLog -Tail 12
        Get-Content -LiteralPath $integrationErrors
        $integrationCombinedLog = [IO.File]::ReadAllText($integrationLog) + [Environment]::NewLine + [IO.File]::ReadAllText($integrationErrors)
        if ($integrationCombinedLog -match '(?im)SCRIPT ERROR|Parse Error|Parser Error|Invalid polygon|Invalid call|Failed to load script|GDScript::reload') {
            throw ('Carton integration has a script or drawing error at ' + $integrationSize)
        }
        if ($null -ne $integrationProcess.ExitCode -and $integrationProcess.ExitCode -ne 0) { throw ('Carton integration failed at ' + $integrationSize) }
        if (-not (Select-String -LiteralPath $integrationLog -Pattern '^CARTON_SUMMON_INTEGRATION_COMPLETE checks=\d+ captures=\d+ failures=0\s*$' -Quiet)) { throw 'Carton integration did not report successful completion.' }
        $integrationManifestPath = Join-Path $integrationOutput ('manifest-' + $integrationSize + '.json')
        if (-not (Test-Path -LiteralPath $integrationManifestPath -PathType Leaf)) { throw 'Missing carton integration manifest.' }
        if ((Get-Item -LiteralPath $integrationManifestPath).LastWriteTimeUtc -lt $integrationStarted) { throw 'Carton integration manifest is stale.' }
        $integrationManifest = Get-Content -LiteralPath $integrationManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($integrationManifest.failures -ne 0) { throw 'Carton integration manifest reports failures.' }
    }
}
finally {
    $env:APPDATA = $integrationPreviousAppData
    $env:LOCALAPPDATA = $integrationPreviousLocalData
}
