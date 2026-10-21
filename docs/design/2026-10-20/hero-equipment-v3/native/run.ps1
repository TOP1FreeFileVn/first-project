param(
    [string]$Engine = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'
)
$ErrorActionPreference = 'Stop'
$native = [System.IO.Path]::GetFullPath($PSScriptRoot)
$review = [System.IO.Path]::GetFullPath((Join-Path $native '..'))
$profile = [System.IO.Path]::GetFullPath((Join-Path $native 'profile-roaming'))
if (-not $profile.StartsWith($native + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Review profile must stay under the isolated native folder.'
}
foreach ($asset in @('hero-equipment-review.png', 'processed/hero-melee.png', 'processed/hero-ranged.png', 'processed/hero-magic.png', 'processed/hero-heavy.png')) {
    if (-not (Test-Path -LiteralPath (Join-Path $review $asset) -PathType Leaf)) {
        throw "Build review art first. Missing: $asset"
    }
}
if (-not (Test-Path -LiteralPath $Engine -PathType Leaf)) { throw "Missing engine: $Engine" }
$override = "[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"StudioHeroV3`"`n"
[System.IO.File]::WriteAllText((Join-Path $native 'override.cfg'), $override, [System.Text.UTF8Encoding]::new($false))
New-Item -ItemType Directory -Force -Path $profile | Out-Null
$localProfile = Join-Path $native 'profile-local'
New-Item -ItemType Directory -Force -Path $localProfile | Out-Null
$engineArgs = @('--path', ('"' + $native + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--accessibility', 'disabled', '--script', 'res://verify.gd', '--log-file', ('"' + (Join-Path $native 'engine.log') + '"'))
$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $Engine
$startInfo.Arguments = $engineArgs -join ' '
$startInfo.WorkingDirectory = $native
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
# Modify only the child process environment. The shell's APPDATA stays unchanged.
$startInfo.EnvironmentVariables['APPDATA'] = $profile
$startInfo.EnvironmentVariables['LOCALAPPDATA'] = $localProfile
$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
if (-not $process.Start()) { throw 'Unable to start the isolated Godot review.' }
$readOutput = $process.StandardOutput.ReadToEndAsync()
$readError = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(45000)) {
    $process.Kill()
    throw 'Isolated Godot review exceeded 45 seconds; helper was stopped.'
}
[System.IO.File]::WriteAllText((Join-Path $native 'stdout.log'), $readOutput.Result, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $native 'stderr.log'), $readError.Result, [System.Text.UTF8Encoding]::new($false))
if ($process.ExitCode -ne 0) {
    Get-Content -LiteralPath (Join-Path $native 'stderr.log')
    throw "Godot review exited with code $($process.ExitCode)."
}
Get-Content -LiteralPath (Join-Path $native 'stdout.log')
Get-Content -LiteralPath (Join-Path $native 'review-status.json')
