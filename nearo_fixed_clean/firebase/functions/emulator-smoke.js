const admin = require('firebase-admin');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');

const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_CONFIG_PROJECT || 'nearo-demo';

if (!admin.apps.length) {
  admin.initializeApp({ projectId });
}

const db = admin.firestore();
const fieldValue = FieldValue;

async function main() {
  const runId = `smoke_${Date.now()}`;
  const userA = `${runId}_a`;
  const userB = `${runId}_b`;
  const matchId = [userA, userB].sort().join('_');
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000));

  await Promise.all([
    seedUser(userA, 'Smoke A'),
    seedUser(userB, 'Smoke B'),
  ]);

  await db.collection('signals').doc(`${runId}_a_to_b`).set({
    senderId: userA,
    receiverId: userB,
    status: 'pending',
    venueWifiHash: 'smoke-wifi-hash',
    createdAt: now,
    expiresAt,
    cooldownUntil: Timestamp.fromDate(new Date(Date.now() + 5 * 60 * 1000)),
    updatedAt: now,
  });

  await db.collection('signals').doc(`${runId}_b_to_a`).set({
    senderId: userB,
    receiverId: userA,
    status: 'pending',
    venueWifiHash: 'smoke-wifi-hash',
    createdAt: now,
    expiresAt,
    cooldownUntil: Timestamp.fromDate(new Date(Date.now() + 5 * 60 * 1000)),
    updatedAt: now,
  });

  const match = await waitForDoc(`matches/${matchId}`, (data) => data.status === 'active');
  assert(match.conversationId === matchId, 'match conversationId should be deterministic');
  assert(match.connectionId === matchId, 'match connectionId should be deterministic');

  const connection = await waitForDoc(`connections/${matchId}`, (data) => data.status === 'active');
  assert(Array.isArray(connection.userIds) && connection.userIds.length === 2, 'connection should include both users');

  const conversation = await waitForDoc(`conversations/${matchId}`, (data) => data.matchId === matchId);
  assert(Array.isArray(conversation.userIds) && conversation.userIds.length === 2, 'conversation should include both users');

  const revealRef = db.collection('contactReveals').doc(`${runId}_reveal`);
  await revealRef.set({
    matchId,
    requesterId: userA,
    receiverId: userB,
    contactType: 'instagram',
    status: 'requested',
    createdAt: fieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 2 * 60 * 60 * 1000)),
  });
  await revealRef.update({
    status: 'approved',
    respondedAt: fieldValue.serverTimestamp(),
  });

  const reveal = await waitForDoc(`contactReveals/${revealRef.id}`, (data) => data.revealedValue === 'smoke.b');
  assert(reveal.status === 'approved', 'approved reveal should stay approved');

  console.log(`Nearo emulator smoke passed: ${matchId}`);
}

async function seedUser(uid, nickname) {
  await db.collection('users').doc(uid).set({
    nickname,
    photoUrl: 'https://example.com/profile.jpg',
    age: 24,
    bio: 'Smoke test user',
    mood: 'Open to connect',
    visible: true,
    wifiHash: 'smoke-wifi-hash',
    phoneNumber: '',
    socials: {},
    isBanned: false,
    isVerified: false,
    matchesCount: 0,
    signalsSent: 0,
    createdAt: fieldValue.serverTimestamp(),
    updatedAt: fieldValue.serverTimestamp(),
  });
  await db.collection('users').doc(uid).collection('private').doc('contact').set({
    phoneNumber: '+995555000000',
    socials: {
      instagram: uid.endsWith('_b') ? 'smoke.b' : 'smoke.a',
      telegram: uid.endsWith('_b') ? 'smoke_b' : 'smoke_a',
    },
    updatedAt: fieldValue.serverTimestamp(),
  });
}

async function waitForDoc(path, predicate, timeoutMs = 15000) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < timeoutMs) {
    const snapshot = await db.doc(path).get();
    const data = snapshot.data();
    if (snapshot.exists && data && predicate(data)) return data;
    await delay(250);
  }
  throw new Error(`Timed out waiting for ${path}`);
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
