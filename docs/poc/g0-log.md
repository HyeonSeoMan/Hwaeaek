# G0 PoC 기록

> **관련 문서:** [PRD v0.3.0](../../hwaeaek-mvp1-prd-v0.3.0.md) · [기술 스택](../tech-stack.md)  
> **환경:** MacBook (Apple Silicon), macOS 27.2.1, Flutter 3.50.0, Xcode 27.2

## 1회차 (2026-11-19) — 처음부터 끝까지 얇은 흐름

### 만든 것 (`app/`)

| 구성 요소 (PRD §5) | 파일 | 비고 |
| --- | --- | --- |
| TTF 빌더 | `lib/font/ttf_writer.dart` | tech-stack C안(순수 Dart). 단순 글리프, cmap format 4, OVERLAP_SIMPLE 플래그, OS/2 v4(Korean Wansung, Hangul 비트), name(en-US + ko-KR) |
| 조합 엔진 | `lib/hangul/composer.dart` | 규칙 v0: 자모 1벌 + 모음 모양(세로·가로·섞임) × 받침 유무 6가지 배치. 겹자음은 구성 자음으로 대체 |
| 필기 입력 | `lib/ink/ink.dart`, `lib/app/glyph_editor_screen.dart` | `perfect_freehand`, 스타일러스 필압, 획 시계 방향 정규화 |
| 메모 렌더러 | `lib/app/font_session.dart`, `lib/app/memo_screen.dart` | 메모에 쓰인 글자만 담은 폰트를 빌드마다 새 패밀리 이름으로 `FontLoader` 등록. 문맥 메뉴 "다시 그리기" |
| 검증 도구 | `tools/validate_ttf.py`, `tools/render_sample.py` | OTS + fontTools, PIL 렌더링 |
| 개발용 기본 글리프 | `app/assets/dev/nanum_pen_jamo.json` | 나눔손글씨 펜 자모 51자 윤곽선(OFL). 손글씨 샘플 대용 |

### 측정 (macOS, `flutter test`/디버그 빌드)

| 항목 | 결과 | 관련 |
| --- | --- | --- |
| 사각형 글리프 11,172자 TTF 빌드 | 61ms, 393KB, OTS·fontTools 통과 | OQ-03 |
| 픽스처 11,172자 + 자모 51자 조합 | 120~130ms | NFR-02 |
| 위 전체 조합 + TTF 빌드 | 306~325ms, 6.57MB, OTS·fontTools 통과 | OQ-03, NFR-02 |
| 메모용 동적 폰트 (11자) | 빌드 8ms, `FontLoader` 등록 75ms (디버그) | OQ-11 |

### 발견

1. **C안(순수 Dart TTF)은 PoC 범위에서 충분하다.** 첫 실행에 OTS·fontTools를 통과했고 Rust 의존성이 없다. `fontations`(A안)는 Android 빌드에 `cargo-ndk`가 필요하다.
2. **동적 폰트 등록 방식으로 메모가 즉시 손글씨로 표시된다.** IME·커서·선택은 Flutter 기본 동작을 그대로 쓴다. 등록 지연(디버그 75ms)이 새 글자 입력 때마다 생기므로, 실기기 릴리스 빌드에서 측정이 필요하다. → PRD §8에서 기각한 "편집마다 TTF 등록"은 "메모 글자만 담은 작은 폰트 + 고유 패밀리 이름"으로 바꾸면 성립한다. RISK-07 대체안과 주 방식의 순서를 바꾸는 것을 검토한다.
3. **규칙 v0 품질 문제:** 윤곽선을 통째로 축소하므로 받침 있는 음절의 획이 가늘고, 자모 bbox에 맞추므로 크기가 들쭉날쭉하다(`build/poc/sample.png`).
4. **설계 단서 (OQ-01):** 사용자 입력은 획(중심선 + 필압)이므로, 윤곽선이 아니라 **획의 점을 자리로 옮긴 뒤 펜 굵기를 다시 입히면** 받침이 있어도 획 굵기가 일정하다. 기본 글리프를 윤곽선이 아닌 원본 획으로 조합하는 방식을 다음 회차에서 실험한다.

### 남은 확인 (사람이 해야 함)

- [x] macOS에서 메모 입력과 다시 그리기 흐름 동작 확인 (사용자, 2026-11-19). 조합 중 깜빡임·커서 복귀 세부는 미기록
- [ ] 문맥 메뉴 → 다시 그리기 → 저장 → 메모 복귀·반영 → 실행 취소
- [ ] 내보낸 TTF를 서체 관리자로 설치해 Pages·TextEdit에서 사용 (TS-M2)
- [ ] iPad 시뮬레이터·실기기에서 같은 흐름, Apple Pencil 필압
