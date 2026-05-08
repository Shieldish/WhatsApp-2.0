import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/core/router/app_router.dart';
import 'package:whatsapp2_0/core/validators/phone_number_validator.dart';

/// Screen shown when the user denies address-book permission.
///
/// Allows the user to manually enter a phone number in E.164 format to start
/// a conversation directly.
///
/// Requirements: 2.3, 2.4
class ManualContactEntryScreen extends StatefulWidget {
  const ManualContactEntryScreen({super.key});

  @override
  State<ManualContactEntryScreen> createState() =>
      _ManualContactEntryScreenState();
}

class _ManualContactEntryScreenState extends State<ManualContactEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+');
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number.';
    }
    final result = PhoneNumberValidator.validate(value.trim());
    return switch (result) {
      Ok() => null,
      Err(:final error) => error.message,
    };
  }

  Future<void> _onStartChat() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();

    // Navigate to the chat screen for this phone number.
    // The conversationId is derived from the phone number for direct chats.
    // In a real implementation, the use case would look up or create the
    // conversation for this phone number.
    if (mounted) {
      setState(() => _isLoading = false);
      // Navigate to chat list and let the user find or create the conversation.
      // For now, we navigate to the chat list with the phone number as extra.
      context.go(AppRoutes.chatList, extra: {'phone': phone});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter phone number'),
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
                // Explanation text
                Text(
                  'Contacts permission was not granted. You can still start a '
                  'conversation by entering a phone number directly.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Phone number field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (E.164)',
                    hintText: '+14155552671',
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'Include country code, e.g. +1 for the US.',
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 32),

                // Start Chat button
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
                    onPressed: _onStartChat,
                    icon: const Icon(Icons.chat),
                    label: const Text(
                      'START CHAT',
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
