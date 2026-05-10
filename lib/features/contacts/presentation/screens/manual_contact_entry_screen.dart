import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/core/utils/conversation_id.dart';
import 'package:whatsapp2_0/core/validators/phone_number_validator.dart';

class ManualContactEntryScreen extends ConsumerStatefulWidget {
  const ManualContactEntryScreen({super.key});

  @override
  ConsumerState<ManualContactEntryScreen> createState() =>
      _ManualContactEntryScreenState();
}

class _ManualContactEntryScreenState
    extends ConsumerState<ManualContactEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+');
  bool _isLoading = false;
  String? _errorMessage;

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No user found with that number. '
              'Make sure they have registered.';
        });
        return;
      }

      final doc = snapshot.docs.first;
      final userId = doc.id;
      final displayName = (doc.data()['displayName'] as String?) ?? phone;
      final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final convId = directConversationId(myUid, userId);

      setState(() => _isLoading = false);

      context.go('/chats/$convId', extra: {
        'contactName': displayName,
        'recipientId': userId,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error looking up number. Check your connection.';
        });
      }
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
                Text(
                  'Enter the phone number of the person you want to chat with.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (E.164)',
                    hintText: '+14155552671',
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'Include country code, e.g. +213 for Algeria.',
                  ),
                  validator: _validatePhone,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
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
