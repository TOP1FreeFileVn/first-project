param([Parameter(Mandatory=$true)][ValidateSet('bow','staff','axe','katana')][string]$Family)
$ErrorActionPreference = 'Stop'
$weaponDir = $PSScriptRoot
$weaponRoot = (Resolve-Path (Join-Path $weaponDir '../../../..')).Path
$env:APPDATA = Join-Path $weaponRoot "output/hero-weapons-godot-$Family/Roaming"
$env:LOCALAPPDATA = Join-Path $weaponRoot "output/hero-weapons-godot-$Family/Local"
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $weaponDir 'godot') | Out-Null
$weaponSvgs = Get-ChildItem -LiteralPath (Join-Path $weaponDir 'svg') -Filter '*.svg' | Where-Object { $_.BaseName.StartsWith($Family + '-') -or $_.BaseName.StartsWith('hero-' + $Family + '-') }
foreach ($weaponSvg in $weaponSvgs) {
    $weaponVariant = $weaponSvg.BaseName
    $weaponInput = $weaponSvg.FullName.Replace('\','/')
    $weaponOutput = (Join-Path $weaponDir "godot/$weaponVariant.png").Replace('\','/')
    $weaponArgs = @('--headless','--path',('"' + $weaponRoot + '"'),'--script','res://tools/ui/render_svg_png.gd','--',('"' + $weaponInput + '"'),('"' + $weaponOutput + '"'))
    $weaponProc = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $weaponArgs -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput (Join-Path $weaponDir "godot/$weaponVariant-stdout.log") -RedirectStandardError (Join-Path $weaponDir "godot/$weaponVariant-stderr.log")
    if ($weaponProc.ExitCode -ne 0) { throw "Godot render failed: $weaponVariant ($($weaponProc.ExitCode))" }
}
Write-Output "Rendered $($weaponSvgs.Count) $Family SVGs."
