// src/index.ts
import * as functions from "firebase-functions"; // v1 triggers
import admin from "firebase-admin";
import logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();

// ============================================
// HELPER CEK ADMIN
// ============================================
async function checkIsAdmin(uid: string) {
  const adminDoc = await db.collection("users").doc(uid).get();
  if (!adminDoc.exists || adminDoc.data()?.user_role !== "Admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admin can perform this action"
    );
  }
}

// ============================================
// CREATE USER (ADMIN)
// ============================================
export const createUserWithPassword = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { email, password, role, name } = data;
    await checkIsAdmin(context.auth.uid);

    // VALIDASI
    if (!email || !password || !role || !name) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email, password, role, dan name wajib diisi"
      );
    }

    // Buat user di Firebase Auth (hanya email + password + displayName opsional)
    const newUser = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    // Simpan data lengkap di Firestore, termasuk default sisa cuti
    await db
      .collection("users")
      .doc(newUser.uid)
      .set({
        user_id: newUser.uid,
        user_name: name,
        user_email: email,
        user_role: role,
        user_photo: null,
        sisa_cuti: role === "Admin" ? null : 100, // Admin tidak wajib sisa cuti
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        synced_by_admin: true,
      });

    return { success: true, user: newUser };
  }
);

// ============================================
// UPDATE USER PASSWORD (ADMIN)
// ============================================
export const updateUserPassword = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { uid, newPassword } = data;
    await checkIsAdmin(context.auth.uid);

    if (!uid || !newPassword) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "UID dan newPassword wajib diisi"
      );
    }

    await admin.auth().updateUser(uid, { password: newPassword });
    return { success: true };
  }
);

// ============================================
// AUTH TRIGGER DEFAULT (v1)
// ============================================
export const onAuthUserCreated = functions.auth
  .user()
  .onCreate(async (user) => {
    const uid = user.uid;
    const email = user.email || "";

    const docRef = db.collection("users").doc(uid);
    const doc = await docRef.get();

    if (doc.exists && doc.data()?.synced_by_admin) return;

    logger.info(`Creating Firestore doc for new user: ${uid}`);

    await docRef.set({
      user_id: uid,
      user_name: "",
      user_email: email,
      user_role: "Karyawan",
      sisa_cuti: 100,
      user_photo: null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// ============================================
// UPDATE USER EMAIL (ADMIN)
// ============================================
export const updateUserEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { uid, newEmail } = data;
  await checkIsAdmin(context.auth.uid);

  if (!uid || !newEmail) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "UID dan newEmail wajib diisi"
    );
  }

  await admin.auth().updateUser(uid, { email: newEmail });
  return { success: true };
});

// ============================================
// DELETE USER (ADMIN)
// ============================================
export const deleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { uid } = data;
  await checkIsAdmin(context.auth.uid);

  // VALIDASI
  if (!uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "UID user wajib dikirim"
    );
  }

  // Hapus dari Firestore
  await db.collection("users").doc(uid).delete();

  // Hapus dari Firebase Auth
  await admin.auth().deleteUser(uid);

  return {
    success: true,
    message: `User ${uid} berhasil dihapus`,
  };
});
