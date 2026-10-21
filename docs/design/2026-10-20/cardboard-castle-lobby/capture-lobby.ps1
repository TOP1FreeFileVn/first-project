param([string]$Engine = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe')
$ErrorActionPreference = 'Stop'
$reviewPath = [System.IO.Path]::GetFullPath($PSScriptRoot)
$projectPath = [System.IO.Path]::GetFullPath((Join-Path $reviewPath '../../../..'))
$profilePath = Join-Path $reviewPath 'capture-profile-roaming'
$localProfilePath = Join-Path $reviewPath 'capture-profile-local'
New-Item -ItemType Directory -Force -Path $profilePath, $localProfilePath | Out-Null
$engineArgs = @('--path', ('"' + $projectPath + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--accessibility', 'disabled', '--position', '-32000,-32000', '--resolution', '720x1280', '--log-file', ('"' + (Join-Path $reviewPath 'capture-engine.log') + '"'), 'res://docs/design/2026-10-20/cardboard-castle-lobby/LobbyDraftCapture.tscn')
$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $Engine
$startInfo.Arguments = $engineArgs -join ' '
$startInfo.WorkingDirectory = $projectPath
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.EnvironmentVariables['APPDATA'] = $profilePath
$startInfo.EnvironmentVariables['LOCALAPPDATA'] = $localProfilePath
$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
if (-not $process.Start()) { throw 'Unable to start lobby capture.' }
$outputTask = $process.StandardOutput.ReadToEndAsync()
$errorTask = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(45000)) { $process.Kill(); throw 'Lobby capture exceeded 45 seconds.' }
[System.IO.File]::WriteAllText((Join-Path $reviewPath 'capture-stdout.log'), $outputTask.Result, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $reviewPath 'capture-stderr.log'), $errorTask.Result, [System.Text.UTF8Encoding]::new($false))
if ($process.ExitCode -ne 0) { Get-Content -LiteralPath (Join-Path $reviewPath 'capture-stderr.log'); throw "Lobby capture failed: $($process.ExitCode)" }
Get-Content -LiteralPath (Join-Path $reviewPath 'capture-stdout.log')
