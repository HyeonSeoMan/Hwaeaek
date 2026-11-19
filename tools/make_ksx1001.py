"""KS X 1001 완성형 한글 2,350자 목록 생성 (Spec §14).

EUC-KR 표의 한글 영역(0xB0A1~0xC8FE)을 행·열 순서로 디코딩한다.
사용법: python3 -I tools/make_ksx1001.py app/assets/frequency/ksx1001.txt
"""

import sys


def main() -> None:
    out = []
    for lead in range(0xB0, 0xC9):
        for trail in range(0xA1, 0xFF):
            ch = bytes([lead, trail]).decode("euc_kr")
            assert 0xAC00 <= ord(ch) <= 0xD7A3, hex(ord(ch))
            out.append(ch)
    assert len(out) == 2350 and len(set(out)) == 2350
    with open(sys.argv[1], "w", encoding="utf-8") as f:
        f.write("# source=KS X 1001 완성형 (EUC-KR 0xB0A1-0xC8FE) version=1\n")
        f.write("\n".join(out) + "\n")
    print(f"{len(out)} syllables -> {sys.argv[1]}")


if __name__ == "__main__":
    main()
