import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/core/router/app_router.dart';
import 'package:whatsapp2_0/features/auth/presentation/providers/auth_providers.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _PhoneEntryState {
  const _PhoneEntryState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  _PhoneEntryState copyWith({bool? isLoading, String? errorMessage}) {
    return _PhoneEntryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class _PhoneEntryNotifier extends Notifier<_PhoneEntryState> {
  @override
  _PhoneEntryState build() => const _PhoneEntryState();

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final useCase = ref.read(phoneVerificationUseCaseProvider);
    final result = await useCase.sendOtp(phone);

    switch (result) {
      case Ok():
        state = state.copyWith(isLoading: false);
        return true;
      case Err(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: _errorMessage(error),
        );
        return false;
    }
  }

  String _errorMessage(AppError error) {
    return switch (error) {
      ValidationError(:final message) => message,
      AuthError(:final message) => message,
      NetworkError(:final message) => 'Network error: $message',
      _ => 'Something went wrong. Please try again.',
    };
  }
}

final _phoneEntryProvider =
    NotifierProvider.autoDispose<_PhoneEntryNotifier, _PhoneEntryState>(
      _PhoneEntryNotifier.new,
    );

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Phone number entry screen — the first step of the auth flow.
///
/// Requirements: 1.1, 1.2
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryCodeController = TextEditingController(text: '+1');
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final code = _countryCodeController.text.trim();
    final number = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    return '$code$number';
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(_phoneEntryProvider.notifier)
        .sendOtp(_fullPhone);

    if (success && mounted) {
      context.push(AppRoutes.otpVerification, extra: _fullPhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_phoneEntryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter your phone number'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'WhatsApp will send an SMS message to verify your phone number.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        controller: _countryCodeController,
                        enabled: !state.isLoading,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(labelText: 'Code'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!RegExp(r'^\+\d{1,3}$').hasMatch(v.trim())) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        enabled: !state.isLoading,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '(201) 555-0123',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                const SizedBox(height: 32),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _onContinue,
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
