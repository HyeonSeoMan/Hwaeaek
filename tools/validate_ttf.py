"""TTF 검증: OTS sanitize 통과, fontTools 로드·체크섬, cmap·글리프 수 확인.

사용법: .venv-tools/bin/python tools/validate_ttf.py FONT.ttf [--expect-cmap N]
성공 시 JSON 요약을 출력하고 0으로 종료한다.
"""

import argparse
import json
import sys

import ots
from fontTools.pens.recordingPen import RecordingPen
from fontTools.ttLib import TTFont


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("font")
    parser.add_argument("--expect-cmap", type=int)
    args = parser.parse_args()

    result = ots.sanitize(args.font, "/dev/null", capture_output=True)
    if result.returncode != 0:
        print(result.stderr.decode() or result.stdout.decode(), file=sys.stderr)
        return 1

    font = TTFont(args.font, checkChecksums=2)
    cmap = font.getBestCmap()
    glyph_set = font.getGlyphSet()
    for name in font.getGlyphOrder():
        glyph_set[name].draw(RecordingPen())

    names = {
        f"{rec.nameID}/{rec.langID:#06x}": rec.toUnicode()
        for rec in font["name"].names
    }
    summary = {
        "numGlyphs": font["maxp"].numGlyphs,
        "cmapEntries": len(cmap),
        "fontRevision": round(font["head"].fontRevision, 3),
        "names": names,
    }
    print(json.dumps(summary, ensure_ascii=False))
    if args.expect_cmap is not None and len(cmap) != args.expect_cmap:
        print(f"cmap 항목 {len(cmap)} != 기대값 {args.expect_cmap}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
