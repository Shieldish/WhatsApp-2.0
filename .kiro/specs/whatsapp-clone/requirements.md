# Requirements Document

## Introduction

This document defines the requirements for a WhatsApp clone built as a Flutter mobile application targeting Android and iOS. The app replicates the core WhatsApp experience: phone-number-based authentication, real-time one-to-one and group messaging, media sharing, status/stories, voice and video calls, end-to-end encryption, presence indicators, and message delivery receipts.

---

## Glossary

- **App**: The Flutter mobile application being built.
- **Auth_Service**: The component responsible for phone-number verification and session management.
- **Chat_Service**: The component responsible for sending, receiving, and storing messages.
- **Contact_Service**: The component responsible for discovering and managing user contacts.
- **Media_Service**: The component responsible for uploading, downloading, and caching media files.
- **Call_Service**: The component responsible for initiating and managing voice and video calls.
- **Status_Service**: The component responsible for creating, distributing, and expiring status updates.
- **Encryption_Service**: The component responsible for end-to-end encryption key management and message encryption/decryption.
- **Presence_Service**: The component responsible for tracking and broadcasting online/offline/last-seen state.
- **Notification_Service**: The component responsible for delivering push notifications.
- **User**: A registered person identified by a verified phone number.
- **Contact**: A User whose phone number exists in the local device address book.
- **Conversation**: A one-to-one or group chat thread.
- **Group**: A Conversation with two or more participants managed by one or more admins.
- **Message**: A unit of communication within a Conversation (text, image, video, audio, document, location, or contact card).
- **Status**: A time-limited media or text post visible to a User's Contacts for 24 hours.
- **Delivery_Receipt**: A per-message indicator showing sent (✓), delivered (✓✓), or read (blue ✓✓) state.
- **E2EE**: End-to-end encryption — only the sender and recipient(s) can read message content.
- **OTP**: One-time password sent via SMS or voice call for phone verification.
- **Session**: An authenticated App instance tied to a verified phone number.

---

## Requirements

### Requirement 1: Phone Number Registration and Verification

**User Story:** As a new user, I want to register using my phone number, so that I can access the app without creating a username or password.

#### Acceptance Criteria

1. THE Auth_Service SHALL accept a phone number in E.164 format as the sole registration identifier.
2. WHEN a User submits a valid phone number, THE Auth_Service SHALL send an OTP to that number within 60 seconds via SMS.
3. WHEN SMS delivery fails after 60 seconds, THE Auth_Service SHALL offer a voice-call OTP fallback.
4. WHEN a User submits a correct 6-digit OTP within 10 minutes of issuance, THE Auth_Service SHALL create an authenticated Session.
5. IF a User submits an incorrect OTP three consecutive times, THEN THE Auth_Service SHALL lock verification attempts for 1 hour and display a countdown timer.
6. WHEN a Session is created, THE Auth_Service SHALL persist the Session token securely in the device keychain so the User remains logged in across app restarts.
7. WHEN a User registers for the first time, THE Auth_Service SHALL prompt the User to set a display name (1–25 characters) and an optional profile photo before proceeding to the main screen.

---

### Requirement 2: Contact Discovery

**User Story:** As a user, I want the app to automatically find which of my phone contacts also use the app, so that I can start chatting without manually adding friends.

#### Acceptance Criteria

1. WHEN the App is granted address-book permission, THE Contact_Service SHALL upload hashed phone numbers from the device address book to the server to identify registered Users.
2. THE Contact_Service SHALL refresh the contact list whenever the device address book changes.
3. THE Contact_Service SHALL display only Contacts who have registered accounts in the in-app contact list.
4. IF address-book permission is denied, THEN THE Contact_Service SHALL allow the User to manually enter a phone number to start a Conversation.
5. THE Contact_Service SHALL allow a User to block another User, after which the blocked User SHALL NOT appear in the contact list and SHALL NOT be able to send Messages to the blocking User.

---

### Requirement 3: Chats List

**User Story:** As a user, I want to see all my conversations in a single list, so that I can quickly find and open any chat.

#### Acceptance Criteria

1. THE App SHALL display all Conversations sorted by the timestamp of the most recent Message in descending order.
2. WHEN a new Message arrives in a Conversation, THE App SHALL move that Conversation to the top of the list and update its preview text and timestamp.
3. THE App SHALL display an unread-message badge count on each Conversation that contains unread Messages.
4. WHEN a User archives a Conversation, THE App SHALL move it to a separate "Archived" section and remove it from the main list.
5. WHEN a User deletes a Conversation, THE App SHALL remove all local Messages for that Conversation after displaying a confirmation prompt.
6. THE App SHALL support searching Conversations and Messages by keyword, returning results within 500 ms for indexes up to 10,000 Messages.

---

### Requirement 4: One-to-One Messaging

**User Story:** As a user, I want to send and receive text and emoji messages in real time, so that I can have private conversations with my contacts.

#### Acceptance Criteria

1. WHEN a User sends a text Message, THE Chat_Service SHALL deliver it to the recipient within 2 seconds under normal network conditions.
2. THE Chat_Service SHALL support Unicode text including emoji, up to 65,536 characters per Message.
3. WHEN a Message is sent, THE Chat_Service SHALL display a single grey tick (✓) Delivery_Receipt.
4. WHEN the Message reaches the recipient's device, THE Chat_Service SHALL update the Delivery_Receipt to double grey ticks (✓✓).
5. WHEN the recipient opens the Conversation and views the Message, THE Chat_Service SHALL update the Delivery_Receipt to double blue ticks (✓✓).
6. WHEN a User is offline, THE Chat_Service SHALL queue outgoing Messages and deliver them automatically when connectivity is restored.
7. WHEN a User long-presses a Message, THE App SHALL present options to reply, forward, copy, star, delete for me, or delete for everyone (within 60 minutes of sending).
8. THE Chat_Service SHALL support message quoting, allowing a User to reply to a specific Message with the quoted Message displayed inline.
9. WHEN a User deletes a Message for everyone within 60 minutes of sending, THE Chat_Service SHALL replace the Message content with "This message was deleted" for all participants.

---

### Requirement 5: Group Chats

**User Story:** As a user, I want to create and participate in group chats, so that I can communicate with multiple people at once.

#### Acceptance Criteria

1. WHEN a User creates a Group, THE Chat_Service SHALL allow the User to add between 2 and 1,024 participants.
2. THE Chat_Service SHALL designate the Group creator as the initial admin.
3. WHEN an admin adds or removes a participant, THE Chat_Service SHALL broadcast a system Message to all Group members within 2 seconds.
4. WHEN a Group admin changes the Group name or icon, THE Chat_Service SHALL update the Group metadata for all participants within 2 seconds.
5. THE Chat_Service SHALL allow admins to restrict messaging so that only admins can send Messages to the Group.
6. WHEN a User leaves a Group, THE Chat_Service SHALL record a system Message visible to remaining members and remove the User from the participant list.
7. THE Chat_Service SHALL display Delivery_Receipts per Group Message showing how many participants have received and read the Message.
8. WHEN a Group has more than 256 participants, THE Chat_Service SHALL paginate the participant list in increments of 50.

---

### Requirement 6: Media Sharing

**User Story:** As a user, I want to send images, videos, audio clips, documents, and location pins in chats, so that I can share rich content with my contacts.

#### Acceptance Criteria

1. WHEN a User selects an image to send, THE Media_Service SHALL compress images larger than 5 MB to under 5 MB before upload while preserving aspect ratio.
2. THE Media_Service SHALL support sending video files up to 100 MB in MP4 format.
3. THE Media_Service SHALL support sending audio clips up to 16 MB in AAC or MP3 format.
4. THE Media_Service SHALL support sending documents up to 100 MB in PDF, DOCX, XLSX, PPTX, ZIP, and APK formats.
5. WHEN a User sends a location, THE Media_Service SHALL embed a static map preview and the GPS coordinates in the Message.
6. WHEN a User receives a media Message, THE Media_Service SHALL display a thumbnail immediately and download the full file only when the User taps it.
7. THE Media_Service SHALL auto-download images on Wi-Fi and require manual download for video and documents on mobile data, unless the User changes the auto-download settings.
8. WHEN a media upload or download fails, THE Media_Service SHALL retry up to 3 times with exponential back-off before displaying an error to the User.
9. THE Media_Service SHALL allow a User to record and send a voice note up to 2 minutes in length directly within the chat input.

---

### Requirement 7: Status / Stories

**User Story:** As a user, I want to post photo, video, or text status updates that disappear after 24 hours, so that I can share moments with my contacts.

#### Acceptance Criteria

1. WHEN a User posts a Status, THE Status_Service SHALL make it visible to all of the User's Contacts for exactly 24 hours from the time of posting.
2. THE Status_Service SHALL support text statuses (up to 700 characters with a background color), image statuses, and video statuses up to 30 seconds.
3. WHEN a Contact views a User's Status, THE Status_Service SHALL record the viewer's identity and timestamp.
4. THE Status_Service SHALL allow the User to see a list of Contacts who have viewed each Status item.
5. WHEN 24 hours have elapsed since a Status was posted, THE Status_Service SHALL remove it from all viewers' feeds and from the User's own status history.
6. THE Status_Service SHALL allow a User to delete a Status before the 24-hour expiry, after which THE Status_Service SHALL remove it from all viewers' feeds within 30 seconds.
7. WHERE a User has configured a custom privacy list for Status, THE Status_Service SHALL show the Status only to Contacts on that list.

---

### Requirement 8: Voice and Video Calls

**User Story:** As a user, I want to make one-to-one and group voice and video calls, so that I can have real-time audio/video conversations.

#### Acceptance Criteria

1. WHEN a User initiates a voice call, THE Call_Service SHALL establish an audio connection with the recipient within 5 seconds under normal network conditions.
2. WHEN a User initiates a video call, THE Call_Service SHALL establish a video connection with the recipient within 5 seconds under normal network conditions.
3. THE Call_Service SHALL support group voice calls with up to 32 participants.
4. THE Call_Service SHALL support group video calls with up to 8 simultaneous video streams.
5. WHEN a call recipient does not answer within 30 seconds, THE Call_Service SHALL end the call attempt and log a missed-call Message in the Conversation.
6. WHEN a User is on a call and receives a second incoming call, THE Call_Service SHALL notify the User of the second call without interrupting the active call.
7. THE Call_Service SHALL allow a User to mute the microphone, disable the camera, and switch between front and rear cameras during a call.
8. WHEN a call ends, THE Call_Service SHALL log a call-summary Message in the Conversation showing duration and call type.
9. IF network quality drops below a threshold that prevents intelligible audio, THEN THE Call_Service SHALL notify the User with a "Poor connection" indicator.

---

### Requirement 9: End-to-End Encryption

**User Story:** As a user, I want all my messages and calls to be end-to-end encrypted, so that only the intended recipients can read or hear them.

#### Acceptance Criteria

1. THE Encryption_Service SHALL encrypt all Messages using the Signal Protocol (Double Ratchet + X3DH key agreement) before transmission.
2. THE Encryption_Service SHALL encrypt all voice and video call media streams using SRTP with keys derived from the Signal Protocol.
3. THE Encryption_Service SHALL generate a unique key pair per device registration and store the private key exclusively in the device's secure enclave or keychain.
4. WHEN a User's key changes (e.g., reinstall), THE Encryption_Service SHALL notify existing Contacts with a "Security code changed" Message before delivering new Messages.
5. THE App SHALL provide a security-code verification screen where two Users can compare a 60-digit numeric code or scan a QR code to confirm their E2EE session.
6. THE Encryption_Service SHALL ensure that the server stores only encrypted ciphertext and SHALL NOT have access to plaintext Message content or call media.

---

### Requirement 10: Presence and Last Seen

**User Story:** As a user, I want to see whether my contacts are online or when they were last active, so that I know the best time to reach them.

#### Acceptance Criteria

1. WHEN a User opens the App and has an active network connection, THE Presence_Service SHALL broadcast an "online" status to Contacts who have an open Conversation with the User.
2. WHEN a User closes the App or loses network connectivity for more than 30 seconds, THE Presence_Service SHALL update the User's status to "last seen [timestamp]".
3. THE App SHALL display "online" or "last seen [time]" in the Conversation header for one-to-one chats.
4. WHERE a User has set privacy to "Nobody" for last-seen, THE Presence_Service SHALL not broadcast the User's last-seen timestamp to any other User, and THE App SHALL not display last-seen for that User.
5. WHERE a User has set privacy to "My Contacts" for last-seen, THE Presence_Service SHALL broadcast last-seen only to that User's Contacts.
6. WHEN a User disables last-seen sharing, THE App SHALL also hide other Users' last-seen timestamps from that User.

---

### Requirement 11: Push Notifications

**User Story:** As a user, I want to receive push notifications for new messages and calls when the app is in the background, so that I never miss important communications.

#### Acceptance Criteria

1. WHEN a new Message arrives and the App is in the background, THE Notification_Service SHALL deliver a push notification to the device within 5 seconds.
2. WHEN an incoming call arrives and the App is in the background, THE Notification_Service SHALL deliver a full-screen call notification within 2 seconds.
3. THE Notification_Service SHALL group notifications by Conversation so that multiple Messages from the same Conversation appear as a single notification thread.
4. WHEN a User reads a Message in the App, THE Notification_Service SHALL dismiss the corresponding notification from the notification tray within 3 seconds.
5. THE App SHALL allow a User to mute notifications for a specific Conversation for 8 hours, 1 week, or indefinitely.
6. IF a User has enabled Do Not Disturb mode in the App, THEN THE Notification_Service SHALL suppress all notifications except calls from starred Contacts.

---

### Requirement 12: Profile and Privacy Settings

**User Story:** As a user, I want to control my profile information and privacy settings, so that I can decide what others can see about me.

#### Acceptance Criteria

1. THE App SHALL allow a User to set a display name (1–25 characters), profile photo, and a status bio (up to 139 characters).
2. THE App SHALL allow a User to configure visibility of profile photo, status bio, and last-seen independently, with options: "Everyone", "My Contacts", or "Nobody".
3. WHEN a User updates their profile photo, THE App SHALL propagate the change to all Contacts' views within 30 seconds.
4. THE App SHALL allow a User to enable two-step verification by setting a 6-digit PIN that is required when re-registering the phone number.
5. WHEN two-step verification is enabled and a User attempts to re-register, THE Auth_Service SHALL require the 6-digit PIN in addition to OTP verification.
6. THE App SHALL allow a User to export their chat history as a plain-text file with optional media attachments.
7. THE App SHALL allow a User to delete their account, which SHALL permanently remove all their Messages, media, and profile data from the server within 30 days.
