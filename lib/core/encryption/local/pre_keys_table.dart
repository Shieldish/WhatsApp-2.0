import 'package:drift/drift.dart';

/// Drift table definition for Signal Protocol pre-keys.
///
/// Stores one-time pre-keys and signed pre-keys generated during key
/// registration. The [used] flag marks keys that have already been consumed
/// in an X3DH key agreement so they are not reused.
class PreKeysTable extends Table {
  @override
  String get tableName => 'pre_keys';

  IntColumn get keyId => integer()();

  /// Serialised pre-key record (opaque binary blob).
  BlobColumn get keyRecord => blob()();

  /// Whether this pre-key has already been consumed in a key exchange.
  BoolColumn get used => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {keyId};
}
