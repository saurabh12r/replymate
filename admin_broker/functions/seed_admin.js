// One-time admin seed script
// Run: node seed_admin.js
// This creates your first admin account in Firebase Auth + admin_users collection

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const fs = require('fs');

// ── CONFIG — edit these ─────────────────────────────────────────────────────
const ADMIN_EMAIL    = 'admin@replymate.app';   // ← change to your email
const ADMIN_PASSWORD = 'Admin@1234';             // ← change to your password
const ADMIN_NAME     = 'Super Admin';            // ← your name
const ADMIN_PHONE    = '+919999999999';          // ← your phone
const PROJECT_ID     = 'xyzd-7254d';
// ───────────────────────────────────────────────────────────────────────────

// Uses Firebase CLI credentials if running locally without Application Default Credentials
let credential;
let cliAccessToken = null;
try {
  const configPath = '/Users/saurabh/.config/configstore/firebase-tools.json';
  if (fs.existsSync(configPath)) {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const accessToken = config.tokens && config.tokens.access_token;
    if (accessToken) {
      cliAccessToken = accessToken;
      credential = {
        getAccessToken: () => ({
          access_token: accessToken,
          expires_in: 3600
        })
      };
      console.log('ℹ️  Using cached Firebase CLI credentials.');
    }
  }
} catch (e) {
  // Fallback to default
}

initializeApp({
  credential,
  projectId: PROJECT_ID
});

const auth = getAuth();

async function writeFirestoreRest(uid) {
  if (!cliAccessToken) {
    throw new Error('No Firebase CLI access token found. Cannot write to Firestore via REST.');
  }

  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/admin_users/${uid}`;
  const payload = {
    fields: {
      uid: { stringValue: uid },
      name: { stringValue: ADMIN_NAME },
      email: { stringValue: ADMIN_EMAIL },
      phone: { stringValue: ADMIN_PHONE },
      role: { stringValue: 'admin' },
      isActive: { booleanValue: true },
      createdAt: { timestampValue: new Date().toISOString() }
    }
  };

  const response = await fetch(url, {
    method: 'PATCH', // PATCH acts as set with merge: true
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${cliAccessToken}`
    },
    body: JSON.stringify(payload)
  });

  const data = await response.json();
  if (data.error) {
    throw new Error(`Firestore REST Error: ${data.error.message}`);
  }
  return data;
}

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

  // 2. Write admin_users document using Firestore REST API
  await writeFirestoreRest(uid);

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
