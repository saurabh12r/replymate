const API_KEY = 'AIzaSyA72tSwlX3t6AWKSQ6nrHPKNDvPEpp2yHU'; // from web config
const PROJECT_ID = 'replymate-1f925';

async function run() {
  // 1. Create Auth User
  const authRes = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'admin@replymate.app',
      password: 'Admin@1234',
      returnSecureToken: true
    })
  });
  
  let authData = await authRes.json();
  
  if (authData.error && authData.error.message === 'EMAIL_EXISTS') {
    console.log('User exists. Logging in...');
    const loginRes = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@replymate.app',
        password: 'Admin@1234',
        returnSecureToken: true
      })
    });
    authData = await loginRes.json();
  }

  if (authData.error) {
    console.error('Auth Error:', authData.error);
    return;
  }

  const { idToken, localId: uid } = authData;
  console.log('Got UID:', uid);

  // 2. Create Firestore Document
  const firestoreRes = await fetch(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/admin_users?documentId=${uid}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${idToken}`
    },
    body: JSON.stringify({
      fields: {
        uid: { stringValue: uid },
        name: { stringValue: 'Super Admin' },
        email: { stringValue: 'admin@replymate.app' },
        phone: { stringValue: '+919999999999' },
        role: { stringValue: 'admin' },
        isActive: { booleanValue: true }
      }
    })
  });

  const firestoreData = await firestoreRes.json();
  if (firestoreData.error) {
    // If document already exists, try patching it
    if (firestoreData.error.status === 'ALREADY_EXISTS') {
      console.log('Document exists, patching...');
      const patchRes = await fetch(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/admin_users/${uid}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${idToken}`
        },
        body: JSON.stringify({
          fields: {
            uid: { stringValue: uid },
            name: { stringValue: 'Super Admin' },
            email: { stringValue: 'admin@replymate.app' },
            phone: { stringValue: '+919999999999' },
            role: { stringValue: 'admin' },
            isActive: { booleanValue: true }
          }
        })
      });
      console.log('Patch result:', await patchRes.json());
    } else {
      console.error('Firestore Error:', firestoreData.error);
    }
  } else {
    console.log('Document created:', firestoreData);
  }
}

run();
