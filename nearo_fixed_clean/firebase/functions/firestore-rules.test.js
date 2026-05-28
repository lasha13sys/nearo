const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} = require('firebase/firestore');

const projectId = process.env.GCLOUD_PROJECT || 'nearo-demo';
const rulesPath = path.resolve(__dirname, '../firestore.rules');

let testEnv;

async function main() {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
    },
  });

  await testEnv.clearFirestore();

  const tests = [
    ['auth is required for public profile reads', authIsRequiredForProfileReads],
    ['user profile writes cannot expose private fields', userProfilePrivateFieldsAreBlocked],
    ['private contact docs are self-only', privateContactDocsAreSelfOnly],
    ['signal permissions enforce sender and receiver roles', signalPermissionsEnforceRoles],
    ['matches and conversations are participant-only', matchAndConversationRulesAreParticipantOnly],
    ['contact reveal is mutual-only and approval is receiver-only', contactRevealRulesAreMutualOnly],
    ['blocks and reports are constrained', blockAndReportRulesAreConstrained],
  ];

  for (const [name, test] of tests) {
    await testEnv.clearFirestore();
    await test();
    console.log(`✓ ${name}`);
  }

  await testEnv.cleanup();
}

async function authIsRequiredForProfileReads() {
  await seedUser('alice');

  await assertFails(getDoc(doc(unauthDb(), 'users/alice')));
  await assertSucceeds(getDoc(doc(userDb('bob'), 'users/alice')));
}

async function userProfilePrivateFieldsAreBlocked() {
  const alice = userDb('alice');
  const profile = publicProfile('alice');

  await assertSucceeds(setDoc(doc(alice, 'users/alice'), profile));
  await assertFails(setDoc(doc(alice, 'users/bob'), publicProfile('bob')));
  await assertFails(setDoc(doc(alice, 'users/alice-private'), {
    ...publicProfile('alice-private'),
    phoneNumber: '+995555000000',
  }));
  await assertFails(setDoc(doc(alice, 'users/alice-blocked'), {
    ...publicProfile('alice-blocked'),
    blockedUsers: ['bob'],
  }));
  await assertFails(setDoc(doc(alice, 'users/alice-underage'), {
    ...publicProfile('alice-underage'),
    age: 17,
  }));

  await assertSucceeds(updateDoc(doc(alice, 'users/alice'), {
    visible: false,
    phoneNumber: '',
    socials: {},
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(alice, 'users/alice'), {
    matchesCount: 10,
    phoneNumber: '',
    socials: {},
    updatedAt: serverTimestamp(),
  }));
}

async function privateContactDocsAreSelfOnly() {
  await seedUser('alice');
  const aliceContact = doc(userDb('alice'), 'users/alice/private/contact');

  await assertSucceeds(setDoc(aliceContact, {
    phoneNumber: '+995555000000',
    socials: { instagram: 'alice' },
  }));
  await assertSucceeds(getDoc(aliceContact));
  await assertFails(getDoc(doc(userDb('bob'), 'users/alice/private/contact')));
  await assertFails(setDoc(doc(userDb('bob'), 'users/alice/private/contact'), {
    phoneNumber: '+995555111111',
  }));
}

async function signalPermissionsEnforceRoles() {
  await Promise.all([seedUser('alice'), seedUser('bob')]);
  const expiresAt = Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000));

  await assertSucceeds(setDoc(doc(userDb('alice'), 'signals/alice_to_bob'), {
    senderId: 'alice',
    receiverId: 'bob',
    status: 'pending',
    createdAt: Timestamp.now(),
    expiresAt,
  }));
  await assertFails(setDoc(doc(userDb('mallory'), 'signals/fake'), {
    senderId: 'alice',
    receiverId: 'bob',
    status: 'pending',
    createdAt: Timestamp.now(),
    expiresAt,
  }));
  await assertSucceeds(updateDoc(doc(userDb('bob'), 'signals/alice_to_bob'), {
    status: 'accepted',
    respondedAt: serverTimestamp(),
  }));

  await adminSet('signals/expired_signal', {
    senderId: 'alice',
    receiverId: 'bob',
    status: 'pending',
    createdAt: Timestamp.fromDate(new Date(Date.now() - 60 * 60 * 1000)),
    expiresAt: Timestamp.fromDate(new Date(Date.now() - 30 * 60 * 1000)),
  });
  await assertSucceeds(updateDoc(doc(userDb('alice'), 'signals/expired_signal'), {
    status: 'expired',
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(userDb('bob'), 'signals/expired_signal'), {
    status: 'expired',
    updatedAt: serverTimestamp(),
  }));
}

async function matchAndConversationRulesAreParticipantOnly() {
  await seedMatchBundle('alice', 'bob');

  await assertSucceeds(getDoc(doc(userDb('alice'), 'matches/alice_bob')));
  await assertFails(getDoc(doc(userDb('mallory'), 'matches/alice_bob')));
  await assertFails(setDoc(doc(userDb('alice'), 'matches/evil'), {
    userIds: ['alice', 'mallory'],
    status: 'active',
  }));

  await assertSucceeds(getDoc(doc(userDb('bob'), 'conversations/alice_bob')));
  await assertFails(getDoc(doc(userDb('mallory'), 'conversations/alice_bob')));
  await assertSucceeds(setDoc(doc(userDb('alice'), 'conversations/alice_bob/messages/msg1'), {
    senderId: 'alice',
    text: 'Coffee?',
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(userDb('alice'), 'conversations/alice_bob/messages/msg2'), {
    senderId: 'bob',
    text: 'Impersonation',
    createdAt: serverTimestamp(),
  }));
}

async function contactRevealRulesAreMutualOnly() {
  await seedMatchBundle('alice', 'bob');
  const reveal = {
    matchId: 'alice_bob',
    requesterId: 'alice',
    receiverId: 'bob',
    contactType: 'instagram',
    status: 'requested',
    createdAt: Timestamp.now(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 2 * 60 * 60 * 1000)),
  };

  await assertSucceeds(setDoc(doc(userDb('alice'), 'contactReveals/alice_bob_instagram'), reveal));
  await assertFails(setDoc(doc(userDb('alice'), 'contactReveals/alice_mallory'), {
    ...reveal,
    receiverId: 'mallory',
  }));
  await assertFails(setDoc(doc(userDb('alice'), 'contactReveals/unsafe'), {
    ...reveal,
    revealedValue: 'alice',
  }));
  await assertFails(updateDoc(doc(userDb('alice'), 'contactReveals/alice_bob_instagram'), {
    status: 'approved',
    respondedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(doc(userDb('bob'), 'contactReveals/alice_bob_instagram'), {
    status: 'approved',
    respondedAt: serverTimestamp(),
  }));
}

async function blockAndReportRulesAreConstrained() {
  await assertSucceeds(setDoc(doc(userDb('alice'), 'blocks/alice_bob'), {
    blockerId: 'alice',
    blockedUserId: 'bob',
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(userDb('alice'), 'blocks/wrong_id'), {
    blockerId: 'alice',
    blockedUserId: 'bob',
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(userDb('alice'), 'blocks/alice_alice'), {
    blockerId: 'alice',
    blockedUserId: 'alice',
    createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(doc(userDb('alice'), 'blocks/alice_bob')));
  await assertFails(getDoc(doc(userDb('bob'), 'blocks/alice_bob')));

  await assertSucceeds(setDoc(doc(userDb('alice'), 'reports/report1'), {
    reporterId: 'alice',
    reportedUserId: 'bob',
    reason: 'safety_concern',
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(userDb('alice'), 'reports/report2'), {
    reporterId: 'bob',
    reportedUserId: 'alice',
    reason: 'fake_reporter',
    createdAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(userDb('alice'), 'reports/report1')));
}

function publicProfile(uid) {
  return {
    nickname: uid,
    photoUrl: 'https://example.com/profile.jpg',
    age: 24,
    bio: 'Rules test user',
    mood: 'Open to connect',
    visible: true,
    wifiHash: 'rules-wifi-hash',
    phoneNumber: '',
    socials: {},
    isBanned: false,
    isVerified: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

async function seedUser(uid) {
  await adminSet(`users/${uid}`, publicProfile(uid));
}

async function seedMatchBundle(userA, userB) {
  await Promise.all([seedUser(userA), seedUser(userB)]);
  await adminSet('matches/alice_bob', {
    userIds: [userA, userB],
    user1Id: userA,
    user2Id: userB,
    status: 'active',
    conversationId: 'alice_bob',
    connectionId: 'alice_bob',
    createdAt: serverTimestamp(),
  });
  await adminSet('conversations/alice_bob', {
    matchId: 'alice_bob',
    userIds: [userA, userB],
    participants: [userA, userB],
    createdAt: serverTimestamp(),
  });
}

async function adminSet(documentPath, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), documentPath), data);
  });
}

function userDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthDb() {
  return testEnv.unauthenticatedContext().firestore();
}

main()
  .then(async () => {
    if (testEnv) await testEnv.cleanup();
    console.log('Firestore rules unit tests passed.');
    process.exit(0);
  })
  .catch(async (error) => {
    if (testEnv) await testEnv.cleanup();
    console.error(error);
    process.exit(1);
  });
