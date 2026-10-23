$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $taskRoot '../../../..')).Path
$nativeOut = Join-Path $taskRoot 'godot'
$profile = Join-Path $projectRoot 'output/power-icon-native-profile'
New-Item -ItemType Directory -Force $nativeOut, $profile | Out-Null
$env:APPDATA = $profile
$env:LOCALAPPDATA = $profile
$godotExe = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
foreach ($icon in @('crossed', 'fist')) {
    foreach ($size in @(21, 24, 32)) {
        $svgPath = (Join-Path $taskRoot "svg/power-$icon-$size.svg") -replace '\\', '/'
        $pngPath = (Join-Path $nativeOut "power-$icon-$size.png") -replace '\\', '/'
        $process = Start-Process -FilePath $godotExe -WindowStyle Hidden -PassThru -Wait -WorkingDirectory $projectRoot -ArgumentList @('--headless', '--path', '.', '--script', 'res://tools/ui/render_svg_png.gd', '--', $svgPath, $pngPath) -RedirectStandardOutput (Join-Path $nativeOut 'render.log') -RedirectStandardError (Join-Path $nativeOut 'render.err')
        if ($process.ExitCode -ne 0 -or !(Test-Path -LiteralPath $pngPath)) { throw "Native rendering failed: $icon $size" }
    }
}
Write-Output 'Rendered both icons with Godot at 21,24,32px using an isolated profile.'
