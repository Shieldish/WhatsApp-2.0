import * as admin from "firebase-admin";
import * as functionsV1 from "firebase-functions/v1";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as crypto from "crypto";

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// syncContacts
// ---------------------------------------------------------------------------
// Called by the app with a list of SHA-256-hashed phone numbers.
// Looks up which hashes exist in Firestore (/users collection) and returns
// the matching user profiles. Raw phone numbers never reach this function.
//
// Request:  { hashedNumbers: string[] }
// Response: { contacts: AppContact[] }
// ---------------------------------------------------------------------------

export const syncContacts = onCall(
  async (request: CallableRequest<{ hashedNumbers?: unknown }>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const hashedNumbers = request.data.hashedNumbers;
    if (!Array.isArray(hashedNumbers)) {
      throw new HttpsError("invalid-argument", "hashedNumbers must be an array.");
    }

    if (hashedNumbers.length === 0) return { contacts: [] };

    // Firestore `in` queries support max 30 items per batch.
    const BATCH_SIZE = 30;
    const results: Array<{ id: string } & admin.firestore.DocumentData> = [];

    for (let i = 0; i < hashedNumbers.length; i += BATCH_SIZE) {
      const batch = (hashedNumbers as string[]).slice(i, i + BATCH_SIZE);
      const snapshot = await db
        .collection("users")
        .where("phoneHash", "in", batch)
        .get();
      snapshot.forEach((doc) => results.push({ id: doc.id, ...doc.data() }));
    }

    const callerId = request.auth.uid;
    const contacts = results
      .filter((u) => u.id !== callerId)
      .map((u) => ({
        userId: u.id,
        phoneNumber: (u["phoneNumber"] as string) ?? "",
        displayName: (u["displayName"] as string) ?? "",
        photoUrl: (u["photoUrl"] as string | null) ?? null,
        isBlocked: false,
      }));

    return { contacts };
  }
);

// ---------------------------------------------------------------------------
// requestVoiceOtp
// ---------------------------------------------------------------------------
// Fallback OTP path — called after 60 s if SMS hasn't arrived.
// Wire to Twilio / Vonage for production voice calls.
//
// Request:  { phoneNumber: string }   (E.164)
// Response: null
// ---------------------------------------------------------------------------

export const requestVoiceOtp = onCall(
  async (request: CallableRequest<{ phoneNumber?: unknown }>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const phoneNumber = request.data.phoneNumber;
    if (typeof phoneNumber !== "string" || !phoneNumber.startsWith("+")) {
      throw new HttpsError("invalid-argument", "phoneNumber must be E.164.");
    }

    // TODO: integrate Twilio / Vonage for a real voice call.
    logger.info("Voice OTP requested", { phoneNumber });
    return null;
  }
);

// ---------------------------------------------------------------------------
// onNewUserCreated  (Auth trigger — v1)
// ---------------------------------------------------------------------------
// When a new Firebase Auth user registers via phone OTP, create their
// /users/{uid} document with a SHA-256 hash of their phone number so that
// syncContacts can discover them by hash without storing raw numbers server-side.
// ---------------------------------------------------------------------------

export const onNewUserCreated = functionsV1.auth.user().onCreate(async (user) => {
  const phone = user.phoneNumber;
  if (!phone) return;

  const phoneHash = crypto.createHash("sha256").update(phone).digest("hex");

  await db.collection("users").doc(user.uid).set(
    {
      phoneNumber: phone,
      phoneHash,
      displayName: "",
      photoUrl: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true } // won't overwrite displayName if profile setup ran first
  );

  logger.info("User document created", { uid: user.uid });
});
