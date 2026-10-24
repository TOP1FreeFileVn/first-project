"""Package native isolated-demo captures and recordings into a local review gallery."""
import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STAGES = [
    ("arrival", "01 · Thùng đến"),
    ("boxes", "02 · Đáp xuống"),
    ("paw", "03 · Bàn tay hé nắp"),
    ("light", "04 · Ánh sáng"),
    ("reveal", "05 · Đồng đội xuất hiện"),
    ("results", "06 · Kết quả"),
]


def resolve_artifact(value: str, base: Path) -> Path:
    if value.startswith("res://"):
        return ROOT / value.removeprefix("res://")
    path = Path(value)
    return path if path.is_absolute() else base / path


def font(size: int) -> ImageFont.ImageFont:
    for candidate in [Path("C:/Windows/Fonts/segoeui.ttf"), Path("C:/Windows/Fonts/arial.ttf")]:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def load_report(review: Path, count: int, size: str) -> tuple[dict, dict[str, Path]]:
    path = review / f"manifest-{count}-{size}.json"
    report = json.loads(path.read_text(encoding="utf-8-sig"))
    if report.get("failures", 0):
        raise ValueError(f"Native review reports failures: {path}")
    captures = {}
    for capture in report["captures"]:
        stage = capture.get("stage", capture.get("label", ""))
        captures[stage] = resolve_artifact(capture["file"], review)
    missing = [stage for stage, _ in STAGES if stage not in captures]
    if missing:
        raise ValueError(f"Missing storyboard stages in {path.name}: {missing}")
    return report, captures


def build_animation(report: dict, review: Path, destination: Path,
                    interval: tuple[float, float] | None = None) -> dict | None:
    recording = report.get("recording")
    if not recording:
        return None
    directory = resolve_artifact(recording["directory"], review)
    fps = float(recording.get("fps", 24))
    frame_start, frame_end = 0, int(recording["frames"])
    if interval is not None:
        frame_start = max(0, math.floor(interval[0] * fps))
        frame_end = min(frame_end, math.ceil(interval[1] * fps))
    frames = []
    for index in range(frame_start, frame_end):
        with Image.open(directory / f"frame-{index:04d}.png") as source:
            frames.append(source.convert("RGB").resize((350, 622), Image.Resampling.LANCZOS))
    if not frames:
        return None
    samples = frames[::max(1, len(frames) // 12)]
    palette_board = Image.new("RGB", (350 * len(samples), 622))
    for index, frame in enumerate(samples):
        palette_board.paste(frame, (350 * index, 0))
    palette = palette_board.quantize(colors=256)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    # GIF delay uses centiseconds. Distribute the rounding across frames so the
    # whole clip keeps its native timing at 14, 24 or another recorded fps.
    durations = [round((index + 1) * 100 / fps) * 10 - round(index * 100 / fps) * 10
                 for index in range(len(indexed))]
    indexed[0].save(destination, save_all=True, append_images=indexed[1:],
                    duration=durations, loop=0, optimize=True, disposal=2)
    return {"file": destination.name, "frames": len(frames), "fps": fps,
            "seconds": round(len(frames) / fps, 3),
            "source_frames": [frame_start, frame_end],
            "source_seconds": [round(frame_start / fps, 3), round(frame_end / fps, 3)]}


def build_storyboard(captures: dict[str, Path], destination: Path) -> None:
    cell_width, image_height, caption_height, gap = 225, 400, 36, 14
    board = Image.new("RGB", (3 * cell_width + 4 * gap,
                               2 * (image_height + caption_height) + 3 * gap), "#e9dfcc")
    draw = ImageDraw.Draw(board)
    for index, (stage, title) in enumerate(STAGES):
        x = gap + (index % 3) * (cell_width + gap)
        y = gap + (index // 3) * (image_height + caption_height + gap)
        draw.text((x + 4, y + 8), title, fill="#583f21", font=font(16))
        with Image.open(captures[stage]) as source:
            board.paste(source.convert("RGB").resize((cell_width, image_height), Image.Resampling.LANCZOS),
                        (x, y + caption_height))
    board.save(destination)


def build_paw_comparison(review: Path, destination: Path, *, before: Path | None = None,
                         after: Path | None = None) -> dict | None:
    before = before or OUT / "before-continuous-paw/gold-open.png"
    after = after or review / "gold-open.png"
    if not before.exists() or not after.exists():
        return None
    crop = (110, 280, 340, 520)
    scale = 1.5
    image_size = (round((crop[2] - crop[0]) * scale), round((crop[3] - crop[1]) * scale))
    gap, caption_height = 18, 44
    board = Image.new("RGB", (2 * image_size[0] + 3 * gap,
                               image_size[1] + caption_height + 2 * gap), "#eee3cf")
    draw = ImageDraw.Draw(board)
    for index, (label, path) in enumerate([("Trước", before), ("Sau", after)]):
        x = gap + index * (image_size[0] + gap)
        draw.text((x + 5, gap + 5), label, fill="#583f21", font=font(24))
        with Image.open(path) as source:
            if source.size != (450, 800):
                raise ValueError(f"Paw comparison requires a 450x800 native source: {path}")
            image = source.convert("RGB").crop(crop).resize(image_size, Image.Resampling.LANCZOS)
            board.paste(image, (x, gap + caption_height))
    board.save(destination)
    def source_name(path: Path) -> str:
        return path.relative_to(OUT).as_posix() if path.is_relative_to(OUT) else "res://" + path.relative_to(ROOT).as_posix()
    return {"file": destination.name, "before": source_name(before),
            "after": source_name(after), "native_crop": list(crop), "scale": scale}


def write_gallery(cases: list[dict], output: Path) -> None:
    data = json.dumps(cases, ensure_ascii=False).replace("</", "<\\/")
    template = '''<!doctype html>
<html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Demo triệu hồi bằng thùng carton</title>
<style>
:root{color-scheme:light;font:16px/1.55 "Segoe UI",sans-serif;color:#493924;background:#eee6d7}*{box-sizing:border-box}
body{margin:0}main{max-width:1120px;margin:auto;padding:30px 24px 50px}h1{font-size:29px;line-height:1.2;margin:0 0 12px}
p{max-width:760px}button,a{font:inherit}button{background:#fff5df;color:#583f21;border:2px solid #886a43;border-radius:12px;padding:9px 17px;cursor:pointer}
button[aria-pressed=true]{background:#c6b4d8;box-shadow:0 3px 0 #886a43}nav{display:flex;gap:10px;flex-wrap:wrap;margin:22px 0}.layout{display:grid;grid-template-columns:minmax(280px,390px) 1fr;gap:28px}
.panel{background:#f9f3e7;border:2px solid #baa17e;border-radius:20px;padding:20px}.phone{display:block;width:100%;max-width:350px;height:auto;border-radius:13px;margin:14px auto;background:#ded3bd}
.stage{display:block;width:100%;max-width:450px;height:auto;margin:14px auto;border-radius:12px}input{width:100%;accent-color:#8c71a7}.stage-buttons{display:flex;gap:7px;flex-wrap:wrap}.stage-buttons button{font-size:13px;padding:5px 9px}
small{color:#79664d}a{color:#725089}code{overflow-wrap:anywhere}.links{display:flex;gap:18px;flex-wrap:wrap;margin-top:14px}details{margin-top:26px}pre{white-space:pre-wrap;background:#fff6e5;padding:16px;border-radius:12px}
@media(max-width:760px){.layout{grid-template-columns:1fr}main{padding:23px 14px}h1{font-size:25px}}
</style>
<main><h1>Triệu hồi bằng thùng carton</h1>
<p>Demo riêng để xem nhịp thùng đáp xuống, bàn tay hé nắp, ánh sáng và đồng đội xuất hiện. Chọn lượt x1 hoặc x10, rồi kéo từng mốc để xem bố cục.</p>
<p>Để thử nút x1, x10, xem lại và mở tất cả trong cửa sổ Godot có âm thanh, chạy từ thư mục dự án:</p>
<pre>powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-25/carton-summon-demo/run.ps1 -Interactive -Count 10</pre>
<nav id="cases"></nav><div class="layout">
<section class="panel"><strong id="animation-title"></strong><img class="phone" id="animation" alt="Hoạt ảnh demo triệu hồi">
<button id="replay">Phát lại</button><p><small id="animation-meta"></small></p></section>
<section class="panel"><strong id="stage-title"></strong><div class="stage-buttons" id="stage-buttons"></div>
<input id="stage-slider" type="range" min="0" max="5" step="1" value="0" aria-label="Chọn mốc hoạt ảnh">
<img class="stage" id="stage-image" alt="Ảnh gốc của mốc hoạt ảnh"><div class="links"><a id="native-link" target="_blank">Mở ảnh gốc</a><a id="board-link" target="_blank">Xem cả 6 mốc</a></div>
</section></div>
<section class="panel" id="gold-panel" hidden style="margin-top:24px"><strong>Khoảnh khắc Huyền thoại</strong>
<p id="gold-meta"></p><figure id="paw-wrist-comparison" hidden style="margin:20px 0"><a id="paw-wrist-comparison-link" target="_blank"><img id="paw-wrist-comparison-image" alt="Cổ tay lộ rõ trước và sau nối liền lòng bàn chân với cẳng tay" style="display:block;width:100%;max-width:744px;height:auto;border-radius:12px"></a><figcaption><small>Khung x1 ở 4,5 giây: vùng cổ tay lộ rõ, cùng tỷ lệ trước/sau.</small></figcaption></figure><img class="phone" id="gold-animation" alt="Bàn chân nối liền cẳng tay, nhịp ánh sáng vàng và mở hộp">
<div class="links"><a id="gold-anticipation" target="_blank">Giữ ánh sáng vàng</a><a id="gold-open" target="_blank">Hộp mở, mèo chưa lên</a><a href="before-refinement/x10-preview.gif" target="_blank">So với bản trước</a></div>
<figure id="paw-comparison" hidden style="margin:24px 0 0"><a id="paw-comparison-link" target="_blank"><img id="paw-comparison-image" alt="So sánh bàn chân trước và sau nối liền với cẳng tay, cùng vùng cắt" style="display:block;width:100%;max-width:744px;height:auto;border-radius:12px"></a><figcaption><small>Cùng vùng cắt từ ảnh native 450 × 800, phóng 1,5 lần.</small></figcaption></figure></section>
<details><summary>Tạo lại ảnh và GIF</summary><p>Chạy từ thư mục dự án:</p>
<pre>powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-25/carton-summon-demo/run.ps1 -Record
python docs/design/2026-10-25/carton-summon-demo/build_preview.py</pre>
<p>Bản chạy xem thử dùng profile riêng trong workspace. Ảnh và manifest gốc nằm trong <code>review/</code>.</p></details>
</main><script>
const cases=__CASES__;let selected=0;const byId=id=>document.getElementById(id);
function stage(index){const item=cases[selected],shot=item.stages[index];byId('stage-slider').value=index;byId('stage-title').textContent=shot.title;byId('stage-image').src=shot.file;byId('native-link').href=shot.file;byId('board-link').href=item.storyboard;document.querySelectorAll('#stage-buttons button').forEach((b,i)=>b.setAttribute('aria-pressed',i===index));}
function choose(index){selected=index;const item=cases[index];byId('animation-title').textContent=item.title;byId('animation').src=item.animation||item.stages[0].file;byId('animation-meta').textContent=item.animation_meta||'Ảnh mốc từ bản chạy native';byId('stage-buttons').replaceChildren(...item.stages.map((s,i)=>{let b=document.createElement('button');b.textContent=i+1;b.title=s.title;b.onclick=()=>stage(i);return b;}));document.querySelectorAll('#cases button').forEach((b,i)=>b.setAttribute('aria-pressed',i===index));byId('gold-panel').hidden=!item.gold;if(item.gold){byId('gold-animation').src=item.gold.file;byId('gold-meta').textContent=item.gold.caption;for(const key of ['gold-anticipation','gold-open']){const link=byId(key);link.hidden=!item.gold[key];if(item.gold[key])link.href=item.gold[key];}byId('paw-comparison').hidden=!item.gold.comparison;if(item.gold.comparison){byId('paw-comparison-link').href=item.gold.comparison;byId('paw-comparison-image').src=item.gold.comparison;}byId('paw-wrist-comparison').hidden=!item.gold.wrist_comparison;if(item.gold.wrist_comparison){byId('paw-wrist-comparison-link').href=item.gold.wrist_comparison;byId('paw-wrist-comparison-image').src=item.gold.wrist_comparison;}}stage(0);}
cases.forEach((item,i)=>{let b=document.createElement('button');b.textContent=item.title;b.onclick=()=>choose(i);byId('cases').append(b);});byId('stage-slider').oninput=e=>stage(Number(e.target.value));byId('replay').onclick=()=>{let image=byId('animation'),source=cases[selected].animation||cases[selected].stages[0].file;image.src='';requestAnimationFrame(()=>image.src=source+'?replay='+Date.now());};choose(0);
</script></html>'''
    (output / "preview.html").write_text(template.replace("__CASES__", data), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review-dir", type=Path, default=OUT / "review")
    args = parser.parse_args()
    review = args.review_dir.resolve()
    cases = []
    packaged = []
    gold_package = None
    wrist_comparison = None
    for count, size in [(1, "450x800"), (10, "450x800"), (10, "360x640")]:
        report, captures = load_report(review, count, size)
        if count == 1 and size == "450x800" and report.get("recording"):
            recording = report["recording"]
            frame_index = round(4.5 * float(recording.get("fps", 24)))
            after_frame = resolve_artifact(recording["directory"], review) / f"frame-{frame_index:04d}.png"
            wrist_comparison = build_paw_comparison(
                review, OUT / "paw-continuous-wrist-comparison.png",
                before=OUT / "before-continuous-paw/wrist-open.png", after=after_frame)
            if wrist_comparison:
                wrist_comparison.update({"sample_seconds": 4.5, "frame_index": frame_index})
        suffix = f"x{count}" if size == "450x800" else f"x{count}-{size}"
        animation = build_animation(report, review, OUT / f"{suffix}-preview.gif")
        storyboard = OUT / f"{suffix}-storyboard.png"
        build_storyboard(captures, storyboard)
        title = f"x{count} · {size.replace('x', ' × ')}"
        case = {"title": title, "animation": animation["file"] if animation else None,
                "animation_meta": f"{animation['frames']} khung hình · {animation['fps']:g} fps · {animation['seconds']:g} giây" if animation else "",
                "storyboard": storyboard.name,
                "stages": [{"title": title, "file": path.relative_to(OUT).as_posix()}
                           for stage, title in STAGES for path in [captures[stage]]]}
        gold_beat = report.get("gold-beat")
        if count == 10 and size == "450x800" and gold_beat:
            gold_clip = build_animation(report, review, OUT / "paw-continuous-preview.gif",
                                        (float(gold_beat["start"]) - 0.35,
                                         float(gold_beat["end"]) + 0.35))
            if gold_clip:
                gap = float(gold_beat["cat_visible_at"]) - float(gold_beat["full_light_at"])
                gold_package = {"animation": gold_clip, "beat": gold_beat,
                                "full_light_before_cat_seconds": round(gap, 3),
                                "context_seconds": 0.35}
                case["gold"] = {"file": gold_clip["file"],
                                "caption": f"Từ lúc ánh sáng vàng lên đầy tới khi thấy mèo: {gap:.2f} giây. Clip có thêm 0,35 giây ngữ cảnh mỗi phía."}
                for stage in ["gold-anticipation", "gold-open"]:
                    path = captures.get(stage, review / f"{stage}.png")
                    if path.exists():
                        case["gold"][stage] = path.relative_to(OUT).as_posix()
        cases.append(case)
        packaged.append({"count": count, "window": report.get("window"), "animation": animation,
                         "storyboard": storyboard.name, "native_manifest": f"review/manifest-{count}-{size}.json"})
    paw_comparison = build_paw_comparison(review, OUT / "paw-continuous-comparison.png")
    if paw_comparison:
        for case in cases:
            if "gold" in case:
                case["gold"]["comparison"] = paw_comparison["file"]
                if wrist_comparison:
                    case["gold"]["wrist_comparison"] = wrist_comparison["file"]
    write_gallery(cases, OUT)
    package = {"cases": packaged}
    if gold_package:
        package["gold"] = gold_package
    if paw_comparison:
        package["paw_comparison"] = paw_comparison
    if wrist_comparison:
        package["wrist_comparison"] = wrist_comparison
    (OUT / "package.json").write_text(json.dumps(package, ensure_ascii=False, indent=2), encoding="utf-8")
    print("CARTON_SUMMON_PREVIEW_COMPLETE cases=3 gallery=preview.html")


if __name__ == "__main__":
    main()
