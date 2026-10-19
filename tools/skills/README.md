# Project skills

`casual-weapon-design/` là bản nguồn của skill thiết kế vũ khí và trang bị casual cho game. Commit cả thư mục để giữ hướng dẫn, các nghiên cứu stroke, prompt và hình mẫu đã được duyệt cùng nhau.

Để cài lại cho Codex trên Windows, chạy từ thư mục dự án:

```powershell
$projectSkillSource = Join-Path (Get-Location) 'tools/skills/casual-weapon-design'
$projectSkillDestination = Join-Path $env:USERPROFILE '.codex/skills'
New-Item -ItemType Directory -Path $projectSkillDestination -Force | Out-Null
Copy-Item -LiteralPath $projectSkillSource -Destination $projectSkillDestination -Recurse -Force
```

Điểm vào là `casual-weapon-design/SKILL.md`. Các skill giao diện và hình mèo hiện có của dự án nằm trong `.claude/skills/`.
