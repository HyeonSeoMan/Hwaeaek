# 회애액 MVP 1.0 — 기술 스택 조사

> **문서 버전:** v0.1.0 (조사 초안)  
> **작성일:** 2026-11-19  
> **관련 문서:** [MVP 1.0 PRD](../hwaeaek-mvp1-prd-v0.1.0.md)

**상태 표시:** `[확정]` 합의됨 · `[추천]` 조사 기반 1순위 · `[후보]` 대안 · `[검증 필요]` G0 PoC에서 확인

## 1. 아키텍처 원칙

- **앱:** Flutter / Dart, iOS·Android, 스마트폰·태블릿 `[확정]`
- **서버 없음 (온디바이스 전용)** `[확정]`
  - 필기, 조합, 수정, 저장, TTF 빌드, 내보내기를 모두 기기 안에서 처리한다.
  - 근거: NFR-04(로컬 우선, 클라우드 동기화 제외), NFR-05(상시 API 비용 없음), 제외 범위(계정, 동기화, 마켓플레이스).
  - 중요도 빈도 데이터는 앱 번들에 포함한다.
  - 예외: G0에서 온디바이스 TTF 빌드가 불가능하다고 판명되면 서버 빌드(Python fontTools)를 대안으로 재검토한다. 이 경우 PRD 변경이 필요하다.

## 2. 처리 파이프라인

```
① 필기 입력 → ② 획 → 윤곽선 → ③ 윤곽선 정리 → ④ 한글 조합 → ⑤ TTF 생성 → ⑦ 내보내기
                                     ↕
                                 ⑥ 로컬 저장
```

| 단계 | 필요 기능 | 선택 | 상태 |
|---|---|---|---|
| ① 필기 입력 | 압력·기울기, 펜/손가락 구분 | Flutter 기본 `Listener` / `PointerEvent` | `[추천]` 지연은 `[검증 필요]` (NFR-02, OQ-08) |
| ② 획 → 윤곽선 | 점 목록 → 굵기 있는 다각형 | [`perfect_freehand`](https://pub.dev/packages/perfect_freehand) | `[추천]` |
| ③ 윤곽선 정리 | 획 union, 단순화, 곡선 맞춤 | [`clipper2`](https://pub.dev/packages/clipper2) + 곡선 맞춤 자체 구현 | `[후보]` 0.0.3 버전이라 `[검증 필요]` |
| ④ 한글 조합 | 위치별 자모 변형(벌)과 배치 규칙 | 자체 구현 | 핵심 기술, OQ-01 |
| ⑤ TTF 생성 | glyf, cmap 등 TTF 테이블 작성 | 3장 참고 | 최대 위험, OQ-03 |
| ⑥ 저장 | 프로젝트, 원본 획, 선택·검토 상태 | [Drift](https://drift.simonbinder.eu/) (SQLite) + `path_provider` | `[추천]` |
| ⑦ 내보내기 | 기기 저장, OS 공유 | `share_plus`, `file_picker` | `[추천]` |
| 중요도 | 음절 사용 빈도 | 국립국어원 빈도 조사 / 모두의 말뭉치 | 라이선스 `[검증 필요]` (OQ-05) |
| 상태 관리 | 화면 상태, 의존성 주입 | Riverpod | `[추천]` |
| 테스트 | 단위, 골든, 폰트 검증 | `flutter_test`, CI에서 fontTools·OTS 검증 | `[추천]` (NFR-01) |

## 3. TTF 생성 방식 비교

| 방법 | 장점 | 단점 |
|---|---|---|
| **A. [`fontations`](https://pub.dev/packages/fontations)** (Rust `write-fonts`를 감싼 패키지) | `buildFont`에 윤곽선을 넣으면 `.ttf`가 나온다. iOS·Android 지원, MIT 라이선스 | 0.1.2 버전, 사용자가 매우 적어 계속 관리될지 알 수 없음 |
| **B. `flutter_rust_bridge` + [`write-fonts`](https://docs.rs/crate/write-fonts/latest) 직접 연결** | 검증된 Google 라이브러리를 쓰고 우리가 직접 통제 | Rust 개발 환경과 빌드 설정 추가 |
| **C. 순수 Dart TTF 작성기** | 외부 의존성 없음. 필요 테이블이 약 10개(head, hhea, maxp, OS/2, name, cmap, post, glyf, loca, hmtx)라 구현 가능한 규모 | 바이너리 형식 세부 사항을 직접 처리. 쓸 만한 Dart 작성 라이브러리 없음(읽기 전용만 존재) |
| D. 서버 Python fontTools | 가장 성숙한 도구 | 서버 없음 원칙에 어긋남 (1장 예외로만) |

**추천 경로:** G0에서 A로 처음부터 끝까지 동작하는지 검증한다. 패키지가 불안정하면 B로 바꾸고, Rust 의존성을 피하고 싶으면 C로 간다. `opentype.js`는 OTF만 출력하는 것으로 보여 제외했다.

## 4. 설계 고려 사항

- **조합 글리프로 용량 줄이기:** TrueType의 composite glyph는 이미 있는 글리프를 위치·크기 변환만으로 참조한다. 자동 생성 음절을 "자모 변형 참조 + 변환"으로 출력하면 11,172자 폰트 용량이 크게 줄 수 있다. 커스텀 글자만 실제 윤곽선으로 출력한다. 외부 앱 호환성은 `[검증 필요]`.
- **획 union:** 필기 획은 겹친다. 겹친 윤곽선도 대부분 프로그램에서 보이지만 일부 렌더러나 인쇄에서 문제가 생길 수 있어 ③에서 합치는 편이 안전하다.
- **원본 분리 저장:** 원본 획(점·압력·시간)과 변환된 윤곽선을 분리해 저장한다. 그래야 FR-02의 다시 편집과 POL-06의 비파괴 내보내기가 가능하다.
- **좌표계:** 화면 좌표(y 아래 방향)를 폰트 단위(UPM 1000 기준, y 위 방향)로 바꾸는 변환 규칙을 한곳에 둔다.

## 5. G0 PoC에서 확인할 항목

1. `fontations`로 만든 11,172자 TTF가 iOS·Android·Windows·macOS의 실제 프로그램에서 설치·선택·입력되는지
2. 11,172자 생성과 TTF 빌드에 걸리는 시간, 메모리 사용량, 파일 크기 (중급 Android 기기 기준)
3. 위치별 자모 변형(벌) 수와 사용자 입력 글자 수의 균형 (OQ-01)
4. 빈도 자료를 앱에 넣어 배포할 수 있는 라이선스인지, 아니면 대체 출처가 필요한지 (OQ-05)
5. `clipper2` union 결과의 품질과 속도
6. 펜과 손가락의 필기 지연 (iPad + Apple Pencil, Android 태블릿 + S Pen, 휴대폰)

## 참고 자료

- [fontations (pub.dev)](https://pub.dev/packages/fontations)
- [write-fonts (docs.rs)](https://docs.rs/crate/write-fonts/latest)
- [perfect_freehand (pub.dev)](https://pub.dev/packages/perfect_freehand)
- [clipper2 (pub.dev)](https://pub.dev/packages/clipper2)
- [Flutter local database options (PowerSync)](https://powersync.com/blog/flutter-local-database-options)
- [Unifont Hangul generation](https://unifoundry.com/hangul/hangul-generation.html)
- [Glyphs — Creating a Hangeul font](https://glyphsapp.com/learn/creating-a-hangeul-font)
- [국립국어원 — 우리말에는 어떤 말이 많이 쓰이고 있을까](https://www.korean.go.kr/nkview/nknews/200302/55_3.html)
