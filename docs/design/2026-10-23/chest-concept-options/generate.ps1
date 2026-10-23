param(
  [Parameter(Mandatory=$true)][ValidateSet('A','B','C','D')][string]$Family,
  [ValidateRange(1,9)][int]$Revision=1,
  [switch]$GoldOnly
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..\..')).Path
$outDir = Join-Path $root 'output\imagegen\chest-options-2026-10-23'
[IO.Directory]::CreateDirectory($outDir) | Out-Null
$stem = $Family + $(if ($Revision -gt 1) { '-v'+$Revision } else { '' })
$rawPath = Join-Path $outDir ($stem+'-raw.png')
if (Test-Path -LiteralPath $rawPath) { Write-Output "Preserving existing raw $Family"; exit 0 }

# Reuse the established local router credential in memory only. Never log it.
$cfg = [IO.File]::ReadAllText((Join-Path $env:USERPROFILE '.codex\config.toml'),[Text.Encoding]::UTF8)
$section = [regex]::Match($cfg,'(?ms)^\[model_providers\.r9\]\s*(.*?)(?=^\[|\z)').Groups[1].Value
$token = [regex]::Match($section,'(?m)^\s*experimental_bearer_token\s*=\s*"([^"]+)"').Groups[1].Value
if ([string]::IsNullOrWhiteSpace($token)) { throw 'Local router credential unavailable' }
$promptFile = Join-Path $PSScriptRoot ('prompts\'+$stem+'.txt')
$prompt = [IO.File]::ReadAllText($promptFile,[Text.Encoding]::UTF8)
$references = @(
  (Join-Path $root 'game\ui\art\cat_hero.png'),
  (Join-Path $root 'docs\design\2026-10-22\chest-premium\round-2.png')
)
if ($Revision -gt 1) { $references += Join-Path $outDir ($Family+'-raw.png') }
if ($GoldOnly) {
  $references = @(
    (Join-Path $root 'docs\design\2026-10-23\chest-concept-options\png\B3.png'),
    (Join-Path $root 'game\ui\art\cat_hero.png')
  )
}
$requestedSize = if ($GoldOnly) { '1024x1024' } else { '1536x1024' }
$instruction = if ($GoldOnly) {
  'Create one upgraded gold chest image using the image generation tool. Preserve the approved chest silhouette and add restrained crafted gold detail and mild cartoon metal polish as instructed. Exactly one closed chest, no text, no extra objects. Return the generated image.'
} else {
  'Create the requested chest concept sheet using the image generation tool. Follow the flat game-art reference, exactly three closed objects, tier progression and no-text constraints. Return the generated image, not a description.'
}
$content = @(@{type='input_text';text=[string]$prompt})
foreach ($file in $references) {
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($file))
  $content += @{type='input_image';image_url=('data:image/png;base64,'+$b64)}
}
$body = @{
  model='cx/gpt-6-astra';
  instructions=$instruction;
  input=@(@{role='user';content=$content});
  tools=@(@{type='image_generation';model='gpt-image-2.5-sunburst';action='generate';size=$requestedSize;quality='medium';output_format='png'});
  tool_choice=@{type='image_generation'};stream=$false;store=$false
}
$json = $body | ConvertTo-Json -Depth 20 -Compress
$metadata = [ordered]@{
  review_only=$true;production_changed=$false;family=$Family;revision=$Revision;
  requested_image_model='gpt-image-2.5-sunburst';orchestrator='cx/gpt-6-astra';
  transport='9Router local /v1/responses';quality='medium';requested_size=$requestedSize;
  user_authorized_custom_route=$true;
  started_utc=[DateTime]::UtcNow.ToString('o');prompt=('prompts/'+$stem+'.txt');
  reference_files=@($references | ForEach-Object { $_.Substring($root.Length+1).Replace('\','/') });
  status='generating'
}
$metadataPath = Join-Path $outDir ($stem+'-generation.json')
$metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metadataPath -Encoding UTF8
Write-Output "Generating chest family $Family via local Responses image tool..."
try {
  $response = Invoke-RestMethod -Uri 'http://127.0.0.1:20129/v1/responses' -Method Post -Headers @{Authorization=('Bearer '+$token)} -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 600
  $result = @($response.output | Where-Object {$_.type -eq 'image_generation_call' -and $_.result}) | Select-Object -First 1
  if (-not $result) { throw 'Router returned no image generation result' }
  [IO.File]::WriteAllBytes($rawPath,[Convert]::FromBase64String($result.result))
  $metadata.status='generated';$metadata.finished_utc=[DateTime]::UtcNow.ToString('o')
  $metadata.output=($stem+'-raw.png');$metadata.response_id=$response.id
  $metadata.response_model=$response.model;$metadata.image_call_id=$result.id
  if ($result.model) { $metadata.reported_image_model=$result.model }
  if ($result.revised_prompt) { $metadata.revised_prompt=$result.revised_prompt }
  $metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metadataPath -Encoding UTF8
  Write-Output "Generated $Family : $rawPath"
} catch {
  $metadata.status='failed';$metadata.finished_utc=[DateTime]::UtcNow.ToString('o')
  $metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metadataPath -Encoding UTF8
  # Only the exception message is emitted, never the credential or request body.
  throw $_.Exception.Message
}
