"""Sinh bộ icon launcher Android (5 mật độ) cho ứng dụng Thống Kê 24.

Chạy: python tool/make_android_icon.py
Yêu cầu: Pillow (`pip install pillow`).

Icon: nền gradient xanh đêm + vòng vàng + số "24" — lấy đúng bảng màu của
`lib/src/ui/theme.dart` (bg 0A0F19, gold EFBD5B) để đồng bộ với bản web/Flutter.
"""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BG_TOP = (22, 33, 58)
BG_BOTTOM = (10, 15, 25)
GOLD = (239, 189, 91)
GOLD_BRIGHT = (255, 216, 121)
CORAL = (239, 111, 97)
GREEN = (99, 201, 157)

# mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
    r"C:\Windows\Fonts\calibrib.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]

SUPERSAMPLE = 4


def load_font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    raise SystemExit("Khong tim thay font bold nao trong FONT_CANDIDATES")


def vertical_gradient(width: int, height: int) -> Image.Image:
    grad = Image.new("RGB", (1, height))
    for y in range(height):
        t = y / max(height - 1, 1)
        grad.putpixel(
            (0, y),
            tuple(
                round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)
            ),
        )
    return grad.resize((width, height), Image.BICUBIC)


def rounded_mask(size: int, radius: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=radius, fill=255
    )
    return mask


def dot(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, color) -> None:
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)


def build_icon(target: int) -> Image.Image:
    s = target * SUPERSAMPLE
    canvas = vertical_gradient(s, s).convert("RGBA")

    draw = ImageDraw.Draw(canvas)

    # Quầng sáng vàng mờ phía trên cho icon có chiều sâu.
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        (s * 0.12, -s * 0.32, s * 0.88, s * 0.44), fill=(*GOLD, 34)
    )
    canvas = Image.alpha_composite(canvas, glow)
    draw = ImageDraw.Draw(canvas)

    # Vòng tròn vàng kiểu quả bóng loto.
    ring_w = s * 0.045
    pad = s * 0.155
    draw.ellipse(
        (pad, pad, s - pad, s - pad), outline=GOLD, width=round(ring_w)
    )

    # Bốn chấm nhỏ ở bốn hướng của vòng (điểm nhấn màu).
    r = s * 0.032
    mid = s / 2
    top = pad + ring_w / 2
    dot(draw, mid, top, r, GREEN)
    dot(draw, mid, s - top, r, CORAL)
    dot(draw, top, mid, r, GOLD_BRIGHT)
    dot(draw, s - top, mid, r, GOLD_BRIGHT)

    # Số 24 canh giữa trong vòng.
    font = load_font(round(s * 0.40))
    text = "24"
    box = draw.textbbox((0, 0), text, font=font)
    tw, th = box[2] - box[0], box[3] - box[1]
    draw.text(
        (mid - tw / 2 - box[0], mid - th / 2 - box[1]),
        text,
        font=font,
        fill=GOLD_BRIGHT,
    )

    mask = rounded_mask(s, radius=s * 0.22)
    canvas.putalpha(mask)
    return canvas.resize((target, target), Image.LANCZOS)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    res = root / "android" / "app" / "src" / "main" / "res"
    if not res.is_dir():
        raise SystemExit(f"Khong thay thu muc res: {res}")

    for name, size in DENSITIES.items():
        out = res / f"mipmap-{name}" / "ic_launcher.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        build_icon(size).save(out, "PNG", optimize=True)
        print(f"-> {out.relative_to(root)} ({size}x{size})")

    preview = root / "tool" / "icon" / "ic_launcher_512.png"
    preview.parent.mkdir(parents=True, exist_ok=True)
    build_icon(512).save(preview, "PNG", optimize=True)
    print(f"-> {preview.relative_to(root)} (512x512, ban xem truoc)")


if __name__ == "__main__":
    main()
