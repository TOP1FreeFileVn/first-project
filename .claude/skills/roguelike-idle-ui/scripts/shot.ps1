# Renders a Godot scene to a PNG at 720x1280 and stops Godot if the shot never comes
# (a parse error leaves the window open). The scene must read "-- --shot=PATH" and quit.
param(
	[Parameter(Mandatory = $true)][string]$Scene,
	[Parameter(Mandatory = $true)][string]$Out,
	[int]$TimeoutSec = 60,
	[string]$Godot = "C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"
)
$log = [System.IO.Path]::ChangeExtension($Out, ".log")
$err = [System.IO.Path]::ChangeExtension($Out, ".err.log")
$p = Start-Process -FilePath $Godot -ArgumentList "--path", ".", "--resolution", "720x1280", $Scene, "--", "--shot=$Out" `
	-RedirectStandardOutput $log -RedirectStandardError $err -PassThru
if (-not $p.WaitForExit($TimeoutSec * 1000)) {
	Stop-Process -Id $p.Id -Confirm:$false
	Write-Output "TIMEOUT: Godot did not finish; see $err"
}
Get-Content $err -ErrorAction SilentlyContinue | Where-Object { $_ -match "ERROR" -or $_ -match "at:" }
if (Test-Path $Out) { Write-Output "Saved $Out" } else { Write-Output "No image written" }
