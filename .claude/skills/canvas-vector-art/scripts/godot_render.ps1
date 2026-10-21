# Render every SVG in <dir>/svg to <dir>/godot/*.png with the game's own SVG renderer.
# powershell -File .claude/skills/canvas-vector-art/scripts/godot_render.ps1 -Dir docs/design/<date>/<name>
param(
    [Parameter(Mandatory)][string]$Dir,
    [string]$Godot = "C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"
)
$svgDir = Join-Path $Dir "svg"
$outDir = Join-Path $Dir "godot"
New-Item -ItemType Directory -Force $outDir | Out-Null
$failed = 0
foreach ($f in Get-ChildItem $svgDir -Filter *.svg) {
    $png = Join-Path $outDir ($f.BaseName + ".png")
    if (Test-Path $png) { Remove-Item $png }
    # The GUI Godot exe can return before the PNG is written; wait for the process.
    $p = Start-Process -FilePath $Godot -NoNewWindow -PassThru -Wait -RedirectStandardError "$outDir\render.err" `
        -ArgumentList "--headless", "--path", ".", "--script", "res://tools/ui/render_svg_png.gd", "--", `
        ($f.FullName -replace '\\', '/'), ($png -replace '\\', '/')
    if (Test-Path $png) { "OK   $png" } else { "FAIL $($f.Name) (exit $($p.ExitCode))"; Get-Content "$outDir\render.err" | Select-String 'rror'; $failed++ }
}
exit $failed
