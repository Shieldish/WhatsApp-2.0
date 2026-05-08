import 'package:cloud_functions/cloud_functions.dart'
    hide Result; // avoid conflict with core/result.dart
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/contacts/domain/contact_hasher.dart';
import 'package:whatsapp2_0/features/contacts/domain/entities/app_contact.dart';

/// Orchestrates the contact discovery flow:
///
/// 1. Requests address-book permission.
/// 2. If denied, returns [Err(PermissionError)].
/// 3. Reads device contacts via [flutter_contacts].
/// 4. Hashes all phone numbers with [ContactHasher.hashAll].
/// 5. Calls the Firebase Cloud Function `syncContacts` with the hashed numbers.
/// 6. Parses the response as a list of [AppContact] objects.
/// 7. Returns [Ok(contacts)].
///
/// Requirements: 2.1, 2.2
class ContactSyncUseCase {
  const ContactSyncUseCase({FirebaseFunctions? functions})
    : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _ff => _functions ?? FirebaseFunctions.instance;

  /// Syncs device contacts with the server and returns the subset of
  /// registered users.
  ///
  /// Raw phone numbers are never sent to the server — only SHA-256 hashes.
  Future<Result<List<AppContact>, AppError>> sync() async {
    // 1. Request contacts permission.
    final status = await Permission.contacts.request();

    if (!status.isGranted) {
      return Err(
        PermissionError(
          message: status.isPermanentlyDenied
              ? 'Contacts permission permanently denied. '
                    'Please enable it in Settings.'
              : 'Contacts permission denied.',
        ),
      );
    }

    try {
      // 2. Read device contacts (with phone numbers).
      final deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      // 3. Collect all E.164 phone numbers from device contacts.
      final rawNumbers = <String>[];
      for (final contact in deviceContacts) {
        for (final phone in contact.phones) {
          final normalized = _normalizePhone(phone.number);
          if (normalized != null) {
            rawNumbers.add(normalized);
          }
        }
      }

      // 4. Hash all phone numbers — raw numbers never leave the device.
      final hashedNumbers = ContactHasher.hashAll(rawNumbers);

      // 5. Call the Cloud Function with hashed numbers only.
      final callable = _ff.httpsCallable('syncContacts');
      final response = await callable.call<Map<String, dynamic>>({
        'hashedNumbers': hashedNumbers,
      });

      // 6. Parse the response.
      final data = response.data;
      final contactsList = data['contacts'] as List<dynamic>? ?? [];

      final appContacts = contactsList
          .whereType<Map<String, dynamic>>()
          .map(_parseAppContact)
          .toList();

      // 7. Return the registered contacts.
      return Ok(appContacts);
    } on FirebaseFunctionsException catch (e) {
      return Err(
        NetworkError(
          message: e.message ?? 'Cloud Function call failed.',
          statusCode: null,
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: 'Contact sync failed.', cause: e));
    }
  }

  /// Attempts to normalize a phone number string to E.164 format.
  ///
  /// Returns `null` if the number cannot be normalized (e.g. too short,
  /// contains only letters, etc.).
  String? _normalizePhone(String raw) {
    // Strip all non-digit characters except the leading '+'.
    final stripped = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (stripped.isEmpty) return null;

    // If it already starts with '+', keep as-is if it looks valid.
    if (stripped.startsWith('+') && stripped.length >= 8) {
      return stripped;
    }

    // If it starts with a digit and is long enough, assume it needs a '+'.
    if (!stripped.startsWith('+') && stripped.length >= 7) {
      return '+$stripped';
    }

    return null;
  }

  /// Parses a single contact map from the Cloud Function response into an
  /// [AppContact].
  AppContact _parseAppContact(Map<String, dynamic> map) {
    return AppContact(
      userId: map['userId'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      isBlocked: map['isBlocked'] as bool? ?? false,
    );
  }
}
