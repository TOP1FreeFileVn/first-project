$ErrorActionPreference = 'Stop'
$chestRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path
$chestOutput = Join-Path $chestRoot 'output/imagegen/silver-chest-2026-10-24'
[IO.Directory]::CreateDirectory($chestOutput) | Out-Null
$chestRaw = Join-Path $chestOutput 'silver-raw.png'
if (Test-Path -LiteralPath $chestRaw) { Write-Output 'Preserving existing silver chest output'; exit 0 }
# Existing user-authorized 9Router Responses workflow. Credentials stay in memory.
$chestConfig = [IO.File]::ReadAllText((Join-Path $env:USERPROFILE '.codex/config.toml'), [Text.Encoding]::UTF8)
$chestProvider = [regex]::Match($chestConfig, '(?ms)^\[model_providers\.r9\]\s*(.*?)(?=^\[|\z)').Groups[1].Value
$chestToken = [regex]::Match($chestProvider, '(?m)^\s*experimental_bearer_token\s*=\s*"([^"]+)"').Groups[1].Value
if ([string]::IsNullOrWhiteSpace($chestToken)) { throw 'Local router credential unavailable' }
$chestPrompt = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'prompt.txt'), [Text.Encoding]::UTF8)
$chestReferences = @('game/ui/art/chests/strongbox-b/silver/closed.png','game/ui/art/chests/strongbox-b/wood/closed.png','game/ui/art/chests/strongbox-b/gold/closed.png')
$chestContent = @(@{type='input_text';text=$chestPrompt})
foreach ($chestReference in $chestReferences) {
    $chestContent += @{type='input_image';image_url=('data:image/png;base64,' + [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $chestRoot $chestReference))))}
}
$chestBody = @{
    model='cx/gpt-6-astra';
    instructions='Generate exactly one isolated closed silver chest game illustration using the image generation tool. Match the supplied thick flat cartoon style and redesign the silver tier structure. No text or extra objects. Return the image.';
    input=@(@{role='user';content=$chestContent});
    tools=@(@{type='image_generation';model='gpt-image-2.5-sunburst';action='generate';size='1024x1024';quality='medium';output_format='png'});
    tool_choice=@{type='image_generation'};stream=$false;store=$false
}
$chestMeta = [ordered]@{status='generating';transport='User-selected 9Router local /v1/responses';requested_image_model='gpt-image-2.5-sunburst';requested_size='1024x1024';quality='medium';started_utc=[DateTime]::UtcNow.ToString('o');prompt='docs/design/2026-10-24/silver-chest-upgrade/prompt.txt';reference_files=$chestReferences}
$chestMetaPath = Join-Path $chestOutput 'silver-generation.json'
$chestMeta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $chestMetaPath -Encoding UTF8
Write-Output 'Generating upgraded silver chest illustration...'
try {
    $chestJson = $chestBody | ConvertTo-Json -Depth 20 -Compress
    $chestResponse = Invoke-RestMethod -Uri 'http://127.0.0.1:20129/v1/responses' -Method Post -Headers @{Authorization=('Bearer ' + $chestToken)} -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($chestJson)) -TimeoutSec 600
    $chestResult = @($chestResponse.output | Where-Object {$_.type -eq 'image_generation_call' -and $_.result}) | Select-Object -First 1
    if (-not $chestResult) { throw 'Router returned no image generation result' }
    [IO.File]::WriteAllBytes($chestRaw,[Convert]::FromBase64String($chestResult.result))
    $chestMeta.status='generated'; $chestMeta.finished_utc=[DateTime]::UtcNow.ToString('o'); $chestMeta.output='silver-raw.png'; $chestMeta.response_model=$chestResponse.model
    if ($chestResult.model) { $chestMeta.reported_image_model=$chestResult.model }
    $chestMeta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $chestMetaPath -Encoding UTF8
    Write-Output ('Generated silver chest: ' + $chestRaw)
}
catch {
    $chestMeta.status='failed'; $chestMeta.finished_utc=[DateTime]::UtcNow.ToString('o')
    $chestMeta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $chestMetaPath -Encoding UTF8
    throw 'Silver image generation failed. See safe generation metadata for status.'
}
