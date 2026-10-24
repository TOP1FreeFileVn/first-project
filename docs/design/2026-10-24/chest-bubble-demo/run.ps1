param([switch]$Capture)
$ErrorActionPreference = 'Stop'
$bubbleRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$bubbleProfile = Join-Path $bubbleRoot 'output/chest-bubble-demo-profile'
New-Item -ItemType Directory -Force -Path (Join-Path $bubbleProfile 'Roaming'), (Join-Path $bubbleProfile 'Local') | Out-Null
$bubblePreviousAppData = $env:APPDATA
$bubblePreviousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $bubbleProfile 'Roaming'
    $env:LOCALAPPDATA = Join-Path $bubbleProfile 'Local'
    $bubbleArguments = @('--path', ('"' + $bubbleRoot + '"'), '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', 'res://docs/design/2026-10-24/chest-bubble-demo/ChestBubbleDemo.tscn')
    $bubbleLaunch = @{ FilePath = 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe'; ArgumentList = $bubbleArguments; PassThru = $true }
    if ($Capture) {
        $bubbleArguments += @('--', '--capture')
        $bubbleLaunch.ArgumentList = $bubbleArguments
        $bubbleProcess = Start-Process @bubbleLaunch -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'capture.log') -RedirectStandardError (Join-Path $PSScriptRoot 'errors.log')
        if (-not $bubbleProcess.WaitForExit(75000)) { Stop-Process -Id $bubbleProcess.Id; throw 'Chest bubble capture timed out.' }
        Get-Content -Encoding utf8 (Join-Path $PSScriptRoot 'capture.log') -Tail 5
        Get-Content -Encoding utf8 (Join-Path $PSScriptRoot 'errors.log')
        exit $bubbleProcess.ExitCode
    }
    else {
        $bubbleProcess = Start-Process @bubbleLaunch -WindowStyle Normal -RedirectStandardOutput (Join-Path $PSScriptRoot 'live.log') -RedirectStandardError (Join-Path $PSScriptRoot 'live-errors.log')
        Write-Output ('CHEST_BUBBLE_DEMO_PID=' + $bubbleProcess.Id)
    }
}
finally {
    $env:APPDATA = $bubblePreviousAppData
    $env:LOCALAPPDATA = $bubblePreviousLocalData
}
