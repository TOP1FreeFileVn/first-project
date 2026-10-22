$ErrorActionPreference = 'Stop'
# Keep the original four-slot capture and logs intact; rerun current checks in their own revision folder.
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'centered-icons/run.ps1')
exit $LASTEXITCODE
