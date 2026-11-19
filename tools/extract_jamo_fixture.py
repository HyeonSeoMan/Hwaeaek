"""개발용 기본 글리프 픽스처 추출: TTF의 호환 자모(U+3131~U+3163) 윤곽선 → JSON.

사용법: .venv-tools/bin/python -I tools/extract_jamo_fixture.py FONT.ttf OUT.json
좌표는 UPM 1000, y 위 방향 정수로 정규화한다. 점은 [x, y, onCurve(0/1)].
"""

import json
import sys

from fontTools.ttLib import TTFont


def main() -> int:
    src, out = sys.argv[1], sys.argv[2]
    font = TTFont(src)
    scale = 1000 / font["head"].unitsPerEm
    cmap = font.getBestCmap()
    glyf = font["glyf"]
    hmtx = font["hmtx"]

    glyphs = {}
    for cp in range(0x3131, 0x3164):
        name = cmap.get(cp)
        if name is None:
            continue
        coords, end_pts, flags = glyf[name].getCoordinates(glyf)
        contours, start = [], 0
        for end in end_pts:
            contours.append(
                [
                    [round(x * scale), round(y * scale), flags[i] & 1]
                    for i, (x, y) in enumerate(coords[start : end + 1], start)
                ]
            )
            start = end + 1
        glyphs[chr(cp)] = {
            "advance": round(hmtx[name][0] * scale),
            "contours": contours,
        }

    os2 = font["OS/2"]
    data = {
        "source": font["name"].getDebugName(4),
        "license": "SIL Open Font License 1.1 (see OFL.txt)",
        "upm": 1000,
        "ascender": round(os2.sTypoAscender * scale),
        "descender": round(os2.sTypoDescender * scale),
        "glyphs": glyphs,
    }
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(glyphs)} jamo → {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
