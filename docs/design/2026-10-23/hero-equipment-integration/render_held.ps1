$ErrorActionPreference = 'Stop'
$integrationDir = $PSScriptRoot
$integrationRoot = (Resolve-Path (Join-Path $integrationDir '../../../..')).Path
$sourceDir = Join-Path $integrationRoot 'docs/design/2026-10-22/hero-weapons-canvas/svg'
$env:APPDATA = Join-Path $integrationRoot 'output/hero-equipment-integration/Roaming'
$env:LOCALAPPDATA = Join-Path $integrationRoot 'output/hero-equipment-integration/Local'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $integrationDir 'svg'),(Join-Path $integrationDir 'godot') | Out-Null
foreach ($integrationFamily in @('bow','staff','katana')) {
    $integrationSvg = Get-Content -LiteralPath (Join-Path $sourceDir "hero-$integrationFamily-256.svg") -Raw
    # Change the output resolution only. Retain paths, viewBox, cat, palm and paws.
    $integrationSvg = $integrationSvg.Replace('width="256" height="240"','width="768" height="720"')
    $integrationInput = (Join-Path $integrationDir "svg/hero-$integrationFamily-768.svg").Replace('\','/')
    [System.IO.File]::WriteAllText($integrationInput, $integrationSvg, (New-Object System.Text.UTF8Encoding($false)))
    $integrationOutput = (Join-Path $integrationDir "godot/hero-$integrationFamily-768.png").Replace('\','/')
    $integrationArgs = @('--headless','--path',('"' + $integrationRoot + '"'),'--script','res://tools/ui/render_svg_png.gd','--',('"' + $integrationInput + '"'),('"' + $integrationOutput + '"'))
    $integrationProc = Start-Process -FilePath 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' -ArgumentList $integrationArgs -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput (Join-Path $integrationDir "godot/$integrationFamily-stdout.log") -RedirectStandardError (Join-Path $integrationDir "godot/$integrationFamily-stderr.log")
    if ($integrationProc.ExitCode -ne 0) { throw "Godot render failed: $integrationFamily ($($integrationProc.ExitCode))" }
}
Write-Output 'Rendered three latest held weapons natively at 768x720.'
