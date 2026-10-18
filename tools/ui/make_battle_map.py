"""Original, flat meadow art for the battle backdrop.

Run: python -I tools/ui/make_battle_map.py
The cat-style environment has solid fills, rounded brown outlines, and a quiet
centre for the battle. This generator is separate from the shared UI generator.
Castle/wall art is generated separately.
"""

from pathlib import Path


OUT = Path(__file__).resolve().parents[2] / "game" / "ui" / "skin"
LINE = "#583f21"


def svg(width: int, height: int, body: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n{body}\n</svg>\n'
    )


def outline(width: float = 5) -> str:
    return (
        f'stroke="{LINE}" stroke-width="{width}" '
        'stroke-linejoin="round" stroke-linecap="round"'
    )


def field() -> str:
    # Broad ground shapes have no outlines; characters and scenery carry them.
    ground = '''
<path fill="#c5d5a2" d="M0 0H720V740H0Z"/>
<path fill="#b5cb92" d="M0 0H100Q64 66 83 136T62 284Q91 374 70 454T71 615L58 740H0Z"/>
<path fill="#b5cb92" d="M720 0H634Q665 91 649 173T663 334Q636 424 655 511T653 658L666 740H720Z"/>
<path fill="#d6ddb4" d="M282 0H439Q406 85 428 158T415 294Q393 365 410 433T395 570Q376 635 406 740H272Q294 639 291 577T306 438Q321 369 308 302T322 162Q335 86 282 0Z"/>
<path fill="#c2a57d" d="M0 700H720V1280H0Z"/>
<path fill="#d5bd92" d="M0 744Q171 722 360 739T720 744V1280H0Z"/>
<rect x="34" y="736" width="652" height="440" rx="26" fill="#e8d5ad" stroke="#8d714d" stroke-width="4"/>
<path d="M55 1192H665" fill="none" stroke="#b99d71" stroke-width="3" stroke-linecap="round"/>
'''
    # Muted grass marks sit outside the middle lane.
    for x, y, scale in [
        (117, 166, 1), (552, 206, .9), (184, 301, .8), (592, 357, 1),
        (124, 451, .9), (530, 509, .8), (188, 598, 1), (594, 607, .8),
        (233, 105, .7), (488, 107, .8), (468, 384, .7), (243, 493, .7),
    ]:
        ground += (
            f'<path d="M-7 0L-9-6M0 0V-10M7 0L10-7" '
            f'transform="translate({x} {y}) scale({scale})" fill="none" '
            'stroke="#a9c18b" stroke-width="3" stroke-linecap="round"/>\n'
        )
    for x, y, rx, ry in [(84, 348, 6, 3), (631, 246, 5, 3), (90, 570, 6, 4), (628, 552, 7, 4)]:
        ground += f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#b5bf92"/>\n'
    return svg(720, 1280, ground)


def round_tree() -> str:
    return svg(128, 176, f'''
<path d="M52 104Q49 128 48 158Q63 168 80 158L76 103Z" fill="#b79369" {outline()}/>
<path d="M63 146L65 119M65 133L75 124" fill="none" {outline(4)}/>
<path d="M18 108C2 98 4 77 18 67C3 49 20 23 42 26C47 3 81 2 91 24C115 19 132 43 118 63C138 82 122 111 103 112Q61 129 18 108Z" fill="#9bbb7b" {outline(5.5)}/>
<path d="M21 80Q29 85 36 80M88 92Q98 96 106 89" fill="none" {outline(3.5)}/>
''')


def tall_tree() -> str:
    return svg(128, 190, f'''
<path d="M51 116L48 174Q63 183 80 174L76 114Z" fill="#b79369" {outline()}/>
<path d="M64 160V139" fill="none" {outline(4)}/>
<path d="M62 7C47 7 38 23 38 37C21 38 17 55 25 68C4 77 3 96 18 108C6 128 22 148 42 148Q63 158 85 148C110 151 126 132 112 111C131 97 123 77 106 70C117 54 106 35 90 36C89 19 78 7 62 7Z" fill="#91b17a" {outline(5.5)}/>
<path d="M26 108Q34 113 42 109M82 71Q90 75 98 71" fill="none" {outline(3.5)}/>
''')


def bush() -> str:
    return svg(88, 56, f'''
<path d="M12 48C1 42 4 25 16 22C17 6 36 3 45 15C56 1 76 11 74 26C90 30 85 49 74 50Q41 57 12 48Z" fill="#a5bd7b" {outline(4.5)}/>
<path d="M28 44L26 35M49 45L53 36M65 45L69 40" fill="none" {outline(3)}/>
''')


def rock() -> str:
    return svg(64, 48, f'''
<path d="M5 31L16 12Q30 4 42 10L57 25L58 36Q36 47 11 39Z" fill="#d1c7ac" {outline(4)}/>
<path d="M16 12L26 26L43 27L57 25M26 26L23 40" fill="none" {outline(2.5)}/>
''')


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    assets = {
        "field": field(),
        "tree": round_tree(),
        "pine": tall_tree(),
        "bush": bush(),
        "rock": rock(),
    }
    for name, art in assets.items():
        path = OUT / f"battle_map_{name}.svg"
        path.write_text(art, encoding="utf-8")
        print(path.relative_to(OUT.parents[2]))


if __name__ == "__main__":
    main()
