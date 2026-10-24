// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ChildrenTable extends Children with TableInfo<$ChildrenTable, Child> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildrenTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, avatar, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'children';
  @override
  VerificationContext validateIntegrity(
    Insertable<Child> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Child map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Child(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChildrenTable createAlias(String alias) {
    return $ChildrenTable(attachedDatabase, alias);
  }
}

class Child extends DataClass implements Insertable<Child> {
  final int id;
  final String avatar;
  final DateTime createdAt;
  const Child({
    required this.id,
    required this.avatar,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['avatar'] = Variable<String>(avatar);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChildrenCompanion toCompanion(bool nullToAbsent) {
    return ChildrenCompanion(
      id: Value(id),
      avatar: Value(avatar),
      createdAt: Value(createdAt),
    );
  }

  factory Child.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Child(
      id: serializer.fromJson<int>(json['id']),
      avatar: serializer.fromJson<String>(json['avatar']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'avatar': serializer.toJson<String>(avatar),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Child copyWith({int? id, String? avatar, DateTime? createdAt}) => Child(
    id: id ?? this.id,
    avatar: avatar ?? this.avatar,
    createdAt: createdAt ?? this.createdAt,
  );
  Child copyWithCompanion(ChildrenCompanion data) {
    return Child(
      id: data.id.present ? data.id.value : this.id,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Child(')
          ..write('id: $id, ')
          ..write('avatar: $avatar, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, avatar, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Child &&
          other.id == this.id &&
          other.avatar == this.avatar &&
          other.createdAt == this.createdAt);
}

class ChildrenCompanion extends UpdateCompanion<Child> {
  final Value<int> id;
  final Value<String> avatar;
  final Value<DateTime> createdAt;
  const ChildrenCompanion({
    this.id = const Value.absent(),
    this.avatar = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChildrenCompanion.insert({
    this.id = const Value.absent(),
    required String avatar,
    this.createdAt = const Value.absent(),
  }) : avatar = Value(avatar);
  static Insertable<Child> custom({
    Expression<int>? id,
    Expression<String>? avatar,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (avatar != null) 'avatar': avatar,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChildrenCompanion copyWith({
    Value<int>? id,
    Value<String>? avatar,
    Value<DateTime>? createdAt,
  }) {
    return ChildrenCompanion(
      id: id ?? this.id,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildrenCompanion(')
          ..write('id: $id, ')
          ..write('avatar: $avatar, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlacesTable extends Places with TableInfo<$PlacesTable, Place> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<int> childId = GeneratedColumn<int>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geohash6Meta = const VerificationMeta(
    'geohash6',
  );
  @override
  late final GeneratedColumn<String> geohash6 = GeneratedColumn<String>(
    'geohash6',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 6,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    childId,
    type,
    label,
    district,
    geohash6,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places';
  @override
  VerificationContext validateIntegrity(
    Insertable<Place> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    }
    if (data.containsKey('geohash6')) {
      context.handle(
        _geohash6Meta,
        geohash6.isAcceptableOrUnknown(data['geohash6']!, _geohash6Meta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Place map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Place(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}child_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      ),
      geohash6: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geohash6'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlacesTable createAlias(String alias) {
    return $PlacesTable(attachedDatabase, alias);
  }
}

class Place extends DataClass implements Insertable<Place> {
  final int id;
  final int childId;

  /// auto | home | school | park | grandparents | custom
  final String type;
  final String? label;
  final String? district;
  final String? geohash6;
  final DateTime createdAt;
  const Place({
    required this.id,
    required this.childId,
    required this.type,
    this.label,
    this.district,
    this.geohash6,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['child_id'] = Variable<int>(childId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || district != null) {
      map['district'] = Variable<String>(district);
    }
    if (!nullToAbsent || geohash6 != null) {
      map['geohash6'] = Variable<String>(geohash6);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlacesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCompanion(
      id: Value(id),
      childId: Value(childId),
      type: Value(type),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      district: district == null && nullToAbsent
          ? const Value.absent()
          : Value(district),
      geohash6: geohash6 == null && nullToAbsent
          ? const Value.absent()
          : Value(geohash6),
      createdAt: Value(createdAt),
    );
  }

  factory Place.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Place(
      id: serializer.fromJson<int>(json['id']),
      childId: serializer.fromJson<int>(json['childId']),
      type: serializer.fromJson<String>(json['type']),
      label: serializer.fromJson<String?>(json['label']),
      district: serializer.fromJson<String?>(json['district']),
      geohash6: serializer.fromJson<String?>(json['geohash6']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'childId': serializer.toJson<int>(childId),
      'type': serializer.toJson<String>(type),
      'label': serializer.toJson<String?>(label),
      'district': serializer.toJson<String?>(district),
      'geohash6': serializer.toJson<String?>(geohash6),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Place copyWith({
    int? id,
    int? childId,
    String? type,
    Value<String?> label = const Value.absent(),
    Value<String?> district = const Value.absent(),
    Value<String?> geohash6 = const Value.absent(),
    DateTime? createdAt,
  }) => Place(
    id: id ?? this.id,
    childId: childId ?? this.childId,
    type: type ?? this.type,
    label: label.present ? label.value : this.label,
    district: district.present ? district.value : this.district,
    geohash6: geohash6.present ? geohash6.value : this.geohash6,
    createdAt: createdAt ?? this.createdAt,
  );
  Place copyWithCompanion(PlacesCompanion data) {
    return Place(
      id: data.id.present ? data.id.value : this.id,
      childId: data.childId.present ? data.childId.value : this.childId,
      type: data.type.present ? data.type.value : this.type,
      label: data.label.present ? data.label.value : this.label,
      district: data.district.present ? data.district.value : this.district,
      geohash6: data.geohash6.present ? data.geohash6.value : this.geohash6,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Place(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('district: $district, ')
          ..write('geohash6: $geohash6, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, childId, type, label, district, geohash6, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Place &&
          other.id == this.id &&
          other.childId == this.childId &&
          other.type == this.type &&
          other.label == this.label &&
          other.district == this.district &&
          other.geohash6 == this.geohash6 &&
          other.createdAt == this.createdAt);
}

class PlacesCompanion extends UpdateCompanion<Place> {
  final Value<int> id;
  final Value<int> childId;
  final Value<String> type;
  final Value<String?> label;
  final Value<String?> district;
  final Value<String?> geohash6;
  final Value<DateTime> createdAt;
  const PlacesCompanion({
    this.id = const Value.absent(),
    this.childId = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.district = const Value.absent(),
    this.geohash6 = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlacesCompanion.insert({
    this.id = const Value.absent(),
    required int childId,
    required String type,
    this.label = const Value.absent(),
    this.district = const Value.absent(),
    this.geohash6 = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : childId = Value(childId),
       type = Value(type);
  static Insertable<Place> custom({
    Expression<int>? id,
    Expression<int>? childId,
    Expression<String>? type,
    Expression<String>? label,
    Expression<String>? district,
    Expression<String>? geohash6,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (type != null) 'type': type,
      if (label != null) 'label': label,
      if (district != null) 'district': district,
      if (geohash6 != null) 'geohash6': geohash6,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlacesCompanion copyWith({
    Value<int>? id,
    Value<int>? childId,
    Value<String>? type,
    Value<String?>? label,
    Value<String?>? district,
    Value<String?>? geohash6,
    Value<DateTime>? createdAt,
  }) {
    return PlacesCompanion(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      type: type ?? this.type,
      label: label ?? this.label,
      district: district ?? this.district,
      geohash6: geohash6 ?? this.geohash6,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<int>(childId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (geohash6.present) {
      map['geohash6'] = Variable<String>(geohash6.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCompanion(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('district: $district, ')
          ..write('geohash6: $geohash6, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ArtworksTable extends Artworks with TableInfo<$ArtworksTable, Artwork> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtworksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<int> childId = GeneratedColumn<int>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id)',
    ),
  );
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  @override
  late final GeneratedColumn<int> placeId = GeneratedColumn<int>(
    'place_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES places (id)',
    ),
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sharedAtMeta = const VerificationMeta(
    'sharedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sharedAt = GeneratedColumn<DateTime>(
    'shared_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    childId,
    placeId,
    style,
    detail,
    folder,
    tags,
    isFavorite,
    isCompleted,
    sharedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artworks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Artwork> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    } else if (isInserting) {
      context.missing(_detailMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('shared_at')) {
      context.handle(
        _sharedAtMeta,
        sharedAt.isAcceptableOrUnknown(data['shared_at']!, _sharedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Artwork map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Artwork(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}child_id'],
      )!,
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_id'],
      ),
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      sharedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}shared_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ArtworksTable createAlias(String alias) {
    return $ArtworksTable(attachedDatabase, alias);
  }
}

class Artwork extends DataClass implements Insertable<Artwork> {
  final int id;
  final int childId;
  final int? placeId;

  /// realistic | cute | template
  final String style;

  /// simple | normal | detailed
  final String detail;

  /// Folder holding this artwork's files, relative to the artwork store.
  final String folder;

  /// Comma-separated categories from on-device image labeling.
  final String tags;
  final bool isFavorite;
  final bool isCompleted;
  final DateTime? sharedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Artwork({
    required this.id,
    required this.childId,
    this.placeId,
    required this.style,
    required this.detail,
    required this.folder,
    required this.tags,
    required this.isFavorite,
    required this.isCompleted,
    this.sharedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['child_id'] = Variable<int>(childId);
    if (!nullToAbsent || placeId != null) {
      map['place_id'] = Variable<int>(placeId);
    }
    map['style'] = Variable<String>(style);
    map['detail'] = Variable<String>(detail);
    map['folder'] = Variable<String>(folder);
    map['tags'] = Variable<String>(tags);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || sharedAt != null) {
      map['shared_at'] = Variable<DateTime>(sharedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ArtworksCompanion toCompanion(bool nullToAbsent) {
    return ArtworksCompanion(
      id: Value(id),
      childId: Value(childId),
      placeId: placeId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeId),
      style: Value(style),
      detail: Value(detail),
      folder: Value(folder),
      tags: Value(tags),
      isFavorite: Value(isFavorite),
      isCompleted: Value(isCompleted),
      sharedAt: sharedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Artwork.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Artwork(
      id: serializer.fromJson<int>(json['id']),
      childId: serializer.fromJson<int>(json['childId']),
      placeId: serializer.fromJson<int?>(json['placeId']),
      style: serializer.fromJson<String>(json['style']),
      detail: serializer.fromJson<String>(json['detail']),
      folder: serializer.fromJson<String>(json['folder']),
      tags: serializer.fromJson<String>(json['tags']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      sharedAt: serializer.fromJson<DateTime?>(json['sharedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'childId': serializer.toJson<int>(childId),
      'placeId': serializer.toJson<int?>(placeId),
      'style': serializer.toJson<String>(style),
      'detail': serializer.toJson<String>(detail),
      'folder': serializer.toJson<String>(folder),
      'tags': serializer.toJson<String>(tags),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'sharedAt': serializer.toJson<DateTime?>(sharedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Artwork copyWith({
    int? id,
    int? childId,
    Value<int?> placeId = const Value.absent(),
    String? style,
    String? detail,
    String? folder,
    String? tags,
    bool? isFavorite,
    bool? isCompleted,
    Value<DateTime?> sharedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Artwork(
    id: id ?? this.id,
    childId: childId ?? this.childId,
    placeId: placeId.present ? placeId.value : this.placeId,
    style: style ?? this.style,
    detail: detail ?? this.detail,
    folder: folder ?? this.folder,
    tags: tags ?? this.tags,
    isFavorite: isFavorite ?? this.isFavorite,
    isCompleted: isCompleted ?? this.isCompleted,
    sharedAt: sharedAt.present ? sharedAt.value : this.sharedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Artwork copyWithCompanion(ArtworksCompanion data) {
    return Artwork(
      id: data.id.present ? data.id.value : this.id,
      childId: data.childId.present ? data.childId.value : this.childId,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      style: data.style.present ? data.style.value : this.style,
      detail: data.detail.present ? data.detail.value : this.detail,
      folder: data.folder.present ? data.folder.value : this.folder,
      tags: data.tags.present ? data.tags.value : this.tags,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      sharedAt: data.sharedAt.present ? data.sharedAt.value : this.sharedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Artwork(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('placeId: $placeId, ')
          ..write('style: $style, ')
          ..write('detail: $detail, ')
          ..write('folder: $folder, ')
          ..write('tags: $tags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('sharedAt: $sharedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    childId,
    placeId,
    style,
    detail,
    folder,
    tags,
    isFavorite,
    isCompleted,
    sharedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artwork &&
          other.id == this.id &&
          other.childId == this.childId &&
          other.placeId == this.placeId &&
          other.style == this.style &&
          other.detail == this.detail &&
          other.folder == this.folder &&
          other.tags == this.tags &&
          other.isFavorite == this.isFavorite &&
          other.isCompleted == this.isCompleted &&
          other.sharedAt == this.sharedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ArtworksCompanion extends UpdateCompanion<Artwork> {
  final Value<int> id;
  final Value<int> childId;
  final Value<int?> placeId;
  final Value<String> style;
  final Value<String> detail;
  final Value<String> folder;
  final Value<String> tags;
  final Value<bool> isFavorite;
  final Value<bool> isCompleted;
  final Value<DateTime?> sharedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ArtworksCompanion({
    this.id = const Value.absent(),
    this.childId = const Value.absent(),
    this.placeId = const Value.absent(),
    this.style = const Value.absent(),
    this.detail = const Value.absent(),
    this.folder = const Value.absent(),
    this.tags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.sharedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ArtworksCompanion.insert({
    this.id = const Value.absent(),
    required int childId,
    this.placeId = const Value.absent(),
    required String style,
    required String detail,
    required String folder,
    this.tags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.sharedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : childId = Value(childId),
       style = Value(style),
       detail = Value(detail),
       folder = Value(folder);
  static Insertable<Artwork> custom({
    Expression<int>? id,
    Expression<int>? childId,
    Expression<int>? placeId,
    Expression<String>? style,
    Expression<String>? detail,
    Expression<String>? folder,
    Expression<String>? tags,
    Expression<bool>? isFavorite,
    Expression<bool>? isCompleted,
    Expression<DateTime>? sharedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (placeId != null) 'place_id': placeId,
      if (style != null) 'style': style,
      if (detail != null) 'detail': detail,
      if (folder != null) 'folder': folder,
      if (tags != null) 'tags': tags,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (sharedAt != null) 'shared_at': sharedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ArtworksCompanion copyWith({
    Value<int>? id,
    Value<int>? childId,
    Value<int?>? placeId,
    Value<String>? style,
    Value<String>? detail,
    Value<String>? folder,
    Value<String>? tags,
    Value<bool>? isFavorite,
    Value<bool>? isCompleted,
    Value<DateTime?>? sharedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ArtworksCompanion(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      placeId: placeId ?? this.placeId,
      style: style ?? this.style,
      detail: detail ?? this.detail,
      folder: folder ?? this.folder,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      sharedAt: sharedAt ?? this.sharedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<int>(childId.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<int>(placeId.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (sharedAt.present) {
      map['shared_at'] = Variable<DateTime>(sharedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtworksCompanion(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('placeId: $placeId, ')
          ..write('style: $style, ')
          ..write('detail: $detail, ')
          ..write('folder: $folder, ')
          ..write('tags: $tags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('sharedAt: $sharedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
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
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
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
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
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

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
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
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
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
  late final $ChildrenTable children = $ChildrenTable(this);
  late final $PlacesTable places = $PlacesTable(this);
  late final $ArtworksTable artworks = $ArtworksTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    children,
    places,
    artworks,
    settings,
  ];
}

typedef $$ChildrenTableCreateCompanionBuilder = ChildrenCompanion Function({
  Value<int> id,
  required String avatar,
  Value<DateTime> createdAt,
});
typedef $$ChildrenTableUpdateCompanionBuilder = ChildrenCompanion Function({
  Value<int> id,
  Value<String> avatar,
  Value<DateTime> createdAt,
});

final class $$ChildrenTableReferences
    extends BaseReferences<_$AppDatabase, $ChildrenTable, Child> {
  $$ChildrenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlacesTable, List<Place>> _placesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.places,
    aliasName: 'children__id__places__child_id',
  );

  $$PlacesTableProcessedTableManager get placesRefs {
    final manager = $$PlacesTableTableManager(
      $_db,
      $_db.places,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_placesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArtworksTable, List<Artwork>> _artworksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.artworks,
    aliasName: 'children__id__artworks__child_id',
  );

  $$ArtworksTableProcessedTableManager get artworksRefs {
    final manager = $$ArtworksTableTableManager(
      $_db,
      $_db.artworks,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_artworksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChildrenTableFilterComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableFilterComposer({
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

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> placesRefs(
    Expression<bool> Function($$PlacesTableFilterComposer f) f,
  ) {
    final $$PlacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableFilterComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> artworksRefs(
    Expression<bool> Function($$ArtworksTableFilterComposer f) f,
  ) {
    final $$ArtworksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableFilterComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableOrderingComposer({
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

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChildrenTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> placesRefs<T extends Object>(
    Expression<T> Function($$PlacesTableAnnotationComposer a) f,
  ) {
    final $$PlacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableAnnotationComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> artworksRefs<T extends Object>(
    Expression<T> Function($$ArtworksTableAnnotationComposer a) f,
  ) {
    final $$ArtworksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableAnnotationComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildrenTable,
          Child,
          $$ChildrenTableFilterComposer,
          $$ChildrenTableOrderingComposer,
          $$ChildrenTableAnnotationComposer,
          $$ChildrenTableCreateCompanionBuilder,
          $$ChildrenTableUpdateCompanionBuilder,
          (Child, $$ChildrenTableReferences),
          Child,
          PrefetchHooks Function({bool placesRefs, bool artworksRefs})
        > {
  $$ChildrenTableTableManager(_$AppDatabase db, $ChildrenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildrenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildrenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildrenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> avatar = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) => ChildrenCompanion(id: id, avatar: avatar, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String avatar,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChildrenCompanion.insert(
                id: id,
                avatar: avatar,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChildrenTable, Child>(table),
                  $$ChildrenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({placesRefs = false, artworksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (placesRefs) db.places,
                if (artworksRefs) db.artworks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (placesRefs)
                    await $_getPrefetchedDataByColumns<
                      Child,
                      $ChildrenTable,
                      Place,
                      $PlacesTable
                    >(
                      currentTable: table,
                      referencedTable: $$ChildrenTableReferences
                          ._placesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChildrenTableReferences(db, table, p0).placesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'child_id',
                      typedResults: items,
                    ),
                  if (artworksRefs)
                    await $_getPrefetchedDataByColumns<
                      Child,
                      $ChildrenTable,
                      Artwork,
                      $ArtworksTable
                    >(
                      currentTable: table,
                      referencedTable: $$ChildrenTableReferences
                          ._artworksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChildrenTableReferences(db, table, p0).artworksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'child_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChildrenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildrenTable,
      Child,
      $$ChildrenTableFilterComposer,
      $$ChildrenTableOrderingComposer,
      $$ChildrenTableAnnotationComposer,
      $$ChildrenTableCreateCompanionBuilder,
      $$ChildrenTableUpdateCompanionBuilder,
      (Child, $$ChildrenTableReferences),
      Child,
      PrefetchHooks Function({bool placesRefs, bool artworksRefs})
    >;
typedef $$PlacesTableCreateCompanionBuilder = PlacesCompanion Function({
  Value<int> id,
  required int childId,
  required String type,
  Value<String?> label,
  Value<String?> district,
  Value<String?> geohash6,
  Value<DateTime> createdAt,
});
typedef $$PlacesTableUpdateCompanionBuilder = PlacesCompanion Function({
  Value<int> id,
  Value<int> childId,
  Value<String> type,
  Value<String?> label,
  Value<String?> district,
  Value<String?> geohash6,
  Value<DateTime> createdAt,
});

final class $$PlacesTableReferences
    extends BaseReferences<_$AppDatabase, $PlacesTable, Place> {
  $$PlacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('places__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<int>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ArtworksTable, List<Artwork>> _artworksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.artworks,
    aliasName: 'places__id__artworks__place_id',
  );

  $$ArtworksTableProcessedTableManager get artworksRefs {
    final manager = $$ArtworksTableTableManager(
      $_db,
      $_db.artworks,
    ).filter((f) => f.placeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_artworksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlacesTableFilterComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geohash6 => $composableBuilder(
    column: $table.geohash6,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> artworksRefs(
    Expression<bool> Function($$ArtworksTableFilterComposer f) f,
  ) {
    final $$ArtworksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.placeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableFilterComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geohash6 => $composableBuilder(
    column: $table.geohash6,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get geohash6 =>
      $composableBuilder(column: $table.geohash6, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> artworksRefs<T extends Object>(
    Expression<T> Function($$ArtworksTableAnnotationComposer a) f,
  ) {
    final $$ArtworksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.placeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableAnnotationComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlacesTable,
          Place,
          $$PlacesTableFilterComposer,
          $$PlacesTableOrderingComposer,
          $$PlacesTableAnnotationComposer,
          $$PlacesTableCreateCompanionBuilder,
          $$PlacesTableUpdateCompanionBuilder,
          (Place, $$PlacesTableReferences),
          Place,
          PrefetchHooks Function({bool childId, bool artworksRefs})
        > {
  $$PlacesTableTableManager(_$AppDatabase db, $PlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> childId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> district = const Value.absent(),
                Value<String?> geohash6 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlacesCompanion(
                id: id,
                childId: childId,
                type: type,
                label: label,
                district: district,
                geohash6: geohash6,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int childId,
                required String type,
                Value<String?> label = const Value.absent(),
                Value<String?> district = const Value.absent(),
                Value<String?> geohash6 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlacesCompanion.insert(
                id: id,
                childId: childId,
                type: type,
                label: label,
                district: district,
                geohash6: geohash6,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlacesTable, Place>(table),
                  $$PlacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false, artworksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (artworksRefs) db.artworks],
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
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$PlacesTableReferences._childIdTable(
                          db,
                        ),
                        referencedColumn: $$PlacesTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (artworksRefs)
                    await $_getPrefetchedDataByColumns<
                      Place,
                      $PlacesTable,
                      Artwork,
                      $ArtworksTable
                    >(
                      currentTable: table,
                      referencedTable: $$PlacesTableReferences
                          ._artworksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlacesTableReferences(db, table, p0).artworksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'place_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlacesTable,
      Place,
      $$PlacesTableFilterComposer,
      $$PlacesTableOrderingComposer,
      $$PlacesTableAnnotationComposer,
      $$PlacesTableCreateCompanionBuilder,
      $$PlacesTableUpdateCompanionBuilder,
      (Place, $$PlacesTableReferences),
      Place,
      PrefetchHooks Function({bool childId, bool artworksRefs})
    >;
typedef $$ArtworksTableCreateCompanionBuilder = ArtworksCompanion Function({
  Value<int> id,
  required int childId,
  Value<int?> placeId,
  required String style,
  required String detail,
  required String folder,
  Value<String> tags,
  Value<bool> isFavorite,
  Value<bool> isCompleted,
  Value<DateTime?> sharedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ArtworksTableUpdateCompanionBuilder = ArtworksCompanion Function({
  Value<int> id,
  Value<int> childId,
  Value<int?> placeId,
  Value<String> style,
  Value<String> detail,
  Value<String> folder,
  Value<String> tags,
  Value<bool> isFavorite,
  Value<bool> isCompleted,
  Value<DateTime?> sharedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ArtworksTableReferences
    extends BaseReferences<_$AppDatabase, $ArtworksTable, Artwork> {
  $$ArtworksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('artworks__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<int>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlacesTable _placeIdTable(_$AppDatabase db) =>
      db.places.createAlias('artworks__place_id__places__id');

  $$PlacesTableProcessedTableManager? get placeId {
    final $_column = $_itemColumn<int>('place_id');
    if ($_column == null) return null;
    final manager = $$PlacesTableTableManager(
      $_db,
      $_db.places,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_placeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArtworksTableFilterComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableFilterComposer({
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

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sharedAt => $composableBuilder(
    column: $table.sharedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlacesTableFilterComposer get placeId {
    final $$PlacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableFilterComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtworksTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableOrderingComposer({
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

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sharedAt => $composableBuilder(
    column: $table.sharedAt,
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

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlacesTableOrderingComposer get placeId {
    final $$PlacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableOrderingComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtworksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sharedAt =>
      $composableBuilder(column: $table.sharedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlacesTableAnnotationComposer get placeId {
    final $$PlacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableAnnotationComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtworksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtworksTable,
          Artwork,
          $$ArtworksTableFilterComposer,
          $$ArtworksTableOrderingComposer,
          $$ArtworksTableAnnotationComposer,
          $$ArtworksTableCreateCompanionBuilder,
          $$ArtworksTableUpdateCompanionBuilder,
          (Artwork, $$ArtworksTableReferences),
          Artwork,
          PrefetchHooks Function({bool childId, bool placeId})
        > {
  $$ArtworksTableTableManager(_$AppDatabase db, $ArtworksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtworksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtworksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtworksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> childId = const Value.absent(),
                Value<int?> placeId = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<String> folder = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> sharedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ArtworksCompanion(
                id: id,
                childId: childId,
                placeId: placeId,
                style: style,
                detail: detail,
                folder: folder,
                tags: tags,
                isFavorite: isFavorite,
                isCompleted: isCompleted,
                sharedAt: sharedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int childId,
                Value<int?> placeId = const Value.absent(),
                required String style,
                required String detail,
                required String folder,
                Value<String> tags = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> sharedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ArtworksCompanion.insert(
                id: id,
                childId: childId,
                placeId: placeId,
                style: style,
                detail: detail,
                folder: folder,
                tags: tags,
                isFavorite: isFavorite,
                isCompleted: isCompleted,
                sharedAt: sharedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArtworksTable, Artwork>(table),
                  $$ArtworksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false, placeId = false}) {
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
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$ArtworksTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$ArtworksTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (placeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.placeId,
                        referencedTable: $$ArtworksTableReferences
                            ._placeIdTable(db),
                        referencedColumn: $$ArtworksTableReferences
                            ._placeIdTable(db)
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

typedef $$ArtworksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtworksTable,
      Artwork,
      $$ArtworksTableFilterComposer,
      $$ArtworksTableOrderingComposer,
      $$ArtworksTableAnnotationComposer,
      $$ArtworksTableCreateCompanionBuilder,
      $$ArtworksTableUpdateCompanionBuilder,
      (Artwork, $$ArtworksTableReferences),
      Artwork,
      PrefetchHooks Function({bool childId, bool placeId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
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

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChildrenTableTableManager get children =>
      $$ChildrenTableTableManager(_db, _db.children);
  $$PlacesTableTableManager get places =>
      $$PlacesTableTableManager(_db, _db.places);
  $$ArtworksTableTableManager get artworks =>
      $$ArtworksTableTableManager(_db, _db.artworks);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
