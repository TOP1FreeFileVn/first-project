# Screenshot a local HTML page with headless Edge so Claude can look at it.
# powershell -File .claude/skills/canvas-vector-art/scripts/snap.ps1 -Page <dir>/preview.html -Out <dir>/round-1.png [-Width 1060 -Height 540]
param(
    [Parameter(Mandatory)][string]$Page,
    [Parameter(Mandatory)][string]$Out,
    [int]$Width = 1060,
    [int]$Height = 540
)
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$pagePath = (Resolve-Path $Page).Path
$outPath = [IO.Path]::GetFullPath($Out)
if (Test-Path $outPath) { Remove-Item $outPath }
$url = "file:///" + ($pagePath -replace '\\', '/')
& $edge --headless=new --disable-gpu --allow-file-access-from-files --hide-scrollbars `
    "--window-size=$Width,$Height" --virtual-time-budget=3000 "--screenshot=$outPath" $url 2>$null
for ($i = 0; $i -lt 20 -and -not (Test-Path $outPath); $i++) { Start-Sleep -Milliseconds 300 }
if (Test-Path $outPath) { "Saved $outPath" } else { "FAILED: no screenshot for $url"; exit 1 }
