// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class Projects extends Table with TableInfo<Projects, ProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Projects(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _baseSetVersionMeta = const VerificationMeta(
    'baseSetVersion',
  );
  late final GeneratedColumn<int> baseSetVersion = GeneratedColumn<int>(
    'base_set_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ruleVersionMeta = const VerificationMeta(
    'ruleVersion',
  );
  late final GeneratedColumn<int> ruleVersion = GeneratedColumn<int>(
    'rule_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _memoUnlockedAtMeta = const VerificationMeta(
    'memoUnlockedAt',
  );
  late final GeneratedColumn<int> memoUnlockedAt = GeneratedColumn<int>(
    'memo_unlocked_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _glyphRevisionMeta = const VerificationMeta(
    'glyphRevision',
  );
  late final GeneratedColumn<int> glyphRevision = GeneratedColumn<int>(
    'glyph_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _fontFamilyNameMeta = const VerificationMeta(
    'fontFamilyName',
  );
  late final GeneratedColumn<String> fontFamilyName = GeneratedColumn<String>(
    'font_family_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fontAsciiNameMeta = const VerificationMeta(
    'fontAsciiName',
  );
  late final GeneratedColumn<String> fontAsciiName = GeneratedColumn<String>(
    'font_ascii_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fontStyleNameMeta = const VerificationMeta(
    'fontStyleName',
  );
  late final GeneratedColumn<String> fontStyleName = GeneratedColumn<String>(
    'font_style_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'Regular\'',
    defaultValue: const CustomExpression('\'Regular\''),
  );
  static const VerificationMeta _fontVersionMinorMeta = const VerificationMeta(
    'fontVersionMinor',
  );
  late final GeneratedColumn<int> fontVersionMinor = GeneratedColumn<int>(
    'font_version_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (font_version_minor BETWEEN 0 AND 999)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _fontLicenseMeta = const VerificationMeta(
    'fontLicense',
  );
  late final GeneratedColumn<String> fontLicense = GeneratedColumn<String>(
    'font_license',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    baseSetVersion,
    ruleVersion,
    memoUnlockedAt,
    glyphRevision,
    baseRevision,
    fontFamilyName,
    fontAsciiName,
    fontStyleName,
    fontVersionMinor,
    fontLicense,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('base_set_version')) {
      context.handle(
        _baseSetVersionMeta,
        baseSetVersion.isAcceptableOrUnknown(
          data['base_set_version']!,
          _baseSetVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseSetVersionMeta);
    }
    if (data.containsKey('rule_version')) {
      context.handle(
        _ruleVersionMeta,
        ruleVersion.isAcceptableOrUnknown(
          data['rule_version']!,
          _ruleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionMeta);
    }
    if (data.containsKey('memo_unlocked_at')) {
      context.handle(
        _memoUnlockedAtMeta,
        memoUnlockedAt.isAcceptableOrUnknown(
          data['memo_unlocked_at']!,
          _memoUnlockedAtMeta,
        ),
      );
    }
    if (data.containsKey('glyph_revision')) {
      context.handle(
        _glyphRevisionMeta,
        glyphRevision.isAcceptableOrUnknown(
          data['glyph_revision']!,
          _glyphRevisionMeta,
        ),
      );
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('font_family_name')) {
      context.handle(
        _fontFamilyNameMeta,
        fontFamilyName.isAcceptableOrUnknown(
          data['font_family_name']!,
          _fontFamilyNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fontFamilyNameMeta);
    }
    if (data.containsKey('font_ascii_name')) {
      context.handle(
        _fontAsciiNameMeta,
        fontAsciiName.isAcceptableOrUnknown(
          data['font_ascii_name']!,
          _fontAsciiNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fontAsciiNameMeta);
    }
    if (data.containsKey('font_style_name')) {
      context.handle(
        _fontStyleNameMeta,
        fontStyleName.isAcceptableOrUnknown(
          data['font_style_name']!,
          _fontStyleNameMeta,
        ),
      );
    }
    if (data.containsKey('font_version_minor')) {
      context.handle(
        _fontVersionMinorMeta,
        fontVersionMinor.isAcceptableOrUnknown(
          data['font_version_minor']!,
          _fontVersionMinorMeta,
        ),
      );
    }
    if (data.containsKey('font_license')) {
      context.handle(
        _fontLicenseMeta,
        fontLicense.isAcceptableOrUnknown(
          data['font_license']!,
          _fontLicenseMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      baseSetVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_set_version'],
      )!,
      ruleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_version'],
      )!,
      memoUnlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}memo_unlocked_at'],
      ),
      glyphRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}glyph_revision'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      )!,
      fontFamilyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_family_name'],
      )!,
      fontAsciiName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_ascii_name'],
      )!,
      fontStyleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_style_name'],
      )!,
      fontVersionMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}font_version_minor'],
      )!,
      fontLicense: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_license'],
      )!,
    );
  }

  @override
  Projects createAlias(String alias) {
    return Projects(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ProjectRow extends DataClass implements Insertable<ProjectRow> {
  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  final int baseSetVersion;
  final int ruleVersion;
  final int? memoUnlockedAt;
  final int glyphRevision;
  final int baseRevision;
  final String fontFamilyName;
  final String fontAsciiName;
  final String fontStyleName;
  final int fontVersionMinor;
  final String fontLicense;
  const ProjectRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.baseSetVersion,
    required this.ruleVersion,
    this.memoUnlockedAt,
    required this.glyphRevision,
    required this.baseRevision,
    required this.fontFamilyName,
    required this.fontAsciiName,
    required this.fontStyleName,
    required this.fontVersionMinor,
    required this.fontLicense,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['base_set_version'] = Variable<int>(baseSetVersion);
    map['rule_version'] = Variable<int>(ruleVersion);
    if (!nullToAbsent || memoUnlockedAt != null) {
      map['memo_unlocked_at'] = Variable<int>(memoUnlockedAt);
    }
    map['glyph_revision'] = Variable<int>(glyphRevision);
    map['base_revision'] = Variable<int>(baseRevision);
    map['font_family_name'] = Variable<String>(fontFamilyName);
    map['font_ascii_name'] = Variable<String>(fontAsciiName);
    map['font_style_name'] = Variable<String>(fontStyleName);
    map['font_version_minor'] = Variable<int>(fontVersionMinor);
    map['font_license'] = Variable<String>(fontLicense);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      baseSetVersion: Value(baseSetVersion),
      ruleVersion: Value(ruleVersion),
      memoUnlockedAt: memoUnlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(memoUnlockedAt),
      glyphRevision: Value(glyphRevision),
      baseRevision: Value(baseRevision),
      fontFamilyName: Value(fontFamilyName),
      fontAsciiName: Value(fontAsciiName),
      fontStyleName: Value(fontStyleName),
      fontVersionMinor: Value(fontVersionMinor),
      fontLicense: Value(fontLicense),
    );
  }

  factory ProjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      baseSetVersion: serializer.fromJson<int>(json['base_set_version']),
      ruleVersion: serializer.fromJson<int>(json['rule_version']),
      memoUnlockedAt: serializer.fromJson<int?>(json['memo_unlocked_at']),
      glyphRevision: serializer.fromJson<int>(json['glyph_revision']),
      baseRevision: serializer.fromJson<int>(json['base_revision']),
      fontFamilyName: serializer.fromJson<String>(json['font_family_name']),
      fontAsciiName: serializer.fromJson<String>(json['font_ascii_name']),
      fontStyleName: serializer.fromJson<String>(json['font_style_name']),
      fontVersionMinor: serializer.fromJson<int>(json['font_version_minor']),
      fontLicense: serializer.fromJson<String>(json['font_license']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'base_set_version': serializer.toJson<int>(baseSetVersion),
      'rule_version': serializer.toJson<int>(ruleVersion),
      'memo_unlocked_at': serializer.toJson<int?>(memoUnlockedAt),
      'glyph_revision': serializer.toJson<int>(glyphRevision),
      'base_revision': serializer.toJson<int>(baseRevision),
      'font_family_name': serializer.toJson<String>(fontFamilyName),
      'font_ascii_name': serializer.toJson<String>(fontAsciiName),
      'font_style_name': serializer.toJson<String>(fontStyleName),
      'font_version_minor': serializer.toJson<int>(fontVersionMinor),
      'font_license': serializer.toJson<String>(fontLicense),
    };
  }

  ProjectRow copyWith({
    String? id,
    String? name,
    int? createdAt,
    int? updatedAt,
    int? baseSetVersion,
    int? ruleVersion,
    Value<int?> memoUnlockedAt = const Value.absent(),
    int? glyphRevision,
    int? baseRevision,
    String? fontFamilyName,
    String? fontAsciiName,
    String? fontStyleName,
    int? fontVersionMinor,
    String? fontLicense,
  }) => ProjectRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    baseSetVersion: baseSetVersion ?? this.baseSetVersion,
    ruleVersion: ruleVersion ?? this.ruleVersion,
    memoUnlockedAt: memoUnlockedAt.present
        ? memoUnlockedAt.value
        : this.memoUnlockedAt,
    glyphRevision: glyphRevision ?? this.glyphRevision,
    baseRevision: baseRevision ?? this.baseRevision,
    fontFamilyName: fontFamilyName ?? this.fontFamilyName,
    fontAsciiName: fontAsciiName ?? this.fontAsciiName,
    fontStyleName: fontStyleName ?? this.fontStyleName,
    fontVersionMinor: fontVersionMinor ?? this.fontVersionMinor,
    fontLicense: fontLicense ?? this.fontLicense,
  );
  ProjectRow copyWithCompanion(ProjectsCompanion data) {
    return ProjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      baseSetVersion: data.baseSetVersion.present
          ? data.baseSetVersion.value
          : this.baseSetVersion,
      ruleVersion: data.ruleVersion.present
          ? data.ruleVersion.value
          : this.ruleVersion,
      memoUnlockedAt: data.memoUnlockedAt.present
          ? data.memoUnlockedAt.value
          : this.memoUnlockedAt,
      glyphRevision: data.glyphRevision.present
          ? data.glyphRevision.value
          : this.glyphRevision,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      fontFamilyName: data.fontFamilyName.present
          ? data.fontFamilyName.value
          : this.fontFamilyName,
      fontAsciiName: data.fontAsciiName.present
          ? data.fontAsciiName.value
          : this.fontAsciiName,
      fontStyleName: data.fontStyleName.present
          ? data.fontStyleName.value
          : this.fontStyleName,
      fontVersionMinor: data.fontVersionMinor.present
          ? data.fontVersionMinor.value
          : this.fontVersionMinor,
      fontLicense: data.fontLicense.present
          ? data.fontLicense.value
          : this.fontLicense,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('baseSetVersion: $baseSetVersion, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('memoUnlockedAt: $memoUnlockedAt, ')
          ..write('glyphRevision: $glyphRevision, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('fontFamilyName: $fontFamilyName, ')
          ..write('fontAsciiName: $fontAsciiName, ')
          ..write('fontStyleName: $fontStyleName, ')
          ..write('fontVersionMinor: $fontVersionMinor, ')
          ..write('fontLicense: $fontLicense')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    updatedAt,
    baseSetVersion,
    ruleVersion,
    memoUnlockedAt,
    glyphRevision,
    baseRevision,
    fontFamilyName,
    fontAsciiName,
    fontStyleName,
    fontVersionMinor,
    fontLicense,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.baseSetVersion == this.baseSetVersion &&
          other.ruleVersion == this.ruleVersion &&
          other.memoUnlockedAt == this.memoUnlockedAt &&
          other.glyphRevision == this.glyphRevision &&
          other.baseRevision == this.baseRevision &&
          other.fontFamilyName == this.fontFamilyName &&
          other.fontAsciiName == this.fontAsciiName &&
          other.fontStyleName == this.fontStyleName &&
          other.fontVersionMinor == this.fontVersionMinor &&
          other.fontLicense == this.fontLicense);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> baseSetVersion;
  final Value<int> ruleVersion;
  final Value<int?> memoUnlockedAt;
  final Value<int> glyphRevision;
  final Value<int> baseRevision;
  final Value<String> fontFamilyName;
  final Value<String> fontAsciiName;
  final Value<String> fontStyleName;
  final Value<int> fontVersionMinor;
  final Value<String> fontLicense;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.baseSetVersion = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.memoUnlockedAt = const Value.absent(),
    this.glyphRevision = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.fontFamilyName = const Value.absent(),
    this.fontAsciiName = const Value.absent(),
    this.fontStyleName = const Value.absent(),
    this.fontVersionMinor = const Value.absent(),
    this.fontLicense = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    required int createdAt,
    required int updatedAt,
    required int baseSetVersion,
    required int ruleVersion,
    this.memoUnlockedAt = const Value.absent(),
    this.glyphRevision = const Value.absent(),
    this.baseRevision = const Value.absent(),
    required String fontFamilyName,
    required String fontAsciiName,
    this.fontStyleName = const Value.absent(),
    this.fontVersionMinor = const Value.absent(),
    this.fontLicense = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       baseSetVersion = Value(baseSetVersion),
       ruleVersion = Value(ruleVersion),
       fontFamilyName = Value(fontFamilyName),
       fontAsciiName = Value(fontAsciiName);
  static Insertable<ProjectRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? baseSetVersion,
    Expression<int>? ruleVersion,
    Expression<int>? memoUnlockedAt,
    Expression<int>? glyphRevision,
    Expression<int>? baseRevision,
    Expression<String>? fontFamilyName,
    Expression<String>? fontAsciiName,
    Expression<String>? fontStyleName,
    Expression<int>? fontVersionMinor,
    Expression<String>? fontLicense,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (baseSetVersion != null) 'base_set_version': baseSetVersion,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (memoUnlockedAt != null) 'memo_unlocked_at': memoUnlockedAt,
      if (glyphRevision != null) 'glyph_revision': glyphRevision,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (fontFamilyName != null) 'font_family_name': fontFamilyName,
      if (fontAsciiName != null) 'font_ascii_name': fontAsciiName,
      if (fontStyleName != null) 'font_style_name': fontStyleName,
      if (fontVersionMinor != null) 'font_version_minor': fontVersionMinor,
      if (fontLicense != null) 'font_license': fontLicense,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? baseSetVersion,
    Value<int>? ruleVersion,
    Value<int?>? memoUnlockedAt,
    Value<int>? glyphRevision,
    Value<int>? baseRevision,
    Value<String>? fontFamilyName,
    Value<String>? fontAsciiName,
    Value<String>? fontStyleName,
    Value<int>? fontVersionMinor,
    Value<String>? fontLicense,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      baseSetVersion: baseSetVersion ?? this.baseSetVersion,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      memoUnlockedAt: memoUnlockedAt ?? this.memoUnlockedAt,
      glyphRevision: glyphRevision ?? this.glyphRevision,
      baseRevision: baseRevision ?? this.baseRevision,
      fontFamilyName: fontFamilyName ?? this.fontFamilyName,
      fontAsciiName: fontAsciiName ?? this.fontAsciiName,
      fontStyleName: fontStyleName ?? this.fontStyleName,
      fontVersionMinor: fontVersionMinor ?? this.fontVersionMinor,
      fontLicense: fontLicense ?? this.fontLicense,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (baseSetVersion.present) {
      map['base_set_version'] = Variable<int>(baseSetVersion.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<int>(ruleVersion.value);
    }
    if (memoUnlockedAt.present) {
      map['memo_unlocked_at'] = Variable<int>(memoUnlockedAt.value);
    }
    if (glyphRevision.present) {
      map['glyph_revision'] = Variable<int>(glyphRevision.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (fontFamilyName.present) {
      map['font_family_name'] = Variable<String>(fontFamilyName.value);
    }
    if (fontAsciiName.present) {
      map['font_ascii_name'] = Variable<String>(fontAsciiName.value);
    }
    if (fontStyleName.present) {
      map['font_style_name'] = Variable<String>(fontStyleName.value);
    }
    if (fontVersionMinor.present) {
      map['font_version_minor'] = Variable<int>(fontVersionMinor.value);
    }
    if (fontLicense.present) {
      map['font_license'] = Variable<String>(fontLicense.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('baseSetVersion: $baseSetVersion, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('memoUnlockedAt: $memoUnlockedAt, ')
          ..write('glyphRevision: $glyphRevision, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('fontFamilyName: $fontFamilyName, ')
          ..write('fontAsciiName: $fontAsciiName, ')
          ..write('fontStyleName: $fontStyleName, ')
          ..write('fontVersionMinor: $fontVersionMinor, ')
          ..write('fontLicense: $fontLicense, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class BaseGlyphs extends Table with TableInfo<BaseGlyphs, BaseGlyphRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BaseGlyphs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES projects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _roleKeyMeta = const VerificationMeta(
    'roleKey',
  );
  late final GeneratedColumn<String> roleKey = GeneratedColumn<String>(
    'role_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _strokesMeta = const VerificationMeta(
    'strokes',
  );
  late final GeneratedColumn<Uint8List> strokes = GeneratedColumn<Uint8List>(
    'strokes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    projectId,
    roleKey,
    strokes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'base_glyphs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BaseGlyphRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('role_key')) {
      context.handle(
        _roleKeyMeta,
        roleKey.isAcceptableOrUnknown(data['role_key']!, _roleKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_roleKeyMeta);
    }
    if (data.containsKey('strokes')) {
      context.handle(
        _strokesMeta,
        strokes.isAcceptableOrUnknown(data['strokes']!, _strokesMeta),
      );
    } else if (isInserting) {
      context.missing(_strokesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {projectId, roleKey};
  @override
  BaseGlyphRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BaseGlyphRow(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      roleKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_key'],
      )!,
      strokes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}strokes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  BaseGlyphs createAlias(String alias) {
    return BaseGlyphs(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(project_id, role_key)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class BaseGlyphRow extends DataClass implements Insertable<BaseGlyphRow> {
  final String projectId;
  final String roleKey;
  final Uint8List strokes;
  final int updatedAt;
  const BaseGlyphRow({
    required this.projectId,
    required this.roleKey,
    required this.strokes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['role_key'] = Variable<String>(roleKey);
    map['strokes'] = Variable<Uint8List>(strokes);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BaseGlyphsCompanion toCompanion(bool nullToAbsent) {
    return BaseGlyphsCompanion(
      projectId: Value(projectId),
      roleKey: Value(roleKey),
      strokes: Value(strokes),
      updatedAt: Value(updatedAt),
    );
  }

  factory BaseGlyphRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BaseGlyphRow(
      projectId: serializer.fromJson<String>(json['project_id']),
      roleKey: serializer.fromJson<String>(json['role_key']),
      strokes: serializer.fromJson<Uint8List>(json['strokes']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'project_id': serializer.toJson<String>(projectId),
      'role_key': serializer.toJson<String>(roleKey),
      'strokes': serializer.toJson<Uint8List>(strokes),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  BaseGlyphRow copyWith({
    String? projectId,
    String? roleKey,
    Uint8List? strokes,
    int? updatedAt,
  }) => BaseGlyphRow(
    projectId: projectId ?? this.projectId,
    roleKey: roleKey ?? this.roleKey,
    strokes: strokes ?? this.strokes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BaseGlyphRow copyWithCompanion(BaseGlyphsCompanion data) {
    return BaseGlyphRow(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      roleKey: data.roleKey.present ? data.roleKey.value : this.roleKey,
      strokes: data.strokes.present ? data.strokes.value : this.strokes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BaseGlyphRow(')
          ..write('projectId: $projectId, ')
          ..write('roleKey: $roleKey, ')
          ..write('strokes: $strokes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    projectId,
    roleKey,
    $driftBlobEquality.hash(strokes),
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaseGlyphRow &&
          other.projectId == this.projectId &&
          other.roleKey == this.roleKey &&
          $driftBlobEquality.equals(other.strokes, this.strokes) &&
          other.updatedAt == this.updatedAt);
}

class BaseGlyphsCompanion extends UpdateCompanion<BaseGlyphRow> {
  final Value<String> projectId;
  final Value<String> roleKey;
  final Value<Uint8List> strokes;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BaseGlyphsCompanion({
    this.projectId = const Value.absent(),
    this.roleKey = const Value.absent(),
    this.strokes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BaseGlyphsCompanion.insert({
    required String projectId,
    required String roleKey,
    required Uint8List strokes,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       roleKey = Value(roleKey),
       strokes = Value(strokes),
       updatedAt = Value(updatedAt);
  static Insertable<BaseGlyphRow> custom({
    Expression<String>? projectId,
    Expression<String>? roleKey,
    Expression<Uint8List>? strokes,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (roleKey != null) 'role_key': roleKey,
      if (strokes != null) 'strokes': strokes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BaseGlyphsCompanion copyWith({
    Value<String>? projectId,
    Value<String>? roleKey,
    Value<Uint8List>? strokes,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return BaseGlyphsCompanion(
      projectId: projectId ?? this.projectId,
      roleKey: roleKey ?? this.roleKey,
      strokes: strokes ?? this.strokes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (roleKey.present) {
      map['role_key'] = Variable<String>(roleKey.value);
    }
    if (strokes.present) {
      map['strokes'] = Variable<Uint8List>(strokes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BaseGlyphsCompanion(')
          ..write('projectId: $projectId, ')
          ..write('roleKey: $roleKey, ')
          ..write('strokes: $strokes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CustomRevisions extends Table
    with TableInfo<CustomRevisions, CustomRevisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CustomRevisions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES projects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _codePointMeta = const VerificationMeta(
    'codePoint',
  );
  late final GeneratedColumn<int> codePoint = GeneratedColumn<int>(
    'code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (code_point BETWEEN 44032 AND 55203)',
  );
  static const VerificationMeta _strokesMeta = const VerificationMeta(
    'strokes',
  );
  late final GeneratedColumn<Uint8List> strokes = GeneratedColumn<Uint8List>(
    'strokes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _outlineMeta = const VerificationMeta(
    'outline',
  );
  late final GeneratedColumn<Uint8List> outline = GeneratedColumn<Uint8List>(
    'outline',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _penMeta = const VerificationMeta('pen');
  late final GeneratedColumn<String> pen = GeneratedColumn<String>(
    'pen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    codePoint,
    strokes,
    outline,
    pen,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomRevisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('code_point')) {
      context.handle(
        _codePointMeta,
        codePoint.isAcceptableOrUnknown(data['code_point']!, _codePointMeta),
      );
    } else if (isInserting) {
      context.missing(_codePointMeta);
    }
    if (data.containsKey('strokes')) {
      context.handle(
        _strokesMeta,
        strokes.isAcceptableOrUnknown(data['strokes']!, _strokesMeta),
      );
    } else if (isInserting) {
      context.missing(_strokesMeta);
    }
    if (data.containsKey('outline')) {
      context.handle(
        _outlineMeta,
        outline.isAcceptableOrUnknown(data['outline']!, _outlineMeta),
      );
    } else if (isInserting) {
      context.missing(_outlineMeta);
    }
    if (data.containsKey('pen')) {
      context.handle(
        _penMeta,
        pen.isAcceptableOrUnknown(data['pen']!, _penMeta),
      );
    } else if (isInserting) {
      context.missing(_penMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {projectId, codePoint, id},
  ];
  @override
  CustomRevisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomRevisionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      codePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}code_point'],
      )!,
      strokes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}strokes'],
      )!,
      outline: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}outline'],
      )!,
      pen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pen'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  CustomRevisions createAlias(String alias) {
    return CustomRevisions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(project_id, code_point, id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CustomRevisionRow extends DataClass
    implements Insertable<CustomRevisionRow> {
  final int id;
  final String projectId;
  final int codePoint;
  final Uint8List strokes;
  final Uint8List outline;
  final String pen;
  final int createdAt;
  const CustomRevisionRow({
    required this.id,
    required this.projectId,
    required this.codePoint,
    required this.strokes,
    required this.outline,
    required this.pen,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<String>(projectId);
    map['code_point'] = Variable<int>(codePoint);
    map['strokes'] = Variable<Uint8List>(strokes);
    map['outline'] = Variable<Uint8List>(outline);
    map['pen'] = Variable<String>(pen);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CustomRevisionsCompanion toCompanion(bool nullToAbsent) {
    return CustomRevisionsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      codePoint: Value(codePoint),
      strokes: Value(strokes),
      outline: Value(outline),
      pen: Value(pen),
      createdAt: Value(createdAt),
    );
  }

  factory CustomRevisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomRevisionRow(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<String>(json['project_id']),
      codePoint: serializer.fromJson<int>(json['code_point']),
      strokes: serializer.fromJson<Uint8List>(json['strokes']),
      outline: serializer.fromJson<Uint8List>(json['outline']),
      pen: serializer.fromJson<String>(json['pen']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'project_id': serializer.toJson<String>(projectId),
      'code_point': serializer.toJson<int>(codePoint),
      'strokes': serializer.toJson<Uint8List>(strokes),
      'outline': serializer.toJson<Uint8List>(outline),
      'pen': serializer.toJson<String>(pen),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  CustomRevisionRow copyWith({
    int? id,
    String? projectId,
    int? codePoint,
    Uint8List? strokes,
    Uint8List? outline,
    String? pen,
    int? createdAt,
  }) => CustomRevisionRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    codePoint: codePoint ?? this.codePoint,
    strokes: strokes ?? this.strokes,
    outline: outline ?? this.outline,
    pen: pen ?? this.pen,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomRevisionRow copyWithCompanion(CustomRevisionsCompanion data) {
    return CustomRevisionRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      codePoint: data.codePoint.present ? data.codePoint.value : this.codePoint,
      strokes: data.strokes.present ? data.strokes.value : this.strokes,
      outline: data.outline.present ? data.outline.value : this.outline,
      pen: data.pen.present ? data.pen.value : this.pen,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomRevisionRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('codePoint: $codePoint, ')
          ..write('strokes: $strokes, ')
          ..write('outline: $outline, ')
          ..write('pen: $pen, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    codePoint,
    $driftBlobEquality.hash(strokes),
    $driftBlobEquality.hash(outline),
    pen,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomRevisionRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.codePoint == this.codePoint &&
          $driftBlobEquality.equals(other.strokes, this.strokes) &&
          $driftBlobEquality.equals(other.outline, this.outline) &&
          other.pen == this.pen &&
          other.createdAt == this.createdAt);
}

class CustomRevisionsCompanion extends UpdateCompanion<CustomRevisionRow> {
  final Value<int> id;
  final Value<String> projectId;
  final Value<int> codePoint;
  final Value<Uint8List> strokes;
  final Value<Uint8List> outline;
  final Value<String> pen;
  final Value<int> createdAt;
  const CustomRevisionsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.codePoint = const Value.absent(),
    this.strokes = const Value.absent(),
    this.outline = const Value.absent(),
    this.pen = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomRevisionsCompanion.insert({
    this.id = const Value.absent(),
    required String projectId,
    required int codePoint,
    required Uint8List strokes,
    required Uint8List outline,
    required String pen,
    required int createdAt,
  }) : projectId = Value(projectId),
       codePoint = Value(codePoint),
       strokes = Value(strokes),
       outline = Value(outline),
       pen = Value(pen),
       createdAt = Value(createdAt);
  static Insertable<CustomRevisionRow> custom({
    Expression<int>? id,
    Expression<String>? projectId,
    Expression<int>? codePoint,
    Expression<Uint8List>? strokes,
    Expression<Uint8List>? outline,
    Expression<String>? pen,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (codePoint != null) 'code_point': codePoint,
      if (strokes != null) 'strokes': strokes,
      if (outline != null) 'outline': outline,
      if (pen != null) 'pen': pen,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomRevisionsCompanion copyWith({
    Value<int>? id,
    Value<String>? projectId,
    Value<int>? codePoint,
    Value<Uint8List>? strokes,
    Value<Uint8List>? outline,
    Value<String>? pen,
    Value<int>? createdAt,
  }) {
    return CustomRevisionsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      codePoint: codePoint ?? this.codePoint,
      strokes: strokes ?? this.strokes,
      outline: outline ?? this.outline,
      pen: pen ?? this.pen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (codePoint.present) {
      map['code_point'] = Variable<int>(codePoint.value);
    }
    if (strokes.present) {
      map['strokes'] = Variable<Uint8List>(strokes.value);
    }
    if (outline.present) {
      map['outline'] = Variable<Uint8List>(outline.value);
    }
    if (pen.present) {
      map['pen'] = Variable<String>(pen.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('codePoint: $codePoint, ')
          ..write('strokes: $strokes, ')
          ..write('outline: $outline, ')
          ..write('pen: $pen, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class CustomGlyphs extends Table with TableInfo<CustomGlyphs, CustomGlyphRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CustomGlyphs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES projects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _codePointMeta = const VerificationMeta(
    'codePoint',
  );
  late final GeneratedColumn<int> codePoint = GeneratedColumn<int>(
    'code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (code_point BETWEEN 44032 AND 55203)',
  );
  static const VerificationMeta _selectionMeta = const VerificationMeta(
    'selection',
  );
  late final GeneratedColumn<String> selection = GeneratedColumn<String>(
    'selection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (selection IN (\'generated\', \'custom\'))',
  );
  static const VerificationMeta _currentRevisionIdMeta = const VerificationMeta(
    'currentRevisionId',
  );
  late final GeneratedColumn<int> currentRevisionId = GeneratedColumn<int>(
    'current_revision_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    projectId,
    codePoint,
    selection,
    currentRevisionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_glyphs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomGlyphRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('code_point')) {
      context.handle(
        _codePointMeta,
        codePoint.isAcceptableOrUnknown(data['code_point']!, _codePointMeta),
      );
    } else if (isInserting) {
      context.missing(_codePointMeta);
    }
    if (data.containsKey('selection')) {
      context.handle(
        _selectionMeta,
        selection.isAcceptableOrUnknown(data['selection']!, _selectionMeta),
      );
    } else if (isInserting) {
      context.missing(_selectionMeta);
    }
    if (data.containsKey('current_revision_id')) {
      context.handle(
        _currentRevisionIdMeta,
        currentRevisionId.isAcceptableOrUnknown(
          data['current_revision_id']!,
          _currentRevisionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentRevisionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {projectId, codePoint};
  @override
  CustomGlyphRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomGlyphRow(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      codePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}code_point'],
      )!,
      selection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selection'],
      )!,
      currentRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_revision_id'],
      )!,
    );
  }

  @override
  CustomGlyphs createAlias(String alias) {
    return CustomGlyphs(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(project_id, code_point)',
    'FOREIGN KEY(project_id, code_point, current_revision_id)REFERENCES custom_revisions(project_id, code_point, id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CustomGlyphRow extends DataClass implements Insertable<CustomGlyphRow> {
  final String projectId;
  final int codePoint;
  final String selection;
  final int currentRevisionId;
  const CustomGlyphRow({
    required this.projectId,
    required this.codePoint,
    required this.selection,
    required this.currentRevisionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['code_point'] = Variable<int>(codePoint);
    map['selection'] = Variable<String>(selection);
    map['current_revision_id'] = Variable<int>(currentRevisionId);
    return map;
  }

  CustomGlyphsCompanion toCompanion(bool nullToAbsent) {
    return CustomGlyphsCompanion(
      projectId: Value(projectId),
      codePoint: Value(codePoint),
      selection: Value(selection),
      currentRevisionId: Value(currentRevisionId),
    );
  }

  factory CustomGlyphRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomGlyphRow(
      projectId: serializer.fromJson<String>(json['project_id']),
      codePoint: serializer.fromJson<int>(json['code_point']),
      selection: serializer.fromJson<String>(json['selection']),
      currentRevisionId: serializer.fromJson<int>(json['current_revision_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'project_id': serializer.toJson<String>(projectId),
      'code_point': serializer.toJson<int>(codePoint),
      'selection': serializer.toJson<String>(selection),
      'current_revision_id': serializer.toJson<int>(currentRevisionId),
    };
  }

  CustomGlyphRow copyWith({
    String? projectId,
    int? codePoint,
    String? selection,
    int? currentRevisionId,
  }) => CustomGlyphRow(
    projectId: projectId ?? this.projectId,
    codePoint: codePoint ?? this.codePoint,
    selection: selection ?? this.selection,
    currentRevisionId: currentRevisionId ?? this.currentRevisionId,
  );
  CustomGlyphRow copyWithCompanion(CustomGlyphsCompanion data) {
    return CustomGlyphRow(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      codePoint: data.codePoint.present ? data.codePoint.value : this.codePoint,
      selection: data.selection.present ? data.selection.value : this.selection,
      currentRevisionId: data.currentRevisionId.present
          ? data.currentRevisionId.value
          : this.currentRevisionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomGlyphRow(')
          ..write('projectId: $projectId, ')
          ..write('codePoint: $codePoint, ')
          ..write('selection: $selection, ')
          ..write('currentRevisionId: $currentRevisionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(projectId, codePoint, selection, currentRevisionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomGlyphRow &&
          other.projectId == this.projectId &&
          other.codePoint == this.codePoint &&
          other.selection == this.selection &&
          other.currentRevisionId == this.currentRevisionId);
}

class CustomGlyphsCompanion extends UpdateCompanion<CustomGlyphRow> {
  final Value<String> projectId;
  final Value<int> codePoint;
  final Value<String> selection;
  final Value<int> currentRevisionId;
  final Value<int> rowid;
  const CustomGlyphsCompanion({
    this.projectId = const Value.absent(),
    this.codePoint = const Value.absent(),
    this.selection = const Value.absent(),
    this.currentRevisionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomGlyphsCompanion.insert({
    required String projectId,
    required int codePoint,
    required String selection,
    required int currentRevisionId,
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       codePoint = Value(codePoint),
       selection = Value(selection),
       currentRevisionId = Value(currentRevisionId);
  static Insertable<CustomGlyphRow> custom({
    Expression<String>? projectId,
    Expression<int>? codePoint,
    Expression<String>? selection,
    Expression<int>? currentRevisionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (codePoint != null) 'code_point': codePoint,
      if (selection != null) 'selection': selection,
      if (currentRevisionId != null) 'current_revision_id': currentRevisionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomGlyphsCompanion copyWith({
    Value<String>? projectId,
    Value<int>? codePoint,
    Value<String>? selection,
    Value<int>? currentRevisionId,
    Value<int>? rowid,
  }) {
    return CustomGlyphsCompanion(
      projectId: projectId ?? this.projectId,
      codePoint: codePoint ?? this.codePoint,
      selection: selection ?? this.selection,
      currentRevisionId: currentRevisionId ?? this.currentRevisionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (codePoint.present) {
      map['code_point'] = Variable<int>(codePoint.value);
    }
    if (selection.present) {
      map['selection'] = Variable<String>(selection.value);
    }
    if (currentRevisionId.present) {
      map['current_revision_id'] = Variable<int>(currentRevisionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomGlyphsCompanion(')
          ..write('projectId: $projectId, ')
          ..write('codePoint: $codePoint, ')
          ..write('selection: $selection, ')
          ..write('currentRevisionId: $currentRevisionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Memos extends Table with TableInfo<Memos, MemoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Memos(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES projects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _text$Meta = const VerificationMeta('text\$');
  late final GeneratedColumn<String> text$ = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    text$,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _text$Meta,
        text$.isAcceptableOrUnknown(data['text']!, _text$Meta),
      );
    } else if (isInserting) {
      context.missing(_text$Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      text$: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Memos createAlias(String alias) {
    return Memos(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MemoRow extends DataClass implements Insertable<MemoRow> {
  final String id;
  final String projectId;
  final String text$;
  final int createdAt;
  final int updatedAt;
  const MemoRow({
    required this.id,
    required this.projectId,
    required this.text$,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['text'] = Variable<String>(text$);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  MemosCompanion toCompanion(bool nullToAbsent) {
    return MemosCompanion(
      id: Value(id),
      projectId: Value(projectId),
      text$: Value(text$),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MemoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoRow(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['project_id']),
      text$: serializer.fromJson<String>(json['text']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'project_id': serializer.toJson<String>(projectId),
      'text': serializer.toJson<String>(text$),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  MemoRow copyWith({
    String? id,
    String? projectId,
    String? text$,
    int? createdAt,
    int? updatedAt,
  }) => MemoRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    text$: text$ ?? this.text$,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MemoRow copyWithCompanion(MemosCompanion data) {
    return MemoRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      text$: data.text$.present ? data.text$.value : this.text$,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('text\$: ${text$}, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, text$, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.text$ == this.text$ &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MemosCompanion extends UpdateCompanion<MemoRow> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> text$;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const MemosCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.text$ = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemosCompanion.insert({
    required String id,
    required String projectId,
    required String text$,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       text$ = Value(text$),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MemoRow> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? text$,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (text$ != null) 'text': text$,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemosCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? text$,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return MemosCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      text$: text$ ?? this.text$,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (text$.present) {
      map['text'] = Variable<String>(text$.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemosCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('text\$: ${text$}, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Drafts extends Table with TableInfo<Drafts, DraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Drafts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES projects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'base\', \'custom\'))',
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _strokesMeta = const VerificationMeta(
    'strokes',
  );
  late final GeneratedColumn<Uint8List> strokes = GeneratedColumn<Uint8List>(
    'strokes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    projectId,
    kind,
    key,
    strokes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('strokes')) {
      context.handle(
        _strokesMeta,
        strokes.isAcceptableOrUnknown(data['strokes']!, _strokesMeta),
      );
    } else if (isInserting) {
      context.missing(_strokesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {projectId, kind, key};
  @override
  DraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftRow(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      strokes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}strokes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Drafts createAlias(String alias) {
    return Drafts(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(project_id, kind, "key")',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DraftRow extends DataClass implements Insertable<DraftRow> {
  final String projectId;
  final String kind;
  final String key;
  final Uint8List strokes;
  final int updatedAt;
  const DraftRow({
    required this.projectId,
    required this.kind,
    required this.key,
    required this.strokes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['kind'] = Variable<String>(kind);
    map['key'] = Variable<String>(key);
    map['strokes'] = Variable<Uint8List>(strokes);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      projectId: Value(projectId),
      kind: Value(kind),
      key: Value(key),
      strokes: Value(strokes),
      updatedAt: Value(updatedAt),
    );
  }

  factory DraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftRow(
      projectId: serializer.fromJson<String>(json['project_id']),
      kind: serializer.fromJson<String>(json['kind']),
      key: serializer.fromJson<String>(json['key']),
      strokes: serializer.fromJson<Uint8List>(json['strokes']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'project_id': serializer.toJson<String>(projectId),
      'kind': serializer.toJson<String>(kind),
      'key': serializer.toJson<String>(key),
      'strokes': serializer.toJson<Uint8List>(strokes),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  DraftRow copyWith({
    String? projectId,
    String? kind,
    String? key,
    Uint8List? strokes,
    int? updatedAt,
  }) => DraftRow(
    projectId: projectId ?? this.projectId,
    kind: kind ?? this.kind,
    key: key ?? this.key,
    strokes: strokes ?? this.strokes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DraftRow copyWithCompanion(DraftsCompanion data) {
    return DraftRow(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      kind: data.kind.present ? data.kind.value : this.kind,
      key: data.key.present ? data.key.value : this.key,
      strokes: data.strokes.present ? data.strokes.value : this.strokes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftRow(')
          ..write('projectId: $projectId, ')
          ..write('kind: $kind, ')
          ..write('key: $key, ')
          ..write('strokes: $strokes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    projectId,
    kind,
    key,
    $driftBlobEquality.hash(strokes),
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftRow &&
          other.projectId == this.projectId &&
          other.kind == this.kind &&
          other.key == this.key &&
          $driftBlobEquality.equals(other.strokes, this.strokes) &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<DraftRow> {
  final Value<String> projectId;
  final Value<String> kind;
  final Value<String> key;
  final Value<Uint8List> strokes;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DraftsCompanion({
    this.projectId = const Value.absent(),
    this.kind = const Value.absent(),
    this.key = const Value.absent(),
    this.strokes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftsCompanion.insert({
    required String projectId,
    required String kind,
    required String key,
    required Uint8List strokes,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       kind = Value(kind),
       key = Value(key),
       strokes = Value(strokes),
       updatedAt = Value(updatedAt);
  static Insertable<DraftRow> custom({
    Expression<String>? projectId,
    Expression<String>? kind,
    Expression<String>? key,
    Expression<Uint8List>? strokes,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (kind != null) 'kind': kind,
      if (key != null) 'key': key,
      if (strokes != null) 'strokes': strokes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftsCompanion copyWith({
    Value<String>? projectId,
    Value<String>? kind,
    Value<String>? key,
    Value<Uint8List>? strokes,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DraftsCompanion(
      projectId: projectId ?? this.projectId,
      kind: kind ?? this.kind,
      key: key ?? this.key,
      strokes: strokes ?? this.strokes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (strokes.present) {
      map['strokes'] = Variable<Uint8List>(strokes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('projectId: $projectId, ')
          ..write('kind: $kind, ')
          ..write('key: $key, ')
          ..write('strokes: $strokes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RevisionGuard extends Table
    with TableInfo<RevisionGuard, RevisionGuardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RevisionGuard(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _allowRevisionDeleteMeta =
      const VerificationMeta('allowRevisionDelete');
  late final GeneratedColumn<int> allowRevisionDelete = GeneratedColumn<int>(
    'allow_revision_delete',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (allow_revision_delete IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [id, allowRevisionDelete];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revision_guard';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevisionGuardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('allow_revision_delete')) {
      context.handle(
        _allowRevisionDeleteMeta,
        allowRevisionDelete.isAcceptableOrUnknown(
          data['allow_revision_delete']!,
          _allowRevisionDeleteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowRevisionDeleteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RevisionGuardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevisionGuardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      allowRevisionDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allow_revision_delete'],
      )!,
    );
  }

  @override
  RevisionGuard createAlias(String alias) {
    return RevisionGuard(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class RevisionGuardRow extends DataClass
    implements Insertable<RevisionGuardRow> {
  final int id;
  final int allowRevisionDelete;
  const RevisionGuardRow({required this.id, required this.allowRevisionDelete});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['allow_revision_delete'] = Variable<int>(allowRevisionDelete);
    return map;
  }

  RevisionGuardCompanion toCompanion(bool nullToAbsent) {
    return RevisionGuardCompanion(
      id: Value(id),
      allowRevisionDelete: Value(allowRevisionDelete),
    );
  }

  factory RevisionGuardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevisionGuardRow(
      id: serializer.fromJson<int>(json['id']),
      allowRevisionDelete: serializer.fromJson<int>(
        json['allow_revision_delete'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'allow_revision_delete': serializer.toJson<int>(allowRevisionDelete),
    };
  }

  RevisionGuardRow copyWith({int? id, int? allowRevisionDelete}) =>
      RevisionGuardRow(
        id: id ?? this.id,
        allowRevisionDelete: allowRevisionDelete ?? this.allowRevisionDelete,
      );
  RevisionGuardRow copyWithCompanion(RevisionGuardCompanion data) {
    return RevisionGuardRow(
      id: data.id.present ? data.id.value : this.id,
      allowRevisionDelete: data.allowRevisionDelete.present
          ? data.allowRevisionDelete.value
          : this.allowRevisionDelete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionGuardRow(')
          ..write('id: $id, ')
          ..write('allowRevisionDelete: $allowRevisionDelete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, allowRevisionDelete);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionGuardRow &&
          other.id == this.id &&
          other.allowRevisionDelete == this.allowRevisionDelete);
}

class RevisionGuardCompanion extends UpdateCompanion<RevisionGuardRow> {
  final Value<int> id;
  final Value<int> allowRevisionDelete;
  const RevisionGuardCompanion({
    this.id = const Value.absent(),
    this.allowRevisionDelete = const Value.absent(),
  });
  RevisionGuardCompanion.insert({
    this.id = const Value.absent(),
    required int allowRevisionDelete,
  }) : allowRevisionDelete = Value(allowRevisionDelete);
  static Insertable<RevisionGuardRow> custom({
    Expression<int>? id,
    Expression<int>? allowRevisionDelete,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (allowRevisionDelete != null)
        'allow_revision_delete': allowRevisionDelete,
    });
  }

  RevisionGuardCompanion copyWith({
    Value<int>? id,
    Value<int>? allowRevisionDelete,
  }) {
    return RevisionGuardCompanion(
      id: id ?? this.id,
      allowRevisionDelete: allowRevisionDelete ?? this.allowRevisionDelete,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (allowRevisionDelete.present) {
      map['allow_revision_delete'] = Variable<int>(allowRevisionDelete.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionGuardCompanion(')
          ..write('id: $id, ')
          ..write('allowRevisionDelete: $allowRevisionDelete')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Projects projects = Projects(this);
  late final BaseGlyphs baseGlyphs = BaseGlyphs(this);
  late final CustomRevisions customRevisions = CustomRevisions(this);
  late final Index customRevisionsCp = Index(
    'custom_revisions_cp',
    'CREATE INDEX custom_revisions_cp ON custom_revisions (project_id, code_point)',
  );
  late final CustomGlyphs customGlyphs = CustomGlyphs(this);
  late final Memos memos = Memos(this);
  late final Drafts drafts = Drafts(this);
  late final AppSettings appSettings = AppSettings(this);
  late final RevisionGuard revisionGuard = RevisionGuard(this);
  late final Trigger customRevisionsNoDelete = Trigger(
    'CREATE TRIGGER custom_revisions_no_delete BEFORE DELETE ON custom_revisions WHEN NOT EXISTS (SELECT 1 FROM revision_guard WHERE id = 1 AND allow_revision_delete = 1) BEGIN SELECT RAISE (ABORT, \'custom revision delete not allowed\');END',
    'custom_revisions_no_delete',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    baseGlyphs,
    customRevisions,
    customRevisionsCp,
    customGlyphs,
    memos,
    drafts,
    appSettings,
    revisionGuard,
    customRevisionsNoDelete,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('base_glyphs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('custom_revisions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('custom_glyphs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('memos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('drafts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_revisions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
  ]);
}

typedef $ProjectsCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  required int createdAt,
  required int updatedAt,
  required int baseSetVersion,
  required int ruleVersion,
  Value<int?> memoUnlockedAt,
  Value<int> glyphRevision,
  Value<int> baseRevision,
  required String fontFamilyName,
  required String fontAsciiName,
  Value<String> fontStyleName,
  Value<int> fontVersionMinor,
  Value<String> fontLicense,
  Value<int> rowid,
});
typedef $ProjectsUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> baseSetVersion,
  Value<int> ruleVersion,
  Value<int?> memoUnlockedAt,
  Value<int> glyphRevision,
  Value<int> baseRevision,
  Value<String> fontFamilyName,
  Value<String> fontAsciiName,
  Value<String> fontStyleName,
  Value<int> fontVersionMinor,
  Value<String> fontLicense,
  Value<int> rowid,
});

final class $ProjectsReferences
    extends BaseReferences<_$AppDatabase, Projects, ProjectRow> {
  $ProjectsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<BaseGlyphs, List<BaseGlyphRow>>
  _baseGlyphsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.baseGlyphs,
    aliasName: 'projects__id__base_glyphs__project_id',
  );

  $BaseGlyphsProcessedTableManager get baseGlyphsRefs {
    final manager = $BaseGlyphsTableManager(
      $_db,
      $_db.baseGlyphs,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_baseGlyphsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CustomRevisions, List<CustomRevisionRow>>
  _customRevisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customRevisions,
    aliasName: 'projects__id__custom_revisions__project_id',
  );

  $CustomRevisionsProcessedTableManager get customRevisionsRefs {
    final manager = $CustomRevisionsTableManager(
      $_db,
      $_db.customRevisions,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CustomGlyphs, List<CustomGlyphRow>>
  _customGlyphsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customGlyphs,
    aliasName: 'projects__id__custom_glyphs__project_id',
  );

  $CustomGlyphsProcessedTableManager get customGlyphsRefs {
    final manager = $CustomGlyphsTableManager(
      $_db,
      $_db.customGlyphs,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_customGlyphsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Memos, List<MemoRow>> _memosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.memos,
    aliasName: 'projects__id__memos__project_id',
  );

  $MemosProcessedTableManager get memosRefs {
    final manager = $MemosTableManager(
      $_db,
      $_db.memos,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_memosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Drafts, List<DraftRow>> _draftsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.drafts,
    aliasName: 'projects__id__drafts__project_id',
  );

  $DraftsProcessedTableManager get draftsRefs {
    final manager = $DraftsTableManager(
      $_db,
      $_db.drafts,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_draftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ProjectsFilterComposer extends Composer<_$AppDatabase, Projects> {
  $ProjectsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseSetVersion => $composableBuilder(
    column: $table.baseSetVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memoUnlockedAt => $composableBuilder(
    column: $table.memoUnlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get glyphRevision => $composableBuilder(
    column: $table.glyphRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fontFamilyName => $composableBuilder(
    column: $table.fontFamilyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fontAsciiName => $composableBuilder(
    column: $table.fontAsciiName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fontStyleName => $composableBuilder(
    column: $table.fontStyleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fontVersionMinor => $composableBuilder(
    column: $table.fontVersionMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fontLicense => $composableBuilder(
    column: $table.fontLicense,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> baseGlyphsRefs(
    Expression<bool> Function($BaseGlyphsFilterComposer f) f,
  ) {
    final $BaseGlyphsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.baseGlyphs,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BaseGlyphsFilterComposer(
            $db: $db,
            $table: $db.baseGlyphs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customRevisionsRefs(
    Expression<bool> Function($CustomRevisionsFilterComposer f) f,
  ) {
    final $CustomRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customRevisions,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomRevisionsFilterComposer(
            $db: $db,
            $table: $db.customRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customGlyphsRefs(
    Expression<bool> Function($CustomGlyphsFilterComposer f) f,
  ) {
    final $CustomGlyphsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customGlyphs,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomGlyphsFilterComposer(
            $db: $db,
            $table: $db.customGlyphs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memosRefs(
    Expression<bool> Function($MemosFilterComposer f) f,
  ) {
    final $MemosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memos,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MemosFilterComposer(
            $db: $db,
            $table: $db.memos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> draftsRefs(
    Expression<bool> Function($DraftsFilterComposer f) f,
  ) {
    final $DraftsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.drafts,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DraftsFilterComposer(
            $db: $db,
            $table: $db.drafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProjectsOrderingComposer extends Composer<_$AppDatabase, Projects> {
  $ProjectsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseSetVersion => $composableBuilder(
    column: $table.baseSetVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memoUnlockedAt => $composableBuilder(
    column: $table.memoUnlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get glyphRevision => $composableBuilder(
    column: $table.glyphRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontFamilyName => $composableBuilder(
    column: $table.fontFamilyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontAsciiName => $composableBuilder(
    column: $table.fontAsciiName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontStyleName => $composableBuilder(
    column: $table.fontStyleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fontVersionMinor => $composableBuilder(
    column: $table.fontVersionMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontLicense => $composableBuilder(
    column: $table.fontLicense,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ProjectsAnnotationComposer extends Composer<_$AppDatabase, Projects> {
  $ProjectsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get baseSetVersion => $composableBuilder(
    column: $table.baseSetVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memoUnlockedAt => $composableBuilder(
    column: $table.memoUnlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get glyphRevision => $composableBuilder(
    column: $table.glyphRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fontFamilyName => $composableBuilder(
    column: $table.fontFamilyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fontAsciiName => $composableBuilder(
    column: $table.fontAsciiName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fontStyleName => $composableBuilder(
    column: $table.fontStyleName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fontVersionMinor => $composableBuilder(
    column: $table.fontVersionMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fontLicense => $composableBuilder(
    column: $table.fontLicense,
    builder: (column) => column,
  );

  Expression<T> baseGlyphsRefs<T extends Object>(
    Expression<T> Function($BaseGlyphsAnnotationComposer a) f,
  ) {
    final $BaseGlyphsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.baseGlyphs,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BaseGlyphsAnnotationComposer(
            $db: $db,
            $table: $db.baseGlyphs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customRevisionsRefs<T extends Object>(
    Expression<T> Function($CustomRevisionsAnnotationComposer a) f,
  ) {
    final $CustomRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customRevisions,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.customRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customGlyphsRefs<T extends Object>(
    Expression<T> Function($CustomGlyphsAnnotationComposer a) f,
  ) {
    final $CustomGlyphsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customGlyphs,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomGlyphsAnnotationComposer(
            $db: $db,
            $table: $db.customGlyphs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> memosRefs<T extends Object>(
    Expression<T> Function($MemosAnnotationComposer a) f,
  ) {
    final $MemosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memos,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MemosAnnotationComposer(
            $db: $db,
            $table: $db.memos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> draftsRefs<T extends Object>(
    Expression<T> Function($DraftsAnnotationComposer a) f,
  ) {
    final $DraftsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.drafts,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DraftsAnnotationComposer(
            $db: $db,
            $table: $db.drafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProjectsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Projects,
          ProjectRow,
          $ProjectsFilterComposer,
          $ProjectsOrderingComposer,
          $ProjectsAnnotationComposer,
          $ProjectsCreateCompanionBuilder,
          $ProjectsUpdateCompanionBuilder,
          (ProjectRow, $ProjectsReferences),
          ProjectRow,
          PrefetchHooks Function({
            bool baseGlyphsRefs,
            bool customRevisionsRefs,
            bool customGlyphsRefs,
            bool memosRefs,
            bool draftsRefs,
          })
        > {
  $ProjectsTableManager(_$AppDatabase db, Projects table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProjectsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProjectsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProjectsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> baseSetVersion = const Value.absent(),
                Value<int> ruleVersion = const Value.absent(),
                Value<int?> memoUnlockedAt = const Value.absent(),
                Value<int> glyphRevision = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                Value<String> fontFamilyName = const Value.absent(),
                Value<String> fontAsciiName = const Value.absent(),
                Value<String> fontStyleName = const Value.absent(),
                Value<int> fontVersionMinor = const Value.absent(),
                Value<String> fontLicense = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                baseSetVersion: baseSetVersion,
                ruleVersion: ruleVersion,
                memoUnlockedAt: memoUnlockedAt,
                glyphRevision: glyphRevision,
                baseRevision: baseRevision,
                fontFamilyName: fontFamilyName,
                fontAsciiName: fontAsciiName,
                fontStyleName: fontStyleName,
                fontVersionMinor: fontVersionMinor,
                fontLicense: fontLicense,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int createdAt,
                required int updatedAt,
                required int baseSetVersion,
                required int ruleVersion,
                Value<int?> memoUnlockedAt = const Value.absent(),
                Value<int> glyphRevision = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                required String fontFamilyName,
                required String fontAsciiName,
                Value<String> fontStyleName = const Value.absent(),
                Value<int> fontVersionMinor = const Value.absent(),
                Value<String> fontLicense = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                baseSetVersion: baseSetVersion,
                ruleVersion: ruleVersion,
                memoUnlockedAt: memoUnlockedAt,
                glyphRevision: glyphRevision,
                baseRevision: baseRevision,
                fontFamilyName: fontFamilyName,
                fontAsciiName: fontAsciiName,
                fontStyleName: fontStyleName,
                fontVersionMinor: fontVersionMinor,
                fontLicense: fontLicense,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Projects, ProjectRow>(table),
                  $ProjectsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                baseGlyphsRefs = false,
                customRevisionsRefs = false,
                customGlyphsRefs = false,
                memosRefs = false,
                draftsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (baseGlyphsRefs) db.baseGlyphs,
                    if (customRevisionsRefs) db.customRevisions,
                    if (customGlyphsRefs) db.customGlyphs,
                    if (memosRefs) db.memos,
                    if (draftsRefs) db.drafts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (baseGlyphsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectRow,
                          Projects,
                          BaseGlyphRow,
                          BaseGlyphs
                        >(
                          currentTable: table,
                          referencedTable: $ProjectsReferences
                              ._baseGlyphsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ProjectsReferences(db, table, p0).baseGlyphsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (customRevisionsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectRow,
                          Projects,
                          CustomRevisionRow,
                          CustomRevisions
                        >(
                          currentTable: table,
                          referencedTable: $ProjectsReferences
                              ._customRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) => $ProjectsReferences(
                            db,
                            table,
                            p0,
                          ).customRevisionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (customGlyphsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectRow,
                          Projects,
                          CustomGlyphRow,
                          CustomGlyphs
                        >(
                          currentTable: table,
                          referencedTable: $ProjectsReferences
                              ._customGlyphsRefsTable(db),
                          managerFromTypedResult: (p0) => $ProjectsReferences(
                            db,
                            table,
                            p0,
                          ).customGlyphsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (memosRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectRow,
                          Projects,
                          MemoRow,
                          Memos
                        >(
                          currentTable: table,
                          referencedTable: $ProjectsReferences._memosRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $ProjectsReferences(db, table, p0).memosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (draftsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProjectRow,
                          Projects,
                          DraftRow,
                          Drafts
                        >(
                          currentTable: table,
                          referencedTable: $ProjectsReferences._draftsRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $ProjectsReferences(db, table, p0).draftsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ProjectsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Projects,
      ProjectRow,
      $ProjectsFilterComposer,
      $ProjectsOrderingComposer,
      $ProjectsAnnotationComposer,
      $ProjectsCreateCompanionBuilder,
      $ProjectsUpdateCompanionBuilder,
      (ProjectRow, $ProjectsReferences),
      ProjectRow,
      PrefetchHooks Function({
        bool baseGlyphsRefs,
        bool customRevisionsRefs,
        bool customGlyphsRefs,
        bool memosRefs,
        bool draftsRefs,
      })
    >;
typedef $BaseGlyphsCreateCompanionBuilder = BaseGlyphsCompanion Function({
  required String projectId,
  required String roleKey,
  required Uint8List strokes,
  required int updatedAt,
  Value<int> rowid,
});
typedef $BaseGlyphsUpdateCompanionBuilder = BaseGlyphsCompanion Function({
  Value<String> projectId,
  Value<String> roleKey,
  Value<Uint8List> strokes,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $BaseGlyphsReferences
    extends BaseReferences<_$AppDatabase, BaseGlyphs, BaseGlyphRow> {
  $BaseGlyphsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Projects _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('base_glyphs__project_id__projects__id');

  $ProjectsProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $ProjectsTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $BaseGlyphsFilterComposer extends Composer<_$AppDatabase, BaseGlyphs> {
  $BaseGlyphsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get roleKey => $composableBuilder(
    column: $table.roleKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $ProjectsFilterComposer get projectId {
    final $ProjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $BaseGlyphsOrderingComposer extends Composer<_$AppDatabase, BaseGlyphs> {
  $BaseGlyphsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get roleKey => $composableBuilder(
    column: $table.roleKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ProjectsOrderingComposer get projectId {
    final $ProjectsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $BaseGlyphsAnnotationComposer
    extends Composer<_$AppDatabase, BaseGlyphs> {
  $BaseGlyphsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get roleKey =>
      $composableBuilder(column: $table.roleKey, builder: (column) => column);

  GeneratedColumn<Uint8List> get strokes =>
      $composableBuilder(column: $table.strokes, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $ProjectsAnnotationComposer get projectId {
    final $ProjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $BaseGlyphsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          BaseGlyphs,
          BaseGlyphRow,
          $BaseGlyphsFilterComposer,
          $BaseGlyphsOrderingComposer,
          $BaseGlyphsAnnotationComposer,
          $BaseGlyphsCreateCompanionBuilder,
          $BaseGlyphsUpdateCompanionBuilder,
          (BaseGlyphRow, $BaseGlyphsReferences),
          BaseGlyphRow,
          PrefetchHooks Function({bool projectId})
        > {
  $BaseGlyphsTableManager(_$AppDatabase db, BaseGlyphs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BaseGlyphsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BaseGlyphsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BaseGlyphsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<String> roleKey = const Value.absent(),
                Value<Uint8List> strokes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BaseGlyphsCompanion(
                projectId: projectId,
                roleKey: roleKey,
                strokes: strokes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required String roleKey,
                required Uint8List strokes,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BaseGlyphsCompanion.insert(
                projectId: projectId,
                roleKey: roleKey,
                strokes: strokes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<BaseGlyphs, BaseGlyphRow>(table),
                  $BaseGlyphsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $BaseGlyphsReferences._projectIdTable(
                          db,
                        ),
                        referencedColumn: $BaseGlyphsReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $BaseGlyphsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      BaseGlyphs,
      BaseGlyphRow,
      $BaseGlyphsFilterComposer,
      $BaseGlyphsOrderingComposer,
      $BaseGlyphsAnnotationComposer,
      $BaseGlyphsCreateCompanionBuilder,
      $BaseGlyphsUpdateCompanionBuilder,
      (BaseGlyphRow, $BaseGlyphsReferences),
      BaseGlyphRow,
      PrefetchHooks Function({bool projectId})
    >;
typedef $CustomRevisionsCreateCompanionBuilder =
    CustomRevisionsCompanion Function({
      Value<int> id,
      required String projectId,
      required int codePoint,
      required Uint8List strokes,
      required Uint8List outline,
      required String pen,
      required int createdAt,
    });
typedef $CustomRevisionsUpdateCompanionBuilder =
    CustomRevisionsCompanion Function({
      Value<int> id,
      Value<String> projectId,
      Value<int> codePoint,
      Value<Uint8List> strokes,
      Value<Uint8List> outline,
      Value<String> pen,
      Value<int> createdAt,
    });

final class $CustomRevisionsReferences
    extends BaseReferences<_$AppDatabase, CustomRevisions, CustomRevisionRow> {
  $CustomRevisionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Projects _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('custom_revisions__project_id__projects__id');

  $ProjectsProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $ProjectsTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CustomRevisionsFilterComposer
    extends Composer<_$AppDatabase, CustomRevisions> {
  $CustomRevisionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get codePoint => $composableBuilder(
    column: $table.codePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pen => $composableBuilder(
    column: $table.pen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $ProjectsFilterComposer get projectId {
    final $ProjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomRevisionsOrderingComposer
    extends Composer<_$AppDatabase, CustomRevisions> {
  $CustomRevisionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get codePoint => $composableBuilder(
    column: $table.codePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pen => $composableBuilder(
    column: $table.pen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ProjectsOrderingComposer get projectId {
    final $ProjectsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomRevisionsAnnotationComposer
    extends Composer<_$AppDatabase, CustomRevisions> {
  $CustomRevisionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get codePoint =>
      $composableBuilder(column: $table.codePoint, builder: (column) => column);

  GeneratedColumn<Uint8List> get strokes =>
      $composableBuilder(column: $table.strokes, builder: (column) => column);

  GeneratedColumn<Uint8List> get outline =>
      $composableBuilder(column: $table.outline, builder: (column) => column);

  GeneratedColumn<String> get pen =>
      $composableBuilder(column: $table.pen, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $ProjectsAnnotationComposer get projectId {
    final $ProjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomRevisionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CustomRevisions,
          CustomRevisionRow,
          $CustomRevisionsFilterComposer,
          $CustomRevisionsOrderingComposer,
          $CustomRevisionsAnnotationComposer,
          $CustomRevisionsCreateCompanionBuilder,
          $CustomRevisionsUpdateCompanionBuilder,
          (CustomRevisionRow, $CustomRevisionsReferences),
          CustomRevisionRow,
          PrefetchHooks Function({bool projectId})
        > {
  $CustomRevisionsTableManager(_$AppDatabase db, CustomRevisions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CustomRevisionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CustomRevisionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CustomRevisionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<int> codePoint = const Value.absent(),
                Value<Uint8List> strokes = const Value.absent(),
                Value<Uint8List> outline = const Value.absent(),
                Value<String> pen = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CustomRevisionsCompanion(
                id: id,
                projectId: projectId,
                codePoint: codePoint,
                strokes: strokes,
                outline: outline,
                pen: pen,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String projectId,
                required int codePoint,
                required Uint8List strokes,
                required Uint8List outline,
                required String pen,
                required int createdAt,
              }) => CustomRevisionsCompanion.insert(
                id: id,
                projectId: projectId,
                codePoint: codePoint,
                strokes: strokes,
                outline: outline,
                pen: pen,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<CustomRevisions, CustomRevisionRow>(table),
                  $CustomRevisionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $CustomRevisionsReferences
                            ._projectIdTable(db),
                        referencedColumn: $CustomRevisionsReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CustomRevisionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CustomRevisions,
      CustomRevisionRow,
      $CustomRevisionsFilterComposer,
      $CustomRevisionsOrderingComposer,
      $CustomRevisionsAnnotationComposer,
      $CustomRevisionsCreateCompanionBuilder,
      $CustomRevisionsUpdateCompanionBuilder,
      (CustomRevisionRow, $CustomRevisionsReferences),
      CustomRevisionRow,
      PrefetchHooks Function({bool projectId})
    >;
typedef $CustomGlyphsCreateCompanionBuilder = CustomGlyphsCompanion Function({
  required String projectId,
  required int codePoint,
  required String selection,
  required int currentRevisionId,
  Value<int> rowid,
});
typedef $CustomGlyphsUpdateCompanionBuilder = CustomGlyphsCompanion Function({
  Value<String> projectId,
  Value<int> codePoint,
  Value<String> selection,
  Value<int> currentRevisionId,
  Value<int> rowid,
});

final class $CustomGlyphsReferences
    extends BaseReferences<_$AppDatabase, CustomGlyphs, CustomGlyphRow> {
  $CustomGlyphsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Projects _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('custom_glyphs__project_id__projects__id');

  $ProjectsProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $ProjectsTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CustomGlyphsFilterComposer
    extends Composer<_$AppDatabase, CustomGlyphs> {
  $CustomGlyphsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get codePoint => $composableBuilder(
    column: $table.codePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selection => $composableBuilder(
    column: $table.selection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  $ProjectsFilterComposer get projectId {
    final $ProjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomGlyphsOrderingComposer
    extends Composer<_$AppDatabase, CustomGlyphs> {
  $CustomGlyphsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get codePoint => $composableBuilder(
    column: $table.codePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selection => $composableBuilder(
    column: $table.selection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  $ProjectsOrderingComposer get projectId {
    final $ProjectsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomGlyphsAnnotationComposer
    extends Composer<_$AppDatabase, CustomGlyphs> {
  $CustomGlyphsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get codePoint =>
      $composableBuilder(column: $table.codePoint, builder: (column) => column);

  GeneratedColumn<String> get selection =>
      $composableBuilder(column: $table.selection, builder: (column) => column);

  GeneratedColumn<int> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => column,
  );

  $ProjectsAnnotationComposer get projectId {
    final $ProjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomGlyphsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CustomGlyphs,
          CustomGlyphRow,
          $CustomGlyphsFilterComposer,
          $CustomGlyphsOrderingComposer,
          $CustomGlyphsAnnotationComposer,
          $CustomGlyphsCreateCompanionBuilder,
          $CustomGlyphsUpdateCompanionBuilder,
          (CustomGlyphRow, $CustomGlyphsReferences),
          CustomGlyphRow,
          PrefetchHooks Function({bool projectId})
        > {
  $CustomGlyphsTableManager(_$AppDatabase db, CustomGlyphs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CustomGlyphsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CustomGlyphsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CustomGlyphsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<int> codePoint = const Value.absent(),
                Value<String> selection = const Value.absent(),
                Value<int> currentRevisionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomGlyphsCompanion(
                projectId: projectId,
                codePoint: codePoint,
                selection: selection,
                currentRevisionId: currentRevisionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required int codePoint,
                required String selection,
                required int currentRevisionId,
                Value<int> rowid = const Value.absent(),
              }) => CustomGlyphsCompanion.insert(
                projectId: projectId,
                codePoint: codePoint,
                selection: selection,
                currentRevisionId: currentRevisionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<CustomGlyphs, CustomGlyphRow>(table),
                  $CustomGlyphsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $CustomGlyphsReferences
                            ._projectIdTable(db),
                        referencedColumn: $CustomGlyphsReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CustomGlyphsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CustomGlyphs,
      CustomGlyphRow,
      $CustomGlyphsFilterComposer,
      $CustomGlyphsOrderingComposer,
      $CustomGlyphsAnnotationComposer,
      $CustomGlyphsCreateCompanionBuilder,
      $CustomGlyphsUpdateCompanionBuilder,
      (CustomGlyphRow, $CustomGlyphsReferences),
      CustomGlyphRow,
      PrefetchHooks Function({bool projectId})
    >;
typedef $MemosCreateCompanionBuilder = MemosCompanion Function({
  required String id,
  required String projectId,
  required String text$,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $MemosUpdateCompanionBuilder = MemosCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> text$,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $MemosReferences
    extends BaseReferences<_$AppDatabase, Memos, MemoRow> {
  $MemosReferences(super.$_db, super.$_table, super.$_typedResult);

  static Projects _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('memos__project_id__projects__id');

  $ProjectsProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $ProjectsTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $MemosFilterComposer extends Composer<_$AppDatabase, Memos> {
  $MemosFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get text$ => $composableBuilder(
    column: $table.text$,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $ProjectsFilterComposer get projectId {
    final $ProjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MemosOrderingComposer extends Composer<_$AppDatabase, Memos> {
  $MemosOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get text$ => $composableBuilder(
    column: $table.text$,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ProjectsOrderingComposer get projectId {
    final $ProjectsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MemosAnnotationComposer extends Composer<_$AppDatabase, Memos> {
  $MemosAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get text$ =>
      $composableBuilder(column: $table.text$, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $ProjectsAnnotationComposer get projectId {
    final $ProjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MemosTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Memos,
          MemoRow,
          $MemosFilterComposer,
          $MemosOrderingComposer,
          $MemosAnnotationComposer,
          $MemosCreateCompanionBuilder,
          $MemosUpdateCompanionBuilder,
          (MemoRow, $MemosReferences),
          MemoRow,
          PrefetchHooks Function({bool projectId})
        > {
  $MemosTableManager(_$AppDatabase db, Memos table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MemosFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MemosOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MemosAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> text$ = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemosCompanion(
                id: id,
                projectId: projectId,
                text$: text$,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String text$,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MemosCompanion.insert(
                id: id,
                projectId: projectId,
                text$: text$,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Memos, MemoRow>(table),
                  $MemosReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $MemosReferences._projectIdTable(db),
                        referencedColumn: $MemosReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $MemosProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Memos,
      MemoRow,
      $MemosFilterComposer,
      $MemosOrderingComposer,
      $MemosAnnotationComposer,
      $MemosCreateCompanionBuilder,
      $MemosUpdateCompanionBuilder,
      (MemoRow, $MemosReferences),
      MemoRow,
      PrefetchHooks Function({bool projectId})
    >;
typedef $DraftsCreateCompanionBuilder = DraftsCompanion Function({
  required String projectId,
  required String kind,
  required String key,
  required Uint8List strokes,
  required int updatedAt,
  Value<int> rowid,
});
typedef $DraftsUpdateCompanionBuilder = DraftsCompanion Function({
  Value<String> projectId,
  Value<String> kind,
  Value<String> key,
  Value<Uint8List> strokes,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $DraftsReferences
    extends BaseReferences<_$AppDatabase, Drafts, DraftRow> {
  $DraftsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Projects _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('drafts__project_id__projects__id');

  $ProjectsProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $ProjectsTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DraftsFilterComposer extends Composer<_$AppDatabase, Drafts> {
  $DraftsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $ProjectsFilterComposer get projectId {
    final $ProjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DraftsOrderingComposer extends Composer<_$AppDatabase, Drafts> {
  $DraftsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get strokes => $composableBuilder(
    column: $table.strokes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ProjectsOrderingComposer get projectId {
    final $ProjectsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DraftsAnnotationComposer extends Composer<_$AppDatabase, Drafts> {
  $DraftsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<Uint8List> get strokes =>
      $composableBuilder(column: $table.strokes, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $ProjectsAnnotationComposer get projectId {
    final $ProjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProjectsAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DraftsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Drafts,
          DraftRow,
          $DraftsFilterComposer,
          $DraftsOrderingComposer,
          $DraftsAnnotationComposer,
          $DraftsCreateCompanionBuilder,
          $DraftsUpdateCompanionBuilder,
          (DraftRow, $DraftsReferences),
          DraftRow,
          PrefetchHooks Function({bool projectId})
        > {
  $DraftsTableManager(_$AppDatabase db, Drafts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DraftsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DraftsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DraftsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<Uint8List> strokes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion(
                projectId: projectId,
                kind: kind,
                key: key,
                strokes: strokes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required String kind,
                required String key,
                required Uint8List strokes,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion.insert(
                projectId: projectId,
                kind: kind,
                key: key,
                strokes: strokes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Drafts, DraftRow>(table),
                  $DraftsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $DraftsReferences._projectIdTable(db),
                        referencedColumn: $DraftsReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $DraftsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Drafts,
      DraftRow,
      $DraftsFilterComposer,
      $DraftsOrderingComposer,
      $DraftsAnnotationComposer,
      $DraftsCreateCompanionBuilder,
      $DraftsUpdateCompanionBuilder,
      (DraftRow, $DraftsReferences),
      DraftRow,
      PrefetchHooks Function({bool projectId})
    >;
typedef $AppSettingsCreateCompanionBuilder = AppSettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $AppSettingsUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $AppSettingsFilterComposer extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $AppSettingsOrderingComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AppSettingsAnnotationComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $AppSettingsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AppSettings,
          AppSettingRow,
          $AppSettingsFilterComposer,
          $AppSettingsOrderingComposer,
          $AppSettingsAnnotationComposer,
          $AppSettingsCreateCompanionBuilder,
          $AppSettingsUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, AppSettings, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $AppSettingsTableManager(_$AppDatabase db, AppSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AppSettings, AppSettingRow>(table),
                  BaseReferences<_$AppDatabase, AppSettings, AppSettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AppSettingsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AppSettings,
      AppSettingRow,
      $AppSettingsFilterComposer,
      $AppSettingsOrderingComposer,
      $AppSettingsAnnotationComposer,
      $AppSettingsCreateCompanionBuilder,
      $AppSettingsUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, AppSettings, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $RevisionGuardCreateCompanionBuilder = RevisionGuardCompanion Function({
  Value<int> id,
  required int allowRevisionDelete,
});
typedef $RevisionGuardUpdateCompanionBuilder = RevisionGuardCompanion Function({
  Value<int> id,
  Value<int> allowRevisionDelete,
});

class $RevisionGuardFilterComposer
    extends Composer<_$AppDatabase, RevisionGuard> {
  $RevisionGuardFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allowRevisionDelete => $composableBuilder(
    column: $table.allowRevisionDelete,
    builder: (column) => ColumnFilters(column),
  );
}

class $RevisionGuardOrderingComposer
    extends Composer<_$AppDatabase, RevisionGuard> {
  $RevisionGuardOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allowRevisionDelete => $composableBuilder(
    column: $table.allowRevisionDelete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RevisionGuardAnnotationComposer
    extends Composer<_$AppDatabase, RevisionGuard> {
  $RevisionGuardAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get allowRevisionDelete => $composableBuilder(
    column: $table.allowRevisionDelete,
    builder: (column) => column,
  );
}

class $RevisionGuardTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RevisionGuard,
          RevisionGuardRow,
          $RevisionGuardFilterComposer,
          $RevisionGuardOrderingComposer,
          $RevisionGuardAnnotationComposer,
          $RevisionGuardCreateCompanionBuilder,
          $RevisionGuardUpdateCompanionBuilder,
          (
            RevisionGuardRow,
            BaseReferences<_$AppDatabase, RevisionGuard, RevisionGuardRow>,
          ),
          RevisionGuardRow,
          PrefetchHooks Function()
        > {
  $RevisionGuardTableManager(_$AppDatabase db, RevisionGuard table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RevisionGuardFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RevisionGuardOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RevisionGuardAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> allowRevisionDelete = const Value.absent(),
              }) => RevisionGuardCompanion(
                id: id,
                allowRevisionDelete: allowRevisionDelete,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int allowRevisionDelete,
              }) => RevisionGuardCompanion.insert(
                id: id,
                allowRevisionDelete: allowRevisionDelete,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<RevisionGuard, RevisionGuardRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    RevisionGuard,
                    RevisionGuardRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $RevisionGuardProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RevisionGuard,
      RevisionGuardRow,
      $RevisionGuardFilterComposer,
      $RevisionGuardOrderingComposer,
      $RevisionGuardAnnotationComposer,
      $RevisionGuardCreateCompanionBuilder,
      $RevisionGuardUpdateCompanionBuilder,
      (
        RevisionGuardRow,
        BaseReferences<_$AppDatabase, RevisionGuard, RevisionGuardRow>,
      ),
      RevisionGuardRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $ProjectsTableManager get projects =>
      $ProjectsTableManager(_db, _db.projects);
  $BaseGlyphsTableManager get baseGlyphs =>
      $BaseGlyphsTableManager(_db, _db.baseGlyphs);
  $CustomRevisionsTableManager get customRevisions =>
      $CustomRevisionsTableManager(_db, _db.customRevisions);
  $CustomGlyphsTableManager get customGlyphs =>
      $CustomGlyphsTableManager(_db, _db.customGlyphs);
  $MemosTableManager get memos => $MemosTableManager(_db, _db.memos);
  $DraftsTableManager get drafts => $DraftsTableManager(_db, _db.drafts);
  $AppSettingsTableManager get appSettings =>
      $AppSettingsTableManager(_db, _db.appSettings);
  $RevisionGuardTableManager get revisionGuard =>
      $RevisionGuardTableManager(_db, _db.revisionGuard);
}
