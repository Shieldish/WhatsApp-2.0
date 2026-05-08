import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/features/status/data/status_repository_impl.dart';
import 'package:whatsapp2_0/features/status/domain/entities/status_item.dart';
import 'package:whatsapp2_0/features/status/domain/status_expiry_checker.dart';
import 'package:whatsapp2_0/features/status/domain/status_repository.dart';

/// Provides the [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides the [StatusExpiryChecker] domain utility.
final statusExpiryCheckerProvider = Provider<StatusExpiryChecker>((ref) {
  return StatusExpiryChecker();
});

/// Provides the [StatusRepository] implementation backed by Firestore.
final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final expiryChecker = ref.watch(statusExpiryCheckerProvider);
  return StatusRepositoryImpl(
    firestore: firestore,
    expiryChecker: expiryChecker,
  );
});

/// State class for the status list screen.
class StatusListState {
  const StatusListState({
    this.myStatuses = const [],
    this.contactStatuses = const [],
    this.isLoading = true,
    this.error,
  });

  final List<StatusItem> myStatuses;
  final List<StatusItem> contactStatuses;
  final bool isLoading;
  final String? error;

  StatusListState copyWith({
    List<StatusItem>? myStatuses,
    List<StatusItem>? contactStatuses,
    bool? isLoading,
    String? error,
  }) {
    return StatusListState(
      myStatuses: myStatuses ?? this.myStatuses,
      contactStatuses: contactStatuses ?? this.contactStatuses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider that streams the current user's own statuses and contact statuses.
final statusListProvider = StreamProvider.family<StatusListState, String>((
  ref,
  currentUserId,
) async* {
  final repository = ref.watch(statusRepositoryProvider);

  yield* repository.watchStatuses(currentUserId).map(
    (myStatuses) => StatusListState(
      myStatuses: myStatuses,
      isLoading: false,
    ),
  );
});

/// Provider that streams contact statuses for the status list tab.
final contactStatusesProvider = StreamProvider.family<List<StatusItem>, String>(
  (ref, currentUserId) {
    final repository = ref.watch(statusRepositoryProvider);
    return repository.watchContactStatuses(currentUserId);
  },
);

/// Provider for posting a new status.
final postStatusProvider = FutureProvider.family<StatusItem, PostStatusParams>((
  ref,
  params,
) async {
  final repository = ref.watch(statusRepositoryProvider);
  final result = await repository.postStatus(
    userId: params.userId,
    mediaUrl: params.mediaUrl,
    text: params.text,
    backgroundColor: params.backgroundColor,
    privacyList: params.privacyList,
  );
  return result.fold(
    onOk: (item) => item,
    onErr: (error) => throw error,
  );
});

/// Parameters for posting a status.
class PostStatusParams {
  const PostStatusParams({
    required this.userId,
    this.mediaUrl,
    this.text,
    this.backgroundColor,
    this.privacyList,
  });

  final String userId;
  final String? mediaUrl;
  final String? text;
  final String? backgroundColor;
  final List<String>? privacyList;
}

/// Provider for recording a status view.
final recordStatusViewProvider = FutureProvider.family<void, RecordViewParams>((
  ref,
  params,
) async {
  final repository = ref.watch(statusRepositoryProvider);
  final result = await repository.recordView(
    statusId: params.statusId,
    userId: params.userId,
    viewerId: params.viewerId,
  );
  result.fold(
    onOk: (_) {},
    onErr: (error) => throw error,
  );
});

/// Parameters for recording a status view.
class RecordViewParams {
  const RecordViewParams({
    required this.statusId,
    required this.userId,
    required this.viewerId,
  });

  final String statusId;
  final String userId;
  final String viewerId;
}