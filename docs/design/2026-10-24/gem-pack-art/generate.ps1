param([Parameter(Mandatory=$true)][ValidateRange(1,6)][int]$Tier)
$ErrorActionPreference = 'Stop'
$packRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path
$packOutput = Join-Path $packRoot 'output/imagegen/gem-packs-2026-10-24'
[IO.Directory]::CreateDirectory($packOutput) | Out-Null
$packStem = '{0:d2}' -f $Tier
$packRaw = Join-Path $packOutput ($packStem + '-raw.png')
if (Test-Path -LiteralPath $packRaw) { Write-Output "Preserving existing pack $Tier"; exit 0 }

# User-selected local Responses route, reused from the approved chest workflow.
# Keep credentials in memory and never serialize the request/credential to logs.
$packConfig = [IO.File]::ReadAllText((Join-Path $env:USERPROFILE '.codex/config.toml'), [Text.Encoding]::UTF8)
$packProvider = [regex]::Match($packConfig, '(?ms)^\[model_providers\.r9\]\s*(.*?)(?=^\[|\z)').Groups[1].Value
$packToken = [regex]::Match($packProvider, '(?m)^\s*experimental_bearer_token\s*=\s*"([^"]+)"').Groups[1].Value
if ([string]::IsNullOrWhiteSpace($packToken)) { throw 'Local router credential unavailable' }
$packCommon = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'prompts/style.txt'), [Text.Encoding]::UTF8)
$packPrompt = [IO.File]::ReadAllText((Join-Path $PSScriptRoot ('prompts/' + $packStem + '.txt')), [Text.Encoding]::UTF8)
$packReferences = @((Join-Path $packRoot 'game/ui/art/cat_hero.png'), (Join-Path $packRoot 'game/ui/art/icon_chest.png'))
$packFirst = Join-Path $packOutput '01-raw.png'
if ($Tier -gt 1 -and (Test-Path -LiteralPath $packFirst)) { $packReferences += $packFirst }
$packContent = @(@{type='input_text'; text=($packCommon + "`n`n" + $packPrompt)})
foreach ($packReference in $packReferences) {
    $packContent += @{type='input_image'; image_url=('data:image/png;base64,' + [Convert]::ToBase64String([IO.File]::ReadAllBytes($packReference)))}
}
$packBody = @{
    model='cx/gpt-6-astra';
    instructions='Generate exactly one isolated game shop illustration using the image generation tool. Match the supplied flat cartoon art. Follow the requested pack tier, plain backdrop and no-text constraints. Return the image, not an explanation.';
    input=@(@{role='user';content=$packContent});
    tools=@(@{type='image_generation';model='gpt-image-2.5-sunburst';action='generate';size='1024x1024';quality='medium';output_format='png'});
    tool_choice=@{type='image_generation'};stream=$false;store=$false
}
$packMeta = [ordered]@{tier=$Tier;status='generating';transport='User-selected 9Router local /v1/responses';requested_image_model='gpt-image-2.5-sunburst';requested_size='1024x1024';quality='medium';started_utc=[DateTime]::UtcNow.ToString('o');prompt=('prompts/' + $packStem + '.txt');style_prompt='prompts/style.txt';reference_files=@($packReferences | ForEach-Object { $_.Substring($packRoot.Length+1).Replace('\','/') })}
$packMetaPath = Join-Path $packOutput ($packStem + '-generation.json')
$packMeta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packMetaPath -Encoding UTF8
Write-Output "Generating individual gem-pack illustration $Tier..."
try {
    $packJson = $packBody | ConvertTo-Json -Depth 20 -Compress
    $packResponse = Invoke-RestMethod -Uri 'http://127.0.0.1:20129/v1/responses' -Method Post -Headers @{Authorization=('Bearer ' + $packToken)} -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($packJson)) -TimeoutSec 600
    $packResult = @($packResponse.output | Where-Object {$_.type -eq 'image_generation_call' -and $_.result}) | Select-Object -First 1
    if (-not $packResult) { throw 'Router returned no image generation result' }
    [IO.File]::WriteAllBytes($packRaw, [Convert]::FromBase64String($packResult.result))
    $packMeta.status='generated'; $packMeta.finished_utc=[DateTime]::UtcNow.ToString('o'); $packMeta.output=($packStem + '-raw.png')
    $packMeta.response_id=$packResponse.id; $packMeta.response_model=$packResponse.model
    if ($packResult.model) { $packMeta.reported_image_model=$packResult.model }
    if ($packResult.revised_prompt) { $packMeta.revised_prompt=$packResult.revised_prompt }
    $packMeta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packMetaPath -Encoding UTF8
    Write-Output "Generated pack $Tier : $packRaw"
}
catch {
    $packMeta.status='failed'; $packMeta.finished_utc=[DateTime]::UtcNow.ToString('o')
    $packMeta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $packMetaPath -Encoding UTF8
    throw $_.Exception.Message
}
