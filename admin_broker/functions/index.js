// Firebase Cloud Functions for admin_broker + ReplyMate
// Deploy: cd functions && npm install && firebase deploy --only functions

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentUpdated, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { logger } = require('firebase-functions');

initializeApp();
const db = getFirestore();

// ─── 1. AUTO-EXPIRE SUBSCRIPTIONS ─────────────────────────────────────────────
// Runs once daily (02:00 Asia/Kolkata). Finds users where subscriptionEnd has passed
// but isApproved=true. Sets isApproved=false, status=expired — disables auto-reply in ReplyMate.
// (ReplyMate also corrects expired state when the user document is read.)

const planDurationCache = {};
const planNameCache = {};

async function getPlanInfo(planId) {
  if (planDurationCache[planId] !== undefined) {
    return { durationDays: planDurationCache[planId], name: planNameCache[planId] };
  }
  try {
    const planDoc = await db.collection('plans').doc(planId).get();
    if (planDoc.exists) {
      const pData = planDoc.data();
      planDurationCache[planId] = pData.durationDays || 30;
      planNameCache[planId] = pData.name || 'Subscribed Plan';
    } else {
      planDurationCache[planId] = 30;
      planNameCache[planId] = 'Subscribed Plan';
    }
  } catch (e) {
    planDurationCache[planId] = 30;
    planNameCache[planId] = 'Subscribed Plan';
  }
  return { durationDays: planDurationCache[planId], name: planNameCache[planId] };
}

exports.autoExpireSubscriptions = onSchedule(
  {
    schedule: '0 2 * * *',
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    timeoutSeconds: 120,
  },
  async (_event) => {
    const now = Timestamp.now();
    const snap = await db
      .collection('users')
      .where('isApproved', '==', true)
      .where('subscriptionEnd', '<', now)
      .get();

    if (snap.empty) {
      logger.info('autoExpire: no subscriptions to expire');
      return;
    }

    const BATCH_LIMIT = 400;
    let expiredCount = 0;
    let queuedActivatedCount = 0;

    // Process in batches of 400 (Firestore limit is 500)
    for (let i = 0; i < snap.docs.length; i += BATCH_LIMIT) {
      const chunk = snap.docs.slice(i, i + BATCH_LIMIT);
      const batch = db.batch();
      for (const doc of chunk) {
        const userData = doc.data();
        if (userData.nextPlanId) {
          const nextPlanId = userData.nextPlanId;
          const planInfo = await getPlanInfo(nextPlanId);

          const startDate = userData.nextPlanStartDate ? userData.nextPlanStartDate.toDate() : new Date();
          const durationDays = userData.nextPlanDurationDays || planInfo.durationDays || 30;
          const endDate = userData.nextPlanEndDate ? userData.nextPlanEndDate.toDate() : new Date(startDate.getTime() + durationDays * 24 * 60 * 60 * 1000);

          batch.update(doc.ref, {
            isApproved: true,
            status: 'active',
            planId: nextPlanId,
            planName: userData.nextPlanName || planInfo.name,
            subscriptionStart: Timestamp.fromDate(startDate),
            subscriptionEnd: Timestamp.fromDate(endDate),
            nextPlanId: FieldValue.delete(),
            nextPlanName: FieldValue.delete(),
            nextPlanDurationDays: FieldValue.delete(),
            nextPlanStartDate: FieldValue.delete(),
            nextPlanEndDate: FieldValue.delete(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          queuedActivatedCount++;
        } else {
          batch.update(doc.ref, {
            isApproved: false,
            status: 'expired',
            updatedAt: FieldValue.serverTimestamp(),
          });
          expiredCount++;
        }
      }
      await batch.commit();
    }

    // Update global stats
    await _updateGlobalStats();

    logger.info(`autoExpire: expired ${expiredCount} subscriptions, activated ${queuedActivatedCount} queued plans`);
  }
);

// ─── 2. SEND EXPIRY WARNING NOTIFICATIONS (7 days before expiry) ──────────────
// Runs daily at 9 AM IST.

exports.sendExpiryWarnings = onSchedule(
  { schedule: '0 9 * * *', timeZone: 'Asia/Kolkata', region: 'asia-south1' },
  async (_event) => {
    const now = new Date();
    // Query users expiring within the next 2 days (so we catch those expiring in ~1 day)
    const twoDaysLater = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);

    const snap = await db
      .collection('users')
      .where('isApproved', '==', true)
      .where('subscriptionEnd', '>=', Timestamp.fromDate(now))
      .where('subscriptionEnd', '<=', Timestamp.fromDate(twoDaysLater))
      .get();

    const messaging = getMessaging();
    let notified = 0;

    for (const doc of snap.docs) {
      const data = doc.data();

      // Only notify if there is no queue plan
      if (data.nextPlanId && data.nextPlanId.trim() !== '') {
        continue;
      }

      const fcmToken = data.fcmToken;
      const subEnd = data.subscriptionEnd.toDate();
      const daysLeft = Math.ceil((subEnd - now) / (1000 * 60 * 60 * 24));

      // We notify exactly 1 day before the plan is going to expire
      if (daysLeft === 1) {
        const title = '⏰ Subscription Expires Tomorrow';
        const body = 'Your ReplyMate subscription expires tomorrow. Please renew to avoid interruption.';

        // 1. Send FCM Push Notification to the user
        if (fcmToken) {
          try {
            await messaging.send({
              token: fcmToken,
              notification: {
                title: title,
                body: body,
              },
              data: {
                type: 'subscription_expiry_warning',
                daysLeft: String(daysLeft),
              },
              android: { 
                priority: 'high',
                notification: { sound: 'default' }
              },
            });
            notified++;
          } catch (e) {
            logger.warn(`FCM failed for ${doc.id}: ${e.message}`);
          }
        }

        // 2. Create in-app notification for Admin
        try {
          const adminNotificationId = 'exp_' + doc.id + '_' + Date.now() + '_admin';
          await db.collection('notifications').doc(adminNotificationId).set({
            title: 'Subscription Expiring Tomorrow',
            message: `${data.name || 'User'}'s subscription expires tomorrow.`,
            type: 'subscriptionExpiringSoon',
            userId: doc.id,
            userName: data.name || '',
            userPhone: data.phone || '',
            targetRole: 'admin',
            createdAt: Timestamp.now(),
          });
        } catch (e) {
          logger.warn(`Failed to create admin notification for ${doc.id}: ${e.message}`);
        }

        // 3. Create in-app notification for Broker (if exists)
        if (data.brokerId) {
          try {
            const brokerNotificationId = 'exp_' + doc.id + '_' + Date.now() + '_broker';
            await db.collection('notifications').doc(brokerNotificationId).set({
              title: 'Subscription Expiring Tomorrow',
              message: `${data.name || 'User'}'s subscription expires tomorrow.`,
              type: 'subscriptionExpiringSoon',
              userId: doc.id,
              userName: data.name || '',
              userPhone: data.phone || '',
              targetRole: 'broker',
              targetId: data.brokerId,
              createdAt: Timestamp.now(),
            });
          } catch (e) {
            logger.warn(`Failed to create broker notification for ${doc.id}: ${e.message}`);
          }
        }
      }
    }

    logger.info(`sendExpiryWarnings: notified ${notified} users`);
  }
);

// ─── 3. ON USER APPROVED — Send FCM notification ───────────────────────────────
// Triggered when isApproved changes from false → true in the users collection.

exports.onUserApproved = onDocumentUpdated(
  { document: 'users/{userId}', region: 'asia-south1' },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Notifications are best-effort. A missing fcmToken must only skip the push —
    // it must NOT early-return, or the stats refresh below would be skipped (e.g. a
    // broker approving a user who has never logged in yet, so has no token).
    const fcmToken = after.fcmToken;

    // Approved: false → true
    if (before.isApproved === false && after.isApproved === true && fcmToken) {
      const subStart = after.subscriptionStart?.toDate();
      const subEnd = after.subscriptionEnd?.toDate();
      const subEndStr = subEnd
        ? `${subEnd.getDate()} ${_monthName(subEnd.getMonth())} ${subEnd.getFullYear()}`
        : 'N/A';

      const now = new Date();
      const isFutureStart = subStart && subStart > now;

      try {
        if (isFutureStart) {
          const subStartStr = `${subStart.getDate()} ${_monthName(subStart.getMonth())} ${subStart.getFullYear()}`;
          await getMessaging().send({
            token: fcmToken,
            notification: {
              title: '📅 Subscription Scheduled!',
              body: `Your ReplyMate subscription has been approved and is scheduled to start on ${subStartStr}.`,
            },
            data: {
              type: 'account_approved_scheduled',
              subscriptionStart: subStart.toISOString(),
              subscriptionEnd: subEnd ? subEnd.toISOString() : '',
            },
            android: { priority: 'high' },
          });
        } else {
          await getMessaging().send({
            token: fcmToken,
            notification: {
              title: '✅ Account Activated!',
              body: `Your ReplyMate account is now active. Subscription valid until ${subEndStr}.`,
            },
            data: {
              type: 'account_approved',
              subscriptionEnd: subEnd ? subEnd.toISOString() : '',
            },
            android: { priority: 'high' },
          });
        }
        logger.info(`onUserApproved: FCM sent to user ${event.params.userId}`);
      } catch (e) {
        logger.warn(`onUserApproved FCM failed: ${e.message}`);
      }
    }

    // Unblocked: isBlocked true → false (and approved)
    if (before.isBlocked === true && after.isBlocked === false && after.isApproved === true && fcmToken) {
      try {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title: '✅ Account Restored',
            body: 'Your ReplyMate account has been restored by the admin.',
          },
          data: { type: 'account_unblocked' },
          android: { priority: 'high' },
        });
      } catch (_) { }
    }

    // Plan assigned / renewed (still approved, but planId or endDate changed)
    if (before.isApproved === true && after.isApproved === true && fcmToken) {
      const planChanged = before.planId !== after.planId;
      const subExtended = (after.subscriptionEnd && before.subscriptionEnd && after.subscriptionEnd.toMillis() > before.subscriptionEnd.toMillis());

      if (planChanged || subExtended) {
        const subEnd = after.subscriptionEnd?.toDate();
        const subEndStr = subEnd ? `${subEnd.getDate()} ${_monthName(subEnd.getMonth())} ${subEnd.getFullYear()}` : 'N/A';
        try {
          await getMessaging().send({
            token: fcmToken,
            notification: {
              title: '🎉 Plan Assigned & Renewed',
              body: `Your plan has been updated to "${after.planName || 'New Plan'}". Valid until ${subEndStr}.`,
            },
            data: {
              type: 'plan_assigned',
              subscriptionEnd: subEnd ? subEnd.toISOString() : '',
            },
            android: { priority: 'high' },
          });
        } catch (_) { }
      }
    }

    // Suspended: isBlocked false → true OR isApproved true → false
    const becameBlocked = before.isBlocked === false && after.isBlocked === true;
    const becameDisapproved = before.isApproved === true && after.isApproved === false;
    if ((becameBlocked || becameDisapproved) && fcmToken) {
      try {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title: '🚫 Account Suspended',
            body: 'Your ReplyMate account has been suspended or has expired. Auto-reply services are paused.',
          },
          data: { type: 'account_suspended' },
          android: { priority: 'high' },
        });
      } catch (_) { }
    }

    // Refresh global stats ONLY when a stats-relevant field actually changed.
    // This both (a) guarantees stats update on approval/block regardless of fcmToken,
    // and (b) avoids a full 3-collection re-aggregation on every fcmToken-only write
    // (e.g. token refresh on each login), which is the common case at scale.
    const statsRelevantChanged =
      before.isApproved !== after.isApproved ||
      before.isBlocked !== after.isBlocked ||
      before.brokerId !== after.brokerId;
    if (statsRelevantChanged) {
      await _updateGlobalStats();
    }
  }
);

// ─── 4. ON NEW USER REGISTERED — Notify broker ─────────────────────────────────
// Triggered when a new document is created in 'users' collection.

exports.onBrokerUserRegistered = onDocumentCreated(
  { document: 'users/{userId}', region: 'asia-south1' },
  async (event) => {
    const data = event.data.data();
    const brokerId = data.brokerId;

    // Notify the broker (best-effort) when a user registered with their code. A missing
    // brokerId (direct registration) or missing token must only skip the push — it must NOT
    // early-return, or the stats refresh below would be skipped and a new user would not be
    // counted until some later write happened to trigger a recompute.
    if (brokerId) {
      try {
        // Get broker's portal account to find their FCM token
        const brokerPortalDoc = await db.collection('admin_users').doc(brokerId).get();
        const fcmToken = brokerPortalDoc.data()?.fcmToken;
        if (fcmToken) {
          await getMessaging().send({
            token: fcmToken,
            notification: {
              title: '🆕 New User Registered',
              body: `${data.name || 'A new user'} registered using your broker code. Awaiting your approval.`,
            },
            data: {
              type: 'broker_new_user',
              userId: event.params.userId,
              userName: data.name || '',
            },
            android: { priority: 'normal' },
          });
          logger.info(`onBrokerUserRegistered: notified broker ${brokerId}`);
        }
      } catch (e) {
        logger.warn(`onBrokerUserRegistered FCM failed: ${e.message}`);
      }
    }

    // Always refresh stats — a new user (broker-referred OR direct) changes the counts.
    await _updateGlobalStats();
  }
);

// ─── 5. ON APPROVAL CREATED — Update global stats ──────────────────────────────

exports.onApprovalCreated = onDocumentCreated(
  { document: 'approvals/{approvalId}', region: 'asia-south1' },
  async (_event) => {
    await _updateGlobalStats();
  }
);

// ─── HELPER: Update global stats document ─────────────────────────────────────
// Maintains a pre-aggregated stats/global document for fast dashboard reads.

async function _updateGlobalStats() {
  try {
    const [usersSnap, brokersSnap, approvalsSnap] = await Promise.all([
      db.collection('users').get(),
      db.collection('brokers').get(),
      db.collection('approvals').get(),
    ]);

    const users = usersSnap.docs.map(d => d.data());
    const totalUsers = users.length;
    const activeUsers = users.filter(u => u.isApproved === true).length;
    const pendingUsers = users.filter(u => u.isApproved === false && u.isBlocked !== true && !u.brokerId).length;
    const brokerPendingUsers = users.filter(u => u.isApproved === false && u.isBlocked !== true && u.brokerId).length;

    let totalRevenue = 0;
    let totalBrokerCommission = 0;
    for (const doc of approvalsSnap.docs) {
      const d = doc.data();
      totalRevenue += d.adminRevenue || 0;
      totalBrokerCommission += d.brokerCommission || 0;
    }

    await db.collection('stats').doc('global').set({
      totalUsers,
      activeUsers,
      pendingUsers,
      brokerPendingUsers,
      totalBrokers: brokersSnap.size,
      totalRevenue,
      totalBrokerCommission,
      lastUpdated: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    logger.error('_updateGlobalStats failed:', e);
  }
}

function _monthName(m) {
  return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

// ─── 6. CREATE BROKER (Callable Function) ────────────────────────────────────
// Safely creates a broker auth account via Admin SDK (prevents client logout)

exports.createBroker = onCall({ region: 'asia-south1' }, async (request) => {
  // Ensure the caller is authenticated
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be logged in.');
  }

  // Ensure caller is an admin (by checking admin_users document)
  const callerDoc = await db.collection('admin_users').doc(request.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can create brokers.');
  }

  const { email, password, name, phone } = request.data;
  if (!email || !password || !name) {
    throw new HttpsError('invalid-argument', 'Missing required fields.');
  }

  try {
    // Create the user in Firebase Auth using Admin SDK
    const userRecord = await getAuth().createUser({
      email: email.trim(),
      password: password,
      displayName: name.trim(),
    });

    // The frontend will handle creating the Firestore documents (admin_users & brokers)
    // using this returned UID.
    return { uid: userRecord.uid };
  } catch (error) {
    logger.error('Error creating broker account:', error);
    throw new HttpsError('internal', error.message || 'Failed to create broker');
  }
});

// ─── 7. SEND CAMPAIGN NOTIFICATION (Callable Function) ─────────────────────────
exports.sendCampaignNotification = onCall({ region: 'asia-south1', timeoutSeconds: 300 }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be logged in.');
  }

  const { title, message, imageUrl, targetType, planId } = request.data;
  if (!title || !message || !targetType) {
    throw new HttpsError('invalid-argument', 'Missing required fields.');
  }

  const callerUid = request.auth.uid;
  let callerRole = 'broker';
  let callerName = 'Broker';

  // Check if admin
  const callerDoc = await db.collection('admin_users').doc(callerUid).get();
  if (callerDoc.exists && callerDoc.data().role === 'admin') {
    callerRole = 'admin';
    callerName = callerDoc.data().name || 'Admin';
  } else {
    // Verify broker
    const brokerDoc = await db.collection('brokers').doc(callerUid).get();
    if (!brokerDoc.exists || !brokerDoc.data().isActive) {
      throw new HttpsError('permission-denied', 'Only active brokers or admins can send campaigns.');
    }
    callerName = brokerDoc.data().name || 'Broker';
  }

  // Build Query
  const tokens = [];
  let totalTargeted = 0;

  if (targetType === 'specific_user' && planId) {
    const userIds = typeof planId === 'string' ? planId.split(',') : (Array.isArray(planId) ? planId : [planId]);
    const cleanUserIds = userIds.map(id => id.trim()).filter(id => id.length > 0);
    if (cleanUserIds.length > 0) {
      const userRefs = cleanUserIds.map(id => db.collection('users').doc(id));
      const userDocs = await db.getAll(...userRefs);
      userDocs.forEach(userDoc => {
        if (userDoc.exists) {
          const data = userDoc.data();
          if (callerRole === 'broker' && data.brokerId !== callerUid) {
            return; // Ignore if broker tries to send to user they don't own
          }
          totalTargeted++;
          if (data.fcmToken) {
            tokens.push(data.fcmToken);
          }
        }
      });
    }
  } else {
    let usersQuery = db.collection('users').where('isApproved', '==', true).where('isBlocked', '==', false);

    if (callerRole === 'broker') {
      usersQuery = usersQuery.where('brokerId', '==', callerUid);
    } else if (callerRole === 'admin') {
      if (targetType === 'my_users') {
        usersQuery = usersQuery.where('brokerId', '==', null);
      } else if (targetType === 'specific_broker' && planId) {
        usersQuery = usersQuery.where('brokerId', '==', planId);
      }
    }

    if (targetType === 'specific_plan' && planId) {
      usersQuery = usersQuery.where('planId', '==', planId);
    } else if (targetType === 'expiring_in_2_days') {
      const now = new Date();
      const twoDaysLater = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);
      usersQuery = usersQuery.where('subscriptionEnd', '>=', Timestamp.fromDate(now))
                             .where('subscriptionEnd', '<=', Timestamp.fromDate(twoDaysLater));
    }

    const usersSnap = await usersQuery.get();
    usersSnap.forEach((doc) => {
      const data = doc.data();
      if (targetType === 'all_brokers' && (!data.brokerId || data.brokerId === '')) {
        return;
      }
      totalTargeted++;
      if (data.fcmToken) {
        tokens.push(data.fcmToken);
      }
    });
  }

  if (tokens.length === 0) {
    return { success: 0, failed: 0, total: 0, message: 'No users matched the criteria or had valid FCM tokens.' };
  }

  // Send Notifications in batches of 500 (FCM limit)
  let successCount = 0;
  let failureCount = 0;
  const messaging = getMessaging();

  for (let i = 0; i < tokens.length; i += 500) {
    const tokenBatch = tokens.slice(i, i + 500);
    const messagePayload = {
      tokens: tokenBatch,
      notification: { title, body: message },
      android: { 
        priority: 'high',
        notification: {
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            'mutable-content': 1
          }
        }
      },
      data: { type: 'campaign' }
    };
    if (imageUrl) {
      messagePayload.notification.imageUrl = imageUrl;
      messagePayload.android.notification.imageUrl = imageUrl;
      messagePayload.apns.fcm_options = { image: imageUrl };
    }

    try {
      const response = await messaging.sendEachForMulticast(messagePayload);
      successCount += response.successCount;
      failureCount += response.failureCount;
    } catch (e) {
      logger.error('Error sending multicast message:', e);
      failureCount += tokenBatch.length;
    }
  }

  // Save to Campaign History
  try {
    await db.collection('campaigns').add({
      senderId: callerUid,
      senderRole: callerRole,
      senderName: callerName,
      title,
      message,
      imageUrl: imageUrl || null,
      targetType,
      planId: planId || null,
      totalTargeted,
      successCount,
      failureCount,
      createdAt: FieldValue.serverTimestamp()
    });
  } catch (e) {
    logger.error('Error saving campaign history:', e);
  }

  return { success: successCount, failed: failureCount, total: tokens.length };
});

// ─── 8. MESSAGE CENTRAL OTP (Callable Functions) ───────────────────────────────
// Replaces Firebase Phone Auth OTP delivery. Message Central (VerifyNow v3) sends &
// validates the SMS code; on success we mint a Firebase CUSTOM TOKEN whose uid is the
// user's E.164 phone number, so the existing phone-keyed identity model is preserved.
// Credentials live in functions/.env (git-ignored) and are read from process.env.

const MC_BASE_URL = process.env.MC_BASE_URL || 'https://cpaas.messagecentral.com';
const MC_CUSTOMER_ID = process.env.MC_CUSTOMER_ID || '';
const MC_PASSWORD = process.env.MC_PASSWORD || ''; // already base64 → sent as `key`
const MC_EMAIL = process.env.MC_EMAIL || '';
const MC_COUNTRY = process.env.MC_COUNTRY || '91'; // account country for token generation

// OTP abuse / lifetime tuning.
const OTP_SEND_MAX_PER_WINDOW = 5;       // max sends per phone per window
const OTP_SEND_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const OTP_VERIFY_MAX_ATTEMPTS = 5;       // max validate attempts per verificationId
const OTP_SESSION_TTL_MS = 15 * 60 * 1000; // session validity (matches MC timeout)
// NOTE: enable a Firestore TTL policy on the `expireAt` field of the `otp_sessions`
// and `otp_rate` collections so abandoned docs self-delete. Neither collection is
// listed in firestore.rules, so clients cannot read/write them — Admin SDK only.

// Cached MC auth token (valid for hours). Refreshed on expiry / on demand.
let _mcToken = null;
let _mcTokenExpiresAt = 0;

async function getMcAuthToken() {
  // If a direct long-lived auth token is configured, use it directly
  if (process.env.MC_AUTH_TOKEN) {
    return process.env.MC_AUTH_TOKEN;
  }
  // Fallback: if MC_PASSWORD looks like a JWT token (contains dots), use it directly
  if (MC_PASSWORD && MC_PASSWORD.includes('.')) {
    return MC_PASSWORD;
  }

  const now = Date.now();
  if (_mcToken && now < _mcTokenExpiresAt) return _mcToken;

  if (!MC_CUSTOMER_ID || !MC_PASSWORD) {
    throw new HttpsError('failed-precondition', 'Message Central credentials are not configured.');
  }

  const params = new URLSearchParams({
    customerId: MC_CUSTOMER_ID,
    key: MC_PASSWORD,
    scope: 'NEW',
    country: MC_COUNTRY,
  });
  if (MC_EMAIL) params.set('email', MC_EMAIL);

  const url = `${MC_BASE_URL}/auth/v1/authentication/token?${params.toString()}`;
  let res;
  try {
    res = await fetch(url, { method: 'GET', headers: { accept: '*/*' } });
  } catch (e) {
    logger.error('MC token request failed', e);
    throw new HttpsError('unavailable', 'Could not reach Message Central.');
  }

  const body = await res.json().catch(() => ({}));
  const token = body.token || body.authToken || (body.data && body.data.token);
  if (!res.ok || !token) {
    logger.error('MC token error', { status: res.status, body });
    throw new HttpsError('internal', 'Failed to obtain Message Central auth token.');
  }

  _mcToken = token;
  // Conservative cache window (token is valid for hours; refresh after ~50 min).
  _mcTokenExpiresAt = now + 50 * 60 * 1000;
  return _mcToken;
}

// Split an E.164 number into {countryCode, mobileNumber}. Falls back to provided countryCode.
function splitPhone(phoneNumber, countryCode) {
  const cc = String(countryCode || '').replace(/[^\d]/g, '');
  let digits = String(phoneNumber || '').replace(/[^\d]/g, '');
  if (cc && digits.startsWith(cc)) digits = digits.slice(cc.length);
  return { countryCode: cc || MC_COUNTRY, mobileNumber: digits };
}

// Sliding-window per-phone throttle to prevent SMS bombing / credit abuse.
async function enforceSendRateLimit(phoneKey) {
  const ref = db.collection('otp_rate').doc(phoneKey);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    let count = 0;
    let windowStart = now;
    if (snap.exists) {
      const d = snap.data();
      windowStart = d.windowStart && d.windowStart.toMillis ? d.windowStart.toMillis() : now;
      count = d.count || 0;
      if (now - windowStart >= OTP_SEND_WINDOW_MS) {
        count = 0;
        windowStart = now;
      }
    }
    if (count >= OTP_SEND_MAX_PER_WINDOW) {
      throw new HttpsError('resource-exhausted', 'Too many OTP requests. Please try again later.');
    }
    tx.set(ref, {
      count: count + 1,
      windowStart: Timestamp.fromMillis(windowStart),
      updatedAt: FieldValue.serverTimestamp(),
      expireAt: Timestamp.fromMillis(windowStart + OTP_SEND_WINDOW_MS),
    });
  });
}

exports.sendOtp = onCall({ region: 'asia-south1' }, async (request) => {
  const { phoneNumber, countryCode } = request.data || {};
  if (!phoneNumber) {
    throw new HttpsError('invalid-argument', 'phoneNumber is required.');
  }

  const { countryCode: cc, mobileNumber } = splitPhone(phoneNumber, countryCode);
  if (!mobileNumber) {
    throw new HttpsError('invalid-argument', 'Invalid phone number.');
  }

  // Throttle BEFORE contacting MC so abuse never costs an SMS.
  const phoneKey = String(phoneNumber).replace(/[^\d]/g, '');
  await enforceSendRateLimit(phoneKey);

  const authToken = await getMcAuthToken();
  const params = new URLSearchParams({
    countryCode: cc,
    flowType: 'SMS',
    mobileNumber,
  });
  const url = `${MC_BASE_URL}/verification/v3/send?${params.toString()}`;

  let res;
  try {
    res = await fetch(url, { method: 'POST', headers: { authToken, accept: '*/*' } });
  } catch (e) {
    logger.error('MC send failed', e);
    throw new HttpsError('unavailable', 'Could not reach Message Central.');
  }

  const body = await res.json().catch(() => ({}));
  const verificationId = body.data && (body.data.verificationId || body.data.transactionId);
  if (!res.ok || !verificationId) {
    logger.error('MC send error', { status: res.status, body });
    throw new HttpsError('internal', (body.message) || 'Failed to send OTP.');
  }

  // Bind this verificationId to the phone the SMS was actually sent to. verifyOtp uses
  // THIS stored phone for the token uid — never a client-supplied value — so a caller
  // cannot validate an OTP for a number they control yet mint a token for another number.
  await db.collection('otp_sessions').doc(String(verificationId)).set({
    phoneNumber: String(phoneNumber),
    countryCode: cc,
    attempts: 0,
    createdAt: FieldValue.serverTimestamp(),
    expireAt: Timestamp.fromMillis(Date.now() + OTP_SESSION_TTL_MS),
  });

  return { verificationId: String(verificationId) };
});

exports.verifyOtp = onCall({ region: 'asia-south1' }, async (request) => {
  const { verificationId, code } = request.data || {};
  if (!verificationId || !code) {
    throw new HttpsError('invalid-argument', 'verificationId and code are required.');
  }

  // The phone is taken from the server-side session, NOT from the client.
  const sessionRef = db.collection('otp_sessions').doc(String(verificationId));
  const sessionSnap = await sessionRef.get();
  if (!sessionSnap.exists) {
    throw new HttpsError('invalid-argument', 'OTP session expired. Please request a new code.');
  }
  const session = sessionSnap.data();

  const expMs = session.expireAt && session.expireAt.toMillis ? session.expireAt.toMillis() : 0;
  if (expMs && Date.now() > expMs) {
    await sessionRef.delete().catch(() => {});
    throw new HttpsError('invalid-argument', 'OTP expired. Please request a new code.');
  }

  const attempts = (session.attempts || 0) + 1;
  if (attempts > OTP_VERIFY_MAX_ATTEMPTS) {
    await sessionRef.delete().catch(() => {});
    throw new HttpsError('resource-exhausted', 'Too many attempts. Please request a new code.');
  }
  await sessionRef.update({ attempts });

  const authToken = await getMcAuthToken();
  const params = new URLSearchParams({
    verificationId: String(verificationId),
    code: String(code),
  });
  const url = `${MC_BASE_URL}/verification/v3/validateOtp?${params.toString()}`;

  let res;
  try {
    res = await fetch(url, { method: 'GET', headers: { authToken, accept: '*/*' } });
  } catch (e) {
    logger.error('MC validate failed', e);
    throw new HttpsError('unavailable', 'Could not reach Message Central.');
  }

  const body = await res.json().catch(() => ({}));
  const status = body.data && body.data.verificationStatus;
  if (!res.ok || status !== 'VERIFICATION_COMPLETED') {
    logger.warn('MC validate rejected', { status: res.status, verificationStatus: status });
    throw new HttpsError('invalid-argument', 'Invalid or expired OTP.');
  }

  // Mint a Firebase custom token. uid == E.164 phone (from the trusted session) keeps the
  // phone-keyed identity model, and the phone_number claim satisfies the Firestore
  // `request.auth.token.phone_number` rules.
  const uid = String(session.phoneNumber);
  try {
    const token = await getAuth().createCustomToken(uid, { phone_number: uid });
    await sessionRef.delete().catch(() => {}); // one-time use
    return { token };
  } catch (e) {
    logger.error('createCustomToken failed', e);
    throw new HttpsError('internal', 'Failed to create auth session.');
  }
});
