// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopesMeta = const VerificationMeta('scopes');
  @override
  late final GeneratedColumn<String> scopes = GeneratedColumn<String>(
    'scopes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _needsReloginMeta = const VerificationMeta(
    'needsRelogin',
  );
  @override
  late final GeneratedColumn<bool> needsRelogin = GeneratedColumn<bool>(
    'needs_relogin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_relogin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    characterId,
    name,
    scopes,
    needsRelogin,
    sortOrder,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scopes')) {
      context.handle(
        _scopesMeta,
        scopes.isAcceptableOrUnknown(data['scopes']!, _scopesMeta),
      );
    }
    if (data.containsKey('needs_relogin')) {
      context.handle(
        _needsReloginMeta,
        needsRelogin.isAcceptableOrUnknown(
          data['needs_relogin']!,
          _needsReloginMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterId};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scopes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scopes'],
      )!,
      needsRelogin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_relogin'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final int characterId;
  final String name;
  final String scopes;
  final bool needsRelogin;
  final int sortOrder;
  final DateTime addedAt;
  const Character({
    required this.characterId,
    required this.name,
    required this.scopes,
    required this.needsRelogin,
    required this.sortOrder,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<int>(characterId);
    map['name'] = Variable<String>(name);
    map['scopes'] = Variable<String>(scopes);
    map['needs_relogin'] = Variable<bool>(needsRelogin);
    map['sort_order'] = Variable<int>(sortOrder);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      characterId: Value(characterId),
      name: Value(name),
      scopes: Value(scopes),
      needsRelogin: Value(needsRelogin),
      sortOrder: Value(sortOrder),
      addedAt: Value(addedAt),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      characterId: serializer.fromJson<int>(json['characterId']),
      name: serializer.fromJson<String>(json['name']),
      scopes: serializer.fromJson<String>(json['scopes']),
      needsRelogin: serializer.fromJson<bool>(json['needsRelogin']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<int>(characterId),
      'name': serializer.toJson<String>(name),
      'scopes': serializer.toJson<String>(scopes),
      'needsRelogin': serializer.toJson<bool>(needsRelogin),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Character copyWith({
    int? characterId,
    String? name,
    String? scopes,
    bool? needsRelogin,
    int? sortOrder,
    DateTime? addedAt,
  }) => Character(
    characterId: characterId ?? this.characterId,
    name: name ?? this.name,
    scopes: scopes ?? this.scopes,
    needsRelogin: needsRelogin ?? this.needsRelogin,
    sortOrder: sortOrder ?? this.sortOrder,
    addedAt: addedAt ?? this.addedAt,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      name: data.name.present ? data.name.value : this.name,
      scopes: data.scopes.present ? data.scopes.value : this.scopes,
      needsRelogin: data.needsRelogin.present
          ? data.needsRelogin.value
          : this.needsRelogin,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('scopes: $scopes, ')
          ..write('needsRelogin: $needsRelogin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(characterId, name, scopes, needsRelogin, sortOrder, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.characterId == this.characterId &&
          other.name == this.name &&
          other.scopes == this.scopes &&
          other.needsRelogin == this.needsRelogin &&
          other.sortOrder == this.sortOrder &&
          other.addedAt == this.addedAt);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<int> characterId;
  final Value<String> name;
  final Value<String> scopes;
  final Value<bool> needsRelogin;
  final Value<int> sortOrder;
  final Value<DateTime> addedAt;
  const CharactersCompanion({
    this.characterId = const Value.absent(),
    this.name = const Value.absent(),
    this.scopes = const Value.absent(),
    this.needsRelogin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  CharactersCompanion.insert({
    this.characterId = const Value.absent(),
    required String name,
    this.scopes = const Value.absent(),
    this.needsRelogin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.addedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Character> custom({
    Expression<int>? characterId,
    Expression<String>? name,
    Expression<String>? scopes,
    Expression<bool>? needsRelogin,
    Expression<int>? sortOrder,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (name != null) 'name': name,
      if (scopes != null) 'scopes': scopes,
      if (needsRelogin != null) 'needs_relogin': needsRelogin,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  CharactersCompanion copyWith({
    Value<int>? characterId,
    Value<String>? name,
    Value<String>? scopes,
    Value<bool>? needsRelogin,
    Value<int>? sortOrder,
    Value<DateTime>? addedAt,
  }) {
    return CharactersCompanion(
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      scopes: scopes ?? this.scopes,
      needsRelogin: needsRelogin ?? this.needsRelogin,
      sortOrder: sortOrder ?? this.sortOrder,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scopes.present) {
      map['scopes'] = Variable<String>(scopes.value);
    }
    if (needsRelogin.present) {
      map['needs_relogin'] = Variable<bool>(needsRelogin.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('scopes: $scopes, ')
          ..write('needsRelogin: $needsRelogin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $HttpCacheEntriesTable extends HttpCacheEntries
    with TableInfo<$HttpCacheEntriesTable, HttpCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HttpCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresMeta = const VerificationMeta(
    'expires',
  );
  @override
  late final GeneratedColumn<DateTime> expires = GeneratedColumn<DateTime>(
    'expires',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pagesMeta = const VerificationMeta('pages');
  @override
  late final GeneratedColumn<int> pages = GeneratedColumn<int>(
    'pages',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storedAtMeta = const VerificationMeta(
    'storedAt',
  );
  @override
  late final GeneratedColumn<DateTime> storedAt = GeneratedColumn<DateTime>(
    'stored_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    body,
    etag,
    expires,
    lastModified,
    pages,
    storedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'http_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HttpCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('expires')) {
      context.handle(
        _expiresMeta,
        expires.isAcceptableOrUnknown(data['expires']!, _expiresMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('pages')) {
      context.handle(
        _pagesMeta,
        pages.isAcceptableOrUnknown(data['pages']!, _pagesMeta),
      );
    }
    if (data.containsKey('stored_at')) {
      context.handle(
        _storedAtMeta,
        storedAt.isAcceptableOrUnknown(data['stored_at']!, _storedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_storedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  HttpCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HttpCacheEntry(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      expires: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      ),
      pages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages'],
      ),
      storedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stored_at'],
      )!,
    );
  }

  @override
  $HttpCacheEntriesTable createAlias(String alias) {
    return $HttpCacheEntriesTable(attachedDatabase, alias);
  }
}

class HttpCacheEntry extends DataClass implements Insertable<HttpCacheEntry> {
  final String cacheKey;
  final String body;
  final String? etag;
  final DateTime? expires;
  final String? lastModified;
  final int? pages;
  final DateTime storedAt;
  const HttpCacheEntry({
    required this.cacheKey,
    required this.body,
    this.etag,
    this.expires,
    this.lastModified,
    this.pages,
    required this.storedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || expires != null) {
      map['expires'] = Variable<DateTime>(expires);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<String>(lastModified);
    }
    if (!nullToAbsent || pages != null) {
      map['pages'] = Variable<int>(pages);
    }
    map['stored_at'] = Variable<DateTime>(storedAt);
    return map;
  }

  HttpCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return HttpCacheEntriesCompanion(
      cacheKey: Value(cacheKey),
      body: Value(body),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      expires: expires == null && nullToAbsent
          ? const Value.absent()
          : Value(expires),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      pages: pages == null && nullToAbsent
          ? const Value.absent()
          : Value(pages),
      storedAt: Value(storedAt),
    );
  }

  factory HttpCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HttpCacheEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      body: serializer.fromJson<String>(json['body']),
      etag: serializer.fromJson<String?>(json['etag']),
      expires: serializer.fromJson<DateTime?>(json['expires']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
      pages: serializer.fromJson<int?>(json['pages']),
      storedAt: serializer.fromJson<DateTime>(json['storedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'body': serializer.toJson<String>(body),
      'etag': serializer.toJson<String?>(etag),
      'expires': serializer.toJson<DateTime?>(expires),
      'lastModified': serializer.toJson<String?>(lastModified),
      'pages': serializer.toJson<int?>(pages),
      'storedAt': serializer.toJson<DateTime>(storedAt),
    };
  }

  HttpCacheEntry copyWith({
    String? cacheKey,
    String? body,
    Value<String?> etag = const Value.absent(),
    Value<DateTime?> expires = const Value.absent(),
    Value<String?> lastModified = const Value.absent(),
    Value<int?> pages = const Value.absent(),
    DateTime? storedAt,
  }) => HttpCacheEntry(
    cacheKey: cacheKey ?? this.cacheKey,
    body: body ?? this.body,
    etag: etag.present ? etag.value : this.etag,
    expires: expires.present ? expires.value : this.expires,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
    pages: pages.present ? pages.value : this.pages,
    storedAt: storedAt ?? this.storedAt,
  );
  HttpCacheEntry copyWithCompanion(HttpCacheEntriesCompanion data) {
    return HttpCacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      body: data.body.present ? data.body.value : this.body,
      etag: data.etag.present ? data.etag.value : this.etag,
      expires: data.expires.present ? data.expires.value : this.expires,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      pages: data.pages.present ? data.pages.value : this.pages,
      storedAt: data.storedAt.present ? data.storedAt.value : this.storedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HttpCacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('body: $body, ')
          ..write('etag: $etag, ')
          ..write('expires: $expires, ')
          ..write('lastModified: $lastModified, ')
          ..write('pages: $pages, ')
          ..write('storedAt: $storedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheKey, body, etag, expires, lastModified, pages, storedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HttpCacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.body == this.body &&
          other.etag == this.etag &&
          other.expires == this.expires &&
          other.lastModified == this.lastModified &&
          other.pages == this.pages &&
          other.storedAt == this.storedAt);
}

class HttpCacheEntriesCompanion extends UpdateCompanion<HttpCacheEntry> {
  final Value<String> cacheKey;
  final Value<String> body;
  final Value<String?> etag;
  final Value<DateTime?> expires;
  final Value<String?> lastModified;
  final Value<int?> pages;
  final Value<DateTime> storedAt;
  final Value<int> rowid;
  const HttpCacheEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.body = const Value.absent(),
    this.etag = const Value.absent(),
    this.expires = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.pages = const Value.absent(),
    this.storedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HttpCacheEntriesCompanion.insert({
    required String cacheKey,
    required String body,
    this.etag = const Value.absent(),
    this.expires = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.pages = const Value.absent(),
    required DateTime storedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       body = Value(body),
       storedAt = Value(storedAt);
  static Insertable<HttpCacheEntry> custom({
    Expression<String>? cacheKey,
    Expression<String>? body,
    Expression<String>? etag,
    Expression<DateTime>? expires,
    Expression<String>? lastModified,
    Expression<int>? pages,
    Expression<DateTime>? storedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (body != null) 'body': body,
      if (etag != null) 'etag': etag,
      if (expires != null) 'expires': expires,
      if (lastModified != null) 'last_modified': lastModified,
      if (pages != null) 'pages': pages,
      if (storedAt != null) 'stored_at': storedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HttpCacheEntriesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? body,
    Value<String?>? etag,
    Value<DateTime?>? expires,
    Value<String?>? lastModified,
    Value<int?>? pages,
    Value<DateTime>? storedAt,
    Value<int>? rowid,
  }) {
    return HttpCacheEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      body: body ?? this.body,
      etag: etag ?? this.etag,
      expires: expires ?? this.expires,
      lastModified: lastModified ?? this.lastModified,
      pages: pages ?? this.pages,
      storedAt: storedAt ?? this.storedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (expires.present) {
      map['expires'] = Variable<DateTime>(expires.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (pages.present) {
      map['pages'] = Variable<int>(pages.value);
    }
    if (storedAt.present) {
      map['stored_at'] = Variable<DateTime>(storedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HttpCacheEntriesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('body: $body, ')
          ..write('etag: $etag, ')
          ..write('expires: $expires, ')
          ..write('lastModified: $lastModified, ')
          ..write('pages: $pages, ')
          ..write('storedAt: $storedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteTypesTable extends FavoriteTypes
    with TableInfo<$FavoriteTypesTable, FavoriteType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<int> typeId = GeneratedColumn<int>(
    'type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [typeId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {typeId};
  @override
  FavoriteType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteType(
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoriteTypesTable createAlias(String alias) {
    return $FavoriteTypesTable(attachedDatabase, alias);
  }
}

class FavoriteType extends DataClass implements Insertable<FavoriteType> {
  final int typeId;
  final DateTime addedAt;
  const FavoriteType({required this.typeId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type_id'] = Variable<int>(typeId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoriteTypesCompanion toCompanion(bool nullToAbsent) {
    return FavoriteTypesCompanion(
      typeId: Value(typeId),
      addedAt: Value(addedAt),
    );
  }

  factory FavoriteType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteType(
      typeId: serializer.fromJson<int>(json['typeId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'typeId': serializer.toJson<int>(typeId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FavoriteType copyWith({int? typeId, DateTime? addedAt}) => FavoriteType(
    typeId: typeId ?? this.typeId,
    addedAt: addedAt ?? this.addedAt,
  );
  FavoriteType copyWithCompanion(FavoriteTypesCompanion data) {
    return FavoriteType(
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteType(')
          ..write('typeId: $typeId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(typeId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteType &&
          other.typeId == this.typeId &&
          other.addedAt == this.addedAt);
}

class FavoriteTypesCompanion extends UpdateCompanion<FavoriteType> {
  final Value<int> typeId;
  final Value<DateTime> addedAt;
  const FavoriteTypesCompanion({
    this.typeId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoriteTypesCompanion.insert({
    this.typeId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  static Insertable<FavoriteType> custom({
    Expression<int>? typeId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (typeId != null) 'type_id': typeId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoriteTypesCompanion copyWith({
    Value<int>? typeId,
    Value<DateTime>? addedAt,
  }) {
    return FavoriteTypesCompanion(
      typeId: typeId ?? this.typeId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (typeId.present) {
      map['type_id'] = Variable<int>(typeId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteTypesCompanion(')
          ..write('typeId: $typeId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $SavedFitsTable extends SavedFits
    with TableInfo<$SavedFitsTable, SavedFit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedFitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shipTypeIdMeta = const VerificationMeta(
    'shipTypeId',
  );
  @override
  late final GeneratedColumn<int> shipTypeId = GeneratedColumn<int>(
    'ship_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fitJsonMeta = const VerificationMeta(
    'fitJson',
  );
  @override
  late final GeneratedColumn<String> fitJson = GeneratedColumn<String>(
    'fit_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    shipTypeId,
    fitJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_fits';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedFit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ship_type_id')) {
      context.handle(
        _shipTypeIdMeta,
        shipTypeId.isAcceptableOrUnknown(
          data['ship_type_id']!,
          _shipTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shipTypeIdMeta);
    }
    if (data.containsKey('fit_json')) {
      context.handle(
        _fitJsonMeta,
        fitJson.isAcceptableOrUnknown(data['fit_json']!, _fitJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_fitJsonMeta);
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
  SavedFit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedFit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shipTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ship_type_id'],
      )!,
      fitJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fit_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SavedFitsTable createAlias(String alias) {
    return $SavedFitsTable(attachedDatabase, alias);
  }
}

class SavedFit extends DataClass implements Insertable<SavedFit> {
  final int id;
  final String name;
  final int shipTypeId;
  final String fitJson;
  final DateTime updatedAt;
  const SavedFit({
    required this.id,
    required this.name,
    required this.shipTypeId,
    required this.fitJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['ship_type_id'] = Variable<int>(shipTypeId);
    map['fit_json'] = Variable<String>(fitJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedFitsCompanion toCompanion(bool nullToAbsent) {
    return SavedFitsCompanion(
      id: Value(id),
      name: Value(name),
      shipTypeId: Value(shipTypeId),
      fitJson: Value(fitJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedFit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedFit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      shipTypeId: serializer.fromJson<int>(json['shipTypeId']),
      fitJson: serializer.fromJson<String>(json['fitJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'shipTypeId': serializer.toJson<int>(shipTypeId),
      'fitJson': serializer.toJson<String>(fitJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedFit copyWith({
    int? id,
    String? name,
    int? shipTypeId,
    String? fitJson,
    DateTime? updatedAt,
  }) => SavedFit(
    id: id ?? this.id,
    name: name ?? this.name,
    shipTypeId: shipTypeId ?? this.shipTypeId,
    fitJson: fitJson ?? this.fitJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedFit copyWithCompanion(SavedFitsCompanion data) {
    return SavedFit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      shipTypeId: data.shipTypeId.present
          ? data.shipTypeId.value
          : this.shipTypeId,
      fitJson: data.fitJson.present ? data.fitJson.value : this.fitJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedFit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shipTypeId: $shipTypeId, ')
          ..write('fitJson: $fitJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, shipTypeId, fitJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedFit &&
          other.id == this.id &&
          other.name == this.name &&
          other.shipTypeId == this.shipTypeId &&
          other.fitJson == this.fitJson &&
          other.updatedAt == this.updatedAt);
}

class SavedFitsCompanion extends UpdateCompanion<SavedFit> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> shipTypeId;
  final Value<String> fitJson;
  final Value<DateTime> updatedAt;
  const SavedFitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.shipTypeId = const Value.absent(),
    this.fitJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SavedFitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int shipTypeId,
    required String fitJson,
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       shipTypeId = Value(shipTypeId),
       fitJson = Value(fitJson);
  static Insertable<SavedFit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? shipTypeId,
    Expression<String>? fitJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (shipTypeId != null) 'ship_type_id': shipTypeId,
      if (fitJson != null) 'fit_json': fitJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SavedFitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? shipTypeId,
    Value<String>? fitJson,
    Value<DateTime>? updatedAt,
  }) {
    return SavedFitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      shipTypeId: shipTypeId ?? this.shipTypeId,
      fitJson: fitJson ?? this.fitJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shipTypeId.present) {
      map['ship_type_id'] = Variable<int>(shipTypeId.value);
    }
    if (fitJson.present) {
      map['fit_json'] = Variable<String>(fitJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedFitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shipTypeId: $shipTypeId, ')
          ..write('fitJson: $fitJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StructureInfosTable extends StructureInfos
    with TableInfo<$StructureInfosTable, StructureInfo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StructureInfosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _structureIdMeta = const VerificationMeta(
    'structureId',
  );
  @override
  late final GeneratedColumn<int> structureId = GeneratedColumn<int>(
    'structure_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _solarSystemIdMeta = const VerificationMeta(
    'solarSystemId',
  );
  @override
  late final GeneratedColumn<int> solarSystemId = GeneratedColumn<int>(
    'solar_system_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<int> typeId = GeneratedColumn<int>(
    'type_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessDeniedMeta = const VerificationMeta(
    'accessDenied',
  );
  @override
  late final GeneratedColumn<bool> accessDenied = GeneratedColumn<bool>(
    'access_denied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("access_denied" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    structureId,
    name,
    solarSystemId,
    typeId,
    accessDenied,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'structure_infos';
  @override
  VerificationContext validateIntegrity(
    Insertable<StructureInfo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('structure_id')) {
      context.handle(
        _structureIdMeta,
        structureId.isAcceptableOrUnknown(
          data['structure_id']!,
          _structureIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('solar_system_id')) {
      context.handle(
        _solarSystemIdMeta,
        solarSystemId.isAcceptableOrUnknown(
          data['solar_system_id']!,
          _solarSystemIdMeta,
        ),
      );
    }
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    }
    if (data.containsKey('access_denied')) {
      context.handle(
        _accessDeniedMeta,
        accessDenied.isAcceptableOrUnknown(
          data['access_denied']!,
          _accessDeniedMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {structureId};
  @override
  StructureInfo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StructureInfo(
      structureId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}structure_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      solarSystemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}solar_system_id'],
      ),
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type_id'],
      ),
      accessDenied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}access_denied'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $StructureInfosTable createAlias(String alias) {
    return $StructureInfosTable(attachedDatabase, alias);
  }
}

class StructureInfo extends DataClass implements Insertable<StructureInfo> {
  final int structureId;
  final String? name;
  final int? solarSystemId;
  final int? typeId;
  final bool accessDenied;
  final DateTime fetchedAt;
  const StructureInfo({
    required this.structureId,
    this.name,
    this.solarSystemId,
    this.typeId,
    required this.accessDenied,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['structure_id'] = Variable<int>(structureId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || solarSystemId != null) {
      map['solar_system_id'] = Variable<int>(solarSystemId);
    }
    if (!nullToAbsent || typeId != null) {
      map['type_id'] = Variable<int>(typeId);
    }
    map['access_denied'] = Variable<bool>(accessDenied);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  StructureInfosCompanion toCompanion(bool nullToAbsent) {
    return StructureInfosCompanion(
      structureId: Value(structureId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      solarSystemId: solarSystemId == null && nullToAbsent
          ? const Value.absent()
          : Value(solarSystemId),
      typeId: typeId == null && nullToAbsent
          ? const Value.absent()
          : Value(typeId),
      accessDenied: Value(accessDenied),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory StructureInfo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StructureInfo(
      structureId: serializer.fromJson<int>(json['structureId']),
      name: serializer.fromJson<String?>(json['name']),
      solarSystemId: serializer.fromJson<int?>(json['solarSystemId']),
      typeId: serializer.fromJson<int?>(json['typeId']),
      accessDenied: serializer.fromJson<bool>(json['accessDenied']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'structureId': serializer.toJson<int>(structureId),
      'name': serializer.toJson<String?>(name),
      'solarSystemId': serializer.toJson<int?>(solarSystemId),
      'typeId': serializer.toJson<int?>(typeId),
      'accessDenied': serializer.toJson<bool>(accessDenied),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  StructureInfo copyWith({
    int? structureId,
    Value<String?> name = const Value.absent(),
    Value<int?> solarSystemId = const Value.absent(),
    Value<int?> typeId = const Value.absent(),
    bool? accessDenied,
    DateTime? fetchedAt,
  }) => StructureInfo(
    structureId: structureId ?? this.structureId,
    name: name.present ? name.value : this.name,
    solarSystemId: solarSystemId.present
        ? solarSystemId.value
        : this.solarSystemId,
    typeId: typeId.present ? typeId.value : this.typeId,
    accessDenied: accessDenied ?? this.accessDenied,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  StructureInfo copyWithCompanion(StructureInfosCompanion data) {
    return StructureInfo(
      structureId: data.structureId.present
          ? data.structureId.value
          : this.structureId,
      name: data.name.present ? data.name.value : this.name,
      solarSystemId: data.solarSystemId.present
          ? data.solarSystemId.value
          : this.solarSystemId,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      accessDenied: data.accessDenied.present
          ? data.accessDenied.value
          : this.accessDenied,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StructureInfo(')
          ..write('structureId: $structureId, ')
          ..write('name: $name, ')
          ..write('solarSystemId: $solarSystemId, ')
          ..write('typeId: $typeId, ')
          ..write('accessDenied: $accessDenied, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    structureId,
    name,
    solarSystemId,
    typeId,
    accessDenied,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StructureInfo &&
          other.structureId == this.structureId &&
          other.name == this.name &&
          other.solarSystemId == this.solarSystemId &&
          other.typeId == this.typeId &&
          other.accessDenied == this.accessDenied &&
          other.fetchedAt == this.fetchedAt);
}

class StructureInfosCompanion extends UpdateCompanion<StructureInfo> {
  final Value<int> structureId;
  final Value<String?> name;
  final Value<int?> solarSystemId;
  final Value<int?> typeId;
  final Value<bool> accessDenied;
  final Value<DateTime> fetchedAt;
  const StructureInfosCompanion({
    this.structureId = const Value.absent(),
    this.name = const Value.absent(),
    this.solarSystemId = const Value.absent(),
    this.typeId = const Value.absent(),
    this.accessDenied = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  StructureInfosCompanion.insert({
    this.structureId = const Value.absent(),
    this.name = const Value.absent(),
    this.solarSystemId = const Value.absent(),
    this.typeId = const Value.absent(),
    this.accessDenied = const Value.absent(),
    required DateTime fetchedAt,
  }) : fetchedAt = Value(fetchedAt);
  static Insertable<StructureInfo> custom({
    Expression<int>? structureId,
    Expression<String>? name,
    Expression<int>? solarSystemId,
    Expression<int>? typeId,
    Expression<bool>? accessDenied,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (structureId != null) 'structure_id': structureId,
      if (name != null) 'name': name,
      if (solarSystemId != null) 'solar_system_id': solarSystemId,
      if (typeId != null) 'type_id': typeId,
      if (accessDenied != null) 'access_denied': accessDenied,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  StructureInfosCompanion copyWith({
    Value<int>? structureId,
    Value<String?>? name,
    Value<int?>? solarSystemId,
    Value<int?>? typeId,
    Value<bool>? accessDenied,
    Value<DateTime>? fetchedAt,
  }) {
    return StructureInfosCompanion(
      structureId: structureId ?? this.structureId,
      name: name ?? this.name,
      solarSystemId: solarSystemId ?? this.solarSystemId,
      typeId: typeId ?? this.typeId,
      accessDenied: accessDenied ?? this.accessDenied,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (structureId.present) {
      map['structure_id'] = Variable<int>(structureId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (solarSystemId.present) {
      map['solar_system_id'] = Variable<int>(solarSystemId.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<int>(typeId.value);
    }
    if (accessDenied.present) {
      map['access_denied'] = Variable<bool>(accessDenied.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StructureInfosCompanion(')
          ..write('structureId: $structureId, ')
          ..write('name: $name, ')
          ..write('solarSystemId: $solarSystemId, ')
          ..write('typeId: $typeId, ')
          ..write('accessDenied: $accessDenied, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
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
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
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
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
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

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
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
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
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

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
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
    return (StringBuffer('KeyValuesCompanion(')
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
  late final $CharactersTable characters = $CharactersTable(this);
  late final $HttpCacheEntriesTable httpCacheEntries = $HttpCacheEntriesTable(
    this,
  );
  late final $FavoriteTypesTable favoriteTypes = $FavoriteTypesTable(this);
  late final $SavedFitsTable savedFits = $SavedFitsTable(this);
  late final $StructureInfosTable structureInfos = $StructureInfosTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    characters,
    httpCacheEntries,
    favoriteTypes,
    savedFits,
    structureInfos,
    keyValues,
  ];
}

typedef $$CharactersTableCreateCompanionBuilder = CharactersCompanion Function({
  Value<int> characterId,
  required String name,
  Value<String> scopes,
  Value<bool> needsRelogin,
  Value<int> sortOrder,
  Value<DateTime> addedAt,
});
typedef $$CharactersTableUpdateCompanionBuilder = CharactersCompanion Function({
  Value<int> characterId,
  Value<String> name,
  Value<String> scopes,
  Value<bool> needsRelogin,
  Value<int> sortOrder,
  Value<DateTime> addedAt,
});

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopes => $composableBuilder(
    column: $table.scopes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsRelogin => $composableBuilder(
    column: $table.needsRelogin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopes => $composableBuilder(
    column: $table.scopes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsRelogin => $composableBuilder(
    column: $table.needsRelogin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scopes =>
      $composableBuilder(column: $table.scopes, builder: (column) => column);

  GeneratedColumn<bool> get needsRelogin => $composableBuilder(
    column: $table.needsRelogin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (
            Character,
            BaseReferences<_$AppDatabase, $CharactersTable, Character>,
          ),
          Character,
          PrefetchHooks Function()
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> characterId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scopes = const Value.absent(),
                Value<bool> needsRelogin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => CharactersCompanion(
                characterId: characterId,
                name: name,
                scopes: scopes,
                needsRelogin: needsRelogin,
                sortOrder: sortOrder,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> characterId = const Value.absent(),
                required String name,
                Value<String> scopes = const Value.absent(),
                Value<bool> needsRelogin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => CharactersCompanion.insert(
                characterId: characterId,
                name: name,
                scopes: scopes,
                needsRelogin: needsRelogin,
                sortOrder: sortOrder,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CharactersTable, Character>(table),
                  BaseReferences<_$AppDatabase, $CharactersTable, Character>(
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

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, BaseReferences<_$AppDatabase, $CharactersTable, Character>),
      Character,
      PrefetchHooks Function()
    >;
typedef $$HttpCacheEntriesTableCreateCompanionBuilder =
    HttpCacheEntriesCompanion Function({
      required String cacheKey,
      required String body,
      Value<String?> etag,
      Value<DateTime?> expires,
      Value<String?> lastModified,
      Value<int?> pages,
      required DateTime storedAt,
      Value<int> rowid,
    });
typedef $$HttpCacheEntriesTableUpdateCompanionBuilder =
    HttpCacheEntriesCompanion Function({
      Value<String> cacheKey,
      Value<String> body,
      Value<String?> etag,
      Value<DateTime?> expires,
      Value<String?> lastModified,
      Value<int?> pages,
      Value<DateTime> storedAt,
      Value<int> rowid,
    });

class $$HttpCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HttpCacheEntriesTable> {
  $$HttpCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HttpCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HttpCacheEntriesTable> {
  $$HttpCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HttpCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HttpCacheEntriesTable> {
  $$HttpCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get expires =>
      $composableBuilder(column: $table.expires, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pages =>
      $composableBuilder(column: $table.pages, builder: (column) => column);

  GeneratedColumn<DateTime> get storedAt =>
      $composableBuilder(column: $table.storedAt, builder: (column) => column);
}

class $$HttpCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HttpCacheEntriesTable,
          HttpCacheEntry,
          $$HttpCacheEntriesTableFilterComposer,
          $$HttpCacheEntriesTableOrderingComposer,
          $$HttpCacheEntriesTableAnnotationComposer,
          $$HttpCacheEntriesTableCreateCompanionBuilder,
          $$HttpCacheEntriesTableUpdateCompanionBuilder,
          (
            HttpCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $HttpCacheEntriesTable,
              HttpCacheEntry
            >,
          ),
          HttpCacheEntry,
          PrefetchHooks Function()
        > {
  $$HttpCacheEntriesTableTableManager(
    _$AppDatabase db,
    $HttpCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HttpCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HttpCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HttpCacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> expires = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int?> pages = const Value.absent(),
                Value<DateTime> storedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HttpCacheEntriesCompanion(
                cacheKey: cacheKey,
                body: body,
                etag: etag,
                expires: expires,
                lastModified: lastModified,
                pages: pages,
                storedAt: storedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String body,
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> expires = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int?> pages = const Value.absent(),
                required DateTime storedAt,
                Value<int> rowid = const Value.absent(),
              }) => HttpCacheEntriesCompanion.insert(
                cacheKey: cacheKey,
                body: body,
                etag: etag,
                expires: expires,
                lastModified: lastModified,
                pages: pages,
                storedAt: storedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HttpCacheEntriesTable, HttpCacheEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HttpCacheEntriesTable,
                    HttpCacheEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HttpCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HttpCacheEntriesTable,
      HttpCacheEntry,
      $$HttpCacheEntriesTableFilterComposer,
      $$HttpCacheEntriesTableOrderingComposer,
      $$HttpCacheEntriesTableAnnotationComposer,
      $$HttpCacheEntriesTableCreateCompanionBuilder,
      $$HttpCacheEntriesTableUpdateCompanionBuilder,
      (
        HttpCacheEntry,
        BaseReferences<_$AppDatabase, $HttpCacheEntriesTable, HttpCacheEntry>,
      ),
      HttpCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$FavoriteTypesTableCreateCompanionBuilder =
    FavoriteTypesCompanion Function({
      Value<int> typeId,
      Value<DateTime> addedAt,
    });
typedef $$FavoriteTypesTableUpdateCompanionBuilder =
    FavoriteTypesCompanion Function({
      Value<int> typeId,
      Value<DateTime> addedAt,
    });

class $$FavoriteTypesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteTypesTable> {
  $$FavoriteTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoriteTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteTypesTable> {
  $$FavoriteTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteTypesTable> {
  $$FavoriteTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavoriteTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteTypesTable,
          FavoriteType,
          $$FavoriteTypesTableFilterComposer,
          $$FavoriteTypesTableOrderingComposer,
          $$FavoriteTypesTableAnnotationComposer,
          $$FavoriteTypesTableCreateCompanionBuilder,
          $$FavoriteTypesTableUpdateCompanionBuilder,
          (
            FavoriteType,
            BaseReferences<_$AppDatabase, $FavoriteTypesTable, FavoriteType>,
          ),
          FavoriteType,
          PrefetchHooks Function()
        > {
  $$FavoriteTypesTableTableManager(_$AppDatabase db, $FavoriteTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> typeId = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) => FavoriteTypesCompanion(typeId: typeId, addedAt: addedAt),
          createCompanionCallback: ({
            Value<int> typeId = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) => FavoriteTypesCompanion.insert(typeId: typeId, addedAt: addedAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteTypesTable, FavoriteType>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FavoriteTypesTable,
                    FavoriteType
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteTypesTable,
      FavoriteType,
      $$FavoriteTypesTableFilterComposer,
      $$FavoriteTypesTableOrderingComposer,
      $$FavoriteTypesTableAnnotationComposer,
      $$FavoriteTypesTableCreateCompanionBuilder,
      $$FavoriteTypesTableUpdateCompanionBuilder,
      (
        FavoriteType,
        BaseReferences<_$AppDatabase, $FavoriteTypesTable, FavoriteType>,
      ),
      FavoriteType,
      PrefetchHooks Function()
    >;
typedef $$SavedFitsTableCreateCompanionBuilder = SavedFitsCompanion Function({
  Value<int> id,
  required String name,
  required int shipTypeId,
  required String fitJson,
  Value<DateTime> updatedAt,
});
typedef $$SavedFitsTableUpdateCompanionBuilder = SavedFitsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> shipTypeId,
  Value<String> fitJson,
  Value<DateTime> updatedAt,
});

class $$SavedFitsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedFitsTable> {
  $$SavedFitsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shipTypeId => $composableBuilder(
    column: $table.shipTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fitJson => $composableBuilder(
    column: $table.fitJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedFitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedFitsTable> {
  $$SavedFitsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shipTypeId => $composableBuilder(
    column: $table.shipTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fitJson => $composableBuilder(
    column: $table.fitJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedFitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedFitsTable> {
  $$SavedFitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get shipTypeId => $composableBuilder(
    column: $table.shipTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fitJson =>
      $composableBuilder(column: $table.fitJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavedFitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedFitsTable,
          SavedFit,
          $$SavedFitsTableFilterComposer,
          $$SavedFitsTableOrderingComposer,
          $$SavedFitsTableAnnotationComposer,
          $$SavedFitsTableCreateCompanionBuilder,
          $$SavedFitsTableUpdateCompanionBuilder,
          (SavedFit, BaseReferences<_$AppDatabase, $SavedFitsTable, SavedFit>),
          SavedFit,
          PrefetchHooks Function()
        > {
  $$SavedFitsTableTableManager(_$AppDatabase db, $SavedFitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedFitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedFitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedFitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> shipTypeId = const Value.absent(),
                Value<String> fitJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SavedFitsCompanion(
                id: id,
                name: name,
                shipTypeId: shipTypeId,
                fitJson: fitJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int shipTypeId,
                required String fitJson,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SavedFitsCompanion.insert(
                id: id,
                name: name,
                shipTypeId: shipTypeId,
                fitJson: fitJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedFitsTable, SavedFit>(table),
                  BaseReferences<_$AppDatabase, $SavedFitsTable, SavedFit>(
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

typedef $$SavedFitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedFitsTable,
      SavedFit,
      $$SavedFitsTableFilterComposer,
      $$SavedFitsTableOrderingComposer,
      $$SavedFitsTableAnnotationComposer,
      $$SavedFitsTableCreateCompanionBuilder,
      $$SavedFitsTableUpdateCompanionBuilder,
      (SavedFit, BaseReferences<_$AppDatabase, $SavedFitsTable, SavedFit>),
      SavedFit,
      PrefetchHooks Function()
    >;
typedef $$StructureInfosTableCreateCompanionBuilder =
    StructureInfosCompanion Function({
      Value<int> structureId,
      Value<String?> name,
      Value<int?> solarSystemId,
      Value<int?> typeId,
      Value<bool> accessDenied,
      required DateTime fetchedAt,
    });
typedef $$StructureInfosTableUpdateCompanionBuilder =
    StructureInfosCompanion Function({
      Value<int> structureId,
      Value<String?> name,
      Value<int?> solarSystemId,
      Value<int?> typeId,
      Value<bool> accessDenied,
      Value<DateTime> fetchedAt,
    });

class $$StructureInfosTableFilterComposer
    extends Composer<_$AppDatabase, $StructureInfosTable> {
  $$StructureInfosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get structureId => $composableBuilder(
    column: $table.structureId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get solarSystemId => $composableBuilder(
    column: $table.solarSystemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get accessDenied => $composableBuilder(
    column: $table.accessDenied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StructureInfosTableOrderingComposer
    extends Composer<_$AppDatabase, $StructureInfosTable> {
  $$StructureInfosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get structureId => $composableBuilder(
    column: $table.structureId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get solarSystemId => $composableBuilder(
    column: $table.solarSystemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get accessDenied => $composableBuilder(
    column: $table.accessDenied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StructureInfosTableAnnotationComposer
    extends Composer<_$AppDatabase, $StructureInfosTable> {
  $$StructureInfosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get structureId => $composableBuilder(
    column: $table.structureId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get solarSystemId => $composableBuilder(
    column: $table.solarSystemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);

  GeneratedColumn<bool> get accessDenied => $composableBuilder(
    column: $table.accessDenied,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$StructureInfosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StructureInfosTable,
          StructureInfo,
          $$StructureInfosTableFilterComposer,
          $$StructureInfosTableOrderingComposer,
          $$StructureInfosTableAnnotationComposer,
          $$StructureInfosTableCreateCompanionBuilder,
          $$StructureInfosTableUpdateCompanionBuilder,
          (
            StructureInfo,
            BaseReferences<_$AppDatabase, $StructureInfosTable, StructureInfo>,
          ),
          StructureInfo,
          PrefetchHooks Function()
        > {
  $$StructureInfosTableTableManager(
    _$AppDatabase db,
    $StructureInfosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StructureInfosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StructureInfosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StructureInfosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> structureId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> solarSystemId = const Value.absent(),
                Value<int?> typeId = const Value.absent(),
                Value<bool> accessDenied = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => StructureInfosCompanion(
                structureId: structureId,
                name: name,
                solarSystemId: solarSystemId,
                typeId: typeId,
                accessDenied: accessDenied,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> structureId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> solarSystemId = const Value.absent(),
                Value<int?> typeId = const Value.absent(),
                Value<bool> accessDenied = const Value.absent(),
                required DateTime fetchedAt,
              }) => StructureInfosCompanion.insert(
                structureId: structureId,
                name: name,
                solarSystemId: solarSystemId,
                typeId: typeId,
                accessDenied: accessDenied,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StructureInfosTable, StructureInfo>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StructureInfosTable,
                    StructureInfo
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StructureInfosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StructureInfosTable,
      StructureInfo,
      $$StructureInfosTableFilterComposer,
      $$StructureInfosTableOrderingComposer,
      $$StructureInfosTableAnnotationComposer,
      $$StructureInfosTableCreateCompanionBuilder,
      $$StructureInfosTableUpdateCompanionBuilder,
      (
        StructureInfo,
        BaseReferences<_$AppDatabase, $StructureInfosTable, StructureInfo>,
      ),
      StructureInfo,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
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

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
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

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
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

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
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

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$HttpCacheEntriesTableTableManager get httpCacheEntries =>
      $$HttpCacheEntriesTableTableManager(_db, _db.httpCacheEntries);
  $$FavoriteTypesTableTableManager get favoriteTypes =>
      $$FavoriteTypesTableTableManager(_db, _db.favoriteTypes);
  $$SavedFitsTableTableManager get savedFits =>
      $$SavedFitsTableTableManager(_db, _db.savedFits);
  $$StructureInfosTableTableManager get structureInfos =>
      $$StructureInfosTableTableManager(_db, _db.structureInfos);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
}
