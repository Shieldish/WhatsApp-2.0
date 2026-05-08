import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/contacts/data/block_list_repository_impl.dart';
import 'package:whatsapp2_0/features/contacts/domain/block_list_repository.dart';
import 'package:whatsapp2_0/features/contacts/domain/entities/app_contact.dart';
import 'package:whatsapp2_0/features/contacts/domain/use_cases/contact_sync_use_case.dart';

/// Provides the [ContactSyncUseCase] instance.
///
/// Requirements: 2.1, 2.2
final contactSyncUseCaseProvider = Provider<ContactSyncUseCase>((ref) {
  return const ContactSyncUseCase();
});

/// Provides the [BlockListRepository] implementation backed by Firestore.
///
/// Requirements: 2.5
final blockListRepositoryProvider = Provider<BlockListRepository>((ref) {
  return BlockListRepositoryImpl();
});

/// Fetches the list of registered contacts by running [ContactSyncUseCase.sync].
///
/// Returns an empty list on permission denial or error (the UI handles the
/// error state separately via [contactSyncErrorProvider]).
///
/// Requirements: 2.2, 2.3
final contactsProvider = FutureProvider<List<AppContact>>((ref) async {
  final useCase = ref.watch(contactSyncUseCaseProvider);
  final result = await useCase.sync();
  return switch (result) {
    Ok(:final value) => value,
    Err() => const <AppContact>[],
  };
});

/// Exposes the last sync error message, if any.
///
/// Returns `null` when the last sync succeeded or has not been run yet.
final contactSyncErrorProvider = FutureProvider<String?>((ref) async {
  final useCase = ref.watch(contactSyncUseCaseProvider);
  final result = await useCase.sync();
  return switch (result) {
    Ok() => null,
    Err(:final error) => error.toString(),
  };
});
