# 회애액 (Hwaeaek)

손글씨로 기본 자모 35자를 쓰면, 그 즉시 앱 안에서 내 글씨로 글을 쓸 수 있고, 쓰면서 어색한 글자를 다시 그려 다듬은 뒤, 현대 한글 11,172자를 담은 TTF 폰트로 내보내는 Flutter 앱입니다.

[![ci](https://github.com/HyeonSeoMan/Hwaeaek/actions/workflows/ci.yml/badge.svg)](https://github.com/HyeonSeoMan/Hwaeaek/actions/workflows/ci.yml)

> **상태:** MVP 1.0 개발 중. 구현 단계 1~7 완료, 8단계(iOS 앱 안 폰트 설치)와 G0 실기기 검증이 남아 있습니다.

## 어떻게 동작하나

```text
기본 글리프 35자 손글씨 ──▶ 조합 엔진 ──▶ 메모: 내 글씨로 바로 쓰기 ──▶ TTF 내보내기
 (자음 14 + 모음 21)          │               │ 어색한 글자를 눌러 다시 그리기
                              │               ▼
                              └──── 커스텀 글리프(수정 이력 보존)
```

- **획 단위 조합:** 기본 글리프의 획(중심선·필압)을 초성·중성·종성 자리로 옮긴 뒤 펜 굵기를 다시 입힙니다. 윤곽선을 통째로 줄이는 방식과 달리 받침이 있어도 획 굵기가 고릅니다. 쌍자음·겹받침은 구성 자음으로 만듭니다.
- **설치 없이 바로 쓰기:** 메모에 쓰인 글자만 담은 작은 폰트를 만들어 앱에 등록하므로, 한글 입력 조합·커서·선택을 OS 그대로 쓰면서 내 글씨로 표시됩니다.
- **커스텀 글리프 보호:** 직접 다시 그린 글자는 기본 글리프를 바꾸거나 다시 내보내도 덮어써지지 않습니다. 다시 그리면 수정본이 쌓이고, 실행 취소와 이력에서 되돌릴 수 있습니다. DB 트리거가 허용된 두 경로(커스텀 삭제, 프로젝트 삭제) 밖의 이력 삭제를 막습니다.
- **기기 안에서만 처리:** 서버, 계정, 외부 AI API가 없습니다. TTF는 순수 Dart 작성기로 만들고, 내보낼 때마다 디스크에서 다시 읽어 검증합니다.
- **백업:** 프로젝트 전체를 `.hwaeaek` 파일 하나로 저장하고 새 프로젝트로 가져올 수 있습니다. 가져오기는 압축 폭탄·경로 조작·손상된 데이터를 거부합니다.

## 주요 기능

| 기능 | 화면 | PRD |
| --- | --- | --- |
| 프로젝트 만들기·이름 바꾸기·삭제 | 프로젝트 목록 | FR-01 |
| 기본 글리프 작성(필수 35자, 보강 16자), 가이드, 지우개, 실행 취소, 초안 자동 저장 | 기본 글리프, 글리프 편집 | FR-02, FR-03 |
| 숫자·문장부호·영문 대소문자 그리기(선택, 비례폭) | 기본 글리프 | FR-03, FR-08 |
| 내 폰트로 메모 쓰기, 한글 정규화, 폰트에 없는 글자 구분 표시 | 메모 | FR-07 |
| 메모에서 글자 골라 다시 그리기, 수정 이력, 자동 생성으로 되돌리기 | 메모, 수정 이력 | FR-05 |
| 자주 쓰는 순서로 글자 점검 | 자주 쓰는 글자 | FR-06 |
| TTF 내보내기(빠지는 글자 미리 보기, 저장·공유) | 내보내기 | FR-08 |
| 백업 만들기·가져오기 | 설정, 프로젝트 목록 | FR-09 |

## 저장소 구조

```text
app/                    Flutter 앱
  lib/domain/           글리프 모델, 필기, 조합 엔진, TTF 빌더·리더, 한글 처리 (Flutter 위젯 없음)
  lib/infra/            Drift 저장소, 백업 파일, 동적 폰트 등록, 파일 저장·공유
  lib/state/            Riverpod provider, 저장 실패 재시도, 실행 취소, 내보내기 작업
  lib/ui/               화면
  lib/dev/              개발용 획 픽스처 (main_dev.dart와 테스트에서만 사용)
  test/, integration_test/
  drift_schemas/        DB 스키마 버전별 덤프
tools/                  TTF 검증(OTS·fontTools), 샘플 렌더링, KS X 1001 목록 생성
docs/                   기술 스택, 구현 명세, PoC 기록, 리뷰 보고서
hwaeaek-mvp1-prd-v0.4.2.md  제품 요구사항
```

## 개발 환경

- Flutter 3.50.0 (stable), Dart 3.14
- macOS + Xcode 27 (iOS·macOS 빌드)
- Python 3 (TTF 검증 도구)

```sh
# 의존성
cd app && flutter pub get

# TTF 검증 도구 (저장소 루트에서, git에 넣지 않음)
python3 -m venv .venv-tools
.venv-tools/bin/pip install fonttools opentype-sanitizer pillow
```

## 실행

```sh
cd app

# 개발용: 기본 글리프 35자가 미리 채워진 프로젝트 하나를 만들어 둔다
flutter run -t lib/main_dev.dart -d macos

# 릴리스 진입점: 빈 상태에서 시작
flutter run -d macos
```

iPhone·iPad에서는 `-d <기기 ID>`로 실행합니다(`flutter devices`로 확인). Xcode에서 서명 팀을 먼저 설정해야 합니다.

## 테스트

```sh
cd app
flutter analyze
flutter test                                   # 단위·위젯 테스트
HWAEAEK_REQUIRE_TOOLS=1 flutter test           # 검증 도구가 없으면 건너뛰지 않고 실패
flutter test integration_test -d macos         # 실제 앱 흐름: 기본 글리프 → 메모 → 다시 그리기 → 내보내기
../tools/check_dev_imports.sh                  # lib/dev/를 릴리스 코드에서 가져오지 않는지
```

- 테스트 이름에 PRD 테스트 시나리오 ID(`TS-01` 등)가 들어 있습니다.
- 조합 규칙 결과는 `app/test/golden/compose_v1.sha256`에 고정되어 있습니다. 조합 결과를 바꾸는 변경은 `HangulComposer.ruleVersion`을 올리고 골든을 갱신해야 합니다(`flutter test --update-goldens`).
- DB 스키마를 바꾸면 `drift_schemas/`에 새 덤프를 추가합니다(`dart run drift_dev schema dump lib/infra/db/database.dart drift_schemas/`).
- CI(`.github/workflows/ci.yml`)는 macOS에서 분석·dev import 검사·전체 테스트를 실행합니다.

## 문서

| 문서 | 내용 |
| --- | --- |
| [PRD v0.4.2](hwaeaek-mvp1-prd-v0.4.2.md) | 목표, 기능 요구사항(FR), 정책(POL), 미결정 사항(OQ), 위험, 테스트 시나리오(TS) |
| [구현 명세](docs/spec/mvp1-spec.md) | 아키텍처, DB 스키마, 바이너리 형식, 조합 규칙 v1, TTF·내보내기, 백업, 구현 단계 |
| [기술 스택](docs/tech-stack.md) | 선택한 기술과 대안 |
| [G0 PoC 기록](docs/poc/g0-log.md) | PoC 측정값과 발견(획 단위 조합, 겹받침, 동적 폰트) |
| [리뷰 기록](docs/reviews/) | PRD·명세 리뷰 보고서 |

## 남은 일

- **8단계: iOS 앱 안 폰트 설치** — 사용자가 만든 폰트를 시스템에 설치할 수 있는지, App Store 심사 조건 확인(OQ-09)
- **G0 실기기 검증** — iPhone·iPad 성능, Apple Pencil 필압, 메모 동적 폰트 등록 지연(OQ-03, OQ-08, OQ-11)
- **실제 손글씨로 조합 품질·펜 굵기 조정** (OQ-01, OQ-02)
- **빈도 데이터** — 라이선스를 확인한 음절 빈도 자료로 KS X 1001 순서를 대체(OQ-05)
- **외부 프로그램 수동 검증** — Windows·macOS 설치 후 문서 앱에서 사용(TS-M1, TS-M2)

## 라이선스

라이선스는 아직 정하지 않았습니다. `app/assets/dev/`의 나눔손글씨 펜 자모 데이터는 [SIL Open Font License 1.1](app/assets/dev/OFL.txt)을 따르며, 개발 참고용으로만 두고 앱에는 포함하지 않습니다.
