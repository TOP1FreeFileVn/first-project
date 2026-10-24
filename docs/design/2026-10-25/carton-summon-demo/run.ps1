param(
    [string]$GodotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe',
    [switch]$ImportAssets,
    [switch]$Record,
    [switch]$Interactive,
    [ValidateSet(1, 10)][int]$Count = 10,
    [ValidateSet('450x800', '360x640')][string]$Size = '450x800',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'review')
)

$ErrorActionPreference = 'Stop'
$cartonRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$cartonOutput = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $cartonOutput.StartsWith(($cartonRoot.TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Carton summon review output must stay inside the project.'
}
New-Item -ItemType Directory -Path $cartonOutput -Force | Out-Null
$cartonOutputResource = 'res://' + $cartonOutput.Substring($cartonRoot.Length).TrimStart('\').Replace('\', '/')
$cartonProfileRoot = Join-Path $cartonRoot 'output/carton-summon-demo-review-profile'
$cartonPreviousAppData = $env:APPDATA
$cartonPreviousLocalData = $env:LOCALAPPDATA
$cartonCases = @(
    @{ Count = 1; Size = '450x800' },
    @{ Count = 10; Size = '450x800' },
    @{ Count = 10; Size = '360x640' }
)

try {
    if ($Interactive) {
        $cartonLiveProfile = Join-Path $cartonProfileRoot ('live-x' + $Count + '-' + $Size)
        $cartonLiveRoaming = Join-Path $cartonLiveProfile 'Roaming'
        $cartonLiveLocal = Join-Path $cartonLiveProfile 'Local'
        New-Item -ItemType Directory -Path $cartonLiveRoaming, $cartonLiveLocal -Force | Out-Null
        $env:APPDATA = $cartonLiveRoaming
        $env:LOCALAPPDATA = $cartonLiveLocal
        $cartonLiveArguments = @('--path', ('"' + $cartonRoot + '"'), '--rendering-method', 'gl_compatibility', '--resolution', $Size,
            'res://docs/design/2026-10-25/carton-summon-demo/CartonSummonDemo.tscn', '--', ('--count=' + $Count), ('--size=' + $Size))
        $cartonLive = Start-Process -FilePath $GodotExe -ArgumentList $cartonLiveArguments -WorkingDirectory $cartonRoot -WindowStyle Normal -PassThru -RedirectStandardOutput (Join-Path $cartonOutput 'godot-live.log') -RedirectStandardError (Join-Path $cartonOutput 'godot-live-errors.log')
        Write-Output ('CARTON_SUMMON_DEMO_LIVE process=' + $cartonLive.Id + ' count=' + $Count + ' size=' + $Size)
        return
    }
    foreach ($cartonCase in $cartonCases) {
        $cartonName = 'x' + $cartonCase.Count + '-' + $cartonCase.Size
        $cartonProfile = Join-Path $cartonProfileRoot $cartonName
        $cartonRoaming = Join-Path $cartonProfile 'Roaming'
        $cartonLocal = Join-Path $cartonProfile 'Local'
        New-Item -ItemType Directory -Path $cartonRoaming, $cartonLocal -Force | Out-Null
        $env:APPDATA = $cartonRoaming
        $env:LOCALAPPDATA = $cartonLocal
        if ($ImportAssets -and $cartonName -eq 'x1-450x800') {
            $cartonImportArgs = @('--headless', '--editor', '--import', '--quit', '--path', ('"' + $cartonRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy')
            $cartonImport = Start-Process -FilePath $GodotExe -ArgumentList $cartonImportArgs -WorkingDirectory $cartonRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $cartonOutput 'godot-import.log') -RedirectStandardError (Join-Path $cartonOutput 'godot-import-errors.log')
            $cartonImportHandle = $cartonImport.Handle
            if (-not $cartonImport.WaitForExit(55000)) { Stop-Process -Id $cartonImport.Id -Force; throw 'Carton demo import timed out.' }
            $cartonImport.Refresh()
            if ($null -ne $cartonImport.ExitCode -and $cartonImport.ExitCode -ne 0) { throw ('Carton demo import failed: ' + $cartonImport.ExitCode) }
        }

        $cartonLog = Join-Path $cartonOutput ('godot-' + $cartonName + '.log')
        $cartonErrors = Join-Path $cartonOutput ('godot-' + $cartonName + '-errors.log')
        $cartonArguments = @('--path', ('"' + $cartonRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--resolution', $cartonCase.Size,
            'res://docs/design/2026-10-25/carton-summon-demo/CartonSummonDemo.tscn', '--', ('--count=' + $cartonCase.Count), '--review', ('--size=' + $cartonCase.Size), ('--out=' + $cartonOutputResource))
        if ($Record) { $cartonArguments += '--record' }
        $cartonStarted = [DateTime]::UtcNow
        $cartonProcess = Start-Process -FilePath $GodotExe -ArgumentList $cartonArguments -WorkingDirectory $cartonRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $cartonLog -RedirectStandardError $cartonErrors
        $cartonProcessHandle = $cartonProcess.Handle
        if (-not $cartonProcess.WaitForExit(55000)) {
            Stop-Process -Id $cartonProcess.Id -Force
            Get-Content -LiteralPath $cartonErrors
            throw ('Carton summon demo timed out: ' + $cartonName)
        }
        $cartonProcess.Refresh()
        Get-Content -LiteralPath $cartonLog -Tail 10
        Get-Content -LiteralPath $cartonErrors
        if (Select-String -LiteralPath $cartonErrors -Pattern 'SCRIPT ERROR:|Parse Error:|Invalid polygon data' -Quiet) {
            throw ('Carton demo has script or drawing errors: ' + $cartonName)
        }
        if ($null -ne $cartonProcess.ExitCode -and $cartonProcess.ExitCode -ne 0) { throw ('Carton demo failed: ' + $cartonName + ', exit=' + $cartonProcess.ExitCode) }
        if (-not (Select-String -LiteralPath $cartonLog -Pattern '^CARTON_SUMMON_DEMO_COMPLETE count=\d+ captures=6 failures=0\s*$' -Quiet)) {
            throw ('Carton demo did not report successful completion: ' + $cartonName)
        }
        $cartonManifestPath = Join-Path $cartonOutput ('manifest-' + $cartonCase.Count + '-' + $cartonCase.Size + '.json')
        if (-not (Test-Path -LiteralPath $cartonManifestPath -PathType Leaf)) { throw ('Missing native manifest: ' + $cartonManifestPath) }
        if ((Get-Item -LiteralPath $cartonManifestPath).LastWriteTimeUtc -lt $cartonStarted) { throw ('Native manifest is stale: ' + $cartonName) }
        $cartonManifest = Get-Content -LiteralPath $cartonManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cartonManifest.failures -ne 0) { throw ('Native manifest reported failures: ' + $cartonName) }
        if (@($cartonManifest.captures).Count -ne 6) { throw ('Expected six storyboard captures: ' + $cartonName) }
    }
}
finally {
    $env:APPDATA = $cartonPreviousAppData
    $env:LOCALAPPDATA = $cartonPreviousLocalData
}
