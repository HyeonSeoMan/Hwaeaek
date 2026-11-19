"""TTF로 문장을 렌더링해 PNG로 저장한다 (조합 품질 눈으로 확인용).

사용법: .venv-tools/bin/python -I tools/render_sample.py FONT.ttf OUT.png "줄1" ["줄2" ...]
        [--compare OTHER.ttf ...]  같은 문장을 다른 폰트로 아래에 차례로 그린다(여러 번 가능).
"""

import argparse

from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("font")
    parser.add_argument("out")
    parser.add_argument("lines", nargs="+")
    parser.add_argument("--compare", action="append", default=[])
    parser.add_argument("--size", type=int, default=64)
    args = parser.parse_args()

    fonts = [("ours", ImageFont.truetype(args.font, args.size))]
    for path in args.compare:
        fonts.append((path, ImageFont.truetype(path, args.size)))

    line_h = int(args.size * 1.4)
    width = int(max(len(l) for l in args.lines) * args.size * 1.05) + 40
    height = line_h * len(args.lines) * len(fonts) + 20 * len(fonts) + 20
    img = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(img)
    y = 10
    for label, font in fonts:
        for line in args.lines:
            draw.text((20, y), line, font=font, fill="black")
            y += line_h
        y += 20
        draw.line((0, y - 10, width, y - 10), fill="#ccc")
    img.save(args.out)


if __name__ == "__main__":
    main()
