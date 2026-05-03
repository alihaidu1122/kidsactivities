import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';

admin.initializeApp();

type Role = 'parent' | 'provider' | 'admin';

function assertAuthed(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign-in required.');
  }
  return context.auth;
}

function assertAdmin(auth: { token: Record<string, unknown> }) {
  if (auth.token?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only.');
  }
}

export const setUserRole = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    const auth = assertAuthed(context);
  assertAdmin(auth);

  const uid = String((data as any)?.uid ?? '');
  const role = String((data as any)?.role ?? '') as Role;
  if (!uid) throw new functions.https.HttpsError('invalid-argument', 'uid is required.');
  if (!['parent', 'provider', 'admin'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'role must be parent/provider/admin.');
  }

  await admin.auth().setCustomUserClaims(uid, { role });
  await admin.firestore().doc(`users/${uid}`).set(
    {
      userId: uid,
      role,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { ok: true };
  });

export const trackActivityView = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    // For MVP: authenticated users only. We can relax later with App Check.
    assertAuthed(context);
    const activityId = String((data as any)?.activityId ?? '');
    if (!activityId) {
      throw new functions.https.HttpsError('invalid-argument', 'activityId is required.');
    }

  const ref = admin.firestore().doc(`activities/${activityId}`);
  await ref.set(
    { viewCount: admin.firestore.FieldValue.increment(1), updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { ok: true };
  });

export const onInquiryCreated = functions
  .region('europe-west1')
  .firestore.document('inquiries/{inquiryId}')
  .onCreate(async (snap) => {
    const inquiry = snap.data();
    const activityId = inquiry?.activityId;
    if (!activityId) return;
    await admin.firestore().doc(`activities/${activityId}`).set(
      {
        inquiryCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

export const onAuthUserDeleted = functions
  .region('europe-west1')
  .auth.user()
  .onDelete(async (user) => {
  const uid = user.uid;
  const db = admin.firestore();

  // Delete profile doc (if present)
  await db.doc(`users/${uid}`).delete().catch(() => undefined);

  // Delete children subcollection users/{uid}/children/*
  const childrenSnap = await db.collection(`users/${uid}/children`).get();
  const batch = db.batch();
  for (const doc of childrenSnap.docs) batch.delete(doc.ref);
  await batch.commit().catch(() => undefined);

  // Anonymize inquiries authored by this user
  const inquiriesSnap = await db.collection('inquiries').where('parentUserId', '==', uid).get();
  for (const doc of inquiriesSnap.docs) {
    await doc.ref.set(
      {
        parentName: 'Anonymous',
        parentEmail: null,
        parentPhone: null,
        message: null,
        isAnonymized: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  // Anonymize reviews authored by this user
  const reviewsSnap = await db.collection('reviews').where('parentUserId', '==', uid).get();
  for (const doc of reviewsSnap.docs) {
    await doc.ref.set(
      {
        parentName: 'Anonymous',
        reviewText: null,
        isAnonymized: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  });

// Health check (useful for initial deploy verification)
export const health = functions
  .region('europe-west1')
  .https.onRequest(async (_req, res) => {
    res.status(200).send('ok');
  });

