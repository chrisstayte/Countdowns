// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventDateTimeMeta = const VerificationMeta(
    'eventDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> eventDateTime =
      GeneratedColumn<DateTime>(
        'event_date_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _iconSlugMeta = const VerificationMeta(
    'iconSlug',
  );
  @override
  late final GeneratedColumn<String> iconSlug = GeneratedColumn<String>(
    'icon_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta(
    'colorArgb',
  );
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradientIdMeta = const VerificationMeta(
    'gradientId',
  );
  @override
  late final GeneratedColumn<String> gradientId = GeneratedColumn<String>(
    'gradient_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GradientDirection?, String>
  gradientDirection =
      GeneratedColumn<String>(
        'gradient_direction',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<GradientDirection?>(
        $EventsTable.$convertergradientDirectionn,
      );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoCropsMeta = const VerificationMeta(
    'photoCrops',
  );
  @override
  late final GeneratedColumn<String> photoCrops = GeneratedColumn<String>(
    'photo_crops',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoDarkenMeta = const VerificationMeta(
    'photoDarken',
  );
  @override
  late final GeneratedColumn<double> photoDarken = GeneratedColumn<double>(
    'photo_darken',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.35),
  );
  static const VerificationMeta _fontFamilyMeta = const VerificationMeta(
    'fontFamily',
  );
  @override
  late final GeneratedColumn<String> fontFamily = GeneratedColumn<String>(
    'font_family',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Default'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CountUnit, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CountUnit>($EventsTable.$converterunit);
  @override
  late final GeneratedColumnWithTypeConverter<RepeatRule, String> repeat =
      GeneratedColumn<String>(
        'repeat',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RepeatRule>($EventsTable.$converterrepeat);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legacyHiveKeyMeta = const VerificationMeta(
    'legacyHiveKey',
  );
  @override
  late final GeneratedColumn<int> legacyHiveKey = GeneratedColumn<int>(
    'legacy_hive_key',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    eventDateTime,
    allDay,
    iconSlug,
    colorArgb,
    gradientId,
    gradientDirection,
    photoPath,
    photoCrops,
    photoDarken,
    fontFamily,
    unit,
    repeat,
    createdAt,
    updatedAt,
    legacyHiveKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_date_time')) {
      context.handle(
        _eventDateTimeMeta,
        eventDateTime.isAcceptableOrUnknown(
          data['event_date_time']!,
          _eventDateTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventDateTimeMeta);
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('icon_slug')) {
      context.handle(
        _iconSlugMeta,
        iconSlug.isAcceptableOrUnknown(data['icon_slug']!, _iconSlugMeta),
      );
    }
    if (data.containsKey('color_argb')) {
      context.handle(
        _colorArgbMeta,
        colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta),
      );
    } else if (isInserting) {
      context.missing(_colorArgbMeta);
    }
    if (data.containsKey('gradient_id')) {
      context.handle(
        _gradientIdMeta,
        gradientId.isAcceptableOrUnknown(data['gradient_id']!, _gradientIdMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('photo_crops')) {
      context.handle(
        _photoCropsMeta,
        photoCrops.isAcceptableOrUnknown(data['photo_crops']!, _photoCropsMeta),
      );
    }
    if (data.containsKey('photo_darken')) {
      context.handle(
        _photoDarkenMeta,
        photoDarken.isAcceptableOrUnknown(
          data['photo_darken']!,
          _photoDarkenMeta,
        ),
      );
    }
    if (data.containsKey('font_family')) {
      context.handle(
        _fontFamilyMeta,
        fontFamily.isAcceptableOrUnknown(data['font_family']!, _fontFamilyMeta),
      );
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
    if (data.containsKey('legacy_hive_key')) {
      context.handle(
        _legacyHiveKeyMeta,
        legacyHiveKey.isAcceptableOrUnknown(
          data['legacy_hive_key']!,
          _legacyHiveKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      eventDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_date_time'],
      )!,
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      iconSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_slug'],
      ),
      colorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_argb'],
      )!,
      gradientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gradient_id'],
      ),
      gradientDirection: $EventsTable.$convertergradientDirectionn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}gradient_direction'],
        ),
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      photoCrops: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_crops'],
      ),
      photoDarken: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}photo_darken'],
      )!,
      fontFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_family'],
      )!,
      unit: $EventsTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      repeat: $EventsTable.$converterrepeat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repeat'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      legacyHiveKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_hive_key'],
      ),
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GradientDirection, String, String>
  $convertergradientDirection = const EnumNameConverter<GradientDirection>(
    GradientDirection.values,
  );
  static JsonTypeConverter2<GradientDirection?, String?, String?>
  $convertergradientDirectionn = JsonTypeConverter2.asNullable(
    $convertergradientDirection,
  );
  static JsonTypeConverter2<CountUnit, String, String> $converterunit =
      const EnumNameConverter<CountUnit>(CountUnit.values);
  static JsonTypeConverter2<RepeatRule, String, String> $converterrepeat =
      const EnumNameConverter<RepeatRule>(RepeatRule.values);
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final int id;
  final String title;
  final DateTime eventDateTime;
  final bool allDay;
  final String? iconSlug;
  final int colorArgb;
  final String? gradientId;
  final GradientDirection? gradientDirection;
  final String? photoPath;

  /// JSON: a crop point per shape plus a "same for all" flag.
  final String? photoCrops;
  final double photoDarken;
  final String fontFamily;
  final CountUnit unit;
  final RepeatRule repeat;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The Hive key this row was copied from, so the copy can run again safely.
  final int? legacyHiveKey;
  const EventRow({
    required this.id,
    required this.title,
    required this.eventDateTime,
    required this.allDay,
    this.iconSlug,
    required this.colorArgb,
    this.gradientId,
    this.gradientDirection,
    this.photoPath,
    this.photoCrops,
    required this.photoDarken,
    required this.fontFamily,
    required this.unit,
    required this.repeat,
    required this.createdAt,
    required this.updatedAt,
    this.legacyHiveKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['event_date_time'] = Variable<DateTime>(eventDateTime);
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || iconSlug != null) {
      map['icon_slug'] = Variable<String>(iconSlug);
    }
    map['color_argb'] = Variable<int>(colorArgb);
    if (!nullToAbsent || gradientId != null) {
      map['gradient_id'] = Variable<String>(gradientId);
    }
    if (!nullToAbsent || gradientDirection != null) {
      map['gradient_direction'] = Variable<String>(
        $EventsTable.$convertergradientDirectionn.toSql(gradientDirection),
      );
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || photoCrops != null) {
      map['photo_crops'] = Variable<String>(photoCrops);
    }
    map['photo_darken'] = Variable<double>(photoDarken);
    map['font_family'] = Variable<String>(fontFamily);
    {
      map['unit'] = Variable<String>($EventsTable.$converterunit.toSql(unit));
    }
    {
      map['repeat'] = Variable<String>(
        $EventsTable.$converterrepeat.toSql(repeat),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || legacyHiveKey != null) {
      map['legacy_hive_key'] = Variable<int>(legacyHiveKey);
    }
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      title: Value(title),
      eventDateTime: Value(eventDateTime),
      allDay: Value(allDay),
      iconSlug: iconSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(iconSlug),
      colorArgb: Value(colorArgb),
      gradientId: gradientId == null && nullToAbsent
          ? const Value.absent()
          : Value(gradientId),
      gradientDirection: gradientDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(gradientDirection),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoCrops: photoCrops == null && nullToAbsent
          ? const Value.absent()
          : Value(photoCrops),
      photoDarken: Value(photoDarken),
      fontFamily: Value(fontFamily),
      unit: Value(unit),
      repeat: Value(repeat),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      legacyHiveKey: legacyHiveKey == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyHiveKey),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      eventDateTime: serializer.fromJson<DateTime>(json['eventDateTime']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      iconSlug: serializer.fromJson<String?>(json['iconSlug']),
      colorArgb: serializer.fromJson<int>(json['colorArgb']),
      gradientId: serializer.fromJson<String?>(json['gradientId']),
      gradientDirection: $EventsTable.$convertergradientDirectionn.fromJson(
        serializer.fromJson<String?>(json['gradientDirection']),
      ),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoCrops: serializer.fromJson<String?>(json['photoCrops']),
      photoDarken: serializer.fromJson<double>(json['photoDarken']),
      fontFamily: serializer.fromJson<String>(json['fontFamily']),
      unit: $EventsTable.$converterunit.fromJson(
        serializer.fromJson<String>(json['unit']),
      ),
      repeat: $EventsTable.$converterrepeat.fromJson(
        serializer.fromJson<String>(json['repeat']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      legacyHiveKey: serializer.fromJson<int?>(json['legacyHiveKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'eventDateTime': serializer.toJson<DateTime>(eventDateTime),
      'allDay': serializer.toJson<bool>(allDay),
      'iconSlug': serializer.toJson<String?>(iconSlug),
      'colorArgb': serializer.toJson<int>(colorArgb),
      'gradientId': serializer.toJson<String?>(gradientId),
      'gradientDirection': serializer.toJson<String?>(
        $EventsTable.$convertergradientDirectionn.toJson(gradientDirection),
      ),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoCrops': serializer.toJson<String?>(photoCrops),
      'photoDarken': serializer.toJson<double>(photoDarken),
      'fontFamily': serializer.toJson<String>(fontFamily),
      'unit': serializer.toJson<String>(
        $EventsTable.$converterunit.toJson(unit),
      ),
      'repeat': serializer.toJson<String>(
        $EventsTable.$converterrepeat.toJson(repeat),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'legacyHiveKey': serializer.toJson<int?>(legacyHiveKey),
    };
  }

  EventRow copyWith({
    int? id,
    String? title,
    DateTime? eventDateTime,
    bool? allDay,
    Value<String?> iconSlug = const Value.absent(),
    int? colorArgb,
    Value<String?> gradientId = const Value.absent(),
    Value<GradientDirection?> gradientDirection = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    Value<String?> photoCrops = const Value.absent(),
    double? photoDarken,
    String? fontFamily,
    CountUnit? unit,
    RepeatRule? repeat,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<int?> legacyHiveKey = const Value.absent(),
  }) => EventRow(
    id: id ?? this.id,
    title: title ?? this.title,
    eventDateTime: eventDateTime ?? this.eventDateTime,
    allDay: allDay ?? this.allDay,
    iconSlug: iconSlug.present ? iconSlug.value : this.iconSlug,
    colorArgb: colorArgb ?? this.colorArgb,
    gradientId: gradientId.present ? gradientId.value : this.gradientId,
    gradientDirection: gradientDirection.present
        ? gradientDirection.value
        : this.gradientDirection,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    photoCrops: photoCrops.present ? photoCrops.value : this.photoCrops,
    photoDarken: photoDarken ?? this.photoDarken,
    fontFamily: fontFamily ?? this.fontFamily,
    unit: unit ?? this.unit,
    repeat: repeat ?? this.repeat,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    legacyHiveKey: legacyHiveKey.present
        ? legacyHiveKey.value
        : this.legacyHiveKey,
  );
  EventRow copyWithCompanion(EventsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      eventDateTime: data.eventDateTime.present
          ? data.eventDateTime.value
          : this.eventDateTime,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      iconSlug: data.iconSlug.present ? data.iconSlug.value : this.iconSlug,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      gradientId: data.gradientId.present
          ? data.gradientId.value
          : this.gradientId,
      gradientDirection: data.gradientDirection.present
          ? data.gradientDirection.value
          : this.gradientDirection,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoCrops: data.photoCrops.present
          ? data.photoCrops.value
          : this.photoCrops,
      photoDarken: data.photoDarken.present
          ? data.photoDarken.value
          : this.photoDarken,
      fontFamily: data.fontFamily.present
          ? data.fontFamily.value
          : this.fontFamily,
      unit: data.unit.present ? data.unit.value : this.unit,
      repeat: data.repeat.present ? data.repeat.value : this.repeat,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      legacyHiveKey: data.legacyHiveKey.present
          ? data.legacyHiveKey.value
          : this.legacyHiveKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventDateTime: $eventDateTime, ')
          ..write('allDay: $allDay, ')
          ..write('iconSlug: $iconSlug, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('gradientId: $gradientId, ')
          ..write('gradientDirection: $gradientDirection, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoCrops: $photoCrops, ')
          ..write('photoDarken: $photoDarken, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('unit: $unit, ')
          ..write('repeat: $repeat, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('legacyHiveKey: $legacyHiveKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    eventDateTime,
    allDay,
    iconSlug,
    colorArgb,
    gradientId,
    gradientDirection,
    photoPath,
    photoCrops,
    photoDarken,
    fontFamily,
    unit,
    repeat,
    createdAt,
    updatedAt,
    legacyHiveKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.eventDateTime == this.eventDateTime &&
          other.allDay == this.allDay &&
          other.iconSlug == this.iconSlug &&
          other.colorArgb == this.colorArgb &&
          other.gradientId == this.gradientId &&
          other.gradientDirection == this.gradientDirection &&
          other.photoPath == this.photoPath &&
          other.photoCrops == this.photoCrops &&
          other.photoDarken == this.photoDarken &&
          other.fontFamily == this.fontFamily &&
          other.unit == this.unit &&
          other.repeat == this.repeat &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.legacyHiveKey == this.legacyHiveKey);
}

class EventsCompanion extends UpdateCompanion<EventRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> eventDateTime;
  final Value<bool> allDay;
  final Value<String?> iconSlug;
  final Value<int> colorArgb;
  final Value<String?> gradientId;
  final Value<GradientDirection?> gradientDirection;
  final Value<String?> photoPath;
  final Value<String?> photoCrops;
  final Value<double> photoDarken;
  final Value<String> fontFamily;
  final Value<CountUnit> unit;
  final Value<RepeatRule> repeat;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int?> legacyHiveKey;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.eventDateTime = const Value.absent(),
    this.allDay = const Value.absent(),
    this.iconSlug = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.gradientId = const Value.absent(),
    this.gradientDirection = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoCrops = const Value.absent(),
    this.photoDarken = const Value.absent(),
    this.fontFamily = const Value.absent(),
    this.unit = const Value.absent(),
    this.repeat = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.legacyHiveKey = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime eventDateTime,
    this.allDay = const Value.absent(),
    this.iconSlug = const Value.absent(),
    required int colorArgb,
    this.gradientId = const Value.absent(),
    this.gradientDirection = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoCrops = const Value.absent(),
    this.photoDarken = const Value.absent(),
    this.fontFamily = const Value.absent(),
    required CountUnit unit,
    required RepeatRule repeat,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.legacyHiveKey = const Value.absent(),
  }) : title = Value(title),
       eventDateTime = Value(eventDateTime),
       colorArgb = Value(colorArgb),
       unit = Value(unit),
       repeat = Value(repeat),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EventRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? eventDateTime,
    Expression<bool>? allDay,
    Expression<String>? iconSlug,
    Expression<int>? colorArgb,
    Expression<String>? gradientId,
    Expression<String>? gradientDirection,
    Expression<String>? photoPath,
    Expression<String>? photoCrops,
    Expression<double>? photoDarken,
    Expression<String>? fontFamily,
    Expression<String>? unit,
    Expression<String>? repeat,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? legacyHiveKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (eventDateTime != null) 'event_date_time': eventDateTime,
      if (allDay != null) 'all_day': allDay,
      if (iconSlug != null) 'icon_slug': iconSlug,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (gradientId != null) 'gradient_id': gradientId,
      if (gradientDirection != null) 'gradient_direction': gradientDirection,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoCrops != null) 'photo_crops': photoCrops,
      if (photoDarken != null) 'photo_darken': photoDarken,
      if (fontFamily != null) 'font_family': fontFamily,
      if (unit != null) 'unit': unit,
      if (repeat != null) 'repeat': repeat,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (legacyHiveKey != null) 'legacy_hive_key': legacyHiveKey,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? eventDateTime,
    Value<bool>? allDay,
    Value<String?>? iconSlug,
    Value<int>? colorArgb,
    Value<String?>? gradientId,
    Value<GradientDirection?>? gradientDirection,
    Value<String?>? photoPath,
    Value<String?>? photoCrops,
    Value<double>? photoDarken,
    Value<String>? fontFamily,
    Value<CountUnit>? unit,
    Value<RepeatRule>? repeat,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int?>? legacyHiveKey,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      allDay: allDay ?? this.allDay,
      iconSlug: iconSlug ?? this.iconSlug,
      colorArgb: colorArgb ?? this.colorArgb,
      gradientId: gradientId ?? this.gradientId,
      gradientDirection: gradientDirection ?? this.gradientDirection,
      photoPath: photoPath ?? this.photoPath,
      photoCrops: photoCrops ?? this.photoCrops,
      photoDarken: photoDarken ?? this.photoDarken,
      fontFamily: fontFamily ?? this.fontFamily,
      unit: unit ?? this.unit,
      repeat: repeat ?? this.repeat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      legacyHiveKey: legacyHiveKey ?? this.legacyHiveKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventDateTime.present) {
      map['event_date_time'] = Variable<DateTime>(eventDateTime.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (iconSlug.present) {
      map['icon_slug'] = Variable<String>(iconSlug.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (gradientId.present) {
      map['gradient_id'] = Variable<String>(gradientId.value);
    }
    if (gradientDirection.present) {
      map['gradient_direction'] = Variable<String>(
        $EventsTable.$convertergradientDirectionn.toSql(
          gradientDirection.value,
        ),
      );
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoCrops.present) {
      map['photo_crops'] = Variable<String>(photoCrops.value);
    }
    if (photoDarken.present) {
      map['photo_darken'] = Variable<double>(photoDarken.value);
    }
    if (fontFamily.present) {
      map['font_family'] = Variable<String>(fontFamily.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $EventsTable.$converterunit.toSql(unit.value),
      );
    }
    if (repeat.present) {
      map['repeat'] = Variable<String>(
        $EventsTable.$converterrepeat.toSql(repeat.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (legacyHiveKey.present) {
      map['legacy_hive_key'] = Variable<int>(legacyHiveKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventDateTime: $eventDateTime, ')
          ..write('allDay: $allDay, ')
          ..write('iconSlug: $iconSlug, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('gradientId: $gradientId, ')
          ..write('gradientDirection: $gradientDirection, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoCrops: $photoCrops, ')
          ..write('photoDarken: $photoDarken, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('unit: $unit, ')
          ..write('repeat: $repeat, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('legacyHiveKey: $legacyHiveKey')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, eventId, offsetMinutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {eventId, offsetMinutes},
  ];
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  /// Also used as the notification id.
  final int id;
  final int eventId;

  /// Minutes before the event. 0 means at the time.
  final int offsetMinutes;
  const ReminderRow({
    required this.id,
    required this.eventId,
    required this.offsetMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<int>(eventId);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      eventId: Value(eventId),
      offsetMinutes: Value(offsetMinutes),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<int>(json['eventId']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<int>(eventId),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
    };
  }

  ReminderRow copyWith({int? id, int? eventId, int? offsetMinutes}) =>
      ReminderRow(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('offsetMinutes: $offsetMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, offsetMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.offsetMinutes == this.offsetMinutes);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<int> id;
  final Value<int> eventId;
  final Value<int> offsetMinutes;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required int eventId,
    required int offsetMinutes,
  }) : eventId = Value(eventId),
       offsetMinutes = Value(offsetMinutes);
  static Insertable<ReminderRow> custom({
    Expression<int>? id,
    Expression<int>? eventId,
    Expression<int>? offsetMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? eventId,
    Value<int>? offsetMinutes,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('offsetMinutes: $offsetMinutes')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
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
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
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
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
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

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(MetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
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
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
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

  MetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
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
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $MetaTable meta = $MetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [events, reminders, meta];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  required String title,
  required DateTime eventDateTime,
  Value<bool> allDay,
  Value<String?> iconSlug,
  required int colorArgb,
  Value<String?> gradientId,
  Value<GradientDirection?> gradientDirection,
  Value<String?> photoPath,
  Value<String?> photoCrops,
  Value<double> photoDarken,
  Value<String> fontFamily,
  required CountUnit unit,
  required RepeatRule repeat,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int?> legacyHiveKey,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<DateTime> eventDateTime,
  Value<bool> allDay,
  Value<String?> iconSlug,
  Value<int> colorArgb,
  Value<String?> gradientId,
  Value<GradientDirection?> gradientDirection,
  Value<String?> photoPath,
  Value<String?> photoCrops,
  Value<double> photoDarken,
  Value<String> fontFamily,
  Value<CountUnit> unit,
  Value<RepeatRule> repeat,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int?> legacyHiveKey,
});

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, EventRow> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RemindersTable, List<ReminderRow>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'events__id__reminders__event_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eventDateTime => $composableBuilder(
    column: $table.eventDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconSlug => $composableBuilder(
    column: $table.iconSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gradientId => $composableBuilder(
    column: $table.gradientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GradientDirection?, GradientDirection, String>
  get gradientDirection => $composableBuilder(
    column: $table.gradientDirection,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoCrops => $composableBuilder(
    column: $table.photoCrops,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get photoDarken => $composableBuilder(
    column: $table.photoDarken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fontFamily => $composableBuilder(
    column: $table.fontFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CountUnit, CountUnit, String> get unit =>
      $composableBuilder(
        column: $table.unit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<RepeatRule, RepeatRule, String> get repeat =>
      $composableBuilder(
        column: $table.repeat,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacyHiveKey => $composableBuilder(
    column: $table.legacyHiveKey,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eventDateTime => $composableBuilder(
    column: $table.eventDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconSlug => $composableBuilder(
    column: $table.iconSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradientId => $composableBuilder(
    column: $table.gradientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradientDirection => $composableBuilder(
    column: $table.gradientDirection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoCrops => $composableBuilder(
    column: $table.photoCrops,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get photoDarken => $composableBuilder(
    column: $table.photoDarken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontFamily => $composableBuilder(
    column: $table.fontFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacyHiveKey => $composableBuilder(
    column: $table.legacyHiveKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get eventDateTime => $composableBuilder(
    column: $table.eventDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get iconSlug =>
      $composableBuilder(column: $table.iconSlug, builder: (column) => column);

  GeneratedColumn<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<String> get gradientId => $composableBuilder(
    column: $table.gradientId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GradientDirection?, String>
  get gradientDirection => $composableBuilder(
    column: $table.gradientDirection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoCrops => $composableBuilder(
    column: $table.photoCrops,
    builder: (column) => column,
  );

  GeneratedColumn<double> get photoDarken => $composableBuilder(
    column: $table.photoDarken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fontFamily => $composableBuilder(
    column: $table.fontFamily,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CountUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RepeatRule, String> get repeat =>
      $composableBuilder(column: $table.repeat, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get legacyHiveKey => $composableBuilder(
    column: $table.legacyHiveKey,
    builder: (column) => column,
  );

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          EventRow,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (EventRow, $$EventsTableReferences),
          EventRow,
          PrefetchHooks Function({bool remindersRefs})
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> eventDateTime = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<String?> iconSlug = const Value.absent(),
                Value<int> colorArgb = const Value.absent(),
                Value<String?> gradientId = const Value.absent(),
                Value<GradientDirection?> gradientDirection =
                    const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> photoCrops = const Value.absent(),
                Value<double> photoDarken = const Value.absent(),
                Value<String> fontFamily = const Value.absent(),
                Value<CountUnit> unit = const Value.absent(),
                Value<RepeatRule> repeat = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> legacyHiveKey = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                title: title,
                eventDateTime: eventDateTime,
                allDay: allDay,
                iconSlug: iconSlug,
                colorArgb: colorArgb,
                gradientId: gradientId,
                gradientDirection: gradientDirection,
                photoPath: photoPath,
                photoCrops: photoCrops,
                photoDarken: photoDarken,
                fontFamily: fontFamily,
                unit: unit,
                repeat: repeat,
                createdAt: createdAt,
                updatedAt: updatedAt,
                legacyHiveKey: legacyHiveKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required DateTime eventDateTime,
                Value<bool> allDay = const Value.absent(),
                Value<String?> iconSlug = const Value.absent(),
                required int colorArgb,
                Value<String?> gradientId = const Value.absent(),
                Value<GradientDirection?> gradientDirection =
                    const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> photoCrops = const Value.absent(),
                Value<double> photoDarken = const Value.absent(),
                Value<String> fontFamily = const Value.absent(),
                required CountUnit unit,
                required RepeatRule repeat,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int?> legacyHiveKey = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                title: title,
                eventDateTime: eventDateTime,
                allDay: allDay,
                iconSlug: iconSlug,
                colorArgb: colorArgb,
                gradientId: gradientId,
                gradientDirection: gradientDirection,
                photoPath: photoPath,
                photoCrops: photoCrops,
                photoDarken: photoDarken,
                fontFamily: fontFamily,
                unit: unit,
                repeat: repeat,
                createdAt: createdAt,
                updatedAt: updatedAt,
                legacyHiveKey: legacyHiveKey,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventsTable, EventRow>(table),
                  $$EventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({remindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (remindersRefs) db.reminders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (remindersRefs)
                    await $_getPrefetchedDataByColumns<
                      EventRow,
                      $EventsTable,
                      ReminderRow,
                      $RemindersTable
                    >(
                      currentTable: table,
                      referencedTable: $$EventsTableReferences
                          ._remindersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$EventsTableReferences(db, table, p0).remindersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'event_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      EventRow,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (EventRow, $$EventsTableReferences),
      EventRow,
      PrefetchHooks Function({bool remindersRefs})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  required int eventId,
  required int offsetMinutes,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<int> eventId,
  Value<int> offsetMinutes,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('reminders__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (ReminderRow, $$RemindersTableReferences),
          ReminderRow,
          PrefetchHooks Function({bool eventId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                eventId: eventId,
                offsetMinutes: offsetMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int eventId,
                required int offsetMinutes,
              }) => RemindersCompanion.insert(
                id: id,
                eventId: eventId,
                offsetMinutes: offsetMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, ReminderRow>(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
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
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$RemindersTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._eventIdTable(db)
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

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (ReminderRow, $$RemindersTableReferences),
      ReminderRow,
      PrefetchHooks Function({bool eventId})
    >;
typedef $$MetaTableCreateCompanionBuilder = MetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MetaTableUpdateCompanionBuilder = MetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MetaTableFilterComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
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

class $$MetaTableOrderingComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
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

class $$MetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
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

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaTable,
          MetaRow,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$AppDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MetaTable, MetaRow>(table),
                  BaseReferences<_$AppDatabase, $MetaTable, MetaRow>(
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

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaTable,
      MetaRow,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
