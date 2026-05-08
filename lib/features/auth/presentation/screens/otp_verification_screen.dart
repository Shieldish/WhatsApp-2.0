import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/core/router/app_router.dart';
import 'package:whatsapp2_0/features/auth/domain/entities/session.dart';
import 'package:whatsapp2_0/features/auth/presentation/providers/auth_providers.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum _VerifyStatus { idle, loading, locked }

class _OtpState {
  const _OtpState({
    this.status = _VerifyStatus.idle,
    this.errorMessage,
    this.lockoutRemaining = Duration.zero,
    this.showVoiceCallButton = false,
    this.voiceCallLoading = false,
    this.voiceCallMessage,
  });

  final _VerifyStatus status;
  final String? errorMessage;
  final Duration lockoutRemaining;

  /// Whether the "Call me instead" button is visible (shown after 60 s).
  final bool showVoiceCallButton;

  /// Whether a voice-call OTP request is in progress.
  final bool voiceCallLoading;

  /// Feedback message after a voice-call OTP attempt (success or error).
  final String? voiceCallMessage;

  bool get isLocked => status == _VerifyStatus.locked;
  bool get isLoading => status == _VerifyStatus.loading;

  _OtpState copyWith({
    _VerifyStatus? status,
    String? errorMessage,
    Duration? lockoutRemaining,
    bool? showVoiceCallButton,
    bool? voiceCallLoading,
    // Use a sentinel to allow explicitly clearing the message.
    Object? voiceCallMessage = _keep,
  }) {
    return _OtpState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lockoutRemaining: lockoutRemaining ?? this.lockoutRemaining,
      showVoiceCallButton: showVoiceCallButton ?? this.showVoiceCallButton,
      voiceCallLoading: voiceCallLoading ?? this.voiceCallLoading,
      voiceCallMessage: identical(voiceCallMessage, _keep)
          ? this.voiceCallMessage
          : voiceCallMessage as String?,
    );
  }

  static const Object _keep = Object();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class _OtpNotifier extends Notifier<_OtpState> {
  @override
  _OtpState build() {
    _initLockout();
    return const _OtpState();
  }

  void _initLockout() {
    final lockoutTimer = ref.read(otpLockoutTimerProvider);
    lockoutTimer.initialize().then((_) {
      if (lockoutTimer.isLocked) {
        state = state.copyWith(
          status: _VerifyStatus.locked,
          lockoutRemaining: lockoutTimer.remainingLockoutDuration,
        );
        _listenCountdown();
      }
    });
  }

  void _listenCountdown() {
    final lockoutTimer = ref.read(otpLockoutTimerProvider);
    lockoutTimer.countdownStream.listen((remaining) {
      if (remaining == Duration.zero) {
        state = state.copyWith(
          status: _VerifyStatus.idle,
          lockoutRemaining: Duration.zero,
        );
      } else {
        state = state.copyWith(
          status: _VerifyStatus.locked,
          lockoutRemaining: remaining,
        );
      }
    });
  }

  Future<Session?> verifyOtp(String otp) async {
    final lockoutTimer = ref.read(otpLockoutTimerProvider);

    if (lockoutTimer.isLocked) {
      state = state.copyWith(
        status: _VerifyStatus.locked,
        errorMessage: 'Too many attempts. Please wait.',
      );
      return null;
    }

    state = state.copyWith(status: _VerifyStatus.loading, errorMessage: null);

    final useCase = ref.read(phoneVerificationUseCaseProvider);
    final result = await useCase.verifyOtp(otp);

    switch (result) {
      case Ok(:final value):
        await lockoutTimer.reset();
        state = state.copyWith(status: _VerifyStatus.idle);
        return value;
      case Err(:final error):
        await lockoutTimer.recordFailure();
        final isNowLocked = lockoutTimer.isLocked;
        if (isNowLocked) {
          state = state.copyWith(
            status: _VerifyStatus.locked,
            errorMessage: 'Too many failed attempts. Locked for 1 hour.',
            lockoutRemaining: lockoutTimer.remainingLockoutDuration,
          );
          _listenCountdown();
        } else {
          state = state.copyWith(
            status: _VerifyStatus.idle,
            errorMessage: _errorMessage(error),
          );
        }
        return null;
    }
  }

  /// Shows the "Call me instead" button (called after the 60 s timer fires).
  void revealVoiceCallButton() {
    state = state.copyWith(showVoiceCallButton: true);
  }

  /// Requests a voice-call OTP for [phoneE164].
  Future<void> requestVoiceOtp(String phoneE164) async {
    state = state.copyWith(voiceCallLoading: true, voiceCallMessage: null);

    final useCase = ref.read(requestVoiceOtpUseCaseProvider);
    final result = await useCase.call(phoneE164);

    switch (result) {
      case Ok():
        state = state.copyWith(
          voiceCallLoading: false,
          voiceCallMessage: 'A voice call will be made to your number',
        );
      case Err(:final error):
        state = state.copyWith(
          voiceCallLoading: false,
          voiceCallMessage: _voiceCallErrorMessage(error),
        );
    }
  }

  String _errorMessage(AppError error) {
    return switch (error) {
      ValidationError(:final message) => message,
      AuthError(:final message) => message,
      NetworkError(:final message) => 'Network error: $message',
      _ => 'Verification failed. Please try again.',
    };
  }

  String _voiceCallErrorMessage(AppError error) {
    return switch (error) {
      NetworkError(:final message) => 'Could not initiate call: $message',
      _ => 'Could not initiate call. Please try again.',
    };
  }
}

final _otpProvider = NotifierProvider.autoDispose<_OtpNotifier, _OtpState>(
  _OtpNotifier.new,
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// OTP verification screen — the second step of the auth flow.
///
/// Requirements: 1.2, 1.3, 1.4, 1.5
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  /// Timer that reveals the "Call me instead" button after 60 seconds.
  Timer? _voiceCallTimer;

  @override
  void initState() {
    super.initState();
    _startVoiceCallTimer();
  }

  void _startVoiceCallTimer() {
    _voiceCallTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        ref.read(_otpProvider.notifier).revealVoiceCallButton();
      }
    });
  }

  @override
  void dispose() {
    _voiceCallTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code.')),
      );
      return;
    }

    final session = await ref.read(_otpProvider.notifier).verifyOtp(otp);

    if (session != null && mounted) {
      context.go(AppRoutes.profileSetup);
    }
  }

  Future<void> _onCallMeInstead() async {
    await ref.read(_otpProvider.notifier).requestVoiceOtp(widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_otpProvider);
    final theme = Theme.of(context);
    final isInteractive = !state.isLoading && !state.isLocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your number'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'We sent a 6-digit code to',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                enabled: isInteractive,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '------',
                  counterText: '',
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (state.isLocked && state.lockoutRemaining > Duration.zero) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_clock,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Try again in ${_formatDuration(state.lockoutRemaining)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: isInteractive ? _onVerify : null,
                  child: const Text(
                    'VERIFY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

              // ---------------------------------------------------------------
              // Voice-call OTP fallback — shown after 60 s (Requirement 1.3)
              // ---------------------------------------------------------------
              if (state.showVoiceCallButton) ...[
                const SizedBox(height: 16),
                if (state.voiceCallLoading)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    onPressed: isInteractive ? _onCallMeInstead : null,
                    child: const Text('Call me instead'),
                  ),
                if (state.voiceCallMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.voiceCallMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isVoiceCallSuccess(state.voiceCallMessage!)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isVoiceCallSuccess(String message) =>
      message == 'A voice call will be made to your number';

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
