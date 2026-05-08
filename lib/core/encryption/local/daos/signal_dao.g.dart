// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_dao.dart';

// ignore_for_file: type=lint
mixin _$SignalDaoMixin on DatabaseAccessor<AppDatabase> {
  $SignalSessionsTableTable get signalSessionsTable =>
      attachedDatabase.signalSessionsTable;
  $PreKeysTableTable get preKeysTable => attachedDatabase.preKeysTable;
  SignalDaoManager get managers => SignalDaoManager(this);
}

class SignalDaoManager {
  final _$SignalDaoMixin _db;
  SignalDaoManager(this._db);
  $$SignalSessionsTableTableTableManager get signalSessionsTable =>
      $$SignalSessionsTableTableTableManager(
        _db.attachedDatabase,
        _db.signalSessionsTable,
      );
  $$PreKeysTableTableTableManager get preKeysTable =>
      $$PreKeysTableTableTableManager(_db.attachedDatabase, _db.preKeysTable);
}
