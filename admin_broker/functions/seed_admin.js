// One-time admin seed script
// Run: node seed_admin.js
// This creates your first admin account in Firebase Auth + admin_users collection

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// ── CONFIG — edit these ─────────────────────────────────────────────────────
const ADMIN_EMAIL    = 'admin@replymate.app';   // ← change to your email
const ADMIN_PASSWORD = 'Admin@1234';             // ← change to your password
const ADMIN_NAME     = 'Super Admin';            // ← your name
const ADMIN_PHONE    = '+919999999999';          // ← your phone
// ───────────────────────────────────────────────────────────────────────────

// Uses Application Default Credentials (firebase login sets this up)
initializeApp({ projectId: 'replymate-1f925' });

const auth = getAuth();
const db   = getFirestore();

async function seedAdmin() {
  console.log('🔧 Creating admin account...\n');

  // 1. Create Firebase Auth user
  let uid;
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL);
    uid = existing.uid;
    console.log(`ℹ️  Auth user already exists: ${uid}`);
  } catch {
    const user = await auth.createUser({
      email:         ADMIN_EMAIL,
      password:      ADMIN_PASSWORD,
      displayName:   ADMIN_NAME,
      emailVerified: true,
    });
    uid = user.uid;
    console.log(`✅ Firebase Auth user created: ${uid}`);
  }

  // 2. Write admin_users document
  await db.collection('admin_users').doc(uid).set({
    uid,
    name:      ADMIN_NAME,
    email:     ADMIN_EMAIL,
    phone:     ADMIN_PHONE,
    role:      'admin',
    isActive:  true,
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`✅ admin_users document written for uid: ${uid}`);
  console.log('\n🎉 Done! Login credentials:');
  console.log(`   Email:    ${ADMIN_EMAIL}`);
  console.log(`   Password: ${ADMIN_PASSWORD}`);
  console.log('\n   Open: http://localhost:8080');
  process.exit(0);
}

seedAdmin().catch(e => {
  console.error('❌ Error:', e.message);
  process.exit(1);
});
