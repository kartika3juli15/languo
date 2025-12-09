"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUser = exports.updateUserEmail = exports.onAuthUserCreated = exports.updateUserPassword = exports.createUserWithPassword = void 0;
// src/index.ts
const functions = __importStar(require("firebase-functions")); // v1 triggers
const firebase_admin_1 = __importDefault(require("firebase-admin"));
const logger_1 = __importDefault(require("firebase-functions/logger"));
firebase_admin_1.default.initializeApp();
const db = firebase_admin_1.default.firestore();
// ============================================
// HELPER CEK ADMIN
// ============================================
async function checkIsAdmin(uid) {
    const adminDoc = await db.collection("users").doc(uid).get();
    if (!adminDoc.exists || adminDoc.data()?.user_role !== "Admin") {
        throw new functions.https.HttpsError("permission-denied", "Only admin can perform this action");
    }
}
// ============================================
// CREATE USER (ADMIN)
// ============================================
exports.createUserWithPassword = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { email, password, role, name } = data;
    await checkIsAdmin(context.auth.uid);
    // VALIDASI
    if (!email || !password || !role || !name) {
        throw new functions.https.HttpsError("invalid-argument", "Email, password, role, dan name wajib diisi");
    }
    // Buat user di Firebase Auth (hanya email + password + displayName opsional)
    const newUser = await firebase_admin_1.default.auth().createUser({
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
        created_at: firebase_admin_1.default.firestore.FieldValue.serverTimestamp(),
        synced_by_admin: true,
    });
    return { success: true, user: newUser };
});
// ============================================
// UPDATE USER PASSWORD (ADMIN)
// ============================================
exports.updateUserPassword = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { uid, newPassword } = data;
    await checkIsAdmin(context.auth.uid);
    if (!uid || !newPassword) {
        throw new functions.https.HttpsError("invalid-argument", "UID dan newPassword wajib diisi");
    }
    await firebase_admin_1.default.auth().updateUser(uid, { password: newPassword });
    return { success: true };
});
// ============================================
// AUTH TRIGGER DEFAULT (v1)
// ============================================
exports.onAuthUserCreated = functions.auth
    .user()
    .onCreate(async (user) => {
    const uid = user.uid;
    const email = user.email || "";
    const docRef = db.collection("users").doc(uid);
    const doc = await docRef.get();
    if (doc.exists && doc.data()?.synced_by_admin)
        return;
    logger_1.default.info(`Creating Firestore doc for new user: ${uid}`);
    await docRef.set({
        user_id: uid,
        user_name: "",
        user_email: email,
        user_role: "Karyawan",
        sisa_cuti: 100,
        user_photo: null,
        created_at: firebase_admin_1.default.firestore.FieldValue.serverTimestamp(),
    });
});
// ============================================
// UPDATE USER EMAIL (ADMIN)
// ============================================
exports.updateUserEmail = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { uid, newEmail } = data;
    await checkIsAdmin(context.auth.uid);
    if (!uid || !newEmail) {
        throw new functions.https.HttpsError("invalid-argument", "UID dan newEmail wajib diisi");
    }
    await firebase_admin_1.default.auth().updateUser(uid, { email: newEmail });
    return { success: true };
});
// ============================================
// DELETE USER (ADMIN)
// ============================================
exports.deleteUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { uid } = data;
    await checkIsAdmin(context.auth.uid);
    // VALIDASI
    if (!uid) {
        throw new functions.https.HttpsError("invalid-argument", "UID user wajib dikirim");
    }
    // Hapus dari Firestore
    await db.collection("users").doc(uid).delete();
    // Hapus dari Firebase Auth
    await firebase_admin_1.default.auth().deleteUser(uid);
    return {
        success: true,
        message: `User ${uid} berhasil dihapus`,
    };
});
