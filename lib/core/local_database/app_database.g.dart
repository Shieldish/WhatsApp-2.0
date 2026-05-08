// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MessagesTableTable extends MessagesTable
    with TableInfo<$MessagesTableTable, MessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciphertextMeta = const VerificationMeta(
    'ciphertext',
  );
  @override
  late final GeneratedColumn<Uint8List> ciphertext = GeneratedColumn<Uint8List>(
    'ciphertext',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plaintextCacheMeta = const VerificationMeta(
    'plaintextCache',
  );
  @override
  late final GeneratedColumn<String> plaintextCache = GeneratedColumn<String>(
    'plaintext_cache',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaLocalPathMeta = const VerificationMeta(
    'mediaLocalPath',
  );
  @override
  late final GeneratedColumn<String> mediaLocalPath = GeneratedColumn<String>(
    'media_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<int> deliveredAt = GeneratedColumn<int>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<int> readAt = GeneratedColumn<int>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedForEveryoneMeta =
      const VerificationMeta('deletedForEveryone');
  @override
  late final GeneratedColumn<bool> deletedForEveryone = GeneratedColumn<bool>(
    'deleted_for_everyone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_for_everyone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quotedMessageIdMeta = const VerificationMeta(
    'quotedMessageId',
  );
  @override
  late final GeneratedColumn<String> quotedMessageId = GeneratedColumn<String>(
    'quoted_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    senderId,
    ciphertext,
    plaintextCache,
    mediaLocalPath,
    type,
    sentAt,
    deliveredAt,
    readAt,
    deletedForEveryone,
    quotedMessageId,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('ciphertext')) {
      context.handle(
        _ciphertextMeta,
        ciphertext.isAcceptableOrUnknown(data['ciphertext']!, _ciphertextMeta),
      );
    } else if (isInserting) {
      context.missing(_ciphertextMeta);
    }
    if (data.containsKey('plaintext_cache')) {
      context.handle(
        _plaintextCacheMeta,
        plaintextCache.isAcceptableOrUnknown(
          data['plaintext_cache']!,
          _plaintextCacheMeta,
        ),
      );
    }
    if (data.containsKey('media_local_path')) {
      context.handle(
        _mediaLocalPathMeta,
        mediaLocalPath.isAcceptableOrUnknown(
          data['media_local_path']!,
          _mediaLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('deleted_for_everyone')) {
      context.handle(
        _deletedForEveryoneMeta,
        deletedForEveryone.isAcceptableOrUnknown(
          data['deleted_for_everyone']!,
          _deletedForEveryoneMeta,
        ),
      );
    }
    if (data.containsKey('quoted_message_id')) {
      context.handle(
        _quotedMessageIdMeta,
        quotedMessageId.isAcceptableOrUnknown(
          data['quoted_message_id']!,
          _quotedMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      ciphertext: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}ciphertext'],
      )!,
      plaintextCache: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plaintext_cache'],
      ),
      mediaLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_local_path'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      )!,
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivered_at'],
      ),
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_at'],
      ),
      deletedForEveryone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_for_everyone'],
      )!,
      quotedMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quoted_message_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $MessagesTableTable createAlias(String alias) {
    return $MessagesTableTable(attachedDatabase, alias);
  }
}

class MessagesTableData extends DataClass
    implements Insertable<MessagesTableData> {
  final String id;
  final String conversationId;
  final String senderId;
  final Uint8List ciphertext;

  /// Decrypted plaintext cache — in-memory only, cleared on logout.
  final String? plaintextCache;
  final String? mediaLocalPath;
  final String type;
  final int sentAt;
  final int? deliveredAt;
  final int? readAt;
  final bool deletedForEveryone;
  final String? quotedMessageId;

  /// Message delivery status: sending | sent | delivered | read | failed
  final String status;
  const MessagesTableData({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.ciphertext,
    this.plaintextCache,
    this.mediaLocalPath,
    required this.type,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    required this.deletedForEveryone,
    this.quotedMessageId,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['ciphertext'] = Variable<Uint8List>(ciphertext);
    if (!nullToAbsent || plaintextCache != null) {
      map['plaintext_cache'] = Variable<String>(plaintextCache);
    }
    if (!nullToAbsent || mediaLocalPath != null) {
      map['media_local_path'] = Variable<String>(mediaLocalPath);
    }
    map['type'] = Variable<String>(type);
    map['sent_at'] = Variable<int>(sentAt);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<int>(deliveredAt);
    }
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<int>(readAt);
    }
    map['deleted_for_everyone'] = Variable<bool>(deletedForEveryone);
    if (!nullToAbsent || quotedMessageId != null) {
      map['quoted_message_id'] = Variable<String>(quotedMessageId);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  MessagesTableCompanion toCompanion(bool nullToAbsent) {
    return MessagesTableCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      ciphertext: Value(ciphertext),
      plaintextCache: plaintextCache == null && nullToAbsent
          ? const Value.absent()
          : Value(plaintextCache),
      mediaLocalPath: mediaLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaLocalPath),
      type: Value(type),
      sentAt: Value(sentAt),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      deletedForEveryone: Value(deletedForEveryone),
      quotedMessageId: quotedMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(quotedMessageId),
      status: Value(status),
    );
  }

  factory MessagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesTableData(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      ciphertext: serializer.fromJson<Uint8List>(json['ciphertext']),
      plaintextCache: serializer.fromJson<String?>(json['plaintextCache']),
      mediaLocalPath: serializer.fromJson<String?>(json['mediaLocalPath']),
      type: serializer.fromJson<String>(json['type']),
      sentAt: serializer.fromJson<int>(json['sentAt']),
      deliveredAt: serializer.fromJson<int?>(json['deliveredAt']),
      readAt: serializer.fromJson<int?>(json['readAt']),
      deletedForEveryone: serializer.fromJson<bool>(json['deletedForEveryone']),
      quotedMessageId: serializer.fromJson<String?>(json['quotedMessageId']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'ciphertext': serializer.toJson<Uint8List>(ciphertext),
      'plaintextCache': serializer.toJson<String?>(plaintextCache),
      'mediaLocalPath': serializer.toJson<String?>(mediaLocalPath),
      'type': serializer.toJson<String>(type),
      'sentAt': serializer.toJson<int>(sentAt),
      'deliveredAt': serializer.toJson<int?>(deliveredAt),
      'readAt': serializer.toJson<int?>(readAt),
      'deletedForEveryone': serializer.toJson<bool>(deletedForEveryone),
      'quotedMessageId': serializer.toJson<String?>(quotedMessageId),
      'status': serializer.toJson<String>(status),
    };
  }

  MessagesTableData copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    Uint8List? ciphertext,
    Value<String?> plaintextCache = const Value.absent(),
    Value<String?> mediaLocalPath = const Value.absent(),
    String? type,
    int? sentAt,
    Value<int?> deliveredAt = const Value.absent(),
    Value<int?> readAt = const Value.absent(),
    bool? deletedForEveryone,
    Value<String?> quotedMessageId = const Value.absent(),
    String? status,
  }) => MessagesTableData(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    ciphertext: ciphertext ?? this.ciphertext,
    plaintextCache: plaintextCache.present
        ? plaintextCache.value
        : this.plaintextCache,
    mediaLocalPath: mediaLocalPath.present
        ? mediaLocalPath.value
        : this.mediaLocalPath,
    type: type ?? this.type,
    sentAt: sentAt ?? this.sentAt,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
    quotedMessageId: quotedMessageId.present
        ? quotedMessageId.value
        : this.quotedMessageId,
    status: status ?? this.status,
  );
  MessagesTableData copyWithCompanion(MessagesTableCompanion data) {
    return MessagesTableData(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      ciphertext: data.ciphertext.present
          ? data.ciphertext.value
          : this.ciphertext,
      plaintextCache: data.plaintextCache.present
          ? data.plaintextCache.value
          : this.plaintextCache,
      mediaLocalPath: data.mediaLocalPath.present
          ? data.mediaLocalPath.value
          : this.mediaLocalPath,
      type: data.type.present ? data.type.value : this.type,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      deletedForEveryone: data.deletedForEveryone.present
          ? data.deletedForEveryone.value
          : this.deletedForEveryone,
      quotedMessageId: data.quotedMessageId.present
          ? data.quotedMessageId.value
          : this.quotedMessageId,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableData(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('plaintextCache: $plaintextCache, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('type: $type, ')
          ..write('sentAt: $sentAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('readAt: $readAt, ')
          ..write('deletedForEveryone: $deletedForEveryone, ')
          ..write('quotedMessageId: $quotedMessageId, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    senderId,
    $driftBlobEquality.hash(ciphertext),
    plaintextCache,
    mediaLocalPath,
    type,
    sentAt,
    deliveredAt,
    readAt,
    deletedForEveryone,
    quotedMessageId,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesTableData &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          $driftBlobEquality.equals(other.ciphertext, this.ciphertext) &&
          other.plaintextCache == this.plaintextCache &&
          other.mediaLocalPath == this.mediaLocalPath &&
          other.type == this.type &&
          other.sentAt == this.sentAt &&
          other.deliveredAt == this.deliveredAt &&
          other.readAt == this.readAt &&
          other.deletedForEveryone == this.deletedForEveryone &&
          other.quotedMessageId == this.quotedMessageId &&
          other.status == this.status);
}

class MessagesTableCompanion extends UpdateCompanion<MessagesTableData> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<Uint8List> ciphertext;
  final Value<String?> plaintextCache;
  final Value<String?> mediaLocalPath;
  final Value<String> type;
  final Value<int> sentAt;
  final Value<int?> deliveredAt;
  final Value<int?> readAt;
  final Value<bool> deletedForEveryone;
  final Value<String?> quotedMessageId;
  final Value<String> status;
  final Value<int> rowid;
  const MessagesTableCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.ciphertext = const Value.absent(),
    this.plaintextCache = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.type = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.deletedForEveryone = const Value.absent(),
    this.quotedMessageId = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesTableCompanion.insert({
    required String id,
    required String conversationId,
    required String senderId,
    required Uint8List ciphertext,
    this.plaintextCache = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    required String type,
    required int sentAt,
    this.deliveredAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.deletedForEveryone = const Value.absent(),
    this.quotedMessageId = const Value.absent(),
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       senderId = Value(senderId),
       ciphertext = Value(ciphertext),
       type = Value(type),
       sentAt = Value(sentAt),
       status = Value(status);
  static Insertable<MessagesTableData> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<Uint8List>? ciphertext,
    Expression<String>? plaintextCache,
    Expression<String>? mediaLocalPath,
    Expression<String>? type,
    Expression<int>? sentAt,
    Expression<int>? deliveredAt,
    Expression<int>? readAt,
    Expression<bool>? deletedForEveryone,
    Expression<String>? quotedMessageId,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (ciphertext != null) 'ciphertext': ciphertext,
      if (plaintextCache != null) 'plaintext_cache': plaintextCache,
      if (mediaLocalPath != null) 'media_local_path': mediaLocalPath,
      if (type != null) 'type': type,
      if (sentAt != null) 'sent_at': sentAt,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (readAt != null) 'read_at': readAt,
      if (deletedForEveryone != null)
        'deleted_for_everyone': deletedForEveryone,
      if (quotedMessageId != null) 'quoted_message_id': quotedMessageId,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? senderId,
    Value<Uint8List>? ciphertext,
    Value<String?>? plaintextCache,
    Value<String?>? mediaLocalPath,
    Value<String>? type,
    Value<int>? sentAt,
    Value<int?>? deliveredAt,
    Value<int?>? readAt,
    Value<bool>? deletedForEveryone,
    Value<String?>? quotedMessageId,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return MessagesTableCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      ciphertext: ciphertext ?? this.ciphertext,
      plaintextCache: plaintextCache ?? this.plaintextCache,
      mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      quotedMessageId: quotedMessageId ?? this.quotedMessageId,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (ciphertext.present) {
      map['ciphertext'] = Variable<Uint8List>(ciphertext.value);
    }
    if (plaintextCache.present) {
      map['plaintext_cache'] = Variable<String>(plaintextCache.value);
    }
    if (mediaLocalPath.present) {
      map['media_local_path'] = Variable<String>(mediaLocalPath.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<int>(deliveredAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<int>(readAt.value);
    }
    if (deletedForEveryone.present) {
      map['deleted_for_everyone'] = Variable<bool>(deletedForEveryone.value);
    }
    if (quotedMessageId.present) {
      map['quoted_message_id'] = Variable<String>(quotedMessageId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('plaintextCache: $plaintextCache, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('type: $type, ')
          ..write('sentAt: $sentAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('readAt: $readAt, ')
          ..write('deletedForEveryone: $deletedForEveryone, ')
          ..write('quotedMessageId: $quotedMessageId, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTableTable extends ConversationsTable
    with TableInfo<$ConversationsTableTable, ConversationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<int> lastMessageAt = GeneratedColumn<int>(
    'last_message_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mutedUntilMeta = const VerificationMeta(
    'mutedUntil',
  );
  @override
  late final GeneratedColumn<int> mutedUntil = GeneratedColumn<int>(
    'muted_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    lastMessagePreview,
    lastMessageAt,
    isArchived,
    unreadCount,
    mutedUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('muted_until')) {
      context.handle(
        _mutedUntilMeta,
        mutedUntil.isAcceptableOrUnknown(data['muted_until']!, _mutedUntilMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_at'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      mutedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}muted_until'],
      ),
    );
  }

  @override
  $ConversationsTableTable createAlias(String alias) {
    return $ConversationsTableTable(attachedDatabase, alias);
  }
}

class ConversationsTableData extends DataClass
    implements Insertable<ConversationsTableData> {
  final String id;

  /// Conversation type: direct | group
  final String type;
  final String? lastMessagePreview;
  final int? lastMessageAt;
  final bool isArchived;
  final int unreadCount;

  /// Unix timestamp (ms) until which notifications are muted; null = not muted.
  final int? mutedUntil;
  const ConversationsTableData({
    required this.id,
    required this.type,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.isArchived,
    required this.unreadCount,
    this.mutedUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<int>(lastMessageAt);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || mutedUntil != null) {
      map['muted_until'] = Variable<int>(mutedUntil);
    }
    return map;
  }

  ConversationsTableCompanion toCompanion(bool nullToAbsent) {
    return ConversationsTableCompanion(
      id: Value(id),
      type: Value(type),
      lastMessagePreview: lastMessagePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessagePreview),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      isArchived: Value(isArchived),
      unreadCount: Value(unreadCount),
      mutedUntil: mutedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(mutedUntil),
    );
  }

  factory ConversationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationsTableData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      lastMessagePreview: serializer.fromJson<String?>(
        json['lastMessagePreview'],
      ),
      lastMessageAt: serializer.fromJson<int?>(json['lastMessageAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      mutedUntil: serializer.fromJson<int?>(json['mutedUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'lastMessagePreview': serializer.toJson<String?>(lastMessagePreview),
      'lastMessageAt': serializer.toJson<int?>(lastMessageAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'mutedUntil': serializer.toJson<int?>(mutedUntil),
    };
  }

  ConversationsTableData copyWith({
    String? id,
    String? type,
    Value<String?> lastMessagePreview = const Value.absent(),
    Value<int?> lastMessageAt = const Value.absent(),
    bool? isArchived,
    int? unreadCount,
    Value<int?> mutedUntil = const Value.absent(),
  }) => ConversationsTableData(
    id: id ?? this.id,
    type: type ?? this.type,
    lastMessagePreview: lastMessagePreview.present
        ? lastMessagePreview.value
        : this.lastMessagePreview,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    isArchived: isArchived ?? this.isArchived,
    unreadCount: unreadCount ?? this.unreadCount,
    mutedUntil: mutedUntil.present ? mutedUntil.value : this.mutedUntil,
  );
  ConversationsTableData copyWithCompanion(ConversationsTableCompanion data) {
    return ConversationsTableData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      mutedUntil: data.mutedUntil.present
          ? data.mutedUntil.value
          : this.mutedUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsTableData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('mutedUntil: $mutedUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    lastMessagePreview,
    lastMessageAt,
    isArchived,
    unreadCount,
    mutedUntil,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationsTableData &&
          other.id == this.id &&
          other.type == this.type &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.lastMessageAt == this.lastMessageAt &&
          other.isArchived == this.isArchived &&
          other.unreadCount == this.unreadCount &&
          other.mutedUntil == this.mutedUntil);
}

class ConversationsTableCompanion
    extends UpdateCompanion<ConversationsTableData> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> lastMessagePreview;
  final Value<int?> lastMessageAt;
  final Value<bool> isArchived;
  final Value<int> unreadCount;
  final Value<int?> mutedUntil;
  final Value<int> rowid;
  const ConversationsTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.mutedUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsTableCompanion.insert({
    required String id,
    required String type,
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.mutedUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type);
  static Insertable<ConversationsTableData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? lastMessagePreview,
    Expression<int>? lastMessageAt,
    Expression<bool>? isArchived,
    Expression<int>? unreadCount,
    Expression<int>? mutedUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (mutedUntil != null) 'muted_until': mutedUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String?>? lastMessagePreview,
    Value<int?>? lastMessageAt,
    Value<bool>? isArchived,
    Value<int>? unreadCount,
    Value<int?>? mutedUntil,
    Value<int>? rowid,
  }) {
    return ConversationsTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isArchived: isArchived ?? this.isArchived,
      unreadCount: unreadCount ?? this.unreadCount,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<int>(lastMessageAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (mutedUntil.present) {
      map['muted_until'] = Variable<int>(mutedUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('mutedUntil: $mutedUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalSessionsTableTable extends SignalSessionsTable
    with TableInfo<$SignalSessionsTableTable, SignalSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<String> recipientId = GeneratedColumn<String>(
    'recipient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionRecordMeta = const VerificationMeta(
    'sessionRecord',
  );
  @override
  late final GeneratedColumn<Uint8List> sessionRecord =
      GeneratedColumn<Uint8List>(
        'session_record',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [recipientId, deviceId, sessionRecord];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalSessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('session_record')) {
      context.handle(
        _sessionRecordMeta,
        sessionRecord.isAcceptableOrUnknown(
          data['session_record']!,
          _sessionRecordMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionRecordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipientId, deviceId};
  @override
  SignalSessionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSessionsTableData(
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      sessionRecord: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}session_record'],
      )!,
    );
  }

  @override
  $SignalSessionsTableTable createAlias(String alias) {
    return $SignalSessionsTableTable(attachedDatabase, alias);
  }
}

class SignalSessionsTableData extends DataClass
    implements Insertable<SignalSessionsTableData> {
  final String recipientId;
  final String deviceId;

  /// Serialised Signal Protocol session state (opaque binary blob).
  final Uint8List sessionRecord;
  const SignalSessionsTableData({
    required this.recipientId,
    required this.deviceId,
    required this.sessionRecord,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipient_id'] = Variable<String>(recipientId);
    map['device_id'] = Variable<String>(deviceId);
    map['session_record'] = Variable<Uint8List>(sessionRecord);
    return map;
  }

  SignalSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return SignalSessionsTableCompanion(
      recipientId: Value(recipientId),
      deviceId: Value(deviceId),
      sessionRecord: Value(sessionRecord),
    );
  }

  factory SignalSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSessionsTableData(
      recipientId: serializer.fromJson<String>(json['recipientId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      sessionRecord: serializer.fromJson<Uint8List>(json['sessionRecord']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipientId': serializer.toJson<String>(recipientId),
      'deviceId': serializer.toJson<String>(deviceId),
      'sessionRecord': serializer.toJson<Uint8List>(sessionRecord),
    };
  }

  SignalSessionsTableData copyWith({
    String? recipientId,
    String? deviceId,
    Uint8List? sessionRecord,
  }) => SignalSessionsTableData(
    recipientId: recipientId ?? this.recipientId,
    deviceId: deviceId ?? this.deviceId,
    sessionRecord: sessionRecord ?? this.sessionRecord,
  );
  SignalSessionsTableData copyWithCompanion(SignalSessionsTableCompanion data) {
    return SignalSessionsTableData(
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sessionRecord: data.sessionRecord.present
          ? data.sessionRecord.value
          : this.sessionRecord,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSessionsTableData(')
          ..write('recipientId: $recipientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('sessionRecord: $sessionRecord')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recipientId,
    deviceId,
    $driftBlobEquality.hash(sessionRecord),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalSessionsTableData &&
          other.recipientId == this.recipientId &&
          other.deviceId == this.deviceId &&
          $driftBlobEquality.equals(other.sessionRecord, this.sessionRecord));
}

class SignalSessionsTableCompanion
    extends UpdateCompanion<SignalSessionsTableData> {
  final Value<String> recipientId;
  final Value<String> deviceId;
  final Value<Uint8List> sessionRecord;
  final Value<int> rowid;
  const SignalSessionsTableCompanion({
    this.recipientId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sessionRecord = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalSessionsTableCompanion.insert({
    required String recipientId,
    required String deviceId,
    required Uint8List sessionRecord,
    this.rowid = const Value.absent(),
  }) : recipientId = Value(recipientId),
       deviceId = Value(deviceId),
       sessionRecord = Value(sessionRecord);
  static Insertable<SignalSessionsTableData> custom({
    Expression<String>? recipientId,
    Expression<String>? deviceId,
    Expression<Uint8List>? sessionRecord,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipientId != null) 'recipient_id': recipientId,
      if (deviceId != null) 'device_id': deviceId,
      if (sessionRecord != null) 'session_record': sessionRecord,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalSessionsTableCompanion copyWith({
    Value<String>? recipientId,
    Value<String>? deviceId,
    Value<Uint8List>? sessionRecord,
    Value<int>? rowid,
  }) {
    return SignalSessionsTableCompanion(
      recipientId: recipientId ?? this.recipientId,
      deviceId: deviceId ?? this.deviceId,
      sessionRecord: sessionRecord ?? this.sessionRecord,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipientId.present) {
      map['recipient_id'] = Variable<String>(recipientId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sessionRecord.present) {
      map['session_record'] = Variable<Uint8List>(sessionRecord.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalSessionsTableCompanion(')
          ..write('recipientId: $recipientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('sessionRecord: $sessionRecord, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreKeysTableTable extends PreKeysTable
    with TableInfo<$PreKeysTableTable, PreKeysTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreKeysTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
    'key_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyRecordMeta = const VerificationMeta(
    'keyRecord',
  );
  @override
  late final GeneratedColumn<Uint8List> keyRecord = GeneratedColumn<Uint8List>(
    'key_record',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedMeta = const VerificationMeta('used');
  @override
  late final GeneratedColumn<bool> used = GeneratedColumn<bool>(
    'used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("used" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [keyId, keyRecord, used];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pre_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreKeysTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key_id')) {
      context.handle(
        _keyIdMeta,
        keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta),
      );
    }
    if (data.containsKey('key_record')) {
      context.handle(
        _keyRecordMeta,
        keyRecord.isAcceptableOrUnknown(data['key_record']!, _keyRecordMeta),
      );
    } else if (isInserting) {
      context.missing(_keyRecordMeta);
    }
    if (data.containsKey('used')) {
      context.handle(
        _usedMeta,
        used.isAcceptableOrUnknown(data['used']!, _usedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyId};
  @override
  PreKeysTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreKeysTableData(
      keyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_id'],
      )!,
      keyRecord: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}key_record'],
      )!,
      used: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}used'],
      )!,
    );
  }

  @override
  $PreKeysTableTable createAlias(String alias) {
    return $PreKeysTableTable(attachedDatabase, alias);
  }
}

class PreKeysTableData extends DataClass
    implements Insertable<PreKeysTableData> {
  final int keyId;

  /// Serialised pre-key record (opaque binary blob).
  final Uint8List keyRecord;

  /// Whether this pre-key has already been consumed in a key exchange.
  final bool used;
  const PreKeysTableData({
    required this.keyId,
    required this.keyRecord,
    required this.used,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key_id'] = Variable<int>(keyId);
    map['key_record'] = Variable<Uint8List>(keyRecord);
    map['used'] = Variable<bool>(used);
    return map;
  }

  PreKeysTableCompanion toCompanion(bool nullToAbsent) {
    return PreKeysTableCompanion(
      keyId: Value(keyId),
      keyRecord: Value(keyRecord),
      used: Value(used),
    );
  }

  factory PreKeysTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreKeysTableData(
      keyId: serializer.fromJson<int>(json['keyId']),
      keyRecord: serializer.fromJson<Uint8List>(json['keyRecord']),
      used: serializer.fromJson<bool>(json['used']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyId': serializer.toJson<int>(keyId),
      'keyRecord': serializer.toJson<Uint8List>(keyRecord),
      'used': serializer.toJson<bool>(used),
    };
  }

  PreKeysTableData copyWith({int? keyId, Uint8List? keyRecord, bool? used}) =>
      PreKeysTableData(
        keyId: keyId ?? this.keyId,
        keyRecord: keyRecord ?? this.keyRecord,
        used: used ?? this.used,
      );
  PreKeysTableData copyWithCompanion(PreKeysTableCompanion data) {
    return PreKeysTableData(
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      keyRecord: data.keyRecord.present ? data.keyRecord.value : this.keyRecord,
      used: data.used.present ? data.used.value : this.used,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreKeysTableData(')
          ..write('keyId: $keyId, ')
          ..write('keyRecord: $keyRecord, ')
          ..write('used: $used')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(keyId, $driftBlobEquality.hash(keyRecord), used);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreKeysTableData &&
          other.keyId == this.keyId &&
          $driftBlobEquality.equals(other.keyRecord, this.keyRecord) &&
          other.used == this.used);
}

class PreKeysTableCompanion extends UpdateCompanion<PreKeysTableData> {
  final Value<int> keyId;
  final Value<Uint8List> keyRecord;
  final Value<bool> used;
  const PreKeysTableCompanion({
    this.keyId = const Value.absent(),
    this.keyRecord = const Value.absent(),
    this.used = const Value.absent(),
  });
  PreKeysTableCompanion.insert({
    this.keyId = const Value.absent(),
    required Uint8List keyRecord,
    this.used = const Value.absent(),
  }) : keyRecord = Value(keyRecord);
  static Insertable<PreKeysTableData> custom({
    Expression<int>? keyId,
    Expression<Uint8List>? keyRecord,
    Expression<bool>? used,
  }) {
    return RawValuesInsertable({
      if (keyId != null) 'key_id': keyId,
      if (keyRecord != null) 'key_record': keyRecord,
      if (used != null) 'used': used,
    });
  }

  PreKeysTableCompanion copyWith({
    Value<int>? keyId,
    Value<Uint8List>? keyRecord,
    Value<bool>? used,
  }) {
    return PreKeysTableCompanion(
      keyId: keyId ?? this.keyId,
      keyRecord: keyRecord ?? this.keyRecord,
      used: used ?? this.used,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (keyRecord.present) {
      map['key_record'] = Variable<Uint8List>(keyRecord.value);
    }
    if (used.present) {
      map['used'] = Variable<bool>(used.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreKeysTableCompanion(')
          ..write('keyId: $keyId, ')
          ..write('keyRecord: $keyRecord, ')
          ..write('used: $used')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTableTable messagesTable = $MessagesTableTable(this);
  late final $ConversationsTableTable conversationsTable =
      $ConversationsTableTable(this);
  late final $SignalSessionsTableTable signalSessionsTable =
      $SignalSessionsTableTable(this);
  late final $PreKeysTableTable preKeysTable = $PreKeysTableTable(this);
  late final MessageDao messageDao = MessageDao(this as AppDatabase);
  late final ConversationDao conversationDao = ConversationDao(
    this as AppDatabase,
  );
  late final SignalDao signalDao = SignalDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messagesTable,
    conversationsTable,
    signalSessionsTable,
    preKeysTable,
  ];
}

typedef $$MessagesTableTableCreateCompanionBuilder =
    MessagesTableCompanion Function({
      required String id,
      required String conversationId,
      required String senderId,
      required Uint8List ciphertext,
      Value<String?> plaintextCache,
      Value<String?> mediaLocalPath,
      required String type,
      required int sentAt,
      Value<int?> deliveredAt,
      Value<int?> readAt,
      Value<bool> deletedForEveryone,
      Value<String?> quotedMessageId,
      required String status,
      Value<int> rowid,
    });
typedef $$MessagesTableTableUpdateCompanionBuilder =
    MessagesTableCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> senderId,
      Value<Uint8List> ciphertext,
      Value<String?> plaintextCache,
      Value<String?> mediaLocalPath,
      Value<String> type,
      Value<int> sentAt,
      Value<int?> deliveredAt,
      Value<int?> readAt,
      Value<bool> deletedForEveryone,
      Value<String?> quotedMessageId,
      Value<String> status,
      Value<int> rowid,
    });

class $$MessagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableFilterComposer({
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

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plaintextCache => $composableBuilder(
    column: $table.plaintextCache,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deletedForEveryone => $composableBuilder(
    column: $table.deletedForEveryone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quotedMessageId => $composableBuilder(
    column: $table.quotedMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableOrderingComposer({
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

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plaintextCache => $composableBuilder(
    column: $table.plaintextCache,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deletedForEveryone => $composableBuilder(
    column: $table.deletedForEveryone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotedMessageId => $composableBuilder(
    column: $table.quotedMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<Uint8List> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plaintextCache => $composableBuilder(
    column: $table.plaintextCache,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<bool> get deletedForEveryone => $composableBuilder(
    column: $table.deletedForEveryone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quotedMessageId => $composableBuilder(
    column: $table.quotedMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$MessagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTableTable,
          MessagesTableData,
          $$MessagesTableTableFilterComposer,
          $$MessagesTableTableOrderingComposer,
          $$MessagesTableTableAnnotationComposer,
          $$MessagesTableTableCreateCompanionBuilder,
          $$MessagesTableTableUpdateCompanionBuilder,
          (
            MessagesTableData,
            BaseReferences<
              _$AppDatabase,
              $MessagesTableTable,
              MessagesTableData
            >,
          ),
          MessagesTableData,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableTableManager(_$AppDatabase db, $MessagesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<Uint8List> ciphertext = const Value.absent(),
                Value<String?> plaintextCache = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> sentAt = const Value.absent(),
                Value<int?> deliveredAt = const Value.absent(),
                Value<int?> readAt = const Value.absent(),
                Value<bool> deletedForEveryone = const Value.absent(),
                Value<String?> quotedMessageId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                ciphertext: ciphertext,
                plaintextCache: plaintextCache,
                mediaLocalPath: mediaLocalPath,
                type: type,
                sentAt: sentAt,
                deliveredAt: deliveredAt,
                readAt: readAt,
                deletedForEveryone: deletedForEveryone,
                quotedMessageId: quotedMessageId,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String senderId,
                required Uint8List ciphertext,
                Value<String?> plaintextCache = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                required String type,
                required int sentAt,
                Value<int?> deliveredAt = const Value.absent(),
                Value<int?> readAt = const Value.absent(),
                Value<bool> deletedForEveryone = const Value.absent(),
                Value<String?> quotedMessageId = const Value.absent(),
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion.insert(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                ciphertext: ciphertext,
                plaintextCache: plaintextCache,
                mediaLocalPath: mediaLocalPath,
                type: type,
                sentAt: sentAt,
                deliveredAt: deliveredAt,
                readAt: readAt,
                deletedForEveryone: deletedForEveryone,
                quotedMessageId: quotedMessageId,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTableTable,
      MessagesTableData,
      $$MessagesTableTableFilterComposer,
      $$MessagesTableTableOrderingComposer,
      $$MessagesTableTableAnnotationComposer,
      $$MessagesTableTableCreateCompanionBuilder,
      $$MessagesTableTableUpdateCompanionBuilder,
      (
        MessagesTableData,
        BaseReferences<_$AppDatabase, $MessagesTableTable, MessagesTableData>,
      ),
      MessagesTableData,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableTableCreateCompanionBuilder =
    ConversationsTableCompanion Function({
      required String id,
      required String type,
      Value<String?> lastMessagePreview,
      Value<int?> lastMessageAt,
      Value<bool> isArchived,
      Value<int> unreadCount,
      Value<int?> mutedUntil,
      Value<int> rowid,
    });
typedef $$ConversationsTableTableUpdateCompanionBuilder =
    ConversationsTableCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String?> lastMessagePreview,
      Value<int?> lastMessageAt,
      Value<bool> isArchived,
      Value<int> unreadCount,
      Value<int?> mutedUntil,
      Value<int> rowid,
    });

class $$ConversationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTableTable> {
  $$ConversationsTableTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mutedUntil => $composableBuilder(
    column: $table.mutedUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTableTable> {
  $$ConversationsTableTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mutedUntil => $composableBuilder(
    column: $table.mutedUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTableTable> {
  $$ConversationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mutedUntil => $composableBuilder(
    column: $table.mutedUntil,
    builder: (column) => column,
  );
}

class $$ConversationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTableTable,
          ConversationsTableData,
          $$ConversationsTableTableFilterComposer,
          $$ConversationsTableTableOrderingComposer,
          $$ConversationsTableTableAnnotationComposer,
          $$ConversationsTableTableCreateCompanionBuilder,
          $$ConversationsTableTableUpdateCompanionBuilder,
          (
            ConversationsTableData,
            BaseReferences<
              _$AppDatabase,
              $ConversationsTableTable,
              ConversationsTableData
            >,
          ),
          ConversationsTableData,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableTableManager(
    _$AppDatabase db,
    $ConversationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int?> lastMessageAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int?> mutedUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsTableCompanion(
                id: id,
                type: type,
                lastMessagePreview: lastMessagePreview,
                lastMessageAt: lastMessageAt,
                isArchived: isArchived,
                unreadCount: unreadCount,
                mutedUntil: mutedUntil,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int?> lastMessageAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int?> mutedUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsTableCompanion.insert(
                id: id,
                type: type,
                lastMessagePreview: lastMessagePreview,
                lastMessageAt: lastMessageAt,
                isArchived: isArchived,
                unreadCount: unreadCount,
                mutedUntil: mutedUntil,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTableTable,
      ConversationsTableData,
      $$ConversationsTableTableFilterComposer,
      $$ConversationsTableTableOrderingComposer,
      $$ConversationsTableTableAnnotationComposer,
      $$ConversationsTableTableCreateCompanionBuilder,
      $$ConversationsTableTableUpdateCompanionBuilder,
      (
        ConversationsTableData,
        BaseReferences<
          _$AppDatabase,
          $ConversationsTableTable,
          ConversationsTableData
        >,
      ),
      ConversationsTableData,
      PrefetchHooks Function()
    >;
typedef $$SignalSessionsTableTableCreateCompanionBuilder =
    SignalSessionsTableCompanion Function({
      required String recipientId,
      required String deviceId,
      required Uint8List sessionRecord,
      Value<int> rowid,
    });
typedef $$SignalSessionsTableTableUpdateCompanionBuilder =
    SignalSessionsTableCompanion Function({
      Value<String> recipientId,
      Value<String> deviceId,
      Value<Uint8List> sessionRecord,
      Value<int> rowid,
    });

class $$SignalSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SignalSessionsTableTable> {
  $$SignalSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sessionRecord => $composableBuilder(
    column: $table.sessionRecord,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SignalSessionsTableTable> {
  $$SignalSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sessionRecord => $composableBuilder(
    column: $table.sessionRecord,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SignalSessionsTableTable> {
  $$SignalSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<Uint8List> get sessionRecord => $composableBuilder(
    column: $table.sessionRecord,
    builder: (column) => column,
  );
}

class $$SignalSessionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SignalSessionsTableTable,
          SignalSessionsTableData,
          $$SignalSessionsTableTableFilterComposer,
          $$SignalSessionsTableTableOrderingComposer,
          $$SignalSessionsTableTableAnnotationComposer,
          $$SignalSessionsTableTableCreateCompanionBuilder,
          $$SignalSessionsTableTableUpdateCompanionBuilder,
          (
            SignalSessionsTableData,
            BaseReferences<
              _$AppDatabase,
              $SignalSessionsTableTable,
              SignalSessionsTableData
            >,
          ),
          SignalSessionsTableData,
          PrefetchHooks Function()
        > {
  $$SignalSessionsTableTableTableManager(
    _$AppDatabase db,
    $SignalSessionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalSessionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SignalSessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> recipientId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<Uint8List> sessionRecord = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalSessionsTableCompanion(
                recipientId: recipientId,
                deviceId: deviceId,
                sessionRecord: sessionRecord,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipientId,
                required String deviceId,
                required Uint8List sessionRecord,
                Value<int> rowid = const Value.absent(),
              }) => SignalSessionsTableCompanion.insert(
                recipientId: recipientId,
                deviceId: deviceId,
                sessionRecord: sessionRecord,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalSessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SignalSessionsTableTable,
      SignalSessionsTableData,
      $$SignalSessionsTableTableFilterComposer,
      $$SignalSessionsTableTableOrderingComposer,
      $$SignalSessionsTableTableAnnotationComposer,
      $$SignalSessionsTableTableCreateCompanionBuilder,
      $$SignalSessionsTableTableUpdateCompanionBuilder,
      (
        SignalSessionsTableData,
        BaseReferences<
          _$AppDatabase,
          $SignalSessionsTableTable,
          SignalSessionsTableData
        >,
      ),
      SignalSessionsTableData,
      PrefetchHooks Function()
    >;
typedef $$PreKeysTableTableCreateCompanionBuilder =
    PreKeysTableCompanion Function({
      Value<int> keyId,
      required Uint8List keyRecord,
      Value<bool> used,
    });
typedef $$PreKeysTableTableUpdateCompanionBuilder =
    PreKeysTableCompanion Function({
      Value<int> keyId,
      Value<Uint8List> keyRecord,
      Value<bool> used,
    });

class $$PreKeysTableTableFilterComposer
    extends Composer<_$AppDatabase, $PreKeysTableTable> {
  $$PreKeysTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get keyRecord => $composableBuilder(
    column: $table.keyRecord,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreKeysTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PreKeysTableTable> {
  $$PreKeysTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get keyRecord => $composableBuilder(
    column: $table.keyRecord,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreKeysTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreKeysTableTable> {
  $$PreKeysTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get keyRecord =>
      $composableBuilder(column: $table.keyRecord, builder: (column) => column);

  GeneratedColumn<bool> get used =>
      $composableBuilder(column: $table.used, builder: (column) => column);
}

class $$PreKeysTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreKeysTableTable,
          PreKeysTableData,
          $$PreKeysTableTableFilterComposer,
          $$PreKeysTableTableOrderingComposer,
          $$PreKeysTableTableAnnotationComposer,
          $$PreKeysTableTableCreateCompanionBuilder,
          $$PreKeysTableTableUpdateCompanionBuilder,
          (
            PreKeysTableData,
            BaseReferences<_$AppDatabase, $PreKeysTableTable, PreKeysTableData>,
          ),
          PreKeysTableData,
          PrefetchHooks Function()
        > {
  $$PreKeysTableTableTableManager(_$AppDatabase db, $PreKeysTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreKeysTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreKeysTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreKeysTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> keyId = const Value.absent(),
                Value<Uint8List> keyRecord = const Value.absent(),
                Value<bool> used = const Value.absent(),
              }) => PreKeysTableCompanion(
                keyId: keyId,
                keyRecord: keyRecord,
                used: used,
              ),
          createCompanionCallback:
              ({
                Value<int> keyId = const Value.absent(),
                required Uint8List keyRecord,
                Value<bool> used = const Value.absent(),
              }) => PreKeysTableCompanion.insert(
                keyId: keyId,
                keyRecord: keyRecord,
                used: used,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreKeysTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreKeysTableTable,
      PreKeysTableData,
      $$PreKeysTableTableFilterComposer,
      $$PreKeysTableTableOrderingComposer,
      $$PreKeysTableTableAnnotationComposer,
      $$PreKeysTableTableCreateCompanionBuilder,
      $$PreKeysTableTableUpdateCompanionBuilder,
      (
        PreKeysTableData,
        BaseReferences<_$AppDatabase, $PreKeysTableTable, PreKeysTableData>,
      ),
      PreKeysTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableTableManager get messagesTable =>
      $$MessagesTableTableTableManager(_db, _db.messagesTable);
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(_db, _db.conversationsTable);
  $$SignalSessionsTableTableTableManager get signalSessionsTable =>
      $$SignalSessionsTableTableTableManager(_db, _db.signalSessionsTable);
  $$PreKeysTableTableTableManager get preKeysTable =>
      $$PreKeysTableTableTableManager(_db, _db.preKeysTable);
}
