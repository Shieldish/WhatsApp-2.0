import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whatsapp2_0/features/auth/domain/auth_repository.dart';
import 'package:whatsapp2_0/features/auth/domain/entities/session.dart';

/// Persists, retrieves, and invalidates the authenticated [Session].
///
/// Wraps [flutter_secure_storage] for local token persistence and delegates
/// the live auth-state stream to [AuthRepository.sessionStream].
///
/// Storage keys (all stored as JSON):
/// - `'session'` — the serialised [Session] object.
///
/// Requirements: 1.6
class SessionManager {
  SessionManager({
    required AuthRepository authRepository,
    FlutterSecureStorage? storage,
  }) : _authRepository = authRepository,
       _storage = storage ?? const FlutterSecureStorage();

  static const String _sessionKey = 'session';

  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Reads the persisted [Session] from secure storage.
  ///
  /// Returns `null` if no session has been saved or if the stored data is
  /// malformed.
  Future<Session?> getSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _sessionFromMap(map);
    } catch (_) {
      // Stored data is corrupt — treat as no session.
      return null;
    }
  }

  /// Persists [session] to secure storage.
  Future<void> saveSession(Session session) async {
    final encoded = jsonEncode(_sessionToMap(session));
    await _storage.write(key: _sessionKey, value: encoded);
  }

  /// Removes the persisted session from secure storage.
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  /// A stream that emits the current [Session] whenever the Firebase Auth
  /// state changes, or `null` when the user is signed out.
  ///
  /// Delegates directly to [AuthRepository.sessionStream].
  Stream<Session?> get sessionStream => _authRepository.sessionStream;

  /// Returns `true` if a valid (non-null) session is currently persisted.
  Future<bool> get isAuthenticated async {
    final session = await getSession();
    return session != null;
  }

  // ---------------------------------------------------------------------------
  // Serialisation helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _sessionToMap(Session session) => {
    'userId': session.userId,
    'phoneNumber': session.phoneNumber,
    'token': session.token,
    'createdAt': session.createdAt.toIso8601String(),
  };

  Session _sessionFromMap(Map<String, dynamic> map) => Session(
    userId: map['userId'] as String,
    phoneNumber: map['phoneNumber'] as String,
    token: map['token'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
