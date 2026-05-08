import 'dart:async';
import 'package:flutter/material.dart';
import 'package:whatsapp2_0/features/presence/domain/presence_repository.dart';

/// Service that maintains the user's online presence while the app is in the
/// foreground and registers a Firestore `onDisconnect()` handler to
/// automatically set `isOnline: false` and update `lastSeen` when the app
/// goes to the background or loses connectivity.
///
/// ## Behaviour
///
/// - **App foregrounded**: Writes `isOnline: true` and registers the
///   `onDisconnect` handler.
/// - **Periodic heartbeat**: Re-writes `isOnline: true` every 60 seconds
///   while the app is foregrounded to prevent Firestore from clearing the
///   online state due to inactivity.
/// - **App backgrounded**: The `onDisconnect` handler in Firestore
///   automatically sets `isOnline: false` and records `lastSeen`.
///
/// Requirements: 10.1, 10.2
class PresenceHeartbeatService {
  PresenceHeartbeatService({required PresenceRepository repository})
      : _repository = repository;

  final PresenceRepository _repository;
  Timer? _heartbeatTimer;

  /// The interval between heartbeat writes to Firestore.
  static const Duration _heartbeatInterval = Duration(seconds: 60);

  /// Starts the presence heartbeat.
  ///
  /// Call this from [WidgetsBindingObserver.didChangeAppLifecycleState]
  /// when the app transitions to the foreground (resumed state).
  Future<void> start({required String userId}) async {
    // Write online = true and register onDisconnect
    await _repository.setOnline(userId: userId);

    // Start periodic heartbeat
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      await _repository.setOnline(userId: userId);
    });
  }

  /// Stops the presence heartbeat and sets the user offline.
  ///
  /// Call this when the app transitions to the background (paused state)
  /// or when the user explicitly signs out.
  Future<void> stop({required String userId}) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _repository.setOffline(userId: userId);
  }

  /// Disposes of the heartbeat timer.
  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}

/// Widget binding observer that integrates [PresenceHeartbeatService] with
/// the app's lifecycle.
///
/// Automatically starts the heartbeat when the app is resumed and stops it
/// when the app is paused.
class PresenceLifecycleObserver extends WidgetsBindingObserver {
  PresenceLifecycleObserver({
    required PresenceHeartbeatService service,
    required String userId,
  })  : _service = service,
        _userId = userId;

  final PresenceHeartbeatService _service;
  final String _userId;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _service.start(userId: _userId);
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _service.stop(userId: _userId);
    }
  }

  void dispose() {
    _service.dispose();
  }
}