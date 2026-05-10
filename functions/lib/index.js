"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onNewUserCreated = exports.requestVoiceOtp = exports.syncContacts = void 0;
const admin = require("firebase-admin");
const functionsV1 = require("firebase-functions/v1");
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const crypto = require("crypto");
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
exports.syncContacts = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const hashedNumbers = request.data.hashedNumbers;
    if (!Array.isArray(hashedNumbers)) {
        throw new https_1.HttpsError("invalid-argument", "hashedNumbers must be an array.");
    }
    if (hashedNumbers.length === 0)
        return { contacts: [] };
    // Firestore `in` queries support max 30 items per batch.
    const BATCH_SIZE = 30;
    const results = [];
    for (let i = 0; i < hashedNumbers.length; i += BATCH_SIZE) {
        const batch = hashedNumbers.slice(i, i + BATCH_SIZE);
        const snapshot = await db
            .collection("users")
            .where("phoneHash", "in", batch)
            .get();
        snapshot.forEach((doc) => results.push(Object.assign({ id: doc.id }, doc.data())));
    }
    const callerId = request.auth.uid;
    const contacts = results
        .filter((u) => u.id !== callerId)
        .map((u) => {
        var _a, _b, _c;
        return ({
            userId: u.id,
            phoneNumber: (_a = u["phoneNumber"]) !== null && _a !== void 0 ? _a : "",
            displayName: (_b = u["displayName"]) !== null && _b !== void 0 ? _b : "",
            photoUrl: (_c = u["photoUrl"]) !== null && _c !== void 0 ? _c : null,
            isBlocked: false,
        });
    });
    return { contacts };
});
// ---------------------------------------------------------------------------
// requestVoiceOtp
// ---------------------------------------------------------------------------
// Fallback OTP path — called after 60 s if SMS hasn't arrived.
// Wire to Twilio / Vonage for production voice calls.
//
// Request:  { phoneNumber: string }   (E.164)
// Response: null
// ---------------------------------------------------------------------------
exports.requestVoiceOtp = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const phoneNumber = request.data.phoneNumber;
    if (typeof phoneNumber !== "string" || !phoneNumber.startsWith("+")) {
        throw new https_1.HttpsError("invalid-argument", "phoneNumber must be E.164.");
    }
    // TODO: integrate Twilio / Vonage for a real voice call.
    v2_1.logger.info("Voice OTP requested", { phoneNumber });
    return null;
});
// ---------------------------------------------------------------------------
// onNewUserCreated  (Auth trigger — v1)
// ---------------------------------------------------------------------------
// When a new Firebase Auth user registers via phone OTP, create their
// /users/{uid} document with a SHA-256 hash of their phone number so that
// syncContacts can discover them by hash without storing raw numbers server-side.
// ---------------------------------------------------------------------------
exports.onNewUserCreated = functionsV1.auth.user().onCreate(async (user) => {
    const phone = user.phoneNumber;
    if (!phone)
        return;
    const phoneHash = crypto.createHash("sha256").update(phone).digest("hex");
    await db.collection("users").doc(user.uid).set({
        phoneNumber: phone,
        phoneHash,
        displayName: "",
        photoUrl: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true } // won't overwrite displayName if profile setup ran first
    );
    v2_1.logger.info("User document created", { uid: user.uid });
});
//# sourceMappingURL=index.js.map