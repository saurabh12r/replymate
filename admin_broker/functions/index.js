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

          const startDate = new Date();
          const endDate = new Date(startDate.getTime() + planInfo.durationDays * 24 * 60 * 60 * 1000);

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
    // Query users expiring within the next 2 days
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
      const fcmToken = data.fcmToken;
      if (!fcmToken) continue;

      const subEnd = data.subscriptionEnd.toDate();
      const daysLeft = Math.ceil((subEnd - now) / (1000 * 60 * 60 * 24));

      // Send notifications exactly on 2 days, 1 day, and 0 days (today)
      if (daysLeft === 2 || daysLeft === 1 || daysLeft === 0) {
        let title = '⚠️ Subscription Expiring Soon';
        let body = `Your ReplyMate subscription expires in 2 days. Contact your admin/broker to renew.`;
        
        if (daysLeft === 1) {
          title = '⏰ Subscription Expires Tomorrow';
          body = 'Your ReplyMate subscription expires tomorrow. Please renew to avoid interruption.';
        } else if (daysLeft === 0) {
          title = '🚨 Subscription Expires Today';
          body = 'Your ReplyMate subscription expires today. Renew immediately to keep auto-reply active.';
        }

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

    // Only trigger when isApproved changes false → true
    if (before.isApproved === false && after.isApproved === true) {
      const fcmToken = after.fcmToken;
      if (!fcmToken) return;

      const subEnd = after.subscriptionEnd?.toDate();
      const subEndStr = subEnd
        ? `${subEnd.getDate()} ${_monthName(subEnd.getMonth())} ${subEnd.getFullYear()}`
        : 'N/A';

      try {
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
        logger.info(`onUserApproved: FCM sent to user ${event.params.userId}`);
      } catch (e) {
        logger.warn(`onUserApproved FCM failed: ${e.message}`);
      }
    }

    // Also trigger when isBlocked changes true → false (unblocked)
    if (before.isBlocked === true && after.isBlocked === false && after.isApproved === true) {
      const fcmToken = after.fcmToken;
      if (!fcmToken) return;
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

    // Trigger when user is assigned a plan / renewed (isApproved remains true, but planId or endDate changes)
    if (before.isApproved === true && after.isApproved === true) {
      const planChanged = before.planId !== after.planId;
      const subExtended = (after.subscriptionEnd && before.subscriptionEnd && after.subscriptionEnd.toMillis() > before.subscriptionEnd.toMillis());
      
      if (planChanged || subExtended) {
        const fcmToken = after.fcmToken;
        if (fcmToken) {
          const subEnd = after.subscriptionEnd?.toDate();
          const subEndStr = subEnd ? `${subEnd.getDate()} ${_monthName(subEnd.getMonth())} ${subEnd.getFullYear()}` : 'N/A';
          try {
            await getMessaging().send({
              token: fcmToken,
              notification: {
                title: '🎉 Plan Assigned & Renewed',
                body: `Your plan has been updated to "${after.planName || 'New Plan'}". Valid until ${subEndStr}.`,
              },
              data: { type: 'plan_assigned' },
              android: { priority: 'high' },
            });
          } catch (_) { }
        }
      }
    }

    // Trigger when isBlocked changes false → true (suspended)
    if (before.isBlocked === false && after.isBlocked === true) {
      const fcmToken = after.fcmToken;
      if (!fcmToken) return;
      try {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title: '🚫 Account Suspended',
            body: 'Your ReplyMate account has been suspended by the admin. Auto-reply services are paused.',
          },
          data: { type: 'account_suspended' },
          android: { priority: 'high' },
        });
      } catch (_) { }
    }

    // Update global stats on any approval change
    await _updateGlobalStats();
  }
);

// ─── 4. ON NEW USER REGISTERED — Notify broker ─────────────────────────────────
// Triggered when a new document is created in 'users' collection.

exports.onBrokerUserRegistered = onDocumentCreated(
  { document: 'users/{userId}', region: 'asia-south1' },
  async (event) => {
    const data = event.data.data();
    const brokerId = data.brokerId;
    if (!brokerId) return; // Direct (no broker) registration — skip

    try {
      // Get broker's portal account to find their FCM token
      const brokerPortalDoc = await db.collection('admin_users').doc(brokerId).get();
      const fcmToken = brokerPortalDoc.data()?.fcmToken;
      if (!fcmToken) return;

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
    } catch (e) {
      logger.warn(`onBrokerUserRegistered FCM failed: ${e.message}`);
    }

    // Update global stats
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
