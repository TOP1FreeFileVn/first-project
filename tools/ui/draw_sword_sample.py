"""Draw a standalone sword study using the project's flat icon renderer.

Run from the project root: python tools/ui/draw_sword_sample.py
This study writes only to docs/art_samples; it does not replace a game icon.
"""
from pathlib import Path

from make_svgs import Icon, circle_d, rr_d, wraps


def sword():
    icon = Icon()
    angle = 43

    def shape(path, color):
        icon.shape(path, color, color, 64, rot=angle)

    # Broad blade with a softened point and an uninterrupted readable silhouette.
    shape(
        "M64 7 Q65.5 7 67 9 L78 22 Q80 24 80 28 "
        "L80 80 L48 80 L48 28 Q48 24 50 22 L61 9 Q62.5 7 64 7 Z",
        "#e2e9e9",
    )
    # The fuller is an engraved feature, not reflected light.
    icon.raw(
        '<path d="M64 27 L64 63" fill="none" stroke="#a6b7b8" '
        'stroke-width="3.6" stroke-linecap="round"/>',
        angle,
    )

    # Grip behind the guard; three broad leather bindings stay legible at 64 px.
    shape(rr_d(55, 83, 18, 28, 5), "#b8774f")
    wraps(icon, 64, 87, 106, 18, "#72472e", angle, step=7)

    # One continuous guard avoids outlines piling up at the ends.
    shape(
        "M42 70 Q45 69 48 73 L52 76 L76 76 L80 73 "
        "Q83 69 86 70 Q91 72 90 78 L88 88 Q87 94 81 94 "
        "L75 91 L53 91 L47 94 Q41 94 40 88 L38 78 Q37 72 42 70 Z",
        "#edba59",
    )
    icon.raw('<path d="M64 78 L69 83.5 L64 89 L59 83.5 Z" fill="#c85c4c"/>', angle)

    # Rounded gold pommel with a single inset rivet.
    shape(circle_d(64, 115, 9), "#edba59")
    icon.raw(
        '<circle cx="64" cy="115" r="2.3" fill="#a16d38"/>',
        angle,
    )
    return icon


def main():
    output = Path(__file__).resolve().parents[2] / "docs" / "art_samples"
    output.mkdir(parents=True, exist_ok=True)
    icon = sword()
    for size in (64, 128, 512):
        suffix = "" if size == 512 else f"_{size}"
        target = output / f"sword_sample_v1{suffix}.svg"
        target.write_text(icon.flat_svg(size), encoding="utf-8")
        print(target)


if __name__ == "__main__":
    main()
