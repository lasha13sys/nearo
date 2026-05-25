const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');

admin.initializeApp();
const db = admin.firestore();
const fieldValue = FieldValue;

exports.detectMutualSignal = functions.firestore
  .document('signals/{signalId}')
  .onCreate(async (snapshot) => {
    const signal = snapshot.data();
    if (!signal || signal.status !== 'pending') return null;
    if (isExpired(signal)) {
      await snapshot.ref.update({ status: 'expired', updatedAt: fieldValue.serverTimestamp() });
      return null;
    }

    const { senderId, receiverId } = signal;
    if (!senderId || !receiverId || senderId === receiverId) return null;

    const allowed = await interactionAllowed(senderId, receiverId);
    if (!allowed) {
      await snapshot.ref.update({ status: 'blocked', updatedAt: fieldValue.serverTimestamp() });
      return null;
    }

    await db.collection('users').doc(senderId).update({
      signalsSent: fieldValue.increment(1),
      lastSignalAt: fieldValue.serverTimestamp(),
    });

    const reciprocal = await db
      .collection('signals')
      .where('senderId', '==', receiverId)
      .where('receiverId', '==', senderId)
      .where('status', '==', 'pending')
      .limit(1)
      .get();

    if (reciprocal.empty) return null;
    const reciprocalDoc = reciprocal.docs[0];
    if (isExpired(reciprocalDoc.data())) return null;

    return createMatchBundle({
      signalRef: snapshot.ref,
      reciprocalRef: reciprocalDoc.ref,
      senderId,
      receiverId,
      venueId: signal.venueId || null,
      venueWifiHash: signal.venueWifiHash || null,
      interactionInitiatorId: null,
    });
  });

exports.handleSignalAcceptance = functions.firestore
  .document('signals/{signalId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;
    if (before.status !== 'pending' || after.status !== 'accepted') return null;
    if (isExpired(after)) {
      await change.after.ref.update({ status: 'expired', updatedAt: fieldValue.serverTimestamp() });
      return null;
    }

    const allowed = await interactionAllowed(after.senderId, after.receiverId);
    if (!allowed) {
      await change.after.ref.update({ status: 'blocked', updatedAt: fieldValue.serverTimestamp() });
      return null;
    }

    return createMatchBundle({
      signalRef: change.after.ref,
      reciprocalRef: null,
      senderId: after.senderId,
      receiverId: after.receiverId,
      venueId: after.venueId || null,
      venueWifiHash: after.venueWifiHash || null,
      interactionInitiatorId: after.receiverId,
    });
  });

exports.copyApprovedContactReveal = functions.firestore
  .document('contactReveals/{revealId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return null;
    if (before.status === 'approved' || after.status !== 'approved') return null;
    if (isExpired(after)) {
      return change.after.ref.update({ status: 'expired', updatedAt: fieldValue.serverTimestamp() });
    }

    const receiverContact = await db
      .collection('users')
      .doc(after.receiverId)
      .collection('private')
      .doc('contact')
      .get();

    const value = contactValue(receiverContact.data(), after.contactType);
    if (!value) {
      return change.after.ref.update({
        status: 'declined',
        updatedAt: fieldValue.serverTimestamp(),
      });
    }

    return change.after.ref.update({
      revealedValue: value,
      approvedAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    });
  });

exports.cleanupExpiredSignalsAndReveals = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async () => {
  const now = Timestamp.now();
    const [expiredSignals, expiredReveals] = await Promise.all([
      db.collection('signals').where('status', '==', 'pending').where('expiresAt', '<=', now).limit(500).get(),
      db.collection('contactReveals').where('status', '==', 'requested').where('expiresAt', '<=', now).limit(500).get(),
    ]);

    const batch = db.batch();
    expiredSignals.docs.forEach((doc) => batch.update(doc.ref, {
      status: 'expired',
      updatedAt: fieldValue.serverTimestamp(),
    }));
    expiredReveals.docs.forEach((doc) => batch.update(doc.ref, {
      status: 'expired',
      updatedAt: fieldValue.serverTimestamp(),
    }));
    if (expiredSignals.empty && expiredReveals.empty) return null;
    await batch.commit();
    return null;
  });

async function createMatchBundle({
  signalRef,
  reciprocalRef,
  senderId,
  receiverId,
  venueId,
  venueWifiHash,
  interactionInitiatorId,
}) {
  const userIds = [senderId, receiverId].sort();
  const matchId = `${userIds[0]}_${userIds[1]}`;
  const matchRef = db.collection('matches').doc(matchId);
  const connectionRef = db.collection('connections').doc(matchId);
  const conversationRef = db.collection('conversations').doc(matchId);
  const expiresAt = Timestamp.fromDate(new Date(Date.now() + 2 * 60 * 60 * 1000));

  await db.runTransaction(async (transaction) => {
    const matchSnapshot = await transaction.get(matchRef);
    if (matchSnapshot.exists && matchSnapshot.data().status === 'active') return;

    transaction.set(matchRef, {
      userIds,
      user1Id: userIds[0],
      user2Id: userIds[1],
      status: 'active',
      conversationId: conversationRef.id,
      connectionId: connectionRef.id,
      venueId,
      venueWifiHash,
      interactionInitiatorId,
      expiresAt,
      lastInteractionAt: fieldValue.serverTimestamp(),
      createdAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(connectionRef, {
      matchId,
      userIds,
      status: 'active',
      selectedOptions: [],
      interactionInitiatorId,
      temporaryTimerEndsAt: null,
      expiresAt,
      createdAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(conversationRef, {
      matchId,
      userIds,
      participants: userIds,
      venueId,
      createdAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
      lastMessage: null,
      lastMessageAt: null,
    }, { merge: true });

    transaction.update(signalRef, {
      status: 'matched',
      respondedAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    });

    if (reciprocalRef) {
      transaction.update(reciprocalRef, {
        status: 'matched',
        respondedAt: fieldValue.serverTimestamp(),
        updatedAt: fieldValue.serverTimestamp(),
      });
    }

    transaction.update(db.collection('users').doc(senderId), {
      matchesCount: fieldValue.increment(1),
    });
    transaction.update(db.collection('users').doc(receiverId), {
      matchesCount: fieldValue.increment(1),
    });
  });

  await Promise.all([
    sendMatchNotification(senderId, receiverId, matchId),
    sendMatchNotification(receiverId, senderId, matchId),
  ]);
}

async function interactionAllowed(userA, userB) {
  const [a, b, aBlockedB, bBlockedA] = await Promise.all([
    db.collection('users').doc(userA).get(),
    db.collection('users').doc(userB).get(),
    db.collection('blocks').doc(`${userA}_${userB}`).get(),
    db.collection('blocks').doc(`${userB}_${userA}`).get(),
  ]);
  if (!a.exists || !b.exists) return false;
  const aData = a.data();
  const bData = b.data();
  if (aData.isBanned === true || bData.isBanned === true) return false;
  if (bData.visible !== true) return false;
  return !aBlockedB.exists && !bBlockedA.exists;
}

function isExpired(data) {
  if (!data.expiresAt) return false;
  return data.expiresAt.toMillis() <= Date.now();
}

function contactValue(data, type) {
  if (!data) return null;
  if (type === 'phone') return data.phoneNumber || null;
  const socials = data.socials || {};
  return socials[type] || null;
}

async function sendMatchNotification(userId, matchedUserId, matchId) {
  const notificationDoc = await db
    .collection('users')
    .doc(userId)
    .collection('private')
    .doc('notification')
    .get();
  const token = notificationDoc.data()?.fcmToken;
  if (!token) return;

  const matchedDoc = await db.collection('users').doc(matchedUserId).get();
  const matchedName = matchedDoc.data()?.nickname || 'Someone nearby';

  await admin.messaging().send({
    token,
    notification: {
      title: 'New Nearo match',
      body: `You matched with ${matchedName}. Choose how to start.`,
    },
    data: {
      type: 'match',
      matchId,
    },
  });
}
