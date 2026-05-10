import 'package:country_code_picker/country_code_picker.dart';
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

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _dialCode = '+1';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final number = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    return '$_dialCode$number';
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Country picker with flag
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CountryCodePicker(
                        onChanged: (code) {
                          setState(() => _dialCode = code.dialCode ?? '+1');
                        },
                        initialSelection: 'DZ',
                        favorite: const ['+213', '+33', '+1'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        enabled: !state.isLoading,
                        textStyle: theme.textTheme.bodyMedium,
                        dialogSize: const Size(400, 500),
                        searchDecoration: const InputDecoration(
                          hintText: 'Search country',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Phone number field
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        enabled: !state.isLoading,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '555 000 001',
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
