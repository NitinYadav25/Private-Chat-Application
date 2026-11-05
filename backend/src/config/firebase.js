const admin = require('firebase-admin');

let initialized = false;

function initFirebase() {
  if (initialized) return admin;

  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      initialized = true;
      console.log('Firebase Admin initialized with SERVICE_ACCOUNT_JSON');
    } else if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      initialized = true;
      console.log('Firebase Admin initialized with individual credentials');
    } else {
      // Default credentials or fallback
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || 'ghostconv',
      });
      initialized = true;
      console.log('Firebase Admin initialized with default projectId');
    }
  } catch (error) {
    console.warn('Firebase Admin initialization warning:', error.message);
  }

  return admin;
}

initFirebase();

module.exports = {
  admin,
  db: admin.firestore(),
  auth: admin.auth(),
};

