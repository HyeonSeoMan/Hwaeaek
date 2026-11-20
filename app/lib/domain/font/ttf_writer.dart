/// 순수 Dart TrueType(`glyf`) 폰트 작성기.
///
/// Spec §7.1, tech-stack.md 3장 C안. 단순 글리프(composite 없음)만 쓰며, 모든 코드포인트는
/// BMP 안에 있다고 가정한다(한글 음절·호환 자모·ASCII).
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../glyph/glyph.dart';
import 'metrics.dart';
import 'naming.dart';

class FontGlyph {
  const FontGlyph(this.outline, this.advanceWidth) : parts = null;

  /// 부품 참조 글리프(composite). [outline]은 부품을 합친 윤곽선으로, 메트릭
  /// 계산에만 쓴다. [parts]는 [FontSpec.parts]의 인덱스이며 오프셋 0으로 놓는다.
  const FontGlyph.composite(
    this.outline,
    this.advanceWidth,
    List<int> this.parts,
  );

  final GlyphOutline outline;
  final int advanceWidth;
  final List<int>? parts;
}

class FontSpec {
  FontSpec({
    required this.familyName,
    required this.asciiFamilyName,
    required this.glyphs,
    this.styleName = 'Regular',
    this.versionMajor = 1,
    this.versionMinor = 0,
    required this.created,
    this.parts = const [],
    this.unitsPerEm = FontMetrics.unitsPerEm,
    this.ascender = FontMetrics.ascender,
    this.descender = FontMetrics.descender,
    this.lineGap = FontMetrics.lineGap,
    this.vendorId = 'HWAE',
    this.license = '',
    FontGlyph? notdef,
  }) : notdef = notdef ?? _defaultNotdef(unitsPerEm, ascender);

  /// 사용자에게 보이는 이름. 한글 가능.
  final String familyName;

  /// name ID 1/4/6 등에 쓰는 ASCII 이름.
  final String asciiFamilyName;
  final String styleName;
  final int versionMajor;
  final int versionMinor;
  final int unitsPerEm;
  final int ascender;
  final int descender;
  final int lineGap;
  final String vendorId;
  final String license;

  /// 코드포인트 → 글리프. 공백(U+0020)이 없으면 자동으로 추가한다.
  final Map<int, FontGlyph> glyphs;

  /// cmap에 없는 부품 글리프. 부품 참조 글리프가 인덱스로 가리킨다.
  final List<GlyphOutline> parts;
  final FontGlyph notdef;

  /// head.created/modified. 내보내기는 내보내기 시각, 메모 폰트는
  /// [FontMetrics.fixedCreated].
  final DateTime created;

  String get versionString =>
      'Version $versionMajor.${versionMinor.toString().padLeft(3, '0')}';

  static FontGlyph _defaultNotdef(int upm, int ascender) {
    final w = upm ~/ 2;
    final top = (ascender * 0.8).round();
    final m = upm ~/ 20;
    return FontGlyph(
      GlyphOutline([
        [
          GlyphPoint(m, 0),
          GlyphPoint(m, top),
          GlyphPoint(w - m, top),
          GlyphPoint(w - m, 0),
        ],
        [
          GlyphPoint(2 * m, m),
          GlyphPoint(w - 2 * m, m),
          GlyphPoint(w - 2 * m, top - m),
          GlyphPoint(2 * m, top - m),
        ],
      ]),
      w,
    );
  }
}

Uint8List buildTtf(FontSpec spec) => _TtfBuilder(spec).build();

class _TtfBuilder {
  _TtfBuilder(this.spec) {
    final map = Map<int, FontGlyph>.of(spec.glyphs);
    map.putIfAbsent(
      0x20,
      () => const FontGlyph(GlyphOutline.empty, FontMetrics.spaceAdvance),
    );
    codePoints = map.keys.toList()..sort();
    for (final cp in codePoints) {
      if (cp < 0 || cp > 0xFFFE) {
        throw ArgumentError('BMP 밖 코드포인트는 지원하지 않는다: $cp');
      }
    }
    glyphs = [
      spec.notdef,
      for (final cp in codePoints) map[cp]!,
      for (final part in spec.parts) FontGlyph(part, 0),
    ];
    partBase = 1 + codePoints.length;
  }

  final FontSpec spec;
  late final List<int> codePoints;

  /// 글리프 순서: 0 = .notdef, 이후 코드포인트 오름차순.
  late final List<FontGlyph> glyphs;

  /// 첫 부품 글리프의 ID.
  late final int partBase;

  Uint8List build() {
    final glyf = _GlyfData.encode(glyphs, partBase);
    final tables = <String, Uint8List>{
      'OS/2': _os2(),
      'cmap': _cmap(),
      'glyf': glyf.glyf,
      'head': _head(glyf.indexToLocFormat),
      'hhea': _hhea(),
      'hmtx': _hmtx(),
      'loca': glyf.loca,
      'maxp': _maxp(),
      'name': _name(),
      'post': _post(),
    };
    return _assemble(tables);
  }

  Bounds get _fontBounds {
    Bounds? b;
    for (final g in glyphs) {
      final gb = g.outline.bounds;
      if (gb != null) b = b == null ? gb : b.union(gb);
    }
    return b ?? const Bounds(0, 0, 0, 0);
  }

  Uint8List _head(int indexToLocFormat) {
    final b = _fontBounds;
    final w = _Writer()
      ..u32(0x00010000)
      ..u32(_fixed(spec.versionMajor + spec.versionMinor / 1000))
      ..u32(0) // checkSumAdjustment: 조립 후 채운다.
      ..u32(0x5F0F3CF5)
      ..u16(0x000B) // baseline y=0, lsb x=0, 정수 ppem
      ..u16(spec.unitsPerEm)
      ..i64(_longDateTime(spec.created))
      ..i64(_longDateTime(spec.created))
      ..i16(b.xMin)
      ..i16(b.yMin)
      ..i16(b.xMax)
      ..i16(b.yMax)
      ..u16(0) // macStyle
      ..u16(8) // lowestRecPPEM
      ..i16(2) // fontDirectionHint
      ..i16(indexToLocFormat)
      ..i16(0);
    return w.bytes;
  }

  Uint8List _hhea() {
    var advanceMax = 0;
    int? minLsb, minRsb, xMaxExtent;
    for (final g in glyphs) {
      advanceMax = math.max(advanceMax, g.advanceWidth);
      final b = g.outline.bounds;
      if (b == null) continue;
      minLsb = math.min(minLsb ?? b.xMin, b.xMin);
      final rsb = g.advanceWidth - b.xMax;
      minRsb = math.min(minRsb ?? rsb, rsb);
      xMaxExtent = math.max(xMaxExtent ?? b.xMax, b.xMax);
    }
    final w = _Writer()
      ..u32(0x00010000)
      ..i16(spec.ascender)
      ..i16(spec.descender)
      ..i16(spec.lineGap)
      ..u16(advanceMax)
      ..i16(minLsb ?? 0)
      ..i16(minRsb ?? 0)
      ..i16(xMaxExtent ?? 0)
      ..i16(1) // caretSlopeRise
      ..i16(0)
      ..i16(0)
      ..i16(0)
      ..i16(0)
      ..i16(0)
      ..i16(0)
      ..i16(0) // metricDataFormat
      ..u16(glyphs.length);
    return w.bytes;
  }

  Uint8List _hmtx() {
    final w = _Writer();
    for (final g in glyphs) {
      w
        ..u16(g.advanceWidth)
        ..i16(g.outline.bounds?.xMin ?? 0);
    }
    return w.bytes;
  }

  Uint8List _maxp() {
    var maxPoints = 0, maxContours = 0;
    var maxCompositePoints = 0, maxCompositeContours = 0, maxComponents = 0;
    for (final g in glyphs) {
      if (g.parts case final parts?) {
        maxCompositePoints = math.max(maxCompositePoints, g.outline.pointCount);
        maxCompositeContours = math.max(
          maxCompositeContours,
          g.outline.contours.length,
        );
        maxComponents = math.max(maxComponents, parts.length);
      } else {
        maxPoints = math.max(maxPoints, g.outline.pointCount);
        maxContours = math.max(maxContours, g.outline.contours.length);
      }
    }
    final w = _Writer()
      ..u32(0x00010000)
      ..u16(glyphs.length)
      ..u16(maxPoints)
      ..u16(maxContours)
      ..u16(maxCompositePoints)
      ..u16(maxCompositeContours)
      ..u16(2) // maxZones
      ..u16(0) // maxTwilightPoints
      ..u16(0) // maxStorage
      ..u16(0) // maxFunctionDefs
      ..u16(0) // maxInstructionDefs
      ..u16(0) // maxStackElements
      ..u16(0) // maxSizeOfInstructions
      ..u16(maxComponents)
      ..u16(maxComponents == 0 ? 0 : 1); // maxComponentDepth
    return w.bytes;
  }

  Uint8List _os2() {
    final b = _fontBounds;
    final advances = glyphs.map((g) => g.advanceWidth).where((a) => a > 0);
    final avg = advances.isEmpty
        ? 0
        : (advances.reduce((a, c) => a + c) / advances.length).round();

    var unicode1 = 0, unicode2 = 0, codePage1 = 0;
    for (final cp in codePoints) {
      if (cp <= 0x7F) unicode1 |= 1; // bit 0 Basic Latin
      if (cp >= 0x80 && cp <= 0xFF) unicode1 |= 1 << 1; // Latin-1 Supplement
      if (cp >= 0x2000 && cp <= 0x206F) {
        unicode1 |= 1 << 31; // General Punctuation
      }
      if ((cp >= 0x41 && cp <= 0x5A) || (cp >= 0x61 && cp <= 0x7A)) {
        codePage1 |= 1; // Latin 1
      }
      if (cp >= 0x3130 && cp <= 0x318F) unicode2 |= 1 << (52 - 32);
      if (cp >= 0xAC00 && cp <= 0xD7AF) {
        unicode2 |= 1 << (56 - 32);
        codePage1 |= 1 << 19; // Korean Wansung
      }
    }

    final upm = spec.unitsPerEm;
    final w = _Writer()
      ..u16(4)
      ..i16(avg)
      ..u16(400)
      ..u16(5)
      ..u16(0) // fsType: 설치 가능
      ..i16(upm * 65 ~/ 100)
      ..i16(upm * 60 ~/ 100)
      ..i16(0)
      ..i16(upm * 7 ~/ 100)
      ..i16(upm * 65 ~/ 100)
      ..i16(upm * 60 ~/ 100)
      ..i16(0)
      ..i16(upm * 35 ~/ 100)
      ..i16(upm * 5 ~/ 100)
      ..i16(upm * 30 ~/ 100)
      ..i16(0); // sFamilyClass
    for (var i = 0; i < 10; i++) {
      w.u8(0); // panose
    }
    w
      ..u32(unicode1)
      ..u32(unicode2)
      ..u32(0)
      ..u32(0)
      ..raw(ascii.encode(spec.vendorId.padRight(4).substring(0, 4)))
      ..u16(0x40 | 0x80) // REGULAR | USE_TYPO_METRICS
      ..u16(codePoints.first)
      ..u16(codePoints.last)
      ..i16(spec.ascender)
      ..i16(spec.descender)
      ..i16(spec.lineGap)
      ..u16(math.max(spec.ascender, b.yMax))
      ..u16(math.max(-spec.descender, -b.yMin))
      ..u32(codePage1)
      ..u32(0)
      ..i16(upm ~/ 2)
      ..i16(upm * 7 ~/ 10)
      ..u16(0)
      ..u16(0x20)
      ..u16(0);
    return w.bytes;
  }

  Uint8List _cmap() {
    // 코드포인트와 글리프 ID가 함께 연속인 구간을 하나의 세그먼트로 묶는다.
    final segments = <(int, int, int)>[]; // (start, end, delta)
    for (var i = 0; i < codePoints.length; i++) {
      final cp = codePoints[i];
      final gid = i + 1;
      if (segments.isNotEmpty) {
        final (start, end, delta) = segments.last;
        if (end + 1 == cp && (cp + delta) & 0xFFFF == gid) {
          segments[segments.length - 1] = (start, cp, delta);
          continue;
        }
      }
      segments.add((cp, cp, (gid - cp) & 0xFFFF));
    }
    segments.add((0xFFFF, 0xFFFF, 1));

    final segCount = segments.length;
    final searchRange = 2 * _highestPowerOf2(segCount);
    final sub = _Writer()
      ..u16(4)
      ..u16(16 + segCount * 8)
      ..u16(0)
      ..u16(segCount * 2)
      ..u16(searchRange)
      ..u16(_log2(searchRange ~/ 2))
      ..u16(segCount * 2 - searchRange);
    for (final s in segments) {
      sub.u16(s.$2);
    }
    sub.u16(0);
    for (final s in segments) {
      sub.u16(s.$1);
    }
    for (final s in segments) {
      sub.u16(s.$3);
    }
    for (var i = 0; i < segCount; i++) {
      sub.u16(0); // idRangeOffset
    }

    const offset = 4 + 8 * 2;
    final w = _Writer()
      ..u16(0)
      ..u16(2)
      ..u16(0) // Unicode
      ..u16(3) // BMP
      ..u32(offset)
      ..u16(3) // Windows
      ..u16(1) // Unicode BMP
      ..u32(offset)
      ..raw(sub.bytes);
    return w.bytes;
  }

  Uint8List _name() {
    const en = 0x0409, ko = 0x0412;
    final ascii = spec.asciiFamilyName;
    final ps = postScriptName('$ascii-${spec.styleName}');
    final records = <(int, int, String)>[
      // (languageID, nameID, value)
      if (spec.license.isNotEmpty) (en, 0, spec.license),
      (en, 1, ascii),
      (en, 2, spec.styleName),
      (en, 3, '$ps;${spec.versionString}'),
      (en, 4, ascii),
      (en, 5, spec.versionString),
      (en, 6, ps),
      if (spec.familyName != ascii) ...[
        (ko, 1, spec.familyName),
        (ko, 4, spec.familyName),
      ],
    ]..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);

    final strings = _Writer();
    final header = _Writer()
      ..u16(0)
      ..u16(records.length)
      ..u16(6 + 12 * records.length);
    for (final (lang, id, value) in records) {
      final encoded = _utf16be(value);
      header
        ..u16(3)
        ..u16(1)
        ..u16(lang)
        ..u16(id)
        ..u16(encoded.length)
        ..u16(strings.length);
      strings.raw(encoded);
    }
    return (header..raw(strings.bytes)).bytes;
  }

  Uint8List _post() {
    final w = _Writer()
      ..u32(0x00030000)
      ..u32(0)
      ..i16(-(spec.unitsPerEm ~/ 10))
      ..i16(spec.unitsPerEm ~/ 20)
      ..u32(0)
      ..u32(0)
      ..u32(0)
      ..u32(0)
      ..u32(0);
    return w.bytes;
  }

  static Uint8List _assemble(Map<String, Uint8List> tables) {
    final tags = tables.keys.toList()..sort();
    final numTables = tags.length;
    final searchRange = 16 * _highestPowerOf2(numTables);
    final header = _Writer()
      ..u32(0x00010000)
      ..u16(numTables)
      ..u16(searchRange)
      ..u16(_log2(searchRange ~/ 16))
      ..u16(numTables * 16 - searchRange);

    var offset = 12 + 16 * numTables;
    final body = _Writer();
    var headOffset = 0;
    for (final tag in tags) {
      final data = tables[tag]!;
      if (tag == 'head') headOffset = offset;
      header
        ..raw(ascii.encode(tag))
        ..u32(_checksum(data))
        ..u32(offset)
        ..u32(data.length);
      body.raw(data);
      body.pad4();
      offset += (data.length + 3) & ~3;
    }
    final font = (header..raw(body.bytes)).bytes;
    final adjustment = (0xB1B0AFBA - _checksum(font)) & 0xFFFFFFFF;
    ByteData.sublistView(font).setUint32(headOffset + 8, adjustment);
    return font;
  }
}

class _GlyfData {
  _GlyfData(this.glyf, this.loca, this.indexToLocFormat);

  final Uint8List glyf;
  final Uint8List loca;
  final int indexToLocFormat;

  static _GlyfData encode(List<FontGlyph> glyphs, int partBase) {
    final glyf = _Writer();
    final offsets = <int>[];
    for (final g in glyphs) {
      offsets.add(glyf.length);
      if (g.parts case final parts?) {
        glyf.raw(
          _compositeGlyph(g.outline, [for (final p in parts) partBase + p]),
        );
        glyf.pad4();
      } else if (!g.outline.isEmpty) {
        glyf.raw(_simpleGlyph(g.outline));
        glyf.pad4();
      }
    }
    offsets.add(glyf.length);

    final loca = _Writer();
    final short = offsets.last <= 0x1FFFE;
    for (final o in offsets) {
      short ? loca.u16(o ~/ 2) : loca.u32(o);
    }
    return _GlyfData(glyf.bytes, loca.bytes, short ? 0 : 1);
  }

  static const _onCurve = 0x01;
  static const _xShort = 0x02;
  static const _yShort = 0x04;
  static const _repeat = 0x08;
  static const _xSameOrPositive = 0x10;
  static const _ySameOrPositive = 0x20;
  static const _overlapSimple = 0x40;

  static const _argsAreXyValues = 0x0002;
  static const _moreComponents = 0x0020;
  static const _overlapCompound = 0x0400;

  /// 부품을 오프셋 0으로 겹쳐 놓는 composite 글리프.
  static Uint8List _compositeGlyph(GlyphOutline merged, List<int> glyphIds) {
    final b = merged.bounds!;
    final w = _Writer()
      ..i16(-1)
      ..i16(b.xMin)
      ..i16(b.yMin)
      ..i16(b.xMax)
      ..i16(b.yMax);
    for (final (i, id) in glyphIds.indexed) {
      var flags = _argsAreXyValues;
      if (i < glyphIds.length - 1) flags |= _moreComponents;
      // 부품끼리 겹치므로 렌더러에 알린다.
      if (i == 0) flags |= _overlapCompound;
      w
        ..u16(flags)
        ..u16(id)
        ..u8(0)
        ..u8(0);
    }
    return w.bytes;
  }

  static Uint8List _simpleGlyph(GlyphOutline outline) {
    final contours = outline.contours.where((c) => c.isNotEmpty).toList();
    final b = outline.bounds!;
    final w = _Writer()
      ..i16(contours.length)
      ..i16(b.xMin)
      ..i16(b.yMin)
      ..i16(b.xMax)
      ..i16(b.yMax);
    var end = -1;
    for (final c in contours) {
      end += c.length;
      w.u16(end);
    }
    w.u16(0); // instructionLength

    final flags = <int>[];
    final xs = _Writer();
    final ys = _Writer();
    var px = 0, py = 0;
    for (final c in contours) {
      for (final p in c) {
        var f = p.onCurve ? _onCurve : 0;
        f |= _coord(p.x - px, xs, _xShort, _xSameOrPositive);
        f |= _coord(p.y - py, ys, _yShort, _ySameOrPositive);
        flags.add(f);
        px = p.x;
        py = p.y;
      }
    }
    // 손글씨 획은 서로 겹치므로 렌더러에 겹침을 알린다.
    flags[0] |= _overlapSimple;

    for (var i = 0; i < flags.length;) {
      var run = 1;
      while (i + run < flags.length &&
          flags[i + run] == flags[i] &&
          run < 256) {
        run++;
      }
      if (run > 1) {
        w
          ..u8(flags[i] | _repeat)
          ..u8(run - 1);
      } else {
        w.u8(flags[i]);
      }
      i += run;
    }
    return (w
          ..raw(xs.bytes)
          ..raw(ys.bytes))
        .bytes;
  }

  static int _coord(int delta, _Writer out, int shortFlag, int sameFlag) {
    if (delta == 0) return sameFlag;
    if (delta.abs() <= 255) {
      out.u8(delta.abs());
      return shortFlag | (delta > 0 ? sameFlag : 0);
    }
    out.i16(delta);
    return 0;
  }
}

class _Writer {
  final _b = BytesBuilder(copy: false);
  final _tmp = ByteData(8);

  int get length => _b.length;
  Uint8List get bytes => _b.toBytes();

  void u8(int v) => _b.addByte(v & 0xFF);

  void u16(int v) {
    if (v < 0 || v > 0xFFFF) throw RangeError.value(v, 'uint16');
    _tmp.setUint16(0, v);
    _b.add(_tmp.buffer.asUint8List(0, 2).toList());
  }

  void i16(int v) {
    if (v < -32768 || v > 32767) throw RangeError.value(v, 'int16');
    _tmp.setInt16(0, v);
    _b.add(_tmp.buffer.asUint8List(0, 2).toList());
  }

  void u32(int v) {
    _tmp.setUint32(0, v & 0xFFFFFFFF);
    _b.add(_tmp.buffer.asUint8List(0, 4).toList());
  }

  void i64(int v) {
    _tmp.setInt64(0, v);
    _b.add(_tmp.buffer.asUint8List(0, 8).toList());
  }

  void raw(List<int> data) => _b.add(data);

  void pad4() {
    while (_b.length % 4 != 0) {
      _b.addByte(0);
    }
  }
}

int _checksum(Uint8List data) {
  var sum = 0;
  final padded = data.length % 4 == 0
      ? data
      : (Uint8List((data.length + 3) & ~3)..setAll(0, data));
  final view = ByteData.sublistView(padded);
  for (var i = 0; i < padded.length; i += 4) {
    sum = (sum + view.getUint32(i)) & 0xFFFFFFFF;
  }
  return sum;
}

int _fixed(double v) => (v * 65536).round();

int _longDateTime(DateTime t) =>
    t.toUtc().difference(DateTime.utc(1904)).inSeconds;

int _highestPowerOf2(int n) {
  var p = 1;
  while (p * 2 <= n) {
    p *= 2;
  }
  return p;
}

int _log2(int n) {
  var r = 0;
  while ((1 << (r + 1)) <= n) {
    r++;
  }
  return r;
}

Uint8List _utf16be(String s) {
  final w = _Writer();
  for (final unit in s.codeUnits) {
    w.u16(unit);
  }
  return w.bytes;
}
