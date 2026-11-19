# 회애액 MVP 1.0 — 구현 명세 (Spec)

> **문서 버전:** v0.3.0 (초안)  
> **최초 작성일:** 2026-11-19 · **최종 수정일:** 2026-11-19  
> **기반 문서:** [PRD v0.4.1](../../hwaeaek-mvp1-prd-v0.4.1.md) · [기술 스택](../tech-stack.md) · [G0 PoC 기록](../poc/g0-log.md) · 리뷰: [v0.1.0](../reviews/spec-v0.1.0-egm-review.md), [v0.2.0](../reviews/spec-v0.2.0-egm-review.md)  
> **상태:** G0 진행 중.

## 0. 문서 규칙

### 0.1 표현

- 이 문서는 PRD의 **무엇을**에 대해 **어떻게**를 정한다. PRD와 충돌하면 PRD가 우선하며 이 문서를 고친다.
- 규범: "~한다", "~해야 한다" = 필수. "~를 권장한다" = 권장. "~할 수 있다" = 선택(사용자 기능에는 "사용자는 ~할 수 있다"로 주어를 밝힌다). PoC의 현재 동작은 항상 "PoC는 …"으로 쓴다.
- 수치: 측정값에는 측정 조건을 붙이고, 추정값에는 "추정"을 붙인다.
- 경로는 저장소 루트 기준 전체 경로로 쓴다(예: `app/lib/app/font_session.dart`).
- PoC 대응 표기: **(PoC 동작 유지)** 동작이 같다. **(PoC 경로 변경)** 동작은 같고 위치만 바뀐다. **(PoC 변경: 요지)** 동작이 바뀐다. **(신규)** PoC에 없다.

### 0.2 태그

| 태그 | 의미 |
| --- | --- |
| `[G0 대기: OQ-xx]` | 남은 G0 검증 결과에 따라 바뀔 수 있다. 영향은 §16 |
| `[G1 대기: OQ-xx]` | G1에서 닫히는 OQ에 기댄다. 영향은 §16 |
| `[Spec 결정]` | PRD에 없고 이 문서에서 정했다. 근거는 §17, PRD 반영 상태는 §19 |

절 제목의 태그는 절 전체에, 문장·표 행 끝의 태그는 그 문장·행에만 적용한다.

### 0.3 용어

PRD §0 용어를 따른다. 추가로:

| 용어 | 뜻 |
| --- | --- |
| 윤곽선 | `GlyphOutline` 하나(글리프 하나의 전체 모양) |
| 컨투어 | 윤곽선을 이루는 닫힌 경로 하나 |
| 조합 영역 | 조합 엔진이 자리를 계산하는 사각형(§2). PRD의 "글자 몸 상자"(advance × [descender, ascender])와 다르다 |
| 역할 키 | 기본 글리프를 가리키는 문자열(§3.2). 지금은 호환 자모 1자 |
| 스냅샷 | 한 시점의 프로젝트 글리프 상태를 담은 불변 객체(§3.3) |

관련 PRD ID는 각 절의 "관련:" 줄에 적는다. 전체 대응은 부록 A.

### 0.4 목적과 범위

PRD v0.4.1의 MVP 1.0 요구사항(FR-01~FR-09)을 구현하기 위한 구조, 데이터, 알고리즘, 테스트를 정한다. 제외 범위는 PRD §9를 따른다. 이 문서에서 특히 다루지 않는 것: Android 시스템 폰트 설치, 영문·숫자·기호 글리프(OQ-04), 호환 자모의 커스텀 글리프, 초안의 백업, 여러 조합 규칙 버전의 동시 지원(OQ-12).

## 1. 아키텍처

관련: NFR-04, NFR-05

### 1.1 계층

```text
UI      app/lib/ui       화면, 위젯, 내비게이션
상태    app/lib/state    Riverpod provider, 쓰기 대기 목록, 실행 취소, 내보내기 작업
도메인  app/lib/domain   글리프 모델, 필기, 조합 엔진, TTF 빌드·읽기, 한글 표
인프라  app/lib/infra    Drift 저장소, 백업 파일, 파일 선택·공유, 동적 폰트 등록, iOS 폰트 설치
```

- 의존은 위에서 아래로만 흐른다. 도메인은 상태·인프라·UI를 모른다.
- 도메인은 `package:flutter/widgets.dart`를 쓰지 않는다. `perfect_freehand`가 `dart:ui`의 `Offset`을 쓰므로 `dart:ui`는 허용한다. 도메인 코드는 백그라운드 isolate에서 돌 수 있어야 한다.
- 앱은 네트워크 요청을 하지 않는다(NFR-04, NFR-05). 네트워크 권한을 선언하지 않는다(Android `INTERNET` 없음, macOS 샌드박스 네트워크 엔타이틀먼트 없음).

### 1.2 디렉터리 `[Spec 결정]`

| 경로 | 내용 | PoC 대응 |
| --- | --- | --- |
| `app/lib/domain/glyph/` | `GlyphPoint`, `GlyphOutline`, `Bounds`, HWO1 직렬화 | `app/lib/font/glyph.dart` (PoC 경로 변경) + 직렬화 (신규) |
| `app/lib/domain/ink/` | `InkPoint`, `InkStroke`, `PenStyle`, 획 → 윤곽선, 단순화, HWS1 직렬화 | `app/lib/ink/ink.dart` (PoC 변경: `t`·기울기 추가, 펜 옵션 명시) |
| `app/lib/domain/hangul/` | 자모 표, 음절 분해, 한글 정규화, 빈도 순서 | `app/lib/hangul/hangul.dart` (PoC 경로 변경) + 정규화·빈도 (신규) |
| `app/lib/domain/compose/` | 조합 엔진(`dependencies` 포함), 레이아웃, 캐시 | `app/lib/hangul/composer.dart` (PoC 변경: 입력을 획 전용으로, `CompositionRule`·PoC `BaseGlyph` 제거, `dependencies` 추가) |
| `app/lib/domain/font/` | 폰트 메트릭 상수, `FontMetadata`, TTF 빌더, TTF 리더 | `app/lib/font/ttf_writer.dart` (PoC 변경: 메트릭 기본값, `created` 필수) + 리더 (신규) |
| `app/lib/domain/project/` | 스냅샷, 유효 글리프, 불변식 검사 | `app/lib/app/font_session.dart`에서 분리 |
| `app/lib/infra/db/` | Drift 테이블, DAO, 마이그레이션 | (신규) |
| `app/lib/infra/backup/` | 백업 쓰기·읽기·검증 | (신규) |
| `app/lib/infra/platform/` | 동적 폰트 등록, 파일 선택·저장·공유, iOS 폰트 설치 | `font_session.dart`·`memo_screen.dart`에서 분리 |
| `app/lib/state/` | provider, 쓰기 대기 목록, 실행 취소, 내보내기 작업 | `font_session.dart`에서 분리 |
| `app/lib/ui/` | 화면, `GlyphPainter`(2차 곡선 렌더러) | `app/lib/app/*` 재작성, `glyph_painter.dart` (PoC 경로 변경) |
| `app/lib/main.dart` | 릴리스 진입점. `dev/`를 가져오지 않는다 | (PoC 변경) |
| `app/lib/main_dev.dart` | 개발 진입점. 픽스처, 규칙 비교 메뉴 | (신규) |
| `app/lib/dev/` | 개발용 획 픽스처 | (PoC 변경: v0 경로·나눔 펜 로더 삭제) |
| `app/assets/frequency/` | 빈도 순서 자산(§14) | (신규) |
| `tools/` | 검증·렌더링·픽스처·KS X 1001 생성 스크립트 | (PoC 동작 유지) + `make_ksx1001.py` (신규) |

개발 코드 격리: `app/lib/dev/`는 `app/lib/main_dev.dart`와 `app/test/`에서만 가져온다. CI가 `tools/check_dev_imports.sh`로 검사한다(§12). 개발 자산(`app/assets/dev/`)은 `pubspec.yaml`의 `assets`에 넣지 않는다. 획 픽스처는 Dart 코드(`app/lib/dev/stroke_fixture.dart`)이고, 나눔 펜 픽스처는 테스트가 파일로 직접 읽는다. 따라서 릴리스 빌드에 개발 자산이 들어가지 않는다 `[Spec 결정]`.

## 2. 좌표계와 폰트 메트릭

관련: FR-02, FR-05, OQ-10

상수는 `app/lib/domain/font/metrics.dart` 한 곳에 둔다. 다른 코드는 숫자를 직접 쓰지 않는다.

| 항목 | 값 | 비고 |
| --- | --- | --- |
| UPM | 1000 | `[G0 대기: OQ-10]` |
| 좌표 방향 | y 위 | TrueType과 같다 |
| ascender / descender | 800 / -200 | hhea와 OS/2 typo에 쓴다. win 메트릭은 §7.1 `[G0 대기: OQ-10]` |
| advance width (한글·호환 자모) | 1000 고정폭 | `[G0 대기: OQ-10]` |
| advance width (공백) | 333 | |
| 글자 몸 상자 | x 0~1000, y -200~800 | PRD 용어. advance × [descender, ascender]. 편집 캔버스 테두리와 같다 |
| 조합 영역 | x 60~940, y -60~800 | §6.2 자리 계산 기준. 편집 화면 보조 가이드 |
| 편집 캔버스 | 정사각형 = x 0~1000, y 800(위)~-200(아래) | 한 변 S, 캔버스 좌표 (cx, cy) → `x = cx/S*1000`, `y = 800 - cy/S*1000` |

획 점과 윤곽선은 이 폰트 단위로 저장한다. OQ-10으로 UPM이나 ascender가 바뀌면 저장된 좌표의 의미가 바뀌므로, 그 전에 출시한 데이터가 없도록 G0에서 확정한다(§16).

## 3. 도메인 모델

관련: PRD §5, FR-02, FR-05

### 3.1 글리프와 획

| 타입 | 필드 | 규칙 |
| --- | --- | --- |
| `GlyphPoint` | `int x, y`, `bool onCurve` | 연속된 off-curve 점 사이에는 on-curve 중점이 암묵적으로 있다 |
| `GlyphOutline` | `List<List<GlyphPoint>> contours` | 채움 규칙 non-zero. 획 컨투어는 모두 시계 방향(y 위 기준) |
| `InkPoint` | `double x, y`, `double? pressure`(0~1), `double? tilt`(라디안, 0 = 수직), `double? orientation`(라디안), `int t`(획 시작부터 ms) | f32 양자화는 입력 계층(§5)과 HWS1 디코더에서만 한다. 조합 엔진이 배치하며 만드는 점은 double을 유지하고 원래 점의 `t`·필압·기울기를 그대로 옮긴다 |
| `InkStroke` | `List<InkPoint> points` | |
| `PenStyle` | `size`, `thinning`, `smoothing`, `streamline`, `easing`, `startCap`, `startTaper`, `startEasing`, `endCap`, `endTaper`, `endEasing`, `tolerance` | 모든 값을 명시적으로 넘긴다(§5.1). easing은 이름(`identity`, `easeInOut`, `easeOutCubic`)으로 저장한다 |

펜 값:

| 이름 | size | thinning | smoothing | streamline | easing | start (cap, taper, easing) | end (cap, taper, easing) | tolerance |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 기본 펜 | 56 | 0.55 | 0.6 | 0.5 | identity | true, 끔, easeInOut | true, 끔, easeOutCubic | 2 |
| 조합 펜 | 56 × 배율(§6.2) | 기본 펜과 같음 | | | | | | |

"taper 끔"은 `perfect_freehand`의 `taperEnabled: false`다. 편집 화면 표시, 커스텀 글리프 저장, 단독 호환 자모는 기본 펜을 쓴다. 그래서 그리는 모양과 저장되는 모양이 같다. 조합 펜은 자모가 줄어든 정도에 따라 기본 펜보다 가늘어지므로(약 28~56), 커스텀 음절은 자동 생성 음절의 가장 굵은 획과 같은 굵기다 `[Spec 결정]`. 펜 값은 실제 손글씨로 다시 맞춘다 `[G1 대기: OQ-01, OQ-02]`.

### 3.2 프로젝트 데이터

| 타입 | 필드 | 비고 |
| --- | --- | --- |
| `Project` | `id`(UUID v4), `name`, `createdAt`, `updatedAt`, `baseSetVersion`, `ruleVersion`, `memoUnlockedAt?`, `glyphRevision`, `baseRevision` | `memoUnlockedAt`: 필수 기본 글리프를 처음 모두 작성한 시각. 한 번 정해지면 다시 비우지 않는다(FR-04). `glyphRevision`·`baseRevision`: §3.3 |
| `FontMetadata` | `familyName`, `asciiFamilyName`, `styleName`, `versionMinor`, `license` | 기본값: 패밀리 = 프로젝트 이름, ASCII = `Hwaeaek-<id 앞 8자>`, 스타일 `Regular`, `versionMinor` 0(= fontRevision 1.000), 라이선스 빈 문자열. 프로젝트 이름을 바꿔도 패밀리 이름은 따라 바뀌지 않는다 |
| `BaseGlyph` (저장 엔터티) | `roleKey`, `strokes`, `updatedAt` | 윤곽선은 저장하지 않는다. 조합 규칙의 일부로 매번 획에서 만든다 `[Spec 결정]` |
| `CustomRevision` | `id`, `codePoint`, `strokes`, `outline`, `pen`, `createdAt` | 윤곽선을 함께 저장한다. 앱 업데이트로 펜 알고리즘이 바뀌어도 커스텀 모양이 바뀌지 않는다(POL-07) `[Spec 결정]` |
| `CustomGlyph` | `codePoint`, `selection`(`generated`/`custom`), `currentRevisionId` | 수정 이력이 있는 음절만 행이 있다. 행이 없으면 `generated` |
| `Memo` | `id`, `projectId`, `text`, `createdAt`, `updatedAt` | |
| `Draft` | `kind`(`base`/`custom`), `key`, `strokes`, `updatedAt` | 편집 중 초안(§4.4) |

**역할 키** `[Spec 결정]`: 기본 글리프와 조합 의존 집합이 쓰는 불투명 문자열. 문법 `<호환 자모 1자>[@<위치 변형>]`. MVP는 `@` 없는 형태만 쓴다(`ㄱ`, `ㅘ`, `ㄺ`). 위치 변형(OQ-01)을 넣을 때 `ㄱ@cho.h` 같은 형태를 추가하며, DB 열과 백업 파일 이름(§11.1, UTF-8 16진 인코딩)은 바뀌지 않는다.

**ASCII 이름 규칙:** 사용자가 바꿀 때 ASCII 33~126 중 `[](){}<>/%`를 뺀 문자와 공백만 허용하고 1~31자로 제한한다. PS 이름(§7.1)으로 정리한 결과가 빈 문자열이면 저장을 막는다. 바꾸면 `font_version_minor`를 0으로 되돌린다(§7.4).

**입력 상한** `[Spec 결정]`:

| 대상 | 상한 | 도달 시 |
| --- | --- | --- |
| 글리프 하나의 획 수 | 200 | "더 그릴 수 없습니다" 안내, 새 획 무시 |
| 획 하나의 점 수 | 5,000 | 그 획을 끝낸 것으로 처리 |
| 글리프 하나의 전체 점 수 | 20,000 | 새 획 무시 + 안내 |
| 메모 하나의 글자 수 | 100,000 | 입력 무시 + 안내 |

평소에는 보이지 않는다. HWS1(§4.2), TTF 빌더(§7.1), 백업 검사(§11.3)의 상한은 이 값에서 나온다.

**기본 글리프 세트 버전:**

| `baseSetVersion` | 필수 | 보강 |
| --- | --- | --- |
| 1 | 자음 14(`ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅅ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ`) + 모음 21 = 35 | 쌍자음 5(`ㄲ ㄸ ㅃ ㅆ ㅉ`) + 겹받침 11(`ㄳ ㄵ ㄶ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅄ`) = 16 |

`[G1 대기: OQ-01]`. 앱이 아는 최신 세트 버전이 프로젝트보다 크면, 프로젝트를 열 때 `baseSetVersion`을 올리고 새 필수 항목을 "작성 필요"로 표시한다(계산으로 도출, 별도 저장 없음). 커스텀 글리프·선택 상태·메모는 건드리지 않는다(POL-07, TS-20). `memoUnlockedAt`이 있으면 메모는 계속 열린다.

### 3.3 스냅샷과 유효 글리프

`GlyphSnapshot`은 불변 객체다. 읽기 트랜잭션 하나로 `projects`(revision 두 값과 메타데이터)와 글리프 테이블을 함께 읽어 만든다. `snapshotProvider`는 `projects` 행의 변화를 구독하되, `glyph_revision`이 바뀌었을 때만 스냅샷을 다시 만든다. 메모 쓰기는 `projects`를 바꾸지 않는다.

| 필드 | 내용 |
| --- | --- |
| `revision` | `projects.glyph_revision`. 글리프에 영향을 주는 쓰기(기본 글리프, 커스텀 저장, 선택 상태 변경, 커스텀 삭제)와 같은 트랜잭션에서 1 증가 |
| `baseStrokes` | 역할 키 → 획 |
| `baseRevision` | `projects.base_revision`. 기본 글리프 쓰기와 같은 트랜잭션에서 1 증가 |
| `customs` | 코드포인트 → (`selection`, 현재 수정본 윤곽선) |
| `metadata` | `FontMetadata` |

```text
effectiveGlyph(snapshot, composer, cp):
  c = snapshot.customs[cp]
  if c != null and c.selection == custom: return c.outline       // 빈 윤곽선이면 오류
  return composer.compose(cp)                                      // null이면 조합 오류
```

**조합 오류 음절**은 `effectiveGlyph`가 null이거나 빈 윤곽선인 음절이다. 메모 폰트(§8)와 TTF 빌드(§7)가 같은 정의를 쓴다.

스냅샷을 만들 때 불변식(`selection == custom ⇒ 현재 수정본이 같은 프로젝트·같은 음절에 존재`)을 검사한다. 위반하면 해당 음절을 조합 오류로 다루고, 앱에 "데이터 오류" 배너를 띄우며 내보내기를 막는다. DB 제약(§4.1) 때문에 정상 경로에서는 일어나지 않는다.

## 4. 저장소

관련: FR-01, FR-05, FR-09, POL-01, POL-05, OQ-07

### 4.1 테이블 (Drift / SQLite) `[Spec 결정]` `[G1 대기: OQ-07]`

```sql
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,              -- epoch ms
  updated_at INTEGER NOT NULL,
  base_set_version INTEGER NOT NULL,
  rule_version INTEGER NOT NULL,
  memo_unlocked_at INTEGER,
  glyph_revision INTEGER NOT NULL DEFAULT 0,
  base_revision INTEGER NOT NULL DEFAULT 0,
  font_family_name TEXT NOT NULL,
  font_ascii_name TEXT NOT NULL,
  font_style_name TEXT NOT NULL DEFAULT 'Regular',
  font_version_minor INTEGER NOT NULL DEFAULT 0 CHECK (font_version_minor BETWEEN 0 AND 999),
  font_license TEXT NOT NULL DEFAULT ''
);

CREATE TABLE base_glyphs (
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  role_key TEXT NOT NULL,
  strokes BLOB NOT NULL,                    -- HWS1, 획 1개 이상
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (project_id, role_key)
);

CREATE TABLE custom_revisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  code_point INTEGER NOT NULL CHECK (code_point BETWEEN 44032 AND 55203),
  strokes BLOB NOT NULL,                    -- HWS1
  outline BLOB NOT NULL,                    -- HWO1
  pen TEXT NOT NULL,                        -- PenStyle JSON
  created_at INTEGER NOT NULL,
  UNIQUE (project_id, code_point, id)
);

CREATE TABLE custom_glyphs (
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  code_point INTEGER NOT NULL CHECK (code_point BETWEEN 44032 AND 55203),
  selection TEXT NOT NULL CHECK (selection IN ('generated', 'custom')),
  current_revision_id INTEGER NOT NULL,
  PRIMARY KEY (project_id, code_point),
  FOREIGN KEY (project_id, code_point, current_revision_id)
    REFERENCES custom_revisions(project_id, code_point, id)
);

CREATE TABLE memos (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  text TEXT NOT NULL,                       -- 한글 정규화(§8.3) 후 저장
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE drafts (
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('base', 'custom')),
  key TEXT NOT NULL,                        -- 역할 키 또는 코드포인트 10진
  strokes BLOB NOT NULL,                    -- HWS1, 화면에 보이는 획 전체
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (project_id, kind, key)
);

CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,                     -- 예: 'draw_with_finger'
  value TEXT NOT NULL
);

-- 수정 이력 삭제를 허용된 두 경로로 제한한다(POL-01).
-- revision_guard는 항상 한 행이다. 행이 없거나 값이 1이 아니면 삭제를 막는다.
CREATE TABLE revision_guard (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  allow_revision_delete INTEGER NOT NULL CHECK (allow_revision_delete IN (0, 1))
);
INSERT INTO revision_guard VALUES (1, 0);  -- Drift onCreate에서 실행
CREATE TRIGGER custom_revisions_no_delete BEFORE DELETE ON custom_revisions
WHEN NOT EXISTS (SELECT 1 FROM revision_guard WHERE id = 1 AND allow_revision_delete = 1)
BEGIN SELECT RAISE(ABORT, 'custom revision delete not allowed'); END;
```

- 모든 연결의 `beforeOpen`에서 `PRAGMA foreign_keys = ON`, `journal_mode = WAL`을 켠다.
- `custom_glyphs`의 복합 외래 키가 "현재 수정본은 같은 프로젝트·같은 음절의 것"을 보장한다.
- **수정 이력 삭제 경로는 둘뿐이다:** 커스텀 글리프 삭제 DAO와 프로젝트 삭제 DAO가 트랜잭션 안에서 `revision_guard.allow_revision_delete = 1`로 바꾸고 삭제한 뒤 0으로 돌린다. 다른 코드가 지우려 하면 트리거가 막는다.
- 메모 삭제는 즉시 행을 지운다. 실행 취소는 메모리에 보관한 행을 다시 넣는다(§9.2).
- 스키마는 Drift `.drift` 파일(`app/lib/infra/db/schema.drift`)에 위 SQL로 쓴다. 복합 외래 키·트리거를 그대로 표현하기 위해서다 `[Spec 결정]`. `schemaVersion` = 1. 마이그레이션마다 이전 버전 DB 픽스처 테스트를 둔다.
- `projects.updated_at`은 프로젝트 이름·메타데이터·글리프 쓰기 때 갱신한다. 메모 쓰기 때는 갱신하지 않는다.

### 4.2 바이너리 형식 `[Spec 결정]`

모두 리틀 엔디언. 파싱 후 남는 바이트가 있으면 오류다.

**HWS1 (획):**

```text
magic "HWS1" (4 bytes) | strokeCount u16 (1..200)
repeat strokeCount:
  pointCount u32 (1..5000)       -- 전체 점 합계 ≤ 20000 (§3.2 입력 상한)
  repeat pointCount:
    x f32 | y f32                 -- 유한수, -32768..32767
    pressure f32                  -- 0..1, 없으면 NaN
    tilt f32 | orientation f32    -- 라디안, 없으면 NaN
    t u32                         -- ms, 감소하지 않음
```

점 하나 24바이트. 글리프 하나의 HWS1은 최대 약 469KB다. 획이 0개인 상태는 HWS1로 쓰지 않는다(§4.4).

**HWO1 (윤곽선):**

```text
magic "HWO1" (4 bytes) | contourCount u16 (0..10000)
repeat contourCount:
  pointCount u16 (3..65535)
  repeat pointCount: x i16 | y i16 | flags u8 (bit0 = onCurve, 나머지 0)
```

### 4.3 쓰기와 실패 처리

관련: FR-01, POL-03, POL-05, TS-15, TS-16

**직렬화:** Drift 단일 연결이 트랜잭션을 순서대로 실행한다. 별도 쓰기 큐를 두지 않는다 `[Spec 결정]`.

**화면 기준은 커밋된 DB다.** 글리프·선택 상태를 바꾸는 작업은 커밋을 기다린 뒤 화면을 갱신한다. 메모 텍스트만 예외로, 입력 중인 텍스트는 `TextEditingController`가 화면 기준이다.

| 이벤트 | 시점 | 쓰기 | 트랜잭션 |
| --- | --- | --- | --- |
| 프로젝트 만들기 | 확인 | `projects` insert(기본 메타데이터, `base_set_version`·`rule_version` = 앱 최신) | 문 1개 |
| 프로젝트 이름 바꾸기 | 확인 | `projects.name`, `updated_at` | 문 1개 |
| 프로젝트 삭제 | 확인 | 가드 켬 → `projects` delete(CASCADE) → 가드 끔 | 1개 |
| 프로젝트 열기 | 열 때 | 앱 최신보다 낮으면 `base_set_version` 올림(§3.2) | 문 1개 |
| 폰트 메타데이터 변경 | 저장 | `projects.font_*`, ASCII 이름이 바뀌면 `font_version_minor = 0`, `updated_at` | 문 1개 |
| 편집 중 획 변경(완료·지우기·Undo·Redo) | 즉시 | 획 ≥ 1이면 `drafts` upsert, 0이면 `drafts` delete | 문 1개 |
| 기본 글리프 저장 | 저장 버튼 | `base_glyphs` upsert, `glyph_revision`·`base_revision` +1, 필수가 처음 다 차면 `memo_unlocked_at`, `drafts` delete | 1개 |
| 커스텀 글리프 저장 | 저장 버튼 | `custom_revisions` insert → `custom_glyphs` upsert(`custom`, 새 id) → `glyph_revision` +1 → `drafts` delete | 1개 |
| 되돌리기·다시 선택·수정본 지정·실행 취소 | 즉시 | `custom_glyphs` update, `glyph_revision` +1 | 1개 |
| 커스텀 글리프 삭제 | 확인 후 | 가드 켬 → `custom_glyphs` delete → `custom_revisions` delete → `glyph_revision` +1 → 가드 끔 | 1개 |
| 메모 만들기 | 새 메모 | `memos` insert(빈 텍스트) | 문 1개 |
| 메모 입력 | 마지막 입력 1초 후, 앱 백그라운드 전환 시 즉시 | `memos` update | 문 1개 |
| 메모 삭제 | 즉시 | `memos` delete(§9.2) | 문 1개 |
| 내보내기 커밋 | §7.2 9단계 | `font_version_minor` | 문 1개 |
| 설정 변경 | 즉시 | `app_settings` upsert | 문 1개 |

**실패 처리** (FR-01):

- 모든 쓰기 실패는 화면 위 배너로 알린다("저장하지 못했습니다. 다시 시도하는 중…").
- 실패한 쓰기는 **대기 목록**에 메모리로 보관하고 1·2·4·…·최대 30초 간격으로 자동 재시도한다. 같은 대상(같은 프로젝트의 같은 기본 글리프·음절·메모·초안)에 대한 새 쓰기는 그 대상의 대기 항목 뒤에서 기다리며, 메모·초안은 최신 값 하나로 합친다. 다른 대상의 쓰기는 영향을 받지 않는다.
- 기본·커스텀 글리프 저장이 실패하면 편집 화면은 "저장 중" 상태로 남는다. 사용자가 화면을 떠나도 대기 항목은 계속 재시도하며 배너가 남는다.
- 실행 취소 대상이 아직 대기 중이면, 실행 취소는 DB를 고치지 않고 그 대기 항목을 지운다.
- `SQLITE_FULL`이거나 같은 항목이 연속 3회 실패하면 배너를 "저장 공간이 부족합니다. 공간을 확보하거나 백업을 내보내 주세요"로 바꾼다. 재시도는 계속한다.
- 앱이 종료되면 대기 목록은 사라진다. 그 대상의 마지막 커밋 상태와 초안이 남는다(PRD FR-01 인수 조건은 "자동 저장이 끝난 뒤" 종료를 대상으로 한다).
- **글리프 대기 항목**(기본 글리프, 커스텀, 선택 상태, 커스텀 삭제)이 있으면 내보내기를 시작하지 않고 "저장되지 않은 변경이 있습니다"를 표시한다. 메모·초안·설정 대기 항목은 내보내기와 백업을 막지 않는다. 백업 만들기는 DB를 읽기만 하므로 저장 공간 부족 상태에서도 시작할 수 있다.

### 4.4 편집 중 초안

획 완료·지우기·Undo·Redo 때마다 화면에 보이는 획 전체로 `drafts`를 덮어쓴다. 획이 0개가 되는 모든 변경(모두 지우기, 마지막 획 지우기·Undo)은 초안 행을 지운다. 편집 화면을 열 때 초안이 있으면 그 획으로 연다(진행 중이던 작업을 잃지 않게 하는 복구이며 별도 질문은 없다). 저장하거나 뒤로 가기에서 "버리기"를 고르면 초안을 지운다. 초안은 백업하지 않는다.

### 4.5 OS 기기 백업

관련: NFR-04, RISK-03

- iOS: DB와 앱 데이터는 iCloud 기기 백업 대상이다. `exports/`와 `installed/`(§13.1)는 `isExcludedFromBackup`을 켠다.
- Android: `allowBackup=true`, `dataExtractionRules`로 DB 파일만 포함한다. Android 자동 백업은 앱당 25MB 한도라 큰 프로젝트는 백업되지 않을 수 있다. 이는 알려진 한계이며 FR-09 백업 파일이 대비책이다.
- 앱이 백그라운드로 갈 때 `PRAGMA wal_checkpoint(TRUNCATE)`로 WAL을 비워 백업 시점 DB를 한 파일로 만든다.

## 5. 필기 입력

관련: FR-02, NFR-02, OQ-08

- `Listener`의 `onPointerDown/Move/Up/Cancel`로 점을 받는다.
- **손바닥 방지:** stylus 포인터가 오면 진행 중인 touch 획을 취소하고 stylus 획을 시작한다. 한 편집 세션에서 stylus를 한 번 보면 이후 touch로는 그리지 않는다. 사용자는 설정에서 "손가락으로도 그리기"를 켤 수 있다(`app_settings.draw_with_finger`).
- **필압:** `kind == stylus`이고 `pressureMax > pressureMin`이면 `clamp((p - min)/(max - min), 0, 1)`, 아니면 null.
- **기울기:** stylus면 `event.tilt`, `event.orientation`, 아니면 null. MVP는 저장만 하고 렌더링에 쓰지 않는다.
- **시간:** 획 시작부터 `event.timeStamp` 차이(ms).
- **양자화:** 포인터 이벤트로 점을 만들 때 x, y, pressure, tilt, orientation을 `Float32List` 왕복으로 f32 값으로 바꾼다. 메모리와 DB가 같은 값을 갖게 해 저장 전후 조합 결과가 같다(FR-02, FR-04). 개발용 획 픽스처도 같은 함수로 양자화하고 `t` = 점 순번 × 8ms로 둔다.
- **상한:** §3.2 입력 상한을 적용한다.
- **표시:** 완료된 획의 윤곽선은 캐시하고, 그리는 중인 획만 프레임마다 다시 계산한다.
- **편집 동작:**
  - 획 지우기: 지우개 모드에서 획을 누르면 그 획을 지운다(획 윤곽선 안의 점 판정).
  - 글리프 다시 쓰기: "모두 지우기"로 모든 획을 지운다.
  - Undo/Redo: 획 추가·지우기·모두 지우기 단위 스택. 화면을 벗어나면 버린다.
- **가이드** (FR-02): 글자 몸 상자(캔버스 테두리), 기준선, 조합 영역(보조선). 기본 글리프 편집이면 해당 자모의 배치 영역(규칙 v1에서 그 자모가 가장 자주 놓이는 자리, 세로형 받침 없음 레이아웃 기준)을 흐리게 표시한다. 커스텀 편집이면 현재 유효 글리프를 흐리게 표시한다(덧그리기, FR-05).
- **표시 펜:** 기본 펜(§3.1). 저장 결과와 같은 굵기다.
- Apple Pencil의 coalesced·predicted 터치 전달 여부를 확인한다 `[G0 대기: OQ-08]`. 전달되지 않아 획이 각지면 `streamline`을 조정하며, 이는 `ruleVersion` 변경이다(§6.3).

### 5.1 획 → 윤곽선 (PoC 변경: 펜 옵션 명시)

1. `perfect_freehand.getStroke`. `PenStyle`의 모든 필드(size, thinning, smoothing, streamline, easing, `StrokeEndOptions.start/end`의 cap·taperEnabled·easing)를 명시적으로 넘기고 `isComplete = true`. 패키지의 정적 기본값(`StrokeOptions.default*`, `StrokeEndOptions.default*`)에 기대지 않는다. `simulatePressure`는 획의 **모든** 점에 필압이 있을 때만 false다.
2. Douglas–Peucker 단순화. 닫힌 다각형을 시작점에서 가장 먼 점으로 둘로 나눠 각각 단순화한다. `tolerance`가 0이면 생략한다.
3. 정수 반올림, 연속 중복 점 제거, 마지막 점이 첫 점과 같으면 제거, 점 3개 미만 컨투어 제거.
4. 시계 방향(y 위)으로 맞춘다.

`perfect_freehand`는 정확한 버전으로 고정한다(`pubspec.yaml`에 `2.5.2+1`).

## 6. 조합 엔진

관련: FR-03, FR-04, POL-02, OQ-01, TS-01, TS-12

### 6.1 인터페이스

```text
HangulComposer(Map<String, List<InkStroke>> baseStrokes)   // 역할 키 → 획
  static const ruleVersion = 1
  compose(int cp) -> GlyphOutline?       // 음절 11,172 + 호환 자모 51. 조합 오류면 null
  dependencies(int cp) -> Set<String>    // 이 글자 조합에 영향을 주는 역할 키
```

- 입력은 기본 글리프 획이다(FR-04). PoC의 윤곽선 입력(규칙 v0)은 삭제했다(git 이력 `582ba4c`에 있음).
- `dependencies(cp)`는 OQ-01 산출물("음절 → 의존 기본 글리프 집합 함수")이자 TS-01의 기대 집합 정의다. 겹자음 자리에는 그 겹자음 키와 구성 자음 키를 **둘 다** 넣는다(겹자음 기본 글리프가 생기면 레이아웃도 바뀌기 때문).

### 6.2 규칙 v1 (PoC 변경: 컨투어 순서, 단독 자모 펜, 오류 판정, 퇴화 범위)

PoC와 다른 점은 해시 골든과 TTF 바이트를 바꾸므로, 구현은 PoC가 아니라 이 절을 따른다.

**1. 분해:** `s = cp - 0xAC00`, 초성 `s / 588`, 중성 `(s % 588) / 28`, 종성 `s % 28`.

**2. 모음 모양:** 가로형 `ㅗ ㅛ ㅜ ㅠ ㅡ`, 섞임형 `ㅘ ㅙ ㅚ ㅝ ㅞ ㅟ ㅢ`, 나머지는 세로형.

**3. 레이아웃:** 자리는 조합 영역 기준 정규화 좌표, y 위.

| 모양 | 받침 | 초성 (x0, y0, x1, y1) | 중성 (x0, y0, x1, y1) | 종성 (x0, y0, x1, y1) |
| --- | --- | --- | --- | --- |
| 세로 | 없음 | 0.00, 0.08, 0.60, 0.92 | 0.55, 0.00, 1.00, 1.00 | — |
| 가로 | 없음 | 0.12, 0.44, 0.88, 1.00 | 0.00, 0.02, 1.00, 0.50 | — |
| 섞임 | 없음 | 0.02, 0.46, 0.62, 1.00 | 0.00, 0.02, 1.00, 1.00 | — |
| 세로 | 있음 | 0.00, 0.44, 0.60, 1.00 | 0.55, 0.36, 1.00, 1.00 | 0.12, 0.00, 0.88, 0.38 |
| 가로 | 있음 | 0.15, 0.64, 0.85, 1.00 | 0.00, 0.36, 1.00, 0.66 | 0.12, 0.00, 0.88, 0.36 |
| 섞임 | 있음 | 0.02, 0.62, 0.60, 1.00 | 0.00, 0.34, 1.00, 1.00 | 0.12, 0.00, 0.88, 0.34 |

**4. 겹받침 자리 높이기:** 종성이 보강 기본 글리프(쌍자음·겹받침)이고 그 기본 글리프가 없으면, 자모 둘을 나란히 넣어야 해 받침이 납작해진다. 이때만 적용한다.

```text
r = 0.06
base = min(초성.y0, 중성.y0)
종성.y1 += r
초성·중성의 각 y: y' = (y <= base) ? base + r : base + r + (y - base) * (1 - base - r) / (1 - base)
```

**5. 자모 배치:** 자리마다 각 변에서 0.03을 뺀 안쪽 자리를 쓴다.
- 역할 키의 기본 글리프가 있으면 그 획을 넣는다.
- 없고 보강 기본 글리프(아래 표)면 구성 자음 둘을 안쪽 자리 안의 (0.00, 0.05, 0.52, 0.95)와 (0.48, 0.05, 1.00, 0.95)에 각각 넣는다. 구성 자음이 없으면 조합 오류.
- 그 외에는 조합 오류.

| 보강 | 구성 | 보강 | 구성 | 보강 | 구성 | 보강 | 구성 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ㄲ | ㄱ ㄱ | ㄸ | ㄷ ㄷ | ㅃ | ㅂ ㅂ | ㅆ | ㅅ ㅅ |
| ㅉ | ㅈ ㅈ | ㄳ | ㄱ ㅅ | ㄵ | ㄴ ㅈ | ㄶ | ㄴ ㅎ |
| ㄺ | ㄹ ㄱ | ㄻ | ㄹ ㅁ | ㄼ | ㄹ ㅂ | ㄽ | ㄹ ㅅ |
| ㄾ | ㄹ ㅌ | ㄿ | ㄹ ㅍ | ㅀ | ㄹ ㅎ | ㅄ | ㅂ ㅅ |

**6. 맞추기:**

```text
fit(points, slot):                      // slot은 폰트 단위로 변환한 자리
  inset = 28                            // 조합 기준 펜 반지름(56/2)
  sx0 += min(inset, (sx1-sx0)/4); sx1 -= 같은 값       // y도 같은 방식
  (gx0, gy0, gx1, gy1) = 점들의 범위; gw = gx1-gx0; gh = gy1-gy0
  if gw < 1 and gh < 1: return 조합 오류          // 점 하나 등 퇴화한 자모
  scaleX = gw < 1 ? ∞ : (sx1-sx0)/gw;  scaleY = gh < 1 ? ∞ : (sy1-sy0)/gh
  if scaleX == ∞: scaleX = scaleY;  if scaleY == ∞: scaleY = scaleX
  if scaleX/scaleY > 1.6: scaleX = scaleY*1.6
  if scaleY/scaleX > 1.6: scaleY = scaleX*1.6
  가운데 정렬: left = sx0 + ((sx1-sx0) - gw*scaleX)/2, bottom도 같은 방식
  p' = (p.x*scaleX + left - gx0*scaleX, p.y*scaleY + bottom - gy0*scaleY)
```

**7. 펜 다시 입히기:** 자모마다 `s = min(scaleX, scaleY)`, 펜 지름 `d = round(56 * clamp(s^0.35, 0.5, 1))`. 자모마다 따로 §5.1로 윤곽선을 만든다(같은 `d`끼리 묶지 않는다). 결과 컨투어는 초성 → 중성 → 종성 순, 겹자음은 왼쪽 → 오른쪽, 자모 안에서는 획 순서대로 이어 붙인다.

**8. 호환 자모 단독:** 기본 글리프가 있으면 그 획을 변환 없이 기본 펜(56)으로 입힌다. 없는 보강 기본 글리프는 전체 자리(여백 0)에 5번 단계로 넣는다.

**오류 판정:** 다음 중 하나면 조합 오류(null)다. 넣은 자모(겹자음이면 각 구성 자음)의 윤곽선이 7단계 뒤 비어 있음, 6단계에서 퇴화 범위, 결과 점 수가 65,535 초과, 좌표가 i16 밖. `compose`는 글자 하나를 계산하다 생긴 예외를 잡아 null로 바꾸며, 다른 글자 계산에 영향을 주지 않는다. 기본 글리프 저장은 획이 1개 이상이고 점 범위가 가로나 세로로 1단위 이상일 때만 허용한다.

### 6.3 규칙 버전과 결정성

`ruleVersion`은 자동 생성 결과를 바꾸는 모든 것의 버전이다: §6.2의 값, §3.1 조합 펜·커스텀 펜 값, §5.1 알고리즘, `perfect_freehand` 버전, 반올림 규칙. 하나라도 바꾸면 올린다.

- `projects.rule_version`은 "이 프로젝트를 마지막으로 연 앱의 규칙 버전"이 아니라 **프로젝트를 만들 때의 규칙 버전**이다. OQ-12가 정해질 때까지 값을 바꾸지 않으며, 앱은 최신 규칙 하나만 포함해 모든 프로젝트를 그 규칙으로 계산한다. POL-08 `[G1 대기: OQ-12]` 구현 시 이 값을 비교 기준으로 쓴다. 백업 manifest에도 기록하지만 가져오기 거부 조건에는 쓰지 않는다(§11.3).
- **해시 골든 테스트:** 개발용 획 픽스처(§5 양자화 적용) + 최신 규칙으로 호환 자모 51 + 음절 11,172자를 코드포인트 오름차순으로 HWO1 직렬화해 이어 붙인 바이트의 SHA-256(`crypto` 패키지)을 `app/test/golden/compose_v<ruleVersion>.sha256`과 비교한다. 골든은 CI 호스트(macOS arm64) 한 종류에서만 비교한다. `ruleVersion`을 올리지 않았는데 해시가 바뀌면 실패한다. Flutter SDK만 바꾸었는데 해시가 바뀌면 SDK 변경 PR에서 원인(삼각함수 구현 등)을 기록하고 `ruleVersion`을 올린 뒤 골든을 갱신한다.
- **같은 기기 보장:** 같은 기기에서는 앱 표시와 TTF가 같은 입력(f32 양자화된 획)과 같은 코드로 만들어지므로 윤곽선이 같다(FR-04).
- **기기 간:** `perfect_freehand`는 `double` 삼각함수를 쓰므로 플랫폼에 따라 자동 생성 윤곽 점이 1단위 다를 수 있다. 이를 허용한다(PRD FR-04). 커스텀 글리프는 윤곽선을 저장하므로 기기 간에도 같다. iOS·Android·macOS의 골든 해시 차이를 G0에서 측정해 기록한다 `[G0 대기: OQ-03]`.

### 6.4 성능 기준

| 작업 | 측정 (G0, Mac, `flutter test`, 개발용 획 픽스처, 1회) | 목표 |
| --- | --- | --- |
| 11,223자 조합 + TTF 빌드 | 1.8초 | `[G0 대기: OQ-13]` iPad 측정 후 NFR-02 |
| 메모 11자 동적 폰트 빌드 | 8~13ms (디버그 앱) | `[G0 대기: OQ-13]` |

### 6.5 캐시

- 프로젝트마다 수명이 긴 조합 엔진 하나와 코드포인트별 윤곽선 캐시를 둔다. 최대 4,000자 LRU.
- 스냅샷의 `baseRevision`이 바뀌면 조합 엔진을 새 획으로 다시 만들고 캐시 전체를 버린다 `[Spec 결정]`. 기본 글리프 편집은 드물고 다시 계산은 필요할 때만 일어나므로 선택적 무효화의 이득이 작다. `dependencies`는 OQ-01·TS-01용으로 둔다.
- 커스텀·선택 상태 변경은 조합 캐시에 영향을 주지 않는다(§3.3 `effectiveGlyph`가 먼저 처리).

## 7. TTF 빌더

관련: FR-08, POL-04, POL-05, POL-06, OQ-03, OQ-10, TS-03, TS-08, TS-13, TS-14

### 7.1 출력

PoC 동작을 유지하되 아래를 바꾼다(PoC 변경): `created`는 필수 인자(내보내기는 내보내기 시각 UTC, 메모 폰트는 고정값 `2026-01-01T00:00:00Z`), ascender/descender 기본값은 §2 상수, u16 필드(`endPtsOfContours`, `maxPoints` 등)에 범위 밖 값이 오면 잘라 쓰지 않고 `RangeError`를 던진다.

| 테이블 | 값 |
| --- | --- |
| `head` | version 1.0, fontRevision `1 + versionMinor/1000`, flags 0x000B, unitsPerEm 1000, created = modified = 내보내기 시각, 전체 bbox, macStyle 0, lowestRecPPEM 8, fontDirectionHint 2, indexToLocFormat 자동(마지막 오프셋 ≤ 0x1FFFE면 short), glyphDataFormat 0 |
| `hhea` | ascender 800, descender -200, lineGap 0, advanceWidthMax·minLSB·minRSB·xMaxExtent 계산, caretSlopeRise 1, numberOfHMetrics = 글리프 수 |
| `maxp` | v1.0, numGlyphs, maxPoints·maxContours 계산, maxZones 2, 나머지 0 |
| `OS/2` | v4. xAvgCharWidth = 0이 아닌 advance 평균, usWeightClass 400, usWidthClass 5, fsType 0, ySubscript X/Y size·X/Y offset = 650/600/0/70, ySuperscript = 650/600/0/350, yStrikeoutSize 50, yStrikeoutPosition 300, sFamilyClass 0, panose 0, ulUnicodeRange bit 0(ASCII 있을 때)·52(호환 자모 있을 때)·56(음절 있을 때), achVendID `HWAE`, fsSelection 0xC0(REGULAR, USE_TYPO_METRICS), usFirst/LastCharIndex, typo 800/-200/0, usWinAscent = max(800, yMax), usWinDescent = max(200, -yMin), ulCodePageRange1 bit 19(음절 있을 때), sxHeight 500, sCapHeight 700, usDefaultChar 0, usBreakChar 0x20 `[G0 대기: OQ-10]` |
| `cmap` | (0,3)과 (3,1)이 format 4 서브테이블 하나를 공유. 코드포인트와 글리프 ID가 함께 연속인 구간을 한 세그먼트로, 끝에 0xFFFF |
| `glyf`/`loca` | 단순 글리프만. 첫 플래그에 OVERLAP_SIMPLE(0x40), 같은 플래그 반복 압축, 좌표는 short/same 플래그 사용 |
| `hmtx` | advance, lsb = xMin(빈 글리프는 0) |
| `name` | 플랫폼 3·인코딩 1. en-US(0x0409): ID 0(라이선스가 있을 때), 1 = ASCII 이름, 2 = 스타일, 3 = `<PS 이름>;Version x.yyy`, 4 = ASCII 이름, 5 = `Version x.yyy`, 6 = PS 이름. ko-KR(0x0412): ID 1, 4 = 한글 이름(ASCII 이름과 다를 때). PS 이름 = `<ASCII 이름>-<스타일>`에서 ASCII 33~126 밖과 `[](){}<>/%`·공백을 지우고 63자로 자름 |
| `post` | v3.0, underlinePosition -100, underlineThickness 50 |

글리프 순서: `.notdef`(폭 500, 이중 사각형), 이후 코드포인트 오름차순(공백, 호환 자모, 음절). 공백은 항상 넣는다.

`[G0 대기: OQ-03]` 파일 크기를 줄이기 위해 자모 composite 글리프(§17 대안)를 채택하면 "단순 글리프만", §7.3 리더, TS-12 비교 방법이 바뀐다.

### 7.2 내보내기 흐름

```text
 1. 글리프 대기 항목(§4.3)이 있으면 시작하지 않는다. 필수 기본 글리프가 없으면 중단한다(FR-08).
 2. 모달 진행 화면을 띄운다. 이 동안 메모 입력을 포함한 모든 편집을 막는다.
 3. 읽기 트랜잭션으로 스냅샷을 만든다. n = font_version_minor + 1 (999면 §7.4)
 4. 백그라운드 isolate: 호환 자모 51 + 음절 11,172의 effectiveGlyph 계산.
    500자마다 진행률을 SendPort로 보낸다.
    제외 = 조합 오류 음절(§6.2) ∪ 저장 윤곽선이 HWO1 검사(§4.2)를 통과하지 못하거나
           글리프 전체 점이 65,535를 넘거나 좌표가 i16 밖인 커스텀 음절
 5. isolate: buildTtf(versionMinor = n, created = 지금)
 6. 결과 시트: 제외 음절 수와 목록(빈도 순, §14)을 보여 준다.
    사용자가 [저장] [공유] [설치(iOS)] 중 하나를 고르거나 [취소]한다.     ← PRD "내보내기 전"
 7. 고르면: exports/<projectId>/<asciiName>-v<n>.ttf.part에 쓴다.
 8. 디스크의 .part를 다시 읽어 §7.3으로 검증한다.
      cmap 항목 수 = 1(공백) + 유효 호환 자모 수 + 유효 음절 수
      numGlyphs    = cmap 항목 수 + 1(.notdef)
 9. DB: font_version_minor = n 커밋
10. .part → .ttf 이름 바꾸기, 고른 동작 실행(§13)
```

- 4~8 단계가 실패하면 버전을 올리지 않고 `.part`를 지운 뒤 원인과 다시 시도를 표시한다(POL-05). 글자 하나의 계산 오류는 4단계에서 제외로 처리되므로 전체 실패가 아니다. 전체 실패 유형: isolate 비정상 종료, 빌더 예외(`ArgumentError`, `RangeError` — 4단계 제외가 정상이면 일어나지 않아야 함), 디스크 쓰기 실패, 검증 불일치.
- 9단계 뒤 10단계 전에 앱이 죽으면 버전 번호 하나를 건너뛴다. 사용자 작업은 바뀌지 않는다(POL-06).
- 6단계에서 취소하면 아무것도 쓰지 않는다.
- **백그라운드 전환:** 앱이 백그라운드로 가도 isolate를 일부러 종료하지 않는다. OS가 일시 정지하면 돌아왔을 때 이어서 계산한다. 6단계 결과 시트를 보는 중이면 결과를 그대로 유지한다(스냅샷은 불변이고 편집은 막혀 있다). OS가 프로세스를 종료하면 9단계 전에는 DB가 바뀌지 않으므로 사용자 데이터는 그대로다. 다음 실행 때 남은 `.part`를 지운다(TS-14) `[Spec 결정]`.
- 버전 증가는 사용자 데이터 중 유일한 변경이다(POL-06).

### 7.3 기기 안 검증 `[Spec 결정]`

`app/lib/domain/font/ttf_reader.dart`는 테이블 디렉터리, 각 테이블 체크섬과 `head.checkSumAdjustment`, `maxp.numGlyphs`, `cmap` format 4 항목 수를 읽는다. 테스트용으로 `glyf` 단순 글리프 디코더를 함께 둔다(TS-12). OTS 수준 검증은 CI에서만 한다(§12). `fontations`의 읽기 기능을 쓰지 않는 이유는 §17.

### 7.4 버전 999 이후와 파일 정리

- `font_version_minor`가 999면 내보내기 시트에서 "폰트 버전이 최대입니다. 폰트 이름을 바꾸면 버전이 1.001부터 다시 시작합니다"를 표시하고 진행하지 않는다. 폰트 이름(ASCII)을 바꾸면 `font_version_minor`를 0으로 되돌리며, 다음 내보내기가 1.001이 된다 `[Spec 결정]`.
- `exports/`의 기준은 앱 문서 폴더(`getApplicationDocumentsDirectory`)다. `exports/<projectId>/`에는 최근 3개 파일만 남긴다(공유 시트가 파일을 읽는 동안 지워지지 않게 하면서 공간이 쌓이지 않게). 앱 시작 시 남은 `.part`를 지운다.
- 파일 크기는 현재 약 7.4MB(획 픽스처)다 `[G0 대기: OQ-03]`.

## 8. 메모 렌더러 (동적 폰트)

관련: FR-07, NFR-06, OQ-04, OQ-11, RISK-07, TS-09, TS-10, TS-11, TS-19

### 8.1 동작 (PoC 변경: 스냅샷 revision 기준, 열린 메모 범위)

```text
전역: familyCounter (프로세스 전체에서 단조 증가하는 정적 값)
메모별 상태: loaded: Set<int>, builtFromRevision: int, appliedFamily: String?,
            appliedCmap: Set<int>, knownErrors: Set<int>

ensureFont(text, snapshot):
  needed = { r in text | 음절 또는 호환 자모 }
  if snapshot.revision == builtFromRevision and loaded ⊇ needed: return
  want = loaded ∪ needed
  glyphs = want의 effectiveGlyph (null·빈 윤곽선 = 조합 오류, 제외)
  bytes = buildTtf(glyphs, created = 2026-01-01T00:00:00Z)
  family = "hw_" + (++familyCounter)
  try FontLoader(family).addFont(bytes).load()
  catch: 1초 뒤 다시 시도(최대 3회), 상태는 바꾸지 않음
  성공 시에만: loaded = want; builtFromRevision = snapshot.revision
             appliedFamily = family; appliedCmap = glyphs의 코드포인트
             knownErrors = want − appliedCmap
```

- **범위:** 지금 열린 메모의 글자만 담는다. 메모를 바꾸면 `loaded`를 비운다. 메모를 열 때 그 메모 전체 글자로 한 번 빌드한다(RISK-07 완화).
- **계기:** 텍스트 변경과 스냅샷 `revision` 변경. `memoFontProvider`가 스냅샷을 구독하므로 편집 화면에서 돌아오면 스스로 다시 빌드한다.
- **실행 위치:** UI isolate에서 동기 빌드한다(PoC와 같음). `[G0 대기: OQ-11]` 다음 측정에서 하나라도 넘으면 층 구조(§17 P-2)로 바꾼다: iPad 릴리스 빌드에서 서로 다른 음절 1,000자 메모의 새 글자 1개당 빌드+등록 p95 > 50ms, 또는 30분 입력 세션의 등록 폰트 누적 > 64MB.
- **조합 중 글자:** 한글 입력기 조합 중 중간 글자(`ㄱ`, `가`)도 `needed`에 넣는다(FR-07 "조합 중에도 사용자 폰트"). 그래서 음절 하나에 빌드가 최대 세 번 일어난다. 이 비용은 위 측정에 포함한다.
- **등록 폰트 누적:** 등록한 폰트는 해제할 수 없어 세션 동안 쌓인다(위 측정 항목).
- **등록 전 프레임:** 새 폰트가 등록될 때까지 `appliedFamily`를 유지한다. 새 글자는 그동안 시스템 폰트로 보인다.

RISK-07 대체안(입력은 시스템 폰트, 아래에 사용자 글리프 미리보기)을 채택하면 §8 전체가 바뀐다(§16).

### 8.2 대체 표시

`TextEditingController.buildTextSpan`을 재정의한다. 문자가 다음 중 하나면 회색 + 점선 밑줄로 그린다(색만으로 구분하지 않는다, NFR-06):

- 음절·호환 자모가 아닌 문자(영문·숫자·기호 등) `[G1 대기: OQ-04]`
- `knownErrors`에 있는 글자(§8.1)

등록 대기 중인 새 글자(`loaded`에 아직 없음)에는 적용하지 않는다. 깜빡임을 막기 위해서다. 글꼴 자체는 OS 대체 폰트가 맡는다.

### 8.3 한글 정규화 `[Spec 결정]`

PRD FR-07(v0.4.1)의 "한글 정규화"를 구현한다.

- 대상: 현대 첫가끝 자모만. L `U+1100~U+1112`, V `U+1161~U+1175`, T `U+11A8~U+11C2`. 연속된 L V (T)를 완성형 음절로 합친다: `0xAC00 + ((L-0x1100)*21 + (V-0x1161))*28 + (T ? T-0x11A7 : 0)`. 그 밖의 문자(옛한글 자모 포함)는 그대로 둔다.
- 시점: `TextInputFormatter`에서 `value.composing`이 비어 있을 때만(붙여넣기, 조합 완료) 적용한다. 한글 입력기 조합 중에는 텍스트를 바꾸지 않는다. 적용 후 커서 위치를 합쳐진 글자 수만큼 보정한다. 저장 직전에도 한 번 더 적용한다.
- 테스트 벡터 (코드포인트):

| 입력 | 출력 | 검사 대상 |
| --- | --- | --- |
| U+1100 U+1161 U+11BC | U+AC15 (강) | L V T |
| U+1100 U+1161 | U+AC00 (가) | L V |
| U+1100 | U+1100 | L 단독 그대로 |
| U+1100 U+1161 U+1100 U+1161 | U+AC00 U+AC00 | 연속 |
| U+0061 U+1112 U+1161 U+11AB | U+0061 U+D55C (a한) | 앞 문자 유지 |
| U+1100 U+1176 | U+1100 U+1176 | 옛한글 V 그대로 |

### 8.4 음절 고르기 (PoC 변경: 호환 자모 제외)

`TextField.contextMenuBuilder`에 항목을 더한다. 대상은 선택 영역의 첫 글자, 선택이 없으면 커서 앞 글자다. 항목: "‘X’ 다시 그리기", 커스텀 음절이면 "자동 생성으로 되돌리기", 이력이 있는 자동 생성 음절이면 "내 글씨 다시 선택". 호환 자모는 커스텀 대상이 아니므로(PRD §9) 이 항목들은 음절에만 보인다. PoC는 호환 자모에도 "다시 그리기"를 보인다. iPad 터치·Pencil 사용성은 `[G0 대기: OQ-11]`.

편집 화면으로 가기 전에 `TextEditingController.selection`과 `ScrollController.offset`을 보관하고, 돌아오면 되돌린다(FR-07).

## 9. 상태와 실행 취소

관련: FR-05, FR-07, POL-03, OQ-06

### 9.1 커스텀 글리프 실행 취소

- 대상: 커스텀 저장, 자동 생성으로 되돌리기, 커스텀 다시 선택, 수정본 지정.
- 슬롯 하나에 `(projectId, codePoint, before, after)`를 보관한다. `before`/`after` = `(selection, currentRevisionId)`, 첫 저장의 `before`는 "행 없음".
- 실행 취소는 한 트랜잭션에서 비교 후 교체하고 `glyph_revision`을 1 올린다:

  ```sql
  UPDATE custom_glyphs SET selection = :before_selection, current_revision_id = :before_rev
  WHERE project_id = :p AND code_point = :cp
    AND selection = :after_selection AND current_revision_id = :after_rev;
  ```

  첫 저장의 실행 취소는 `selection = 'generated'`로 바꾸고 `current_revision_id`는 그대로 둔다(행 삭제 아님, 수정 이력 보존). 영향 행이 0이면 "되돌릴 수 없습니다"를 표시한다.
- 대상 동작이 아직 커밋되지 않고 대기 중이면(§4.3) DB를 고치지 않고 그 대기 항목을 지운다.
- 슬롯을 비우는 때: 스낵바가 사라질 때(5초 `[G1 대기: OQ-06]`), 커스텀 글리프 삭제, 프로젝트 전환·삭제. 새 대상 동작은 슬롯을 교체한다.

### 9.2 메모 삭제 실행 취소

메모를 지우면 행을 즉시 삭제하고, 지운 행을 메모리에 보관한 채 스낵바(5초)를 띄운다. 실행 취소를 누르면 같은 id로 다시 넣는다. 스낵바가 사라지면 보관을 버린다.

### 9.3 provider 구성

Riverpod 3, 코드 생성 없이 `Provider`/`NotifierProvider`/`StreamProvider`를 직접 선언한다 `[Spec 결정]`.

| provider | 내용 | 수명 |
| --- | --- | --- |
| `databaseProvider` | Drift DB | 앱 |
| `pendingWritesProvider` | §4.3 대기 목록, 배너 상태 | 앱 |
| `projectListProvider` | 프로젝트 목록 스트림 | 화면 |
| `projectProvider(id)` | 프로젝트 + 메타데이터 | 프로젝트 열림 동안 |
| `snapshotProvider(id)` | `GlyphSnapshot`(§3.3) | 프로젝트 열림 동안 |
| `glyphRendererProvider(id)` | 스냅샷 + 조합 엔진 캐시(§6.5). `outline(cp)`가 유효 글리프. 조합 엔진은 `baseRevision`이 바뀔 때만 다시 만듦 | 프로젝트 열림 동안 |
| `glyphActionsProvider(id)` | 글리프 쓰기(대기 목록 경유)와 실행 취소 기록 | 프로젝트 열림 동안 |
| `memoFontProvider(memoId)` | §8.1 | 메모 열림 동안 |
| `undoProvider` | §9.1 슬롯 | 앱 |
| `exportJobProvider(id)` | §7.2 진행 상태 | 작업 동안 |

## 10. 화면

관련: PRD §3, FR-01~FR-09

| 화면 | 내용 | FR |
| --- | --- | --- |
| 프로젝트 목록 | 만들기, 이름 바꾸기, 삭제(확인), 가져오기 | FR-01, FR-09 |
| 기본 글리프 작성 (첫 실행) | 필수 35자를 순서대로 안내, 작성률. 다 쓰면 메모로 | FR-03 |
| 프로젝트 홈 | 메모 목록, 작성률, 진입점(기본 글리프 / 빈도순 목록 / 내보내기 / 설정) | FR-07 |
| 메모 | §8 | FR-07 |
| 글리프 편집 | §5. 기본·커스텀 공용 | FR-02, FR-05 |
| 수정 이력 시트 | 커스텀 음절의 수정본을 최신순 썸네일로. 현재 수정본 표시, 눌러서 지정(§9.1 대상), 맨 아래 "커스텀 글리프 삭제"(확인) `[G1 대기: OQ-06]` | FR-05 |
| 기본 글리프 목록 | 필수 / 보강 구분, 작성 여부, "작성 필요" 표시 | FR-03 |
| 빈도순 목록 | §10.1 | FR-06 |
| 내보내기 | §7.2 진행 화면과 결과 시트 | FR-08 |
| 프로젝트 설정 | 폰트 이름(한글·ASCII, §3.2 규칙), 라이선스 문구, 백업 만들기, 손가락으로도 그리기 | FR-08, FR-09 |

**필수 기본 글리프 입력 순서** `[Spec 결정]`: `ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅅ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ`, `ㅏ ㅑ ㅓ ㅕ ㅗ ㅛ ㅜ ㅠ ㅡ ㅣ`, `ㅐ ㅒ ㅔ ㅖ`, `ㅘ ㅙ ㅚ ㅝ ㅞ ㅟ ㅢ`. 자음 다음 단모음, 그다음 복합 모음 순이다. 사용자는 순서를 건너뛰어 아무 글자부터 쓸 수 있다.

### 10.1 빈도순 목록과 썸네일

빈도순 목록, 수정 이력 썸네일, 기본 글리프 목록은 메모 폰트를 쓰지 않고 `GlyphPainter`(`CustomPainter`)로 윤곽선을 직접 그린다. `SliverGrid`로 보이는 칸만 `effectiveGlyph`를 요청하며, 조합 캐시(§6.5 LRU)를 그대로 쓴다.

## 11. 백업 파일

관련: FR-09, RISK-03, RISK-08, TS-17, TS-18

### 11.1 형식 `[Spec 결정]`

확장자 `.hwaeaek`, ZIP(압축 방식 stored 또는 deflate만).

| 항목 이름 (정규식) | 내용 |
| --- | --- |
| `manifest.json` | 아래 |
| `base/[0-9A-F]{2,64}\.hws` | HWS1. 파일 이름은 역할 키의 UTF-8 바이트를 대문자 16진으로 쓴 것(예: `ㄱ` → `E384B1`) |
| `custom/[0-9A-F]{5}/[1-9][0-9]{0,8}\.hws` | HWS1. 폴더는 코드포인트 대문자 16진 5자리(`0AC15`), 파일은 `seq`(음절별 1부터, `created_at, id` 오름차순) |
| `custom/[0-9A-F]{5}/[1-9][0-9]{0,8}\.hwo` | HWO1 |
| `custom/index.json` | 아래 |
| `memos.json` | 아래 |

```jsonc
// manifest.json (모든 필드 필수, project.memoUnlockedAt만 null 가능)
{
  "format": "hwaeaek-backup",
  "formatVersion": 1,
  "schemaVersion": 1,
  "ruleVersion": 1,
  "baseSetVersion": 1,
  "appVersion": "1.0.0+1",
  "createdAt": 1795000000000,
  "project": {
    "name": "내 손글씨",
    "memoUnlockedAt": 1795000000000,
    "font": {"familyName": "…", "asciiFamilyName": "…", "styleName": "Regular",
             "versionMinor": 3, "license": ""},
    "baseGlyphs": {"E384B1": {"updatedAt": 1795000000000}}
  }
}

// custom/index.json — 키는 코드포인트 대문자 16진 5자리
{
  "0AC15": {
    "selection": "custom",
    "current": 2,
    "revisions": [
      {"seq": 1, "createdAt": 1795000000000, "pen": {"size": 56, "...": "..."}},
      {"seq": 2, "createdAt": 1795000100000, "pen": {"size": 56, "...": "..."}}
    ]
  }
}

// memos.json — 메모 id는 백업에 넣지 않고 가져올 때 새 UUID를 만든다
[{"text": "…", "createdAt": 1795000000000, "updatedAt": 1795000000000}]
```

초안과 앱 설정은 포함하지 않는다.

### 11.2 백업 만들기

1. 글리프 대기 항목(§4.3)이 없을 때 시작한다.
2. 읽기 트랜잭션 하나로 프로젝트 데이터를 읽는다.
3. `<임시 폴더>/<파일 이름>.hwaeaek.part`에 항목 단위로 스트리밍해 쓴다(`archive` 패키지의 `OutputFileStream`). 파일 이름은 프로젝트 이름에서 `/\:*?"<>|`와 제어 문자를 `_`로 바꾸고 64자로 자른 것이며, 비면 `hwaeaek-backup`이다.
4. 만든 파일을 §11.3 검사기로 그대로 검사한다(가져오기와 같은 코드). 통과하지 못하면 지우고 "백업을 만들 수 없습니다"를 표시한다. 입력 상한(§3.2) 때문에 정상 데이터는 항상 통과해야 하며, 실패는 버그로 기록한다.
5. 이름을 바꾸고 §13.2 저장·공유로 넘긴다.

### 11.3 가져오기 검증

상한은 §3.2 입력 상한에서 나온다. 수정 이력은 무제한(PRD FR-05)이라 전체 항목 수와 총량은 고정 상한 대신 디스크 공간과 압축률로 막는다.

1. 파일 선택(§13.2)으로 경로를 받는다.
2. 중앙 디렉터리만 읽는다(`InputFileStream`). 중앙 디렉터리 크기 ≤ 64MB. 이름이 §11.1 정규식 밖이거나, 중복 이름, 디렉터리·심볼릭 링크, 암호화, stored·deflate 외 방식이 있으면 거부한다.
3. Dart에는 여유 공간 조회 API가 없으므로, 디스크 부족은 가져오기 트랜잭션의 SQLITE_FULL로 감지해 `storage`로 알린다(쓰기는 모두 롤백) `[Spec 결정]`.
4. 항목마다 따로 풀며, 실제로 나온 바이트를 세어 다음 상한을 넘는 순간 중단한다: `.hws` ≤ 512KB, `.hwo` ≤ 512KB, `manifest.json` ≤ 1MB, `custom/index.json`·`memos.json` ≤ 64MB. 또 항목별 압축률(해제 크기 / 압축 크기) ≤ 200.
5. 의미 검증:
   - manifest 필수 필드와 타입. `formatVersion`, `schemaVersion`, `baseSetVersion`이 앱보다 크면 거부. `ruleVersion`은 거부 조건이 아니다(자동 생성은 앱 규칙으로 다시 계산).
   - 기본 글리프 키는 호환 자모 51자 안. 커스텀 코드포인트는 `AC00~D7A3`.
   - `index.json`의 각 `seq`에 `.hws`와 `.hwo`가 모두 있고, 그 반대도 성립. `current`가 `revisions` 안. 모든 커스텀 음절이 수정본을 1개 이상 가짐.
   - HWS1/HWO1 형식(§4.2) 전부.
   - 메모 텍스트 각 ≤ 100,000자. 폰트 ASCII 이름은 §3.2 규칙 재검사.
6. 모두 통과하면 새 UUID 프로젝트로 한 트랜잭션에 넣는다. 수정본 `created_at`, 기본 글리프 `updated_at`(manifest의 `baseGlyphs`), 메모 시각을 보존한다. `glyph_revision`·`base_revision`은 0에서 시작한다. 실패하면 아무것도 쓰지 않는다.
7. 앱보다 낮은 `formatVersion`은 버전별 변환기로 최신 형식으로 바꾼 뒤 위 검사를 한다(MVP는 1뿐).

| 실패 코드 | 메시지 |
| --- | --- |
| `too_large` | 백업 파일이 너무 큽니다. |
| `not_backup` | 회애액 백업 파일이 아닙니다. |
| `newer_version` | 더 새로운 버전의 앱에서 만든 백업입니다. 앱을 업데이트해 주세요. |
| `corrupt` | 백업 파일이 손상되었습니다. |
| `storage` | 저장 공간이 부족합니다. |

## 12. 테스트

관련: PRD §10, NFR-01

| 종류 | 도구 | 대상 | TS | 단계 |
| --- | --- | --- | --- | --- |
| 단위 | `flutter test` | 분해, 조합, `dependencies`, 점 하나 기본 글리프 → 조합 오류, HWS1/HWO1 왕복, 양자화 후 조합 동일, TTF 빌드·읽기, u16 초과 예외, 한글 정규화 벡터 | — | 1 |
| 해시 골든 | `flutter test` | §6.3 | TS-12 | 1 |
| 불변식·회귀 | `flutter test` + 임시 파일 Drift DB | POL-01~03, POL-05~07. 트리거가 허용 경로 밖 수정본 삭제를 막음, `revision_guard` 행이 없어도 막음, 다른 모든 쓰기 후 `custom_revisions` 행 수가 줄지 않음, `glyph_revision` 증가 | TS-01, TS-04, TS-06, TS-07, TS-20 | 2 |
| 재시작 | 임시 파일 DB 닫고 다시 열기 | | TS-02 | 2 |
| 오류 주입 | 테스트 전용 임시 트리거(`CREATE TEMP TRIGGER … RAISE(ABORT)`), `PRAGMA max_page_count` | 트랜잭션 원자성, 저장 공간 부족, 대기 목록 재시도·순서 | TS-15, TS-16 | 2 |
| 실행 취소 | 위와 같음 | PRD TS-05(다시 그려 저장 → 실행 취소 → 수정본 1이 현재, 2는 이력에 남음), 회귀: 저장 → 삭제 → 실행 취소가 아무것도 바꾸지 않음 | TS-05 | 3 |
| 마이그레이션 | Drift 스키마 테스트 | 버전별 스키마 덤프(`app/drift_schemas/drift_schema_v<n>.json`, `dart run drift_dev schema dump`) | — | 3부터(v2 스키마가 생길 때) |
| 위젯 | `flutter test` | 문맥 메뉴, 편집 후 복귀 위치, 실행 취소 스낵바, 대체 표시, 조합 중 정규화 미적용 | TS-09, TS-10, TS-11, TS-19 | 4 |
| 내보내기 | `flutter test` + `tools/validate_ttf.py` | cmap·numGlyphs 식, 버전 증가, 실패 시 버전 유지, 강제 종료 시 데이터 불변 | TS-03, TS-08, TS-13, TS-14 | 5 |
| 백업 | `flutter test` | 왕복, 손상·악성 파일 픽스처(압축 폭탄, `..` 경로, 범위 밖 좌표, 새 버전) | TS-17, TS-18 | 6 |
| 통합 | `integration_test` (iPad 시뮬레이터) | 작성 → 메모 → 다시 그리기 → 내보내기 | — | 5 |
| 수동 | — | 외부 프로그램 설치·사용 | TS-M1~TS-M4 | 5, 8 |

- CI는 `.venv-tools`(fonttools, opentype-sanitizer, pillow)를 만들고 `HWAEAEK_REQUIRE_TOOLS=1`을 설정한다. 이 값이 있으면 외부 검증 도구가 없을 때 테스트가 건너뛰지 않고 실패한다. 테스트는 작업 디렉터리 `app/`에서 실행한다.
- CI는 `flutter analyze`, `flutter test`, `tools/check_dev_imports.sh`(§1.2)를 실행한다. CI 설정은 `.github/workflows/ci.yml`(macOS arm64 러너).
- 테스트 이름에 PRD TS ID를 넣는다(예: `'TS-05 다시 그린 뒤 실행 취소'`).

## 13. 플랫폼

관련: FR-08, FR-09, NFR-03, OQ-09

### 13.1 iOS 폰트 설치

- 엔타이틀먼트 `com.apple.developer.user-fonts` = `["system-installation"]` `[G0 대기: OQ-09]`.
- 메서드 채널 `hwaeaek/fonts`의 `install(path, projectId)` → `ok | denied | error(message)`. 구현 파일 `app/ios/Runner/FontInstaller.swift`.
- 순서: (1) 이 프로젝트가 전에 설치한 파일(`<Application Support>/installed/<projectId>-v*.ttf`)이 있으면 `CTFontManagerUnregisterFontURLs`로 해제하고 지운다. (2) 새 파일을 `<Application Support>/installed/<projectId>-v<n>.ttf`로 복사한다. (3) `CTFontManagerRegisterFontURLs([url], .persistent, enabled: true)`로 등록하고 완료 콜백을 위 세 결과에 대응시킨다.
- 설치 전 안내: "이 폰트는 기기의 다른 앱에서도 쓸 수 있게 설치됩니다. 회애액을 삭제하면 설치한 폰트도 함께 제거됩니다."(FR-08)
- `installed/`와 `exports/`의 `isExcludedFromBackup`은 같은 Swift 파일의 `excludeFromBackup(path)` 메서드로 설정한다.
- iOS가 등록 후 원본 파일을 복사하는지 참조하는지, 사용자 생성 폰트 허용·App Store 심사를 G0에서 확인한다 `[G0 대기: OQ-09]`. 불가하면 이 절을 지우고 공유만 남긴다(RISK-05).
- Android에서는 설치 버튼을 숨긴다(PRD §9).

### 13.2 파일 저장·공유·선택

| 동작 | iOS | Android |
| --- | --- | --- |
| TTF·백업 저장 | `share_plus` 공유 시트의 "파일에 저장" | `file_picker`의 `saveFile`(SAF `CREATE_DOCUMENT`) |
| TTF·백업 공유 | `share_plus` (iPad는 `sharePositionOrigin` 필수) | `share_plus` |
| 백업 가져오기 | `file_picker` `pickFiles` | `file_picker` `pickFiles`(SAF `OPEN_DOCUMENT`) |

### 13.3 Android 백업 규칙

`app/android/app/src/main/res/xml/data_extraction_rules.xml`: `cloud-backup`과 `device-transfer`에 `database` 도메인(앱 DB)만 `include`하고 `file` 도메인은 `exclude`한다. `AndroidManifest.xml`에 `android:allowBackup="true"`, `android:dataExtractionRules`를 둔다.

## 14. 빈도 데이터

관련: FR-06, OQ-05, RISK-04

- 자산 `app/assets/frequency/syllables.txt`: 첫 줄 `# source=… version=…`, 이후 음절 1자씩 빈도 순. 로더는 `app/lib/domain/hangul/frequency.dart`.
- 라이선스가 확인되지 않으면 `[G1 대기: OQ-05]` **KS X 1001 2,350자 순서 → 나머지 음절 Unicode 순서**로 대체한다. KS X 1001 목록은 `tools/make_ksx1001.py`가 EUC-KR 표(0xB0A1~0xC8FE)에서 한 번 만들어 `app/assets/frequency/ksx1001.txt`로 커밋한다.
- 내보내기 제외 목록(§7.2)도 이 순서로 정렬한다.

## 15. PoC 코드 처리

| PoC 파일 | 처리 | 단계 |
| --- | --- | --- |
| `app/lib/font/glyph.dart` | `app/lib/domain/glyph/`로 이동 | 1 |
| `app/lib/font/ttf_writer.dart` | `app/lib/domain/font/`로 이동. `created` 필수, 메트릭 기본값을 §2 상수로, u16 범위 검사 | 1 |
| `app/lib/ink/ink.dart` | `app/lib/domain/ink/`로 이동. `InkPoint` 확장, `PenStyle` 전체 옵션 | 1 |
| `app/lib/hangul/hangul.dart` | `app/lib/domain/hangul/`로 이동 | 1 |
| `app/lib/hangul/composer.dart` | `app/lib/domain/compose/`로 이동. 획 입력 전용, `ComposerMetrics`는 `RuleV1Params`(규칙 v1 상수 묶음, `ruleVersion`의 일부)로 이름을 바꿔 남김, `dependencies`는 정적 메서드로 추가. v0 경로와 PoC `BaseGlyph`는 삭제 | 1 |
| `app/lib/app/*` (font_session, memo_screen, base_glyph_screen, glyph_editor_screen) | 단계 1에서 삭제. 단계 4에서 §10 기준으로 새로 작성 | 1 |
| `app/lib/app/glyph_painter.dart` | `app/lib/ui/glyph_painter.dart`로 이동 | 1 |
| `app/lib/main.dart` | 단계 1에서 빈 화면 진입점으로 줄임. 단계 4에서 릴리스 진입점 작성 | 1, 4 |
| `app/lib/dev/fixture_glyphs.dart` | 삭제(나눔 펜 픽스처는 v0 전용) | 1 |
| `app/lib/dev/stroke_fixture.dart` | 양자화·`t` 추가 | 1 |
| `app/test/font/ttf_writer_test.dart` | 새 경로로 import 수정, `created` 인자 | 1 |
| `app/test/hangul/composer_test.dart` | `app/test/domain/compose/`로 옮겨 획 픽스처 + 규칙 v1로 다시 작성 | 1 |
| `app/test/hangul/pen_scale_experiment_test.dart` | `app/test/dev/`로 옮기고 `RuleV1Params`를 쓰도록 수정 | 1 |
| `app/assets/dev/*`(OFL.txt 포함) | 참고용으로 유지(코드에서 쓰지 않음). `pubspec.yaml` assets에서 뺀다 | 1 |
| `tools/*.py` | 유지 | — |
| `material_ui` 패키지 | Flutter 3.50 기본 Material 패키지이므로 유지 | — |

## 16. 대기 항목과 영향

### 16.1 G0 대기

| OQ | 항목 | 바뀔 수 있는 곳 |
| --- | --- | --- |
| OQ-03 | 온디바이스 빌드 경로·기기 간 해시 차이 | §6.3 기록 (PRD FR-04는 이미 허용) |
| OQ-03 | 파일 크기 → composite 채택 | §7.1 "단순 글리프만", §7.3 리더, §12 TS-12 비교 방법, §6.2 |
| OQ-08 | Apple Pencil 샘플링 | §5, `streamline` 변경 시 §3.1 펜 값과 `ruleVersion`(§6.3) |
| OQ-09 | iOS 폰트 설치 | §13.1 전체, §7.2 6단계 설치 버튼, FR-08 안내 문구 |
| OQ-10 | 메트릭·고정폭 | §2(저장 좌표의 의미 포함), §4.2, §6.2 조합 영역, §7.1 OS/2·win 값 |
| OQ-11 | 동적 폰트 빌드 시간·등록 누적(§8.1 기준값) | §8.1 실행 위치·층 구조(P-2) |
| OQ-11 | RISK-07 대체안 채택 | §8 전체(§8.1, §8.2, §8.4) |
| OQ-11 | iPad 음절 고르기 | §8.4 |
| OQ-13 | 성능 수치(조합·빌드·내보내기) | §6.4, §7.2 진행 표시, §6.5 캐시 크기, NFR-02 |

### 16.2 G1 대기

| OQ | 항목 | 바뀔 수 있는 곳 |
| --- | --- | --- |
| OQ-01 | 필수·보강 구성, 위치 변형 | §3.2 세트 표, §6.2, §10 입력 순서, 역할 키 문법 |
| OQ-01, OQ-02 | 실제 손글씨로 펜 값 | §3.1 펜 표, `ruleVersion` |
| OQ-04 | 영문·숫자·기호 | §8.2, §7.1 cmap 범위 |
| OQ-05 | 빈도 데이터 | §14 |
| OQ-06 | 실행 취소 시간, 수정 이력 화면 | §9.1, §10 |
| OQ-07 | 스키마 | §4 |
| OQ-12 | 규칙 변경 적용 방식 | §6.3 `rule_version`의 쓰임, 여러 규칙 버전 포함 여부 |

## 17. 대안 검토

설계 대안 P-1~P-4는 v0.1.0 리뷰에서 나온 것이다: **P-1** 자모 composite 글리프(자모·자리 단위 윤곽을 재사용해 파일 크기·시간 절감), **P-2** 메모 폰트 층 구조(프로젝트 기본층 + 새 글자 증분층 + 편집 덮어쓰기층을 `fontFamilyFallback`으로 연결), **P-3** 프로젝트 단위 SQLite 백업 파일, **P-4** 프로젝트별 장수 조합 워커 isolate.

| 결정 | 채택 | 기각한 대안과 이유 |
| --- | --- | --- |
| 디렉터리(§1.2) | 4계층 | 기능별 폴더: 도메인을 isolate·테스트에서 Flutter 없이 쓰기 어려움 |
| 기본 글리프 저장 | 획만 | 윤곽선도 저장: 기본 글리프 윤곽선은 조합에 쓰지 않고, 규칙 변경 때 불일치 원인이 됨 |
| 커스텀 저장 | 획 + 윤곽선 | 획만: 앱 업데이트로 펜이 바뀌면 사용자가 그린 글자 모양이 바뀜(POL-07) |
| 역할 키 | 불투명 문자열 | 자모 1자 고정: 위치 변형 도입 때 DB·백업 형식 변경 필요 |
| 획 정밀도 | f32 저장 + 입력 즉시 f32 양자화 | f64 저장: 크기 2배. 양자화 없이 f32 저장: 저장 전후 조합 결과가 달라짐 |
| 기기 간 결정성 | 같은 기기만 보장 | 고정 소수점 자체 펜 구현: 비용 큼, 기기 간 이동은 백업 가져오기뿐(사용자 결정) |
| 저장 형식 | 자체 HWS1/HWO1 | JSON: 크기 수 배. protobuf 등: 의존성 추가 |
| 쓰기 직렬화 | Drift 단일 연결 + 대상별 대기 목록 | 전역 쓰기 큐: 실패한 메모 재시도가 글리프 저장·내보내기를 막음 |
| 화면 기준 | 커밋된 DB(메모 텍스트 제외) | 메모리 + DB 덧씌우기: 내보내기와 화면 불일치, 재시도 순서 문제 |
| 수정 이력 보호 | 트리거 + 가드 | 코드 규칙 + 행 수 테스트만: 테스트하지 않은 경로까지 막지는 못함 |
| 메모 삭제 | 즉시 삭제 + 메모리 보관 | 소프트 삭제 + 24시간 정리: 실행 취소가 5초인데 보관이 길고, 모든 조회에 조건이 필요 |
| 조합 캐시 무효화 | 기본 글리프가 바뀌면 전체 | 의존 집합으로 선택 무효화: 기본 글리프 편집이 드물어 이득 작음 |
| 기기 안 TTF 검증 | 자체 최소 리더 | `fontations` 읽기: Android에 Rust 도구 필요(tech-stack.md) |
| 겹침 처리 | OVERLAP_SIMPLE 플래그 | `clipper2` 합집합: 0.0.x 버전, 조합 시간 증가. TS-M1에서 Windows 렌더링에 겹침 자국이 보이면 재검토 |
| 메모 폰트 범위 | 열린 메모 글자 | 모든 메모 글자: 편집마다 수천 자 재빌드. KS X 1001 미리 담기(PRD RISK-07 완화책): 2,350자 빌드·등록이 메모를 열 때마다 생겨 첫 표시가 늦어짐. P-2: §8.1 측정 기준을 넘으면 채택 |
| 자동 생성 글리프 출력 | 단순 글리프 | P-1: 빌더·리더·검증 범위가 늘어남. iPad 내보내기 > 10초 또는 TTF > 10MB면 채택 `[G0 대기: OQ-03, OQ-13]` |
| 백업 형식 | ZIP + JSON + 바이너리 | P-3: 형식 정의는 줄지만 신뢰할 수 없는 SQLite 파싱 공격 면이 생김 |
| 조합 작업 위치 | UI isolate(메모) + 내보내기 isolate | P-4: §8.1 측정 기준을 넘고 P-2로도 부족하면 |
| 내보내기 중 백그라운드 | 계산을 버리지 않음 | iOS 백그라운드 작업으로 유예 후 폐기: 네이티브 코드가 늘고 결과 시트를 보던 중에도 버려짐 |
| 한글 정규화 | 현대 첫가끝 → 완성형만 | 전체 NFC 패키지: MVP에서 비한글은 사용자 폰트로 표시되지 않아 이득 없음(사용자 결정) |
| 필수 입력 순서 | 자음 → 단모음 → 복합 모음 | 자모 섞기: 미리보기를 MVP에서 뺐으므로(사용자 결정) 섞을 이유가 없음 |
| 버전 999 이후 | 이름 변경 시 0으로 | 2.000으로 넘기기: name ID 5 형식(`x.yyy`)과 `fontRevision` 해석이 어긋남 |
| 개발 자산 격리 | 자산 목록에서 빼고 테스트가 파일로 읽음 | flavor별 자산: 빌드 구성이 늘어남 |

## 18. 위험과 완화

| 위험 | 영향 | 완화 | PRD |
| --- | --- | --- | --- |
| 등록 폰트 누적·빌드 지연 | 긴 세션에서 iPad 메모리 경고, 입력 지연 | 열린 메모 범위, §8.1 기준값으로 측정 후 P-2 | RISK-07 |
| 백업 압축 폭탄·악성 파일 | 앱 종료, 데이터 손상 | §11.3 스트리밍·항목 상한·압축률·의미 검증, 새 프로젝트로만 | RISK-08 |
| 실행 취소 슬롯이 하나뿐 | 이전 동작 되돌리기 불가 | 수정 이력에서 수정본 지정으로 복구 가능 | — |
| 기기 간 자동 생성 차이 `[G0 대기: OQ-03]` | 백업 이동 후 미세한 모양 차이 | 허용, G0에서 측정 기록 | — |
| 온디바이스 빌드 성능 | 내보내기 지연 | isolate, 진행 표시, P-1 | RISK-01 |
| iOS 설치 불가·심사 거절 | iOS 인수 경로 축소 | §13.1을 공유만으로 축소 | RISK-05 |
| 초안 고아 행 | 저장 공간 낭비 | 프로젝트 삭제 CASCADE, 저장·버리기·획 0개 때 삭제 | — |
| Android 자동 백업 25MB 한도 | 큰 프로젝트가 OS 백업에서 빠짐 | FR-09 백업 파일 안내 | RISK-03 |
| 조합 품질 부족 | 사용자가 너무 많이 직접 수정 | 보강 기본 글리프, 메모에서 바로 고치기 | RISK-02 |
| 빈도 데이터 라이선스 | 목록 품질 | KS X 1001 대체 | RISK-04 |
| 스키마·규칙 변경 | 기존 프로젝트 손상 | 마이그레이션 픽스처, 해시 골든, 커스텀 윤곽 저장 | RISK-06 |

## 19. PRD 반영 필요 항목

| Spec | 결정 | PRD 위치 | 상태 |
| --- | --- | --- | --- |
| §3.2 | 기본 글리프는 윤곽선을 저장하지 않음, 커스텀 수정본은 펜 값 기록 | §5 | v0.4.1 반영 |
| §6.3 | 같은 기기 안에서만 앱 표시 = TTF 보장 | FR-04 | v0.4.1 반영 |
| §8.3 | NFC 대신 한글 정규화, 조합 중 미적용 | FR-07 | v0.4.1 반영 |
| §7.2 | "내보내기 전" = 파일 저장·공유·설치 전 결과 시트 | FR-08 | v0.4.1 반영 |
| §3.2 | 입력 상한(획 200, 점 20,000, 메모 100,000자) | FR-02, FR-07 | 반영 필요 (G1) |
| §7.4 | 버전 999 이후 이름 변경 시 1.001부터 | FR-08 | 반영 필요 (G1) |
| §4.4 | 초안을 묻지 않고 이어서 열기 | FR-01 | 반영 필요 (G1) |
| §10 | 필수 기본 글리프 입력 순서(건너뛰기 가능) | FR-03 | 반영 필요 (G1) |
| §17 | RISK-07 완화책 중 KS X 1001 미리 담기 미채택 | RISK-07 | 반영 필요 (G1) |

## 20. 구현 단계

각 단계는 `flutter analyze`와 `flutter test`가 통과하는 상태로 끝난다.

**도구 결정** `[Spec 결정]`: Riverpod 3(코드 생성 없음), Drift 스키마는 `.drift` 파일, 코드 생성은 `build_runner`(Drift만).

**패키지** (현재 해석되는 버전, 단계 시작 시 `pubspec.yaml`에 정확한 버전으로 고정):

| 패키지 | 버전 | 단계 |
| --- | --- | --- |
| `perfect_freehand` | 2.5.2+1 | 1 |
| `crypto` | 3.0.8 | 1 |
| `drift` / `drift_flutter` | 2.35.4 / 0.3.1 | 2 |
| `drift_dev`, `build_runner` (dev) | 2.35.3, 2.17.1 | 2 |
| `uuid` | 4.6.0 | 2 |
| `flutter_riverpod` | 3.5.0 | 3 |
| `path_provider`, `share_plus` | 2.1.6, 13.3.1 | 5 |
| `file_picker` | 13.4.0 | 5 |
| `archive` | 4.7.1 | 6 |

| 단계 | 만들 파일 | 고칠·옮길 파일 | 지울 파일 | 통과 기준 |
| --- | --- | --- | --- | --- |
| 1 도메인 | `domain/font/metrics.dart`, `domain/font/ttf_reader.dart`, `domain/glyph/hwo1.dart`, `domain/ink/hws1.dart`, `domain/ink/quantize.dart`, `domain/hangul/normalize.dart`, `domain/decode_error.dart`, `test/golden/compose_v1.sha256`, `test/domain/**`, `test/support/tools.dart`, `tools/check_dev_imports.sh` | §15 단계 1 행 전부, `pubspec.yaml`(perfect_freehand·crypto 고정, dev 자산 제거) | `lib/app/*`, `lib/dev/fixture_glyphs.dart` | 단위, 해시 골든(TS-12) — 완료 |
| 2 저장소 | `infra/db/schema.drift`, `infra/db/database.dart`(+ 생성 파일, 커밋함), `infra/db/{project,glyph,memo}_dao.dart`, `domain/hangul/base_set.dart`, `domain/font/naming.dart`, `state/pending_writes.dart`, `test/infra/db/**`, `test/state/pending_writes_test.dart`, `test/support/db.dart`, `drift_schemas/drift_schema_v1.json` | `pubspec.yaml`(drift, drift_flutter, sqlite3, uuid; dev: drift_dev, build_runner, fake_async) | — | TS-02, TS-04, TS-05(DAO), TS-06, TS-07, TS-15, TS-16, TS-20 — 완료 |
| 3 상태 | `domain/project/snapshot.dart`(스냅샷, 유효 글리프, LRU 캐시), `state/providers.dart`, `state/snapshot.dart`(스냅샷·렌더러 provider), `state/glyph_actions.dart`(쓰기 동작, 실행 취소), `test/state/glyph_state_test.dart` | `pubspec.yaml`(flutter_riverpod), `infra/db/glyph_dao.dart`(`GlyphSelection`을 도메인으로) | — | TS-01, TS-05 — 완료 |
| 4 화면 | `ui/{app,project_screens,base_glyph_screen,glyph_editor_screen,memo_screen,memo_text,custom_glyph_flow}.dart`, `state/{memo_font,projects}.dart`, `infra/platform/dynamic_font.dart`, `main.dart`, `main_dev.dart`, `test/ui/memo_screen_test.dart` | `ui/glyph_painter.dart`, `domain/compose/composer.dart`(`guideSlotFor`) | — | TS-09, TS-10, TS-11, TS-19 — 완료. 빈도순 목록은 단계 7 |
| 5 내보내기 | `domain/font/export.dart`(전체 계산·빌드·검증), `state/export_job.dart`(isolate 진행률, .part → 검증 → 커밋 → 이름 바꾸기, 최근 3개 보관), `infra/platform/files.dart`, `ui/export_screen.dart`, `test/state/export_job_test.dart`, `integration_test/app_flow_test.dart`, `.github/workflows/ci.yml` | `pubspec.yaml`(file_picker, integration_test), macOS 엔타이틀먼트(사용자 선택 파일 읽기·쓰기) | — | TS-03, TS-08, TS-13, TS-14 — 완료. TS-M1, TS-M2는 수동 |
| 6 백업 | `infra/backup/backup.dart`(형식·만들기·검사·가져오기), `state/backup_actions.dart`, `app_info.dart`, `test/infra/backup_test.dart`(악성 파일은 테스트 안에서 만든다), `test/state/backup_actions_test.dart` | `pubspec.yaml`(archive), `infra/platform/files.dart`(백업 고르기), `ui/project_screens.dart`(가져오기·백업 만들기) | — | TS-17, TS-18 — 완료 |
| 7 빈도 | `domain/hangul/frequency.dart`, `state/frequency.dart`, `ui/frequency_screen.dart`, `tools/make_ksx1001.py`, `assets/frequency/ksx1001.txt`, `test/domain/hangul/frequency_test.dart`, `test/ui/frequency_screen_test.dart` | `pubspec.yaml`(assets), `ui/export_screen.dart`(제외 목록 빈도순), `ui/project_screens.dart`(진입점) | — | 단위, 위젯 — 완료. `syllables.txt`는 OQ-05 해소 후 추가 |
| 8 iOS 설치 `[G0 대기: OQ-09]` | `ios/Runner/FontInstaller.swift`, `infra/platform/font_installer.dart`, `android/app/src/main/res/xml/data_extraction_rules.xml` | `ios/Runner/Runner.entitlements`, `AndroidManifest.xml` | — | TS-M3, TS-M4 |

경로는 `app/lib/`, `app/test/` 등 `app/` 아래 기준이다(표 공간 때문에 `app/lib/`를 생략).

## 부록 A. PRD 추적표

| PRD ID | Spec | 비고 |
| --- | --- | --- |
| GOAL-01~07 | 해당 FR을 통해 | |
| SM-01~04 | §6.4, §10, §16 | 수치는 OQ-13 |
| FR-01 | §4, §10 | |
| FR-02 | §3.2 입력 상한, §5 | |
| FR-03 | §3.2, §10 | |
| FR-04 | §3.3, §6 | |
| FR-05 | §3.2, §4.1, §9.1, §10 | |
| FR-06 | §10.1, §14 | |
| FR-07 | §8, §9.2 | |
| FR-08 | §7, §13 | |
| FR-09 | §11, §13.2 | |
| POL-01 | §4.1 트리거, §12 | |
| POL-02 | §3.3, §6 | |
| POL-03 | §4.3, §9.1 | |
| POL-04 | §7.2(모든 음절 포함) | |
| POL-05 | §4.3, §7.2 | |
| POL-06 | §7.2 | |
| POL-07 | §3.2, §6.3 | |
| POL-08 | §6.3 | OQ-12 대기 |
| NFR-01 | §12 | |
| NFR-02 | §6.4, §8.1 | OQ-13 대기 |
| NFR-03 | §5, §13 | 주 대상 iPad, 그 외 동작 지원 |
| NFR-04 | §1.1, §4.5, §13.3 | |
| NFR-05 | §1.1 | 네트워크 권한 없음 |
| NFR-06 | §8.2 | 색 + 점선 밑줄 |
| OQ-01~13 | §16 | |
| RISK-01~08 | §18 | RISK-06은 "스키마·규칙 변경" 행 |
| TS-01~20 | §12 | |
| TS-M1~4 | §12, §20 | |

## 변경 이력

| 버전 | 날짜 | 내용 |
| --- | --- | --- |
| v0.1.0 | 2026-11-19 | 최초 초안. PRD v0.4.0과 G0 1~3회차 기반 |
| v0.2.0 | 2026-11-19 | v0.1.0 EGM 리뷰 반영. 획 f32 양자화와 기울기 저장, 쓰기 큐와 "화면 기준 = 커밋된 DB", 비교 후 교체 실행 취소, 백업 형식 JSON 스키마와 스트리밍 가져오기 검증, `drafts` DDL, 복합 외래 키와 수정본 삭제 트리거, 내보내기 원자성, `ruleVersion` 정의와 해시 골든, 한글 정규화, 메모 폰트 revision 기준·열린 메모 범위, 손바닥 방지, Android 저장·가져오기, iOS 설치 경로, 대안·위험·PRD 반영·구현 단계·추적표. 10자 미리보기 삭제 |
| v0.3.0 | 2026-11-19 | v0.2.0 EGM 리뷰 반영. 전역 쓰기 큐 대신 Drift 직렬화 + 대상별 대기 목록, 모든 쓰기 실패를 알리고 자동 재시도(FR-01), `glyph_revision`·`base_revision` 열, 쓰기 표 보완, `revision_guard` 한 행 강제, 입력 상한과 그에서 도출한 백업 상한·압축률 검사, 백업 이름 정규식·역할 키 16진 파일명·메모 id 규칙, 규칙 v1의 PoC 변경점(컨투어 순서, 단독 자모 펜, 오류 판정, 퇴화 범위) 명시, `PenStyle` easing, 편집 표시 펜 = 저장 펜 56, 양자화 위치, 해시 골든 정의, 내보내기 백그라운드 처리 단순화, 메모 폰트 전환 기준값, 단계별 파일·패키지 버전·도구 결정, PoC 파일 처리 |
