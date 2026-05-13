const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const fieldValue = admin.firestore.FieldValue;

exports.detectMutualSignal = functions.firestore
  .document('signals/{signalId}')
  .onCreate(async (snapshot) => {
    const signal = snapshot.data();
    if (!signal || signal.status !== 'pending') return null;

    const { senderId, receiverId } = signal;
    if (!senderId || !receiverId || senderId === receiverId) return null;

    const reciprocal = await db
      .collection('signals')
      .where('senderId', '==', receiverId)
      .where('receiverId', '==', senderId)
      .where('status', '==', 'pending')
      .limit(1)
      .get();

    if (reciprocal.empty) return null;

    return createMatchFromSignals({
      signalRef: snapshot.ref,
      reciprocalRef: reciprocal.docs[0].ref,
      senderId,
      receiverId,
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

    return createMatchFromSignals({
      signalRef: change.after.ref,
      reciprocalRef: null,
      senderId: after.senderId,
      receiverId: after.receiverId,
      interactionInitiatorId: after.receiverId,
    });
  });

exports.cleanupExpiredSignals = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const expired = await db
      .collection('signals')
      .where('status', '==', 'pending')
      .where('expiresAt', '<=', now)
      .limit(500)
      .get();

    if (expired.empty) return null;

    const batch = db.batch();
    expired.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'expired',
        updatedAt: fieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
    return null;
  });

async function createMatchFromSignals({
  signalRef,
  reciprocalRef,
  senderId,
  receiverId,
  interactionInitiatorId,
}) {
  const [user1Id, user2Id] = [senderId, receiverId].sort();
  const matchId = `${user1Id}_${user2Id}`;
  const matchRef = db.collection('matches').doc(matchId);

  await db.runTransaction(async (transaction) => {
    const matchSnapshot = await transaction.get(matchRef);
    if (matchSnapshot.exists && matchSnapshot.data().status === 'active') {
      return;
    }

    transaction.set(matchRef, {
      user1Id,
      user2Id,
      status: 'active',
      participants: [user1Id, user2Id],
      archivedBy: [],
      interactionType: null,
      interactionInitiatorId,
      conversationId: null,
      createdAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.update(signalRef, {
      status: 'accepted',
      respondedAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    });

    if (reciprocalRef) {
      transaction.update(reciprocalRef, {
        status: 'accepted',
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

async function sendMatchNotification(userId, matchedUserId, matchId) {
  const userDoc = await db.collection('users').doc(userId).get();
  const token = userDoc.data()?.fcmToken;
  if (!token) return;

  const matchedDoc = await db.collection('users').doc(matchedUserId).get();
  const matchedName = matchedDoc.data()?.displayName || 'Someone nearby';

  await admin.messaging().send({
    token,
    notification: {
      title: 'New Nearo match',
      body: `You matched with ${matchedName}.`,
    },
    data: {
      type: 'match',
      matchId,
    },
  });
}
