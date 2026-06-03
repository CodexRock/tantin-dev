const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

const projectId = 'tantin-rules-test';
let testEnv;

jest.setTimeout(30000);

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({ projectId });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

function db(uid) {
  return uid === null
    ? testEnv.unauthenticatedContext().firestore()
    : testEnv.authenticatedContext(uid).firestore();
}

async function seedFirestore() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await Promise.all([
      setDoc(doc(adminDb, 'users/admin'), user('Admin')),
      setDoc(doc(adminDb, 'users/payer'), user('Payer')),
      setDoc(doc(adminDb, 'users/recipient'), user('Recipient')),
      setDoc(doc(adminDb, 'users/outsider'), user('Outsider')),
      setDoc(doc(adminDb, 'darets/d1'), {
        nom: 'Daret Famille',
        cover: 'home',
        accent: '#5247E6',
        montant: 1500,
        frequence: 'Mensuel',
        periodesCount: 3,
        cagnotteParPeriode: 4500,
        statut: 'actif',
        adminUid: 'admin',
        memberUids: ['admin', 'payer', 'recipient'],
        currentPeriode: 1,
        settings: { echeanceDay: 5, graceDays: 2 },
      }),
      setDoc(doc(adminDb, 'darets/draft'), {
        nom: 'Brouillon',
        cover: 'draft',
        accent: '#5247E6',
        montant: 1000,
        frequence: 'Mensuel',
        periodesCount: 2,
        cagnotteParPeriode: 2000,
        statut: 'brouillon',
        adminUid: 'admin',
        memberUids: ['admin'],
        currentPeriode: 0,
        settings: { echeanceDay: 5, graceDays: 2 },
      }),
      setDoc(doc(adminDb, 'darets/d1/members/admin'), member('admin', 'admin')),
      setDoc(doc(adminDb, 'darets/d1/members/payer'), member('payer')),
      setDoc(
        doc(adminDb, 'darets/d1/members/recipient'),
        member('recipient'),
      ),
      setDoc(doc(adminDb, 'darets/d1/periods/01'), {
        index: 1,
        recipientUids: ['recipient'],
        shares: { recipient: 100 },
        scheduledDate: new Date('2026-06-05T00:00:00Z'),
        potAmount: 4500,
        status: 'current',
        paidCount: 0,
        totalCount: 2,
      }),
      setDoc(doc(adminDb, 'darets/d1/periods/01/contributions/payer'), {
        payerUid: 'payer',
        state: 'apayer',
        amount: 1500,
      }),
      setDoc(doc(adminDb, 'darets/d1/periods/01/contributions/admin'), {
        payerUid: 'admin',
        state: 'attente',
        amount: 1500,
      }),
      setDoc(doc(adminDb, 'darets/d1/activity/a1'), {
        type: 'demarre',
        actorUid: 'admin',
        text: 'Daret demarre',
        createdAt: new Date('2026-06-01T00:00:00Z'),
      }),
      setDoc(doc(adminDb, 'invites/TANTIN-TEST'), {
        daretId: 'd1',
        createdByUid: 'admin',
        active: true,
        expiresAt: new Date('2026-07-01T00:00:00Z'),
      }),
      setDoc(doc(adminDb, 'notifications/payer/items/n1'), {
        icon: 'bell',
        text: 'Payez votre part',
        unread: true,
        createdAt: new Date('2026-06-02T00:00:00Z'),
      }),
    ]);
  });
}

function user(name) {
  return {
    prenom: name,
    nom: 'Test',
    name: `${name} Test`,
    initials: `${name[0]}T`,
    phone: '+212600000000',
    avatarPalette: ['#5247E6', '#E7E5FB'],
    settings: {
      defaultEcheanceDay: 5,
      graceDays: 2,
      lang: 'fr',
      notifPrefs: { contributions: true, reminders: true, turns: true },
    },
    stats: { daretsActifs: 0, totalRecuVie: 0 },
  };
}

function member(uid, role = 'member') {
  return {
    uid,
    role,
    approvalStatus: 'pending',
    name: `${uid} Test`,
    prenom: uid,
    initials: uid.slice(0, 2).toUpperCase(),
    avatarPalette: ['#5247E6', '#E7E5FB'],
  };
}

describe('users', () => {
  test('a user can read self but cannot read another profile', async () => {
    await assertSucceeds(getDoc(doc(db('payer'), 'users/payer')));
    await assertFails(getDoc(doc(db('outsider'), 'users/payer')));
  });

  test('a user can update settings but cannot forge stats', async () => {
    await assertSucceeds(
      updateDoc(doc(db('payer'), 'users/payer'), {
        settings: {
          defaultEcheanceDay: 7,
          graceDays: 2,
          lang: 'fr',
          notifPrefs: { contributions: true, reminders: true, turns: true },
        },
      }),
    );
    await assertFails(
      updateDoc(doc(db('payer'), 'users/payer'), {
        stats: { daretsActifs: 99, totalRecuVie: 999999 },
      }),
    );
  });

  test('a user cannot create a profile with server-owned stats', async () => {
    await assertFails(
      setDoc(doc(db('new-user'), 'users/new-user'), user('Forged')),
    );
  });
});

describe('darets', () => {
  test('a member can read a daret but an outsider cannot', async () => {
    await assertSucceeds(getDoc(doc(db('payer'), 'darets/d1')));
    await assertFails(getDoc(doc(db('outsider'), 'darets/d1')));
  });

  test('a member can LIST darets filtered by memberUids; broad list denied', async () => {
    // This mirrors the app's myDarets query and would have caught the
    // get()-based read rule that broke list queries (PERMISSION_DENIED).
    await assertSucceeds(
      getDocs(
        query(
          collection(db('payer'), 'darets'),
          where('memberUids', 'array-contains', 'payer'),
        ),
      ),
    );
    await assertFails(getDocs(collection(db('payer'), 'darets')));
  });

  test('creator can create a strict draft but cannot forge members', async () => {
    const validDraft = {
      nom: 'Nouveau',
      cover: 'star',
      accent: '#5247E6',
      montant: 1000,
      frequence: 'Mensuel',
      periodesCount: 2,
      cagnotteParPeriode: 2000,
      statut: 'brouillon',
      adminUid: 'payer',
      memberUids: ['payer'],
      currentPeriode: 0,
      settings: { echeanceDay: 5, graceDays: 2 },
    };
    await assertSucceeds(setDoc(doc(db('payer'), 'darets/new'), validDraft));
    await assertFails(
      setDoc(doc(db('payer'), 'darets/forged'), {
        ...validDraft,
        memberUids: ['payer', 'outsider'],
      }),
    );
  });

  test('draft admin can edit description but not integrity fields', async () => {
    await assertSucceeds(
      updateDoc(doc(db('admin'), 'darets/draft'), { nom: 'Nouveau nom' }),
    );
    await assertFails(
      updateDoc(doc(db('admin'), 'darets/draft'), {
        statut: 'actif',
        currentPeriode: 1,
      }),
    );
  });
});

describe('members and periods', () => {
  test('member can approve self but cannot change role', async () => {
    const payerMember = doc(db('payer'), 'darets/d1/members/payer');
    await assertSucceeds(updateDoc(payerMember, { approvalStatus: 'approved' }));
    await assertFails(updateDoc(payerMember, { role: 'admin' }));
  });

  test('nested server-owned documents cannot be client-created', async () => {
    await assertFails(
      setDoc(doc(db('admin'), 'darets/d1/members/forged'), member('forged')),
    );
    await assertFails(
      setDoc(doc(db('admin'), 'darets/d1/periods/02'), {
        index: 2,
        recipientUids: ['payer'],
        shares: { payer: 100 },
        scheduledDate: new Date('2026-07-05T00:00:00Z'),
        potAmount: 4500,
        status: 'upcoming',
        paidCount: 0,
        totalCount: 2,
      }),
    );
    await assertFails(
      setDoc(doc(db('admin'), 'darets/d1/periods/01/contributions/forged'), {
        payerUid: 'forged',
        state: 'apayer',
        amount: 1500,
      }),
    );
  });

  test('periods are readable by members and never client-updatable', async () => {
    const payerPeriod = doc(db('payer'), 'darets/d1/periods/01');
    await assertSucceeds(getDoc(payerPeriod));
    await assertFails(updateDoc(payerPeriod, { status: 'closed' }));
    await assertFails(getDoc(doc(db('outsider'), 'darets/d1/periods/01')));
  });
});

describe('contributions', () => {
  test('payer can declare only own contribution paid', async () => {
    await assertSucceeds(
      updateDoc(doc(db('payer'), 'darets/d1/periods/01/contributions/payer'), {
        state: 'attente',
        paidDeclaredAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('recipient'), 'darets/d1/periods/01/contributions/payer'), {
        state: 'attente',
        paidDeclaredAt: serverTimestamp(),
      }),
    );
  });

  test('payer cannot mutate amount while declaring paid', async () => {
    await assertFails(
      updateDoc(doc(db('payer'), 'darets/d1/periods/01/contributions/payer'), {
        state: 'attente',
        amount: 1,
        paidDeclaredAt: serverTimestamp(),
      }),
    );
  });

  test('recipient can confirm waiting contribution but not direct-confirm', async () => {
    await assertSucceeds(
      updateDoc(doc(db('recipient'), 'darets/d1/periods/01/contributions/admin'), {
        state: 'confirme',
        confirmedAt: serverTimestamp(),
        confirmedByUid: 'recipient',
      }),
    );
    await assertFails(
      updateDoc(doc(db('recipient'), 'darets/d1/periods/01/contributions/payer'), {
        state: 'confirme',
        confirmedAt: serverTimestamp(),
        confirmedByUid: 'recipient',
      }),
    );
  });

  test('admin can direct-confirm on behalf but ordinary member cannot', async () => {
    await assertSucceeds(
      updateDoc(doc(db('admin'), 'darets/d1/periods/01/contributions/payer'), {
        state: 'confirme',
        confirmedAt: serverTimestamp(),
        confirmedByUid: 'admin',
      }),
    );
    await assertFails(
      updateDoc(doc(db('payer'), 'darets/d1/periods/01/contributions/admin'), {
        state: 'confirme',
        confirmedAt: serverTimestamp(),
        confirmedByUid: 'payer',
      }),
    );
  });
});

describe('server-owned feeds and invites', () => {
  test('activity is member-readable and never client writable', async () => {
    await assertSucceeds(getDoc(doc(db('payer'), 'darets/d1/activity/a1')));
    await assertFails(
      setDoc(doc(db('payer'), 'darets/d1/activity/forged'), {
        type: 'paiement',
        actorUid: 'payer',
        text: 'Forged',
      }),
    );
  });

  test('invite can be read only by authenticated callers and never written', async () => {
    await assertSucceeds(getDoc(doc(db('payer'), 'invites/TANTIN-TEST')));
    await assertFails(getDoc(doc(db(null), 'invites/TANTIN-TEST')));
    await assertFails(
      updateDoc(doc(db('admin'), 'invites/TANTIN-TEST'), { active: false }),
    );
  });

  test('notification owner can read and toggle unread only', async () => {
    const ownNotification = doc(db('payer'), 'notifications/payer/items/n1');
    await assertSucceeds(getDoc(ownNotification));
    await assertSucceeds(updateDoc(ownNotification, { unread: false }));
    await assertFails(
      updateDoc(ownNotification, { text: 'Forged notification' }),
    );
    await assertFails(
      getDoc(doc(db('outsider'), 'notifications/payer/items/n1')),
    );
  });
});
