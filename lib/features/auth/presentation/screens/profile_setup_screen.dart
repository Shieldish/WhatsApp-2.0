import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp2_0/core/router/app_router.dart';
import 'package:whatsapp2_0/core/validators/display_name_validator.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _ProfileSetupState {
  const _ProfileSetupState({
    this.isLoading = false,
    this.photoFile,
    this.errorMessage,
  });

  final bool isLoading;
  final File? photoFile;
  final String? errorMessage;

  _ProfileSetupState copyWith({
    bool? isLoading,
    File? photoFile,
    bool clearPhoto = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return _ProfileSetupState(
      isLoading: isLoading ?? this.isLoading,
      photoFile: clearPhoto ? null : (photoFile ?? this.photoFile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class _ProfileSetupNotifier extends Notifier<_ProfileSetupState> {
  final _picker = ImagePicker();

  @override
  _ProfileSetupState build() => const _ProfileSetupState();

  Future<void> pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        state = state.copyWith(photoFile: File(picked.path));
      }
    } catch (_) {
      // Silently ignore picker errors (e.g. permission denied).
    }
  }

  /// Validates the display name and, if valid, "saves" the profile.
  ///
  /// Actual Firestore persistence is wired in Task 20.
  bool saveProfile(String displayName) {
    final result = DisplayNameValidator.validate(displayName);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.errorOrNull?.message);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    // TODO(task-20): persist displayName and photoFile to Firestore.
    state = state.copyWith(isLoading: false);
    return true;
  }
}

final _profileSetupProvider =
    NotifierProvider.autoDispose<_ProfileSetupNotifier, _ProfileSetupState>(
      _ProfileSetupNotifier.new,
    );

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Profile setup screen — the final step of the registration flow.
///
/// Requirements: 1.7
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onDone() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text;
    final success = ref.read(_profileSetupProvider.notifier).saveProfile(name);

    if (success && mounted) {
      context.go(AppRoutes.chatList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_profileSetupProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile info'),
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
                'Please provide your name and an optional profile photo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(_profileSetupProvider.notifier).pickPhoto(),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: state.photoFile != null
                            ? FileImage(state.photoFile!)
                            : null,
                        child: state.photoFile == null
                            ? Icon(
                                Icons.person,
                                size: 56,
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                enabled: !state.isLoading,
                maxLength: 25,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Your name',
                  hintText: 'Enter your name',
                  errorText: state.errorMessage,
                ),
              ),
              const SizedBox(height: 32),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _onDone,
                  child: const Text(
                    'DONE',
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
    );
  }
}
