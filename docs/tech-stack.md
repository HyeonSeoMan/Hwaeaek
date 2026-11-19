# 회애액 MVP 1.0 — 기술 스택 조사

> **문서 버전:** v0.2.0 (조사 초안)  
> **작성일:** 2026-11-19 · **최종 수정일:** 2026-11-19  
> **관련 문서:** [MVP 1.0 PRD v0.4.1](../hwaeaek-mvp1-prd-v0.4.1.md) · [구현 명세](spec/mvp1-spec.md)

**상태 표시:** `[확정]` PRD에서 확정됨 · `[추천]` 조사 기반 1순위 · `[후보]` 대안 · `[검증 필요]` G0 PoC에서 확인

이 문서의 `[추천]`·`[후보]`는 기술 선택지이며 PRD 요구사항이 아니다. PRD의 `[확정]`과 충돌하면 PRD가 우선한다.

## 1. 아키텍처 원칙

- **앱:** Flutter / Dart, iOS·Android, 스마트폰·태블릿, 주 대상 iPad + Apple Pencil `[확정]`
- **서버 없음 (온디바이스 전용)** `[확정]`
  - 근거: PRD NFR-04 "시스템은 필기 저장, 조합, TTF 빌드를 모두 기기 안에서 수행한다", NFR-05 "앱은 런타임에 외부 AI/LLM API를 호출하지 않는다".
  - 빈도 데이터는 라이선스가 허용하면 앱 번들에 포함한다(PRD OQ-05).
  - 예외: G0에서 온디바이스 TTF 빌드가 불가능하다고 판명되면 서버 빌드(Python fontTools)를 재검토한다. 이 경우 PRD 변경이 필요하다.
- **단일 조합 엔진** `[확정]`: 앱 안 표시와 TTF 빌드가 같은 Dart 조합 엔진을 쓴다. 자동 생성 글리프는 저장하지 않고 필요할 때 계산한다(메모리 캐시만 허용). 결과 윤곽선은 정수 좌표다. 같은 기기 안에서 결과가 같고, 기기 간 1단위 차이는 허용한다(PRD FR-04, 구현 명세 §6.3). TTF 빌더는 엔진이 만든 윤곽선을 받아 직렬화만 한다.

## 2. 처리 파이프라인

```
① 필기 입력 → ② 획 → 윤곽선 → ③ 윤곽선 정리 ─→ ⑥ 로컬 저장 (기본·커스텀 글리프, 수정 이력, 선택 상태, 메모)
                                                     │
                                                     ▼
                                              ④ 조합 엔진 (단일 구현)
                                               │               │
                                               ▼               ▼
                                    ⑧ 앱 안 표시(메모)   ⑤ TTF 빌드 → ⑦ 내보내기 / iOS 설치
```

| 단계 | 필요 기능 | 선택 | 상태 |
|---|---|---|---|
| ① 필기 입력 | 압력·기울기, 펜/손가락 구분 | Flutter 기본 `Listener` / `PointerEvent` | `[추천]` 지연과 Apple Pencil coalesced·predicted touch 전달 여부 `[검증 필요]` (NFR-02, OQ-08) |
| ② 획 → 윤곽선 | 점 목록 → 굵기 있는 다각형 | [`perfect_freehand`](https://pub.dev/packages/perfect_freehand) | `[추천]` |
| ③ 윤곽선 정리 | 단순화(Douglas–Peucker), 겹침은 OVERLAP_SIMPLE 플래그 | 자체 구현. [`clipper2`](https://pub.dev/packages/clipper2) union은 구현 명세 §17에서 기각(외부 프로그램에서 겹침 문제가 보이면 재검토) | `[추천]` |
| ④ 조합 엔진 | 위치별 자모 변형(벌)과 배치 규칙, 호환 자모 단독 배치 | 자체 구현(Dart). 기본 글리프 원본 획을 자리로 옮겨 펜을 다시 입힌다(G0 규칙 v1) | 핵심 기술, PRD OQ-01 |
| ⑤ TTF 빌드 | glyf, cmap 등 TTF 테이블 작성, 빌드 후 재파싱 검증 | 3장 참고. 재파싱은 자체 최소 리더(구현 명세 §7.3, `fontations` 읽기는 §17에서 기각) | PRD OQ-03 |
| ⑥ 저장 | 프로젝트, 원본 획, 커스텀 수정 이력, 선택 상태, 메모, 폰트 메타데이터. 트랜잭션 저장 | [Drift](https://drift.simonbinder.eu/) (SQLite) + `path_provider` | `[추천]` (PRD OQ-07) |
| ⑥-백업 | 프로젝트 파일 내보내기·가져오기 | 단일 파일(예: zip + JSON + 획 데이터), 스키마 버전 검사 | `[후보]` (PRD FR-09) |
| ⑦ 내보내기 | 기기 저장, OS 공유 | `share_plus`, `file_picker` | `[추천]` |
| ⑦-iOS 폰트 설치 | 앱 안에서 시스템 폰트로 설치 | 플랫폼 채널 + `CTFontManagerRegisterFontURLs`(persistent 범위), `com.apple.developer.user-fonts`(`system-installation`) | `[검증 필요]` Apple 문서는 앱이 소유·번들한 폰트에 쓰라고 안내하므로 사용자 생성 폰트 허용 여부, 재등록 절차, 심사 조건 확인 필요 (PRD OQ-09) |
| ⑧ 앱 안 표시 | 메모 글자만 담은 동적 폰트 | ⑤ TTF 빌더로 작은 폰트를 만들어 `FontLoader`로 등록(빌드마다 새 패밀리 이름), 일반 `TextField`로 표시 | `[추천]` G0 1회차 macOS 동작. iPad 등록 지연 `[검증 필요]` (PRD OQ-11, RISK-07) |
| 빈도 목록 | 음절 사용 빈도 | 국립국어원 빈도 조사 / 모두의 말뭉치. 불가 시 KS X 1001 2,350자 우선 | 라이선스 `[검증 필요]` (PRD OQ-05) |
| 상태 관리 | 화면 상태, 의존성 주입 | Riverpod | `[추천]` |
| 테스트 | 단위, 골든, 폰트 검증 | `flutter_test`, CI에서 테스트 코퍼스 TTF의 fontTools·OTS(OpenType Sanitizer) 검증 | `[추천]` (PRD NFR-01, G2) |

## 3. TTF 빌드 방식 비교

| 방법 | 장점 | 단점 |
|---|---|---|
| **A. [`fontations`](https://pub.dev/packages/fontations)** (Rust `write-fonts`를 감싼 패키지) | `buildFont`에 윤곽선을 넣으면 `.ttf`가 나온다. iOS·Android 지원, MIT 라이선스. 같은 패키지로 재파싱 검증도 가능 | 0.1.2 버전, 사용자가 매우 적어 계속 관리될지 알 수 없음 |
| **B. `flutter_rust_bridge` + [`write-fonts`](https://docs.rs/crate/write-fonts/latest) 직접 연결** | 검증된 Google 라이브러리를 쓰고 우리가 직접 통제 | Rust 개발 환경과 빌드 설정 추가 |
| **C. 순수 Dart TTF 작성기** | 외부 의존성 없음. 필요 테이블이 약 10개(head, hhea, maxp, OS/2, name, cmap, post, glyf, loca, hmtx)라 구현 가능한 규모 | 바이너리 형식 세부 사항을 직접 처리. 쓸 만한 Dart 작성 라이브러리 없음(읽기 전용만 존재) |
| D. 서버 Python fontTools | 가장 성숙한 도구 | 서버 없음 원칙에 어긋남 (1장 예외로만) |

**채택 (G0 1회차):** C안(순수 Dart, `app/lib/font/ttf_writer.dart`). 첫 구현이 OTS·fontTools를 통과했고, 11,172자 빌드가 Mac에서 수백 ms이며, Rust 도구가 필요 없다. A안은 Android 빌드에 `cargo-ndk`가 필요하다. 기기 안 재파싱 검증이 필요하면 A안의 읽기 기능만 쓰는 것을 검토한다. `opentype.js`는 OTF만 출력하는 것으로 보여 제외했다.

## 4. 설계 고려 사항

- **조합 글리프(composite)로 용량 줄이기** `[후보]`: TrueType composite glyph는 이미 있는 글리프를 위치·크기 변환만으로 참조한다. 자동 생성 음절을 "자모 변형 참조 + 변환"으로 출력하면 용량이 크게 줄 수 있다. 단, 자모 간 겹침을 union할 수 없고 스케일하면 획 두께가 변한다. 또 앱 안 표시(평탄한 윤곽선)와 TTF 결과가 달라질 수 있으므로 PRD TS-12(UPM ±1) 기준을 만족하는지 G0에서 확인한다. 만족하지 못하면 단순 글리프로 평탄화한다.
- **획 union:** 필기 획은 겹친다. 겹친 윤곽선도 대부분 프로그램에서 보이지만 일부 렌더러나 인쇄에서 문제가 생길 수 있어 ③에서 합치는 편이 안전하다.
- **원본 분리 저장:** 원본 획(점·압력·시간)과 변환된 윤곽선을 분리해 저장한다. 그래야 다시 편집(PRD FR-02)과 비파괴 내보내기(POL-06)가 가능하다.
- **좌표계:** 화면 좌표(y 아래 방향)를 폰트 단위(PoC는 UPM 1000, y 위 방향)로 바꾸는 변환 규칙을 한곳에 둔다.
- **Windows 호환 메타데이터:** OS/2 `ulCodePageRange1` bit 19(Korean Wansung)와 `ulUnicodeRange` bit 56(Hangul Syllables), `usWinAscent`/`usWinDescent`, name ID 6 규칙(인쇄 가능한 ASCII, 63자 이하, 공백 없음)을 지켜야 Word 한글 글꼴 목록 표시와 잘림 방지가 된다 (PRD OQ-10).

## 5. G0 PoC에서 확인할 항목

1. TTF 빌드(A안)로 만든 11,172자 TTF를 iPad 앱 안 설치, Windows, macOS에서 설치·선택·입력할 수 있는지. Android는 저장·공유만 (PRD OQ-03, OQ-09)
2. 전체 조합 + TTF 빌드 시간, 메모리, 파일 크기. 주 대상 iPad 기준, 보조로 중급 Android (PRD NFR-02, OQ-13)
3. 메모 화면: 한글 IME 조합 중 표시, 커서·선택, 음절 고르기 제스처, 글리프 폭과 커서 위치 일치 (PRD OQ-10, OQ-11)
4. 위치별 자모 변형(벌) 수와 사용자 입력 글자 수의 균형 (PRD OQ-01, G1 차단이지만 G0에서 실험 시작)
5. `clipper2` union 결과의 품질과 속도, composite 출력 시 겹침·두께 문제
6. 펜과 손가락의 필기 지연, Apple Pencil 샘플링 (주 대상 iPad 우선)
7. 같은 이름 폰트를 다시 설치할 때의 OS별 동작
8. 테스트 코퍼스 TTF가 OTS·fontTools 검증을 통과하는지, 기기 안 재파싱 검증이 동작하는지

## 참고 자료

- [fontations (pub.dev)](https://pub.dev/packages/fontations)
- [write-fonts (docs.rs)](https://docs.rs/crate/write-fonts/latest)
- [perfect_freehand (pub.dev)](https://pub.dev/packages/perfect_freehand)
- [clipper2 (pub.dev)](https://pub.dev/packages/clipper2)
- [Flutter local database options (PowerSync)](https://powersync.com/blog/flutter-local-database-options)
- [Unifont Hangul generation](https://unifoundry.com/hangul/hangul-generation.html)
- [Glyphs — Creating a Hangeul font](https://glyphsapp.com/learn/creating-a-hangeul-font)
- [국립국어원 — 우리말에는 어떤 말이 많이 쓰이고 있을까](https://www.korean.go.kr/nkview/nknews/200302/55_3.html)
