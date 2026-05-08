# Implementation Plan: WhatsApp Clone (Flutter)

## Overview

This plan converts the WhatsApp Clone design into incremental coding tasks for a Flutter mobile application targeting Android and iOS. Each task builds on the previous, wiring components together progressively. The implementation follows a feature-first Clean Architecture (Presentation → Domain → Data) using Riverpod, Firebase, Drift, and the Signal Protocol.

## Tasks

- [x] 1. Set up project structure, dependencies, and core infrastructure
  - Add all required dependencies to `pubspec.yaml`: `flutter_riverpod`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `drift`, `sqlite3_flutter_libs`, `flutter_secure_storage`, `go_router`, `fpdart`, `fast_check`, `flutter_local_notifications`, `connectivity_plus`, `flutter_image_compress`, `ffmpeg_kit_flutter`, `flutter_webrtc`, `libsignal_protocol_dart`, `mocktail`
  - Create the full folder structure under `lib/`: `core/encryption`, `core/network`, `core/storage`, `core/router`, `core/theme`, and all `features/` subdirectories with `data/`, `domain/`, `presentation/` sub-folders
  - Configure Firebase project (google-services.json for Android, GoogleService-Info.plist for iOS) and initialise `Firebase.initializeApp()` in `main.dart`
  - Set up `go_router` with placeholder routes for all major screens
  - Create the app `ThemeData` (WhatsApp-style teal/green palette, dark mode support) in `core/theme/`
  - Define the `Result<T, AppError>` sealed class in `core/` for uniform error handling
  - _Requirements: all_

- [x] 2. Implement local database (Drift) schema and migrations
  - [x] 2.1 Define Drift tables: `MessagesTable`, `ConversationsTable`, `SignalSessionsTable`, `PreKeysTable` as specified in the design
    - Include all columns, nullable fields, and default values exactly as in the design schema
    - _Requirements: 4.1, 4.6, 9.3_
  - [x] 2.2 Generate Drift database class and DAOs for messages, conversations, and Signal sessions
    - Write `MessageDao`, `ConversationDao`, and `SignalDao` with typed query methods
    - _Requirements: 3.1, 4.1, 9.1_
  - [ ]* 2.3 Write unit tests for Drift DAOs using an in-memory SQLite database
    - Test insert, update, query, and delete operations for each DAO
    - _Requirements: 3.1, 4.1_

- [x] 3. Implement core domain entities and validators
  - [x] 3.1 Define all domain entities as immutable Dart classes: `Message`, `Conversation`, `AppContact`, `PresenceInfo`, `Call`, `Session`, `KeyBundle`, `StatusItem`
    - _Requirements: 1.1, 2.1, 4.1, 7.1, 8.1_
  - [x] 3.2 Implement `PhoneNumberValidator` (E.164 regex validation) in `core/`
    - _Requirements: 1.1_
  - [x] 3.3 Implement `DisplayNameValidator` (1–25 characters, rejects whitespace-only strings)
    - _Requirements: 1.7, 12.1_
  - [ ]* 3.4 Write property test for `DisplayNameValidator` — Property 5: Whitespace-only display names are invalid
    - **Property 5: Whitespace-only display names are invalid**
    - **Validates: Requirements 1.7, 12.1**
  - [x] 3.5 Implement `MessageStatusMachine` — enforces the `SENDING → SENT → DELIVERED → READ` state machine, rejecting backward transitions
    - _Requirements: 4.3, 4.4, 4.5_
  - [ ]* 3.6 Write property test for `MessageStatusMachine` — Property 3: Delivery receipt monotonicity
    - **Property 3: Delivery receipt monotonicity**
    - **Validates: Requirements 4.3, 4.4, 4.5**

- [x] 4. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement Encryption_Service (Signal Protocol)
  - [x] 5.1 Implement `SignalProtocolStore` backed by `SignalSessionsTable` and `PreKeysTable` in Drift
    - Persist identity keys, pre-keys, and session state; store the identity private key in `flutter_secure_storage`
    - _Requirements: 9.1, 9.3_
  - [x] 5.2 Implement `KeyManager` — generates identity key pair, signed pre-key, and one-time pre-keys on first registration; uploads the public `KeyBundle` to Firestore `/users/{userId}.publicKeyBundle`
    - _Requirements: 9.3, 9.4_
  - [x] 5.3 Implement `EncryptionService` facade with `initialize()`, `encryptMessage()`, `decryptMessage()`, `getPublicKeyBundle()`, and `verifySecurityCode()` using `libsignal_protocol_dart`
    - _Requirements: 9.1, 9.2, 9.5, 9.6_
  - [ ]* 5.4 Write property test for `EncryptionService` — Property 2: Message encryption round-trip
    - **Property 2: Message encryption round-trip**
    - **Validates: Requirements 9.1, 9.6**
  - [x] 5.5 Implement key-change notification: when a new key bundle is detected for a contact in Firestore, inject a "Security code changed" system message into the local conversation before delivering the next message
    - _Requirements: 9.4_

- [x] 6. Implement Auth_Service (phone registration and OTP)
  - [x] 6.1 Implement `AuthRepository` backed by Firebase Auth `verifyPhoneNumber()`; store the Firebase ID token in `flutter_secure_storage` on success
    - _Requirements: 1.1, 1.2, 1.4, 1.6_
  - [x] 6.2 Implement `PhoneVerificationUseCase` orchestrating: validate E.164 → send OTP → verify OTP → create session → persist token
    - _Requirements: 1.1, 1.2, 1.4_
  - [x] 6.3 Implement OTP lockout logic in `OtpLockoutTimer`: after 3 consecutive failures, lock for 1 hour and expose a countdown stream; enforce via a Cloud Function rate-limiter
    - _Requirements: 1.5_
  - [ ]* 6.4 Write property test for `OtpLockoutTimer` — Property 1: OTP lockout after repeated failures
    - **Property 1: OTP lockout after repeated failures**
    - **Validates: Requirements 1.5**
  - [x] 6.5 Implement `SessionManager` — persists, retrieves, and invalidates the session token; exposes `sessionStream` for auth-state changes
    - _Requirements: 1.6_
  - [x] 6.6 Build `PhoneEntryScreen`, `OtpVerificationScreen`, and `ProfileSetupScreen` (display name + optional photo) with Riverpod providers wired to the use cases
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.7_
  - [x] 6.7 Implement voice-call OTP fallback button (shown after 60 s SMS timeout) that triggers a Cloud Function to initiate a voice call
    - _Requirements: 1.3_

- [x] 7. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement Contact_Service (contact discovery and blocking)
  - [x] 8.1 Implement `ContactHasher` — hashes device phone numbers with SHA-256 before any network call
    - _Requirements: 2.1_
  - [ ]* 8.2 Write property test for `ContactHasher` — Property 6: Contact hash privacy
    - **Property 6: Contact hash privacy**
    - **Validates: Requirements 2.1**
  - [x] 8.3 Implement `ContactSyncUseCase` — reads device address book (with permission), hashes numbers, uploads to a Cloud Function, receives back the subset of registered users, and stores them in Firestore and locally
    - _Requirements: 2.1, 2.2_
  - [x] 8.4 Implement `BlockListRepository` — writes block/unblock to Firestore; Firestore Security Rules enforce that blocked users cannot write messages to the blocking user's conversation
    - _Requirements: 2.5_
  - [ ]* 8.5 Write property test for blocked user message rejection — Property 7: Blocked user message rejection
    - **Property 7: Blocked user message rejection**
    - **Validates: Requirements 2.5**
  - [x] 8.6 Implement address-book permission request flow; if denied, show a manual phone-number entry screen to start a conversation
    - _Requirements: 2.3, 2.4_
  - [x] 8.7 Build `ContactListScreen` displaying only registered contacts; wire to `ContactSyncUseCase` via a Riverpod provider that re-syncs on address-book change events
    - _Requirements: 2.2, 2.3_

- [x] 9. Implement Chats List (Requirement 3)
  - [x] 9.1 Implement `ConversationRepository` with `watchConversations()` (Drift reactive query sorted by `lastMessageAt` desc), `archiveConversation()`, `deleteConversation()`, and `search()` backed by Drift FTS5
    - _Requirements: 3.1, 3.2, 3.4, 3.5, 3.6_
  - [x] 9.2 Implement full-text search over messages using Drift FTS5 virtual table; ensure query returns within 500 ms for up to 10,000 messages
    - _Requirements: 3.6_
  - [x] 9.3 Build `ChatListScreen` with a `ListView` of conversation tiles sorted by `lastMessageAt`, unread badge counts, archive swipe action, and delete with confirmation dialog
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  - [x] 9.4 Build `SearchScreen` wired to the FTS5 search use case, displaying matching conversations and messages
    - _Requirements: 3.6_
  - [ ]* 9.5 Write widget tests for `ChatListScreen`: verify sort order, unread badge rendering, and archive/delete actions
    - _Requirements: 3.1, 3.3, 3.4_

- [x] 10. Implement one-to-one Chat_Service and messaging UI (Requirement 4)
  - [x] 10.1 Implement `MessageRepository` with `sendMessage()` (local INSERT with `status=sending` → encrypt → Firestore write → update to `sent`), `watchMessages()` (Drift reactive stream), `deleteMessageForMe()`, and `deleteMessageForEveryone()`
    - _Requirements: 4.1, 4.3, 4.6, 4.7, 4.9_
  - [x] 10.2 Implement delivery receipt listeners: Firestore snapshot listener on each message document updates `deliveredAt` and `readAt` in Drift; `markAsRead()` writes `readAt` to Firestore when the conversation is opened
    - _Requirements: 4.3, 4.4, 4.5_
  - [x] 10.3 Implement offline message queue: messages with `status=failed` are retried automatically when `connectivity_plus` reports reconnection
    - _Requirements: 4.6_
  - [x] 10.4 Implement message quoting: `SendMessageParams` includes an optional `quotedMessageId`; the `MessageBubble` widget renders the quoted message inline
    - _Requirements: 4.8_
  - [x] 10.5 Implement delete-for-everyone: within 60 minutes of `sentAt`, write `deletedForEveryone=true` to Firestore; all listeners replace content with "This message was deleted"
    - _Requirements: 4.9_
  - [ ]* 10.6 Write property test for delete-for-everyone content replacement — Property 12
    - **Property 12: Delete-for-everyone within window**
    - **Validates: Requirements 4.9**
  - [x] 10.7 Build `ChatScreen` with a `ListView` of `MessageBubble` widgets, a text input bar with emoji picker, send button, and long-press context menu (reply, forward, copy, star, delete for me, delete for everyone)
    - _Requirements: 4.1, 4.2, 4.7, 4.8_
  - [ ]* 10.8 Write widget tests for `MessageBubble`: verify correct delivery receipt icon (✓, ✓✓, blue ✓✓) per `DeliveryStatus`
    - _Requirements: 4.3, 4.4, 4.5_

- [x] 11. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Implement Group Chat (Requirement 5)
  - [x] 12.1 Implement `GroupRepository` with `createGroup()` (2–1,024 participants, creator as admin), `addParticipant()`, `removeParticipant()`, `updateGroupMetadata()`, `restrictMessaging()`, and `leaveGroup()`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  - [x] 12.2 Implement system message broadcasting: admin add/remove, name/icon change, and member leave events write a `type=system` message to Firestore within 2 seconds
    - _Requirements: 5.3, 5.4, 5.6_
  - [x] 12.3 Implement per-message group delivery receipts: aggregate `deliveredAt` and `readAt` counts across all participants; expose via `DeliveryReceiptRepository`
    - _Requirements: 5.7_
  - [x] 12.4 Implement participant list pagination: load 50 participants at a time when group size exceeds 256
    - _Requirements: 5.8_
  - [x] 12.5 Build `CreateGroupScreen`, `GroupInfoScreen` (with paginated participant list), and extend `ChatScreen` to handle group conversations and admin-only messaging restriction
    - _Requirements: 5.1, 5.2, 5.4, 5.5, 5.8_
  - [ ]* 12.6 Write property test for group participant list consistency — Property 8
    - **Property 8: Group participant list consistency**
    - **Validates: Requirements 5.3**

- [x] 13. Implement Media_Service (Requirement 6)
  - [x] 13.1 Implement `MediaCompressor` — compress images > 5 MB to JPEG quality 85, max 1920×1080, preserving aspect ratio using `flutter_image_compress`; record voice notes as AAC at 32 kbps up to 2 minutes
    - _Requirements: 6.1, 6.9_
  - [ ]* 13.2 Write property test for `MediaCompressor` — Property 9: Media compression size invariant
    - **Property 9: Media compression size invariant**
    - **Validates: Requirements 6.1**
  - [x] 13.3 Implement `MediaRepository` with `uploadMedia()` (resumable Firebase Storage upload with progress stream), `downloadMedia()` (lazy download on tap), and `retryFailedUpload()` with exponential back-off (1 s, 2 s, 4 s, max 3 retries)
    - _Requirements: 6.2, 6.3, 6.4, 6.8_
  - [ ]* 13.4 Write property test for upload retry exhaustion — Property 10
    - **Property 10: Upload retry exhaustion**
    - **Validates: Requirements 6.8**
  - [x] 13.5 Implement `MediaCache` — LRU disk cache in the app's cache directory; serve cached files without re-downloading
    - _Requirements: 6.6_
  - [x] 13.6 Implement auto-download policy: auto-download images on Wi-Fi; require manual tap for video/documents on mobile data; read policy from user settings
    - _Requirements: 6.7_
  - [x] 13.7 Implement location message: embed static map preview (using a maps tile URL) and GPS coordinates in the message payload
    - _Requirements: 6.5_
  - [x] 13.8 Build media picker integration in `ChatScreen`: image/video from gallery, document picker, voice note recorder (with waveform visualisation and 2-minute cap), and location picker
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.9_
  - [x] 13.9 Build `MediaViewerScreen` — full-screen image/video viewer with download progress indicator; show thumbnail immediately while full file loads
    - _Requirements: 6.6_

- [x] 14. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Implement Status_Service (Requirement 7)
  - [~] 15.1 Implement `StatusRepository` with `postStatus()` (writes to `/status/{userId}/items/{statusId}` with `expiresAt = postedAt + 24h`), `deleteStatus()`, `recordView()`, and `watchStatuses()` (filters out expired items client-side)
    - _Requirements: 7.1, 7.2, 7.3, 7.6_
  - [~] 15.2 Implement `StatusExpiryChecker` — a utility that, given a `postedAt` timestamp and a query time, returns whether the status is still visible
    - _Requirements: 7.1, 7.5_
  - [ ]* 15.3 Write property test for `StatusExpiryChecker` — Property 4: Status expiry
    - **Property 4: Status expiry**
    - **Validates: Requirements 7.1, 7.5**
  - [~] 15.4 Implement status privacy list: `postStatus()` accepts an optional `privacyList`; Firestore Security Rules restrict reads to contacts on the list
    - _Requirements: 7.7_
  - [~] 15.5 Implement Cloud Function `onStatusExpiry` that deletes expired status documents from Firestore after 24 hours and removes them from all viewer feeds within 30 seconds of deletion
    - _Requirements: 7.5, 7.6_
  - [ ]* 15.6 Write property test for status viewer list completeness — Property 13
    - **Property 13: Status viewer list completeness**
    - **Validates: Requirements 7.3, 7.4**
  - [~] 15.7 Build `StatusListScreen` (tab showing contacts' active statuses), `StatusViewerScreen` (full-screen with progress bar, viewer list), and `StatusCreatorScreen` (text with background color, image, or video up to 30 s)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 16. Implement Presence_Service (Requirement 10)
  - [~] 16.1 Implement `PresenceRepository` with `setOnline()`, `setOffline()`, `watchPresence()`, and `updatePrivacySetting()`; use Firestore `onDisconnect()` to set `lastSeen` automatically on disconnect
    - _Requirements: 10.1, 10.2, 10.3_
  - [~] 16.2 Implement `PresenceHeartbeatService` — writes `isOnline: true` when the app is foregrounded; registers `onDisconnect` handler on app start
    - _Requirements: 10.1, 10.2_
  - [~] 16.3 Implement `PresencePrivacyFilter` — server-side Firestore Security Rules enforce "Nobody" and "My Contacts" privacy settings; client reads the setting and hides last-seen accordingly
    - _Requirements: 10.4, 10.5, 10.6_
  - [ ]* 16.4 Write property test for `PresencePrivacyFilter` — Property 11: Privacy setting enforcement for last-seen
    - **Property 11: Privacy setting enforcement for last-seen**
    - **Validates: Requirements 10.4**
  - [~] 16.5 Display "online" or "last seen [time]" in the `ChatScreen` app bar for one-to-one conversations, wired to `watchPresence()`
    - _Requirements: 10.3_

- [ ] 17. Implement Notification_Service (Requirement 11)
  - [~] 17.1 Implement `FcmHandler` — processes FCM payloads in foreground (show in-app banner via `flutter_local_notifications`), background (system notification), and terminated states; register background message handler in `main.dart`
    - _Requirements: 11.1, 11.2_
  - [~] 17.2 Implement call notifications: on Android, launch a foreground service with `CallStyle` notification; on iOS, invoke CallKit via APNs VoIP push
    - _Requirements: 11.2_
  - [~] 17.3 Implement notification grouping by conversation ID using `flutter_local_notifications` notification channels and grouping API
    - _Requirements: 11.3_
  - [~] 17.4 Implement `dismissNotification()` — when `markAsRead()` is called, cancel the corresponding local notification within 3 seconds
    - _Requirements: 11.4_
  - [~] 17.5 Implement mute conversation: `muteConversation()` stores `mutedUntil` in `ConversationsTable`; `FcmHandler` checks the mute state before showing a notification
    - _Requirements: 11.5_
  - [~] 17.6 Implement Do Not Disturb mode: a global setting stored in `flutter_secure_storage`; `FcmHandler` suppresses all notifications except calls from starred contacts when DND is active
    - _Requirements: 11.6_

- [~] 18. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 19. Implement Call_Service — voice and video calls (Requirement 8)
  - [~] 19.1 Implement `CallSignalingService` — writes offer SDP and ICE candidates to `/calls/{callId}` in Firestore; listens for answer SDP and remote ICE candidates
    - _Requirements: 8.1, 8.2_
  - [~] 19.2 Implement `WebRtcCallManager` wrapping `flutter_webrtc`: create peer connection, add local media tracks, handle ICE negotiation, and fall back to TURN relay on ICE failure
    - _Requirements: 8.1, 8.2, 8.9_
  - [~] 19.3 Implement `CallRepository` with `initiateCall()`, `answerCall()`, `endCall()`, `watchCallState()`, `toggleMute()`, `toggleCamera()`, and `switchCamera()`
    - _Requirements: 8.1, 8.2, 8.5, 8.7_
  - [~] 19.4 Implement call timeout: if the callee does not answer within 30 seconds, end the call attempt and write a missed-call system message to the conversation
    - _Requirements: 8.5_
  - [~] 19.5 Implement second-call notification: when a user is on an active call and a new incoming call arrives, show a non-interrupting notification banner
    - _Requirements: 8.6_
  - [~] 19.6 Implement call-summary message: on call end, write a system message to the conversation with duration and call type
    - _Requirements: 8.8_
  - [~] 19.7 Implement poor-connection indicator: monitor WebRTC stats (packet loss > 10% or RTT > 400 ms) and surface a "Poor connection" banner in the call UI
    - _Requirements: 8.9_
  - [~] 19.8 Implement group calls: mesh topology for ≤ 8 video streams; SFU via TURN for voice-only calls up to 32 participants
    - _Requirements: 8.3, 8.4_
  - [~] 19.9 Implement SRTP encryption for call media streams using keys derived from the Signal Protocol session
    - _Requirements: 9.2_
  - [~] 19.10 Build `IncomingCallScreen`, `ActiveCallScreen` (with mute, camera toggle, switch camera, end-call controls), and `GroupCallScreen`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.7_
  - [ ]* 19.11 Write widget tests for `ActiveCallScreen`: verify mute/camera controls render correctly and poor-connection indicator appears on simulated poor stats
    - _Requirements: 8.7, 8.9_

- [ ] 20. Implement Profile and Privacy Settings (Requirement 12)
  - [~] 20.1 Implement `ProfileRepository` — reads and writes display name, profile photo, and status bio to Firestore `/users/{userId}`; propagates photo changes to all contacts' views within 30 seconds via Firestore listeners
    - _Requirements: 12.1, 12.3_
  - [~] 20.2 Implement privacy settings: per-field visibility controls (profile photo, status bio, last-seen) with options "Everyone", "My Contacts", "Nobody"; enforce via Firestore Security Rules
    - _Requirements: 12.2_
  - [~] 20.3 Implement two-step verification: store the 6-digit PIN in `flutter_secure_storage`; require PIN in addition to OTP during re-registration by checking it in `PhoneVerificationUseCase`
    - _Requirements: 12.4, 12.5_
  - [~] 20.4 Implement chat history export: query all messages for a conversation from Drift, format as plain text (with optional media file paths), and write to a shareable file using the `share_plus` package
    - _Requirements: 12.6_
  - [~] 20.5 Implement account deletion: call a Cloud Function that schedules permanent removal of all messages, media, and profile data from Firestore and Firebase Storage within 30 days; sign out locally and clear Drift database
    - _Requirements: 12.7_
  - [~] 20.6 Build `ProfileScreen`, `PrivacySettingsScreen`, `TwoStepVerificationScreen`, and `AccountSettingsScreen` wired to the above repositories via Riverpod providers
    - _Requirements: 12.1, 12.2, 12.4, 12.5, 12.6, 12.7_

- [ ] 21. Implement security code verification screen (Requirement 9)
  - [~] 21.1 Build `SecurityCodeScreen` — displays the 60-digit numeric security code for the current E2EE session with a contact; implements QR code scanning via `mobile_scanner` to compare codes
    - _Requirements: 9.5_

- [ ] 22. Wire navigation and app shell
  - [~] 22.1 Configure `go_router` with all named routes: splash/auth guard, `PhoneEntryScreen`, `OtpVerificationScreen`, `ProfileSetupScreen`, `ChatListScreen` (with tabs: Chats, Status, Calls), `ChatScreen`, `GroupInfoScreen`, `ContactListScreen`, `StatusListScreen`, `StatusViewerScreen`, `StatusCreatorScreen`, `IncomingCallScreen`, `ActiveCallScreen`, `ProfileScreen`, `PrivacySettingsScreen`, `SecurityCodeScreen`
    - _Requirements: all_
  - [~] 22.2 Implement auth guard in `go_router`: redirect unauthenticated users to `PhoneEntryScreen`; redirect authenticated users away from auth screens
    - _Requirements: 1.6_
  - [~] 22.3 Build the main app shell with a bottom navigation bar (or tab bar) for Chats, Status, and Calls tabs
    - _Requirements: 3.1, 7.1, 8.1_

- [~] 23. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 24. Integration tests against Firebase Emulator Suite
  - [ ]* 24.1 Write integration test: full OTP registration flow — register a new user, verify OTP, set display name, assert session persisted
    - _Requirements: 1.1, 1.2, 1.4, 1.6, 1.7_
  - [ ]* 24.2 Write integration test: message send → delivery receipt cycle — two users exchange a message, assert `SENT → DELIVERED → READ` transitions
    - _Requirements: 4.1, 4.3, 4.4, 4.5_
  - [ ]* 24.3 Write integration test: contact sync with hashed numbers — assert raw numbers never appear in Firestore, assert registered contacts returned
    - _Requirements: 2.1_
  - [ ]* 24.4 Write integration test: media upload → download round-trip — upload an image, assert compression, assert download returns identical content
    - _Requirements: 6.1, 6.6_
  - [ ]* 24.5 Write integration test: group creation and participant management — create group, add/remove participant, assert system messages broadcast
    - _Requirements: 5.1, 5.3, 5.6_
  - [ ]* 24.6 Write integration test: status post → expiry — post a status, assert visible to contact, simulate 24 h elapsed, assert no longer visible
    - _Requirements: 7.1, 7.5_

- [~] 25. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP build
- Each task references specific requirements for full traceability
- Property tests use the `fast_check` library with a minimum of 100 iterations per property
- Integration tests require the Firebase Emulator Suite (`firebase emulators:start`) running locally
- Platform-specific call notification code (CallKit on iOS, ConnectionService on Android) is handled in tasks 17.2 and 19.10
- The Signal Protocol private key must never leave `flutter_secure_storage` — this is enforced in tasks 5.1 and 5.2
