import {CollectionReference, DocumentReference, Firestore, Timestamp, getFirestore} from 'firebase-admin/firestore';
import {HttpsError} from 'firebase-functions/v2/https';
import {__testables, parseCallable} from '../src/index';

const fixedNow = Timestamp.fromDate(new Date('2026-06-02T09:00:00Z'));
const db = getFirestore();

type CreateInviteDeps = Parameters<typeof __testables.createInviteHandler>[1];

jest.setTimeout(30000);

function deps(projectId = 'tantin-rules-test', code = 'TANTIN-7K2P'): CreateInviteDeps {
  return {
    db,
    now: () => fixedNow,
    randomCode: () => code,
    projectId,
  };
}

function ctx<T>(uid: string, data: T): {uid: string; appId: string; data: T} {
  return {uid, appId: 'test-app', data};
}

type PeriodAssignment = {
  index: number;
  recipientUids: string[];
  shares: Record<string, number>;
};

beforeAll(() => {
  if (process.env.FIRESTORE_EMULATOR_HOST === undefined) {
    throw new Error('FIRESTORE_EMULATOR_HOST must be set by firebase emulators:exec.');
  }
});

beforeEach(async () => {
  await clearFirestore(db);
});

describe('callable guards', () => {
  test('rejects missing auth and bad input; App Check not enforced in dev', () => {
    expectCode(
      () => parseCallable(__testables.schemas.daretIdInput, {data: {daretId: 'd1'}, app: {appId: 'app'}}),
      'unauthenticated',
    );
    // App Check enforcement is disabled in dev (re-enable before release): a
    // missing app context is allowed and parses successfully.
    expect(() =>
      parseCallable(__testables.schemas.daretIdInput, {data: {daretId: 'd1'}, auth: {uid: 'u1'}}),
    ).not.toThrow();
    expectCode(
      () =>
        parseCallable(__testables.schemas.daretIdInput, {
          data: {daretId: ''},
          auth: {uid: 'u1'},
          app: {appId: 'app'},
        }),
      'invalid-argument',
    );
  });
});

describe('invites and join flow', () => {
  test('createInvite writes an active server-shaped invite and is idempotent', async () => {
    await seedUser('admin', 'Admin');
    await seedDraftDaret('d1', ['admin'], 'admin', 1);

    const first = await __testables.createInviteHandler(ctx('admin', {daretId: 'd1'}), deps());
    const second = await __testables.createInviteHandler(ctx('admin', {daretId: 'd1'}), deps());

    expect(first.code).toBe('TANTIN-7K2P');
    expect(second.code).toBe('TANTIN-7K2P');
    const invite = await db.collection('invites').doc(first.code).get();
    expect(invite.data()).toMatchObject({
      daretId: 'd1',
      createdByUid: 'admin',
      active: true,
    });
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.inviteCode).toBe('TANTIN-7K2P');
  });

  test('createInvite rejects non-admin callers', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('member', 'Member');
    await seedDraftDaret('d1', ['admin'], 'admin', 1);

    await expectCodeAsync(
      __testables.createInviteHandler(ctx('member', {daretId: 'd1'}), deps()),
      'permission-denied',
    );
  });

  test('previewDaret returns only a safe summary and rejects expired invites', async () => {
    await seedUser('admin', 'Admin');
    await seedDraftDaret('d1', ['admin'], 'admin', 2);
    await db.collection('invites').doc('TANTIN-OPEN').set({
      daretId: 'd1',
      createdByUid: 'admin',
      active: true,
      expiresAt: Timestamp.fromDate(new Date('2026-06-09T09:00:00Z')),
    });
    await db.collection('invites').doc('TANTIN-OLD1').set({
      daretId: 'd1',
      createdByUid: 'admin',
      active: true,
      expiresAt: Timestamp.fromDate(new Date('2026-05-01T09:00:00Z')),
    });

    const preview = await __testables.previewDaretHandler(ctx('joiner', {code: 'TANTIN-OPEN'}), deps());

    expect(preview).toMatchObject({
      daretId: 'd1',
      nom: 'Daret Test',
      montant: 1500,
      frequence: 'Mensuel',
      periodesCount: 2,
      membersCount: 1,
      statut: 'brouillon',
    });
    expect(preview).not.toHaveProperty('memberUids');
    await expectCodeAsync(
      __testables.previewDaretHandler(ctx('joiner', {code: 'TANTIN-OLD1'}), deps()),
      'failed-precondition',
    );
  });

  test('joinDaret validates invite expiry server-side and writes memberUids/member/activity', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('joiner', 'Joiner');
    await seedDraftDaret('d1', ['admin'], 'admin', 2);
    await db.collection('invites').doc('TANTIN-OPEN').set({
      daretId: 'd1',
      createdByUid: 'admin',
      active: true,
      expiresAt: Timestamp.fromDate(new Date('2026-06-09T09:00:00Z')),
    });

    const result = await __testables.joinDaretHandler(ctx('joiner', {code: 'TANTIN-OPEN'}), deps());

    expect(result).toEqual({daretId: 'd1', joined: true});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.memberUids).toEqual(['admin', 'joiner']);
    const member = await db.collection('darets').doc('d1').collection('members').doc('joiner').get();
    expect(member.data()).toMatchObject({
      uid: 'joiner',
      role: 'member',
      approvalStatus: 'pending',
      name: 'Joiner Test',
      prenom: 'Joiner',
      initials: 'JT',
    });
    const activity = await db.collection('darets').doc('d1').collection('activity').doc('member-joiner').get();
    expect(activity.data()).toMatchObject({type: 'membre', actorUid: 'joiner'});
  });

  test('joinDaret accepts a single-name user (empty nom)', async () => {
    // Regression: the profile setup allows an empty last name, so the client
    // writes `nom: ''`. readRequiredProfile used requireString('nom'), which
    // rejected empty strings and broke join with "nom must be a string".
    await seedUser('admin', 'Admin');
    await seedUser('joiner', 'Yasmine', '');
    await seedDraftDaret('d1', ['admin'], 'admin', 2);
    await db.collection('invites').doc('TANTIN-OPEN').set({
      daretId: 'd1',
      createdByUid: 'admin',
      active: true,
      expiresAt: Timestamp.fromDate(new Date('2026-06-09T09:00:00Z')),
    });

    const result = await __testables.joinDaretHandler(ctx('joiner', {code: 'TANTIN-OPEN'}), deps());

    expect(result).toEqual({daretId: 'd1', joined: true});
    const member = await db.collection('darets').doc('d1').collection('members').doc('joiner').get();
    expect(member.data()).toMatchObject({
      uid: 'joiner',
      prenom: 'Yasmine',
      name: 'Yasmine',
      initials: 'Y',
    });
  });

  test('joinDaret rejects inactive invites and full darets', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('joiner', 'Joiner');
    await seedDraftDaret('full', ['admin'], 'admin', 1);
    await db.collection('invites').doc('TANTIN-FULL').set({
      daretId: 'full',
      createdByUid: 'admin',
      active: true,
      expiresAt: Timestamp.fromDate(new Date('2026-06-09T09:00:00Z')),
    });
    await db.collection('invites').doc('TANTIN-OFF1').set({
      daretId: 'full',
      createdByUid: 'admin',
      active: false,
      expiresAt: Timestamp.fromDate(new Date('2026-06-09T09:00:00Z')),
    });

    await expectCodeAsync(
      __testables.joinDaretHandler(ctx('joiner', {code: 'TANTIN-OFF1'}), deps()),
      'failed-precondition',
    );
    await expectCodeAsync(
      __testables.joinDaretHandler(ctx('joiner', {code: 'TANTIN-FULL'}), deps()),
      'failed-precondition',
    );
  });
});

describe('daret state integrity', () => {
  test('startDaret generates periods and contribution docs in client/rules shapes', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('member', 'Member');
    await seedDraftDaret('d1', ['admin', 'member'], 'admin', 2, 'brouillon', 'approved');

    const result = await __testables.startDaretHandler(ctx('admin', {daretId: 'd1'}), deps());

    expect(result).toEqual({status: 'actif', currentPeriode: 1});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()).toMatchObject({
      statut: 'actif',
      currentPeriode: 1,
      memberUids: ['admin', 'member'],
    });
    const period = await db.collection('darets').doc('d1').collection('periods').doc('01').get();
    expect(period.data()).toMatchObject({
      index: 1,
      recipientUids: ['admin'],
      shares: {admin: 100},
      status: 'current',
      paidCount: 0,
      totalCount: 1,
    });
    const contribution = await period.ref.collection('contributions').doc('member').get();
    expect(contribution.data()).toMatchObject({
      payerUid: 'member',
      state: 'apayer',
      amount: 1500,
    });
  });

  test('startDaret expands S4 draft payload and joinDaret replaces a pending invite slot', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('joiner', 'Joiner');
    await seedS4DraftPayloadDaret('d1');

    const started = await __testables.startDaretHandler(ctx('admin', {daretId: 'd1'}), deps());

    expect(started).toEqual({status: 'attente', currentPeriode: 1});
    const startedDaret = await db.collection('darets').doc('d1').get();
    expect(startedDaret.data()).toMatchObject({
      statut: 'attente',
      currentPeriode: 1,
      memberUids: ['admin', 'pending_invite_1'],
      cagnotteParPeriode: 3000,
    });
    expect(startedDaret.data()).not.toHaveProperty('draftMembers');
    expect(startedDaret.data()).not.toHaveProperty('draftPeriods');
    const pendingMember = await db.collection('darets').doc('d1').collection('members').doc('pending_invite_1').get();
    expect(pendingMember.data()).toMatchObject({
      uid: 'pending_invite_1',
      approvalStatus: 'pending',
      name: 'Invitation 1',
    });
    expect(pendingMember.data()).not.toHaveProperty('phone');
    const pendingPeriod = await db.collection('darets').doc('d1').collection('periods').doc('02').get();
    expect(pendingPeriod.data()).toMatchObject({
      recipientUids: ['pending_invite_1'],
      shares: {pending_invite_1: 100},
      status: 'upcoming',
    });

    const invite = await __testables.createInviteHandler(ctx('admin', {daretId: 'd1'}), deps());
    const joined = await __testables.joinDaretHandler(ctx('joiner', {code: invite.code}), deps());

    expect(joined).toEqual({daretId: 'd1', joined: true});
    const joinedDaret = await db.collection('darets').doc('d1').get();
    expect(joinedDaret.data()?.memberUids).toEqual(['admin', 'joiner']);
    const removedPending = await db.collection('darets').doc('d1').collection('members').doc('pending_invite_1').get();
    expect(removedPending.exists).toBe(false);
    const joinedPeriod = await db.collection('darets').doc('d1').collection('periods').doc('02').get();
    expect(joinedPeriod.data()).toMatchObject({
      recipientUids: ['joiner'],
      shares: {joiner: 100},
    });

    const approved = await __testables.approveDaretHandler(ctx('joiner', {daretId: 'd1'}), deps());

    expect(approved).toEqual({activated: true});
    const activeDaret = await db.collection('darets').doc('d1').get();
    expect(activeDaret.data()?.statut).toBe('actif');
    const contribution = await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .doc('joiner')
      .get();
    expect(contribution.data()).toMatchObject({payerUid: 'joiner', state: 'apayer', amount: 1500});
  });

  test('startDaret treats grouped recipients as one share for contribution amounts', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('x', 'User X');
    await seedUser('y', 'User Y');
    await seedUser('solo', 'Solo');
    await seedS4GroupDraftPayloadDaret('d2');

    const started = await __testables.startDaretHandler(ctx('admin', {daretId: 'd2'}), deps());

    expect(started).toEqual({status: 'attente', currentPeriode: 1});
    const startedDaret = await db.collection('darets').doc('d2').get();
    expect(startedDaret.data()).toMatchObject({
      statut: 'attente',
      currentPeriode: 1,
      cagnotteParPeriode: 3000,
      memberUids: ['admin', 'x', 'y', 'solo'],
    });
    const groupPeriod = await db.collection('darets').doc('d2').collection('periods').doc('02').get();
    expect(groupPeriod.data()).toMatchObject({
      recipientUids: ['x', 'y'],
      shares: {x: 40, y: 60},
      potAmount: 2000,
    });

    await __testables.approveDaretHandler(ctx('x', {daretId: 'd2'}), deps());
    await __testables.approveDaretHandler(ctx('y', {daretId: 'd2'}), deps());
    const activated = await __testables.approveDaretHandler(ctx('solo', {daretId: 'd2'}), deps());

    expect(activated).toEqual({activated: true});
    const periodOneRef = db.collection('darets').doc('d2').collection('periods').doc('01');
    const periodOne = await periodOneRef.get();
    expect(periodOne.data()).toMatchObject({potAmount: 2000, totalCount: 3});
    await expectContributionAmount(periodOneRef, 'x', 400);
    await expectContributionAmount(periodOneRef, 'y', 600);
    await expectContributionAmount(periodOneRef, 'solo', 1000);
  });

  test('startDaret rejects malformed period shares', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('member', 'Member');
    await seedDraftDaret('d1', ['admin', 'member'], 'admin', 2, 'brouillon', 'approved');
    await db.collection('darets').doc('d1').collection('periods').doc('01').set({
      index: 1,
      recipientUids: ['admin'],
      shares: {admin: 50},
      scheduledDate: fixedNow,
      potAmount: 3000,
      status: 'upcoming',
      paidCount: 0,
      totalCount: 0,
    });
    await db.collection('darets').doc('d1').collection('periods').doc('02').set({
      index: 2,
      recipientUids: ['member'],
      shares: {member: 100},
      scheduledDate: Timestamp.fromDate(new Date('2026-07-02T09:00:00Z')),
      potAmount: 3000,
      status: 'upcoming',
      paidCount: 0,
      totalCount: 0,
    });

    await expectCodeAsync(
      __testables.startDaretHandler(ctx('admin', {daretId: 'd1'}), deps()),
      'failed-precondition',
    );
  });

  test('approveDaret activates only after all members approve and seeds current contributions', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('member', 'Member');
    await seedDraftDaret('d1', ['admin', 'member'], 'admin', 2, 'attente', 'pending');
    await db.collection('darets').doc('d1').update({currentPeriode: 1});
    await db.collection('darets').doc('d1').collection('members').doc('admin').update({approvalStatus: 'approved'});
    await seedPeriodDocs('d1');

    const result = await __testables.approveDaretHandler(ctx('member', {daretId: 'd1'}), deps());

    expect(result.activated).toBe(true);
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.statut).toBe('actif');
    const contribution = await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .doc('member')
      .get();
    expect(contribution.data()).toMatchObject({payerUid: 'member', state: 'apayer', amount: 1500});
  });

  test('approveDaret rejects illegal active-state transition', async () => {
    await seedUser('admin', 'Admin');
    await seedUser('member', 'Member');
    await seedDraftDaret('d1', ['admin', 'member'], 'admin', 2, 'actif', 'pending');

    await expectCodeAsync(
      __testables.approveDaretHandler(ctx('member', {daretId: 'd1'}), deps()),
      'failed-precondition',
    );
  });

  test('closePeriod rejects unconfirmed contributions and advances when all are confirmed', async () => {
    await seedActiveDaretWithContributions('d1', 'attente');

    await expectCodeAsync(
      __testables.closePeriodHandler(ctx('admin', {daretId: 'd1', periodIndex: 1}), deps()),
      'failed-precondition',
    );

    await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .doc('member')
      .update({state: 'confirme'});

    const result = await __testables.closePeriodHandler(ctx('admin', {daretId: 'd1', periodIndex: 1}), deps());

    expect(result).toEqual({closed: true, nextPeriode: 2});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.currentPeriode).toBe(2);
    const previous = await db.collection('darets').doc('d1').collection('periods').doc('01').get();
    const next = await db.collection('darets').doc('d1').collection('periods').doc('02').get();
    expect(previous.data()?.status).toBe('closed');
    expect(next.data()?.status).toBe('current');
  });

  test('closeDaret rejects before every member has received', async () => {
    await seedActiveDaretWithContributions('d1', 'confirme');

    await expectCodeAsync(
      __testables.closeDaretHandler(ctx('admin', {daretId: 'd1'}), deps()),
      'failed-precondition',
    );
  });

  test('closeDaret closes final confirmed period and increments recipient stats', async () => {
    await seedFinalPeriodReadyDaret('d1');

    const result = await __testables.closeDaretHandler(ctx('admin', {daretId: 'd1'}), deps());

    expect(result).toEqual({closed: true});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.statut).toBe('termine');
    const finalPeriod = await db.collection('darets').doc('d1').collection('periods').doc('02').get();
    expect(finalPeriod.data()).toMatchObject({status: 'closed', paidCount: 1, totalCount: 1});
    const member = await db.collection('users').doc('member').get();
    expect(member.data()?.stats).toMatchObject({totalRecuVie: 1500});
    const activity = await db.collection('darets').doc('d1').collection('activity').doc('closed').get();
    expect(activity.data()).toMatchObject({type: 'cloture', actorUid: 'admin'});
  });
});

describe('admin management (Part 4)', () => {
  test('reorderPeriods swaps upcoming recipients and rejects non-admin/illegal targets', async () => {
    await seedReorderDaret('d1');

    await expectCodeAsync(
      __testables.reorderPeriodsHandler(
        ctx('payer', {
          daretId: 'd1',
          periods: [
            {index: 2, recipientUids: ['recipient'], shares: {recipient: 100}},
            {index: 3, recipientUids: ['payer'], shares: {payer: 100}},
          ] as PeriodAssignment[],
        }),
        deps(),
      ),
      'permission-denied',
    );
    // Cannot touch the current period.
    await expectCodeAsync(
      __testables.reorderPeriodsHandler(
        ctx('admin', {
          daretId: 'd1',
          periods: [
            {index: 1, recipientUids: ['payer'], shares: {payer: 100}},
          ] as PeriodAssignment[],
        }),
        deps(),
      ),
      'failed-precondition',
    );
    // Assigning an already-served member breaks the once-each invariant.
    await expectCodeAsync(
      __testables.reorderPeriodsHandler(
        ctx('admin', {
          daretId: 'd1',
          periods: [
            {index: 2, recipientUids: ['admin'], shares: {admin: 100}},
          ] as PeriodAssignment[],
        }),
        deps(),
      ),
      'failed-precondition',
    );

    const result = await __testables.reorderPeriodsHandler(
      ctx('admin', {
        daretId: 'd1',
        periods: [
          {index: 2, recipientUids: ['recipient'], shares: {recipient: 100}},
          {index: 3, recipientUids: ['payer'], shares: {payer: 100}},
        ] as PeriodAssignment[],
      }),
      deps(),
    );

    expect(result).toEqual({updated: 2});
    const p2 = await db.collection('darets').doc('d1').collection('periods').doc('02').get();
    const p3 = await db.collection('darets').doc('d1').collection('periods').doc('03').get();
    expect(p2.data()).toMatchObject({recipientUids: ['recipient'], shares: {recipient: 100}});
    expect(p3.data()).toMatchObject({recipientUids: ['payer'], shares: {payer: 100}});
    const activity = await db
      .collection('darets')
      .doc('d1')
      .collection('activity')
      .doc('reorder-20260602-1')
      .get();
    expect(activity.data()).toMatchObject({type: 'tour', actorUid: 'admin'});
  });

  test('replaceMember swaps an unserved member and rejects served/admin/non-admin', async () => {
    await seedReplaceDaret('d1');

    await expectCodeAsync(
      __testables.replaceMemberHandler(
        ctx('recipient', {daretId: 'd1', fromUid: 'recipient', toUid: 'newcomer'}),
        deps(),
      ),
      'permission-denied',
    );
    await expectCodeAsync(
      __testables.replaceMemberHandler(
        ctx('admin', {daretId: 'd1', fromUid: 'admin', toUid: 'newcomer'}),
        deps(),
      ),
      'failed-precondition',
    );
    // payer already received in the closed period 1.
    await expectCodeAsync(
      __testables.replaceMemberHandler(
        ctx('admin', {daretId: 'd1', fromUid: 'payer', toUid: 'newcomer'}),
        deps(),
      ),
      'failed-precondition',
    );

    const result = await __testables.replaceMemberHandler(
      ctx('admin', {daretId: 'd1', fromUid: 'recipient', toUid: 'newcomer'}),
      deps(),
    );

    expect(result).toEqual({replaced: true});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.memberUids).toEqual(['admin', 'payer', 'newcomer']);
    const oldMember = await db.collection('darets').doc('d1').collection('members').doc('recipient').get();
    const newMember = await db.collection('darets').doc('d1').collection('members').doc('newcomer').get();
    expect(oldMember.exists).toBe(false);
    expect(newMember.data()).toMatchObject({uid: 'newcomer', role: 'member', approvalStatus: 'approved'});
    const p3 = await db.collection('darets').doc('d1').collection('periods').doc('03').get();
    expect(p3.data()).toMatchObject({recipientUids: ['newcomer'], shares: {newcomer: 100}});
    const movedContribution = await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .doc('newcomer')
      .get();
    expect(movedContribution.data()).toMatchObject({payerUid: 'newcomer', state: 'apayer', amount: 1500});
    const oldContribution = await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .doc('recipient')
      .get();
    expect(oldContribution.exists).toBe(false);
  });

  test('replaceMember placeholder mode opens a vacant seat with a fresh invite code', async () => {
    await seedReplaceDaret('d1');

    const result = await __testables.replaceMemberHandler(
      ctx('admin', {daretId: 'd1', fromUid: 'recipient'}),
      deps(),
    );

    expect(result).toEqual({replaced: true, code: 'TANTIN-7K2P', placeholderUid: 'pending_7k2p'});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.memberUids).toEqual(['admin', 'payer', 'pending_7k2p']);
    expect(daret.data()?.inviteCode).toBe('TANTIN-7K2P');
    const seat = await db.collection('darets').doc('d1').collection('members').doc('pending_7k2p').get();
    expect(seat.data()).toMatchObject({uid: 'pending_7k2p', approvalStatus: 'pending', prenom: 'Invitation'});
    const p3 = await db.collection('darets').doc('d1').collection('periods').doc('03').get();
    expect(p3.data()).toMatchObject({recipientUids: ['pending_7k2p'], shares: {pending_7k2p: 100}});
    const liveTour = await db.collection('darets').doc('d1').collection('periods').doc('01').get();
    expect(liveTour.data()?.totalCount).toBe(1);
    const invite = await db.collection('invites').doc('TANTIN-7K2P').get();
    expect(invite.data()).toMatchObject({daretId: 'd1', active: true});
  });

  test('joinDaret fills a re-invited seat on an active daret as an approved member', async () => {
    await seedReplaceDaret('d1');
    await __testables.replaceMemberHandler(ctx('admin', {daretId: 'd1', fromUid: 'recipient'}), deps());
    await seedUser('joiner', 'Joiner');

    const result = await __testables.joinDaretHandler(ctx('joiner', {code: 'TANTIN-7K2P'}), deps());

    expect(result).toEqual({daretId: 'd1', joined: true});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()?.memberUids).toEqual(['admin', 'payer', 'joiner']);
    expect(daret.data()?.statut).toBe('actif');
    const seat = await db.collection('darets').doc('d1').collection('members').doc('pending_7k2p').get();
    expect(seat.exists).toBe(false);
    const joiner = await db.collection('darets').doc('d1').collection('members').doc('joiner').get();
    expect(joiner.data()).toMatchObject({uid: 'joiner', role: 'member', approvalStatus: 'approved'});
    const p3 = await db.collection('darets').doc('d1').collection('periods').doc('03').get();
    expect(p3.data()).toMatchObject({recipientUids: ['joiner'], shares: {joiner: 100}});
  });

  test('editDaretDetails updates cosmetics, rejects non-admin, empty and closed darets', async () => {
    await seedReorderDaret('d1');

    await expectCodeAsync(
      __testables.editDaretDetailsHandler(ctx('payer', {daretId: 'd1', nom: 'Pirate'}), deps()),
      'permission-denied',
    );
    await expectCodeAsync(
      __testables.editDaretDetailsHandler(ctx('admin', {daretId: 'd1'}), deps()),
      'invalid-argument',
    );

    const result = await __testables.editDaretDetailsHandler(
      ctx('admin', {daretId: 'd1', nom: 'Daret Renommé', cover: 'star', accent: '#2E9E6B'}),
      deps(),
    );
    expect(result).toEqual({updated: true});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.data()).toMatchObject({nom: 'Daret Renommé', cover: 'star', accent: '#2E9E6B'});

    await db.collection('darets').doc('d1').update({statut: 'termine'});
    await expectCodeAsync(
      __testables.editDaretDetailsHandler(ctx('admin', {daretId: 'd1', nom: 'Trop tard'}), deps()),
      'failed-precondition',
    );
  });

  test('deleteDaret removes the daret, its subcollections and invite; rejects non-admin', async () => {
    await seedReorderDaret('d1');
    await db.collection('darets').doc('d1').update({inviteCode: 'TANTIN-DEL1'});
    await db.collection('invites').doc('TANTIN-DEL1').set({
      daretId: 'd1',
      createdByUid: 'admin',
      active: true,
      expiresAt: fixedNow,
    });

    await expectCodeAsync(
      __testables.deleteDaretHandler(ctx('payer', {daretId: 'd1'}), deps()),
      'permission-denied',
    );

    const result = await __testables.deleteDaretHandler(ctx('admin', {daretId: 'd1'}), deps());
    expect(result).toEqual({deleted: true});
    const daret = await db.collection('darets').doc('d1').get();
    expect(daret.exists).toBe(false);
    const members = await db.collection('darets').doc('d1').collection('members').get();
    expect(members.size).toBe(0);
    const contributions = await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .get();
    expect(contributions.size).toBe(0);
    const invite = await db.collection('invites').doc('TANTIN-DEL1').get();
    expect(invite.exists).toBe(false);
  });

  test('reorderPeriods and replaceMember lock once a payment is recorded', async () => {
    await seedReorderDaret('d1');
    // payer declares their first-tour payment — the arrangement is now final.
    await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .doc('payer')
      .update({state: 'attente'});

    await expectCodeAsync(
      __testables.reorderPeriodsHandler(
        ctx('admin', {
          daretId: 'd1',
          periods: [
            {index: 2, recipientUids: ['recipient'], shares: {recipient: 100}},
            {index: 3, recipientUids: ['payer'], shares: {payer: 100}},
          ] as PeriodAssignment[],
        }),
        deps(),
      ),
      'failed-precondition',
    );
    await expectCodeAsync(
      __testables.replaceMemberHandler(ctx('admin', {daretId: 'd1', fromUid: 'recipient'}), deps()),
      'failed-precondition',
    );
  });
});

describe('triggers and seed', () => {
  test('onContributionWritten recomputes paidCount and writes idempotent payment activity', async () => {
    await seedActiveDaretWithContributions('d1', 'attente');
    await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('01')
      .collection('contributions')
      .doc('member')
      .update({state: 'confirme', confirmedByUid: 'admin', confirmedAt: fixedNow});

    await __testables.onContributionWrittenHandler(
      {
        daretId: 'd1',
        periodId: '01',
        payerUid: 'member',
        before: {payerUid: 'member', state: 'attente', amount: 1500},
        after: {payerUid: 'member', state: 'confirme', amount: 1500},
      },
      deps(),
    );

    const period = await db.collection('darets').doc('d1').collection('periods').doc('01').get();
    expect(period.data()).toMatchObject({paidCount: 1, totalCount: 1});
    const activity = await db
      .collection('darets')
      .doc('d1')
      .collection('activity')
      .doc('payment-01-member')
      .get();
    expect(activity.data()).toMatchObject({
      type: 'paiement',
      actorUid: 'member',
      amount: 1500,
      periodIndex: 1,
    });
  });

  test('seedDev is dev-guarded and writes canonical Yasmine data to Firestore', async () => {
    await expectCodeAsync(
      __testables.seedDevHandler(ctx('live-yasmine', {}), deps('tantin-prod')),
      'failed-precondition',
    );

    const result = await __testables.seedDevHandler(ctx('live-yasmine', {}), deps());

    expect(result).toEqual({seeded: true, yasmineUid: 'live-yasmine', darets: 4});
    const yasmine = await db.collection('users').doc('live-yasmine').get();
    expect(yasmine.data()).toMatchObject({
      prenom: 'Yasmine',
      nom: 'Benali',
      stats: {daretsActifs: 2, totalRecuVie: 4800},
    });
    const darets = await db.collection('darets').get();
    expect(darets.size).toBe(4);
    const d1 = await db.collection('darets').doc('d1').get();
    expect(d1.data()).toMatchObject({
      nom: 'Daret Famille',
      memberUids: expect.arrayContaining(['live-yasmine', 'seed-person-01']),
      statut: 'actif',
      currentPeriode: 4,
    });
    const contribution = await db
      .collection('darets')
      .doc('d1')
      .collection('periods')
      .doc('04')
      .collection('contributions')
      .doc('live-yasmine')
      .get();
    expect(contribution.data()).toMatchObject({
      payerUid: 'live-yasmine',
      state: 'apayer',
      amount: 1500,
    });
    const notifications = await db.collection('notifications').doc('live-yasmine').collection('items').get();
    expect(notifications.size).toBe(5);
  });
});

async function seedUser(uid: string, prenom: string, nom = 'Test'): Promise<void> {
  await db.collection('users').doc(uid).set({
    prenom,
    nom,
    name: nom.length > 0 ? `${prenom} ${nom}` : prenom,
    initials: `${prenom[0] ?? 'T'}${nom.length > 0 ? nom[0] : ''}`.toUpperCase(),
    phone: '+212600000000',
    photoUrl: null,
    avatarPalette: ['#5247E6', '#E7E5FB'],
    fcmTokens: [],
    settings: {
      defaultEcheanceDay: 5,
      graceDays: 2,
      lang: 'fr',
      notifPrefs: {contributions: true, reminders: true, turns: true},
    },
    stats: {daretsActifs: 0, totalRecuVie: 0},
    createdAt: fixedNow,
    updatedAt: fixedNow,
  });
}

async function seedDraftDaret(
  daretId: string,
  memberUids: string[],
  adminUid: string,
  periodesCount: number,
  statut = 'brouillon',
  approvalStatus: 'pending' | 'approved' = 'pending',
): Promise<void> {
  await db.collection('darets').doc(daretId).set({
    nom: 'Daret Test',
    cover: 'home',
    accent: '#5247E6',
    montant: 1500,
    frequence: 'Mensuel',
    periodesCount,
    cagnotteParPeriode: 1500 * periodesCount,
    statut,
    adminUid,
    memberUids,
    currentPeriode: 0,
    prochaineDate: fixedNow,
    inviteCode: null,
    settings: {echeanceDay: 5, graceDays: 2},
    createdAt: fixedNow,
    startedAt: null,
    closedAt: null,
  });
  for (const uid of memberUids) {
    await db.collection('darets').doc(daretId).collection('members').doc(uid).set({
      uid,
      role: uid === adminUid ? 'admin' : 'member',
      joinedAt: fixedNow,
      approvalStatus,
      name: `${uid} Test`,
      prenom: uid,
      initials: uid.slice(0, 2).toUpperCase(),
      avatarPalette: ['#5247E6', '#E7E5FB'],
      groupePart: null,
    });
  }
}

async function seedS4DraftPayloadDaret(daretId: string): Promise<void> {
  await db.collection('darets').doc(daretId).set({
    nom: 'Daret Test',
    cover: 'home',
    accent: '#5247E6',
    montant: 1500,
    frequence: 'Mensuel',
    periodesCount: 2,
    cagnotteParPeriode: 3000,
    statut: 'brouillon',
    adminUid: 'admin',
    memberUids: ['admin'],
    currentPeriode: 0,
    prochaineDate: fixedNow,
    inviteCode: null,
    settings: {echeanceDay: 5, graceDays: 2},
    createdAt: fixedNow,
    startedAt: null,
    closedAt: null,
    draftMembers: [
      {
        uid: 'admin',
        avatarPalette: ['#5247E6', '#E7E5FB'],
      },
      {
        uid: 'pending_invite_1',
        inviteIndex: 1,
        avatarPalette: ['#F5A623', '#FBEFD6'],
      },
    ],
    draftPeriods: [
      {
        index: 1,
        recipientUids: ['admin'],
        shares: {admin: 100},
      },
      {
        index: 2,
        recipientUids: ['pending_invite_1'],
        shares: {pending_invite_1: 100},
      },
    ],
  });
}

async function seedS4GroupDraftPayloadDaret(daretId: string): Promise<void> {
  await db.collection('darets').doc(daretId).set({
    nom: 'Daret Group Test',
    cover: 'home',
    accent: '#5247E6',
    montant: 1000,
    frequence: 'Mensuel',
    periodesCount: 3,
    cagnotteParPeriode: 3000,
    statut: 'brouillon',
    adminUid: 'admin',
    memberUids: ['admin'],
    currentPeriode: 0,
    prochaineDate: fixedNow,
    inviteCode: null,
    settings: {echeanceDay: 5, graceDays: 2},
    createdAt: fixedNow,
    startedAt: null,
    closedAt: null,
    draftMembers: [
      {uid: 'admin', avatarPalette: ['#5247E6', '#E7E5FB']},
      {uid: 'x', avatarPalette: ['#F5A623', '#FBEFD6']},
      {uid: 'y', avatarPalette: ['#2E9E6B', '#DCF0E6']},
      {uid: 'solo', avatarPalette: ['#D2483F', '#F8DAD7']},
    ],
    draftPeriods: [
      {
        index: 1,
        recipientUids: ['admin'],
        shares: {admin: 100},
      },
      {
        index: 2,
        recipientUids: ['x', 'y'],
        shares: {x: 40, y: 60},
      },
      {
        index: 3,
        recipientUids: ['solo'],
        shares: {solo: 100},
      },
    ],
  });
}

async function seedPeriodDocs(daretId: string): Promise<void> {
  await db.collection('darets').doc(daretId).collection('periods').doc('01').set({
    index: 1,
    recipientUids: ['admin'],
    shares: {admin: 100},
    scheduledDate: fixedNow,
    potAmount: 1500,
    status: 'current',
    paidCount: 0,
    totalCount: 1,
    closedAt: null,
  });
  await db.collection('darets').doc(daretId).collection('periods').doc('02').set({
    index: 2,
    recipientUids: ['member'],
    shares: {member: 100},
    scheduledDate: Timestamp.fromDate(new Date('2026-07-02T09:00:00Z')),
    potAmount: 1500,
    status: 'upcoming',
    paidCount: 0,
    totalCount: 1,
    closedAt: null,
  });
}

async function expectContributionAmount(
  periodRef: DocumentReference,
  uid: string,
  amount: number,
): Promise<void> {
  const contribution = await periodRef.collection('contributions').doc(uid).get();
  expect(contribution.data()).toMatchObject({
    payerUid: uid,
    state: 'apayer',
    amount,
  });
}

async function seedActiveDaretWithContributions(
  daretId: string,
  memberState: 'attente' | 'confirme',
): Promise<void> {
  await seedUser('admin', 'Admin');
  await seedUser('member', 'Member');
  await seedDraftDaret(daretId, ['admin', 'member'], 'admin', 2, 'actif', 'approved');
  await db.collection('darets').doc(daretId).update({currentPeriode: 1});
  await seedPeriodDocs(daretId);
  await db
    .collection('darets')
    .doc(daretId)
    .collection('periods')
    .doc('01')
    .collection('contributions')
    .doc('admin')
    .set({payerUid: 'admin', state: 'recipient', amount: 0, paidDeclaredAt: null, confirmedAt: null, confirmedByUid: null});
  await db
    .collection('darets')
    .doc(daretId)
    .collection('periods')
    .doc('01')
    .collection('contributions')
    .doc('member')
    .set({
      payerUid: 'member',
      state: memberState,
      amount: 1500,
      paidDeclaredAt: fixedNow,
      confirmedAt: memberState === 'confirme' ? fixedNow : null,
      confirmedByUid: memberState === 'confirme' ? 'admin' : null,
    });
}

async function seedFinalPeriodReadyDaret(daretId: string): Promise<void> {
  await seedActiveDaretWithContributions(daretId, 'confirme');
  const daretRef = db.collection('darets').doc(daretId);
  await daretRef.update({currentPeriode: 2});
  await daretRef.collection('periods').doc('01').update({
    status: 'closed',
    closedAt: fixedNow,
  });
  await daretRef.collection('periods').doc('02').update({
    status: 'current',
    paidCount: 1,
    totalCount: 1,
  });
  await daretRef.collection('periods').doc('02').collection('contributions').doc('admin').set({
    payerUid: 'admin',
    state: 'confirme',
    amount: 1500,
    paidDeclaredAt: fixedNow,
    confirmedAt: fixedNow,
    confirmedByUid: 'member',
  });
  await daretRef.collection('periods').doc('02').collection('contributions').doc('member').set({
    payerUid: 'member',
    state: 'recipient',
    amount: 0,
    paidDeclaredAt: null,
    confirmedAt: null,
    confirmedByUid: null,
  });
}

async function seedPeriodDoc(
  daretId: string,
  index: number,
  recipientUid: string,
  status: 'upcoming' | 'current' | 'closed',
): Promise<void> {
  await db
    .collection('darets')
    .doc(daretId)
    .collection('periods')
    .doc(index.toString().padStart(2, '0'))
    .set({
      index,
      recipientUids: [recipientUid],
      shares: {[recipientUid]: 100},
      scheduledDate: Timestamp.fromDate(new Date(`2026-0${5 + index}-02T09:00:00Z`)),
      potAmount: 3000,
      status,
      paidCount: 0,
      totalCount: 2,
      closedAt: status === 'closed' ? fixedNow : null,
    });
}

async function seedCurrentContributions(
  daretId: string,
  periodIndex: number,
  recipientUid: string,
  payerUids: string[],
): Promise<void> {
  const periodRef = db
    .collection('darets')
    .doc(daretId)
    .collection('periods')
    .doc(periodIndex.toString().padStart(2, '0'));
  await periodRef.collection('contributions').doc(recipientUid).set({
    payerUid: recipientUid,
    state: 'recipient',
    amount: 0,
    paidDeclaredAt: null,
    confirmedAt: null,
    confirmedByUid: null,
  });
  for (const uid of payerUids) {
    await periodRef.collection('contributions').doc(uid).set({
      payerUid: uid,
      state: 'apayer',
      amount: 1500,
      paidDeclaredAt: null,
      confirmedAt: null,
      confirmedByUid: null,
    });
  }
}

async function seedReorderDaret(daretId: string): Promise<void> {
  await seedUser('admin', 'Admin');
  await seedUser('payer', 'Payer');
  await seedUser('recipient', 'Recipient');
  await seedDraftDaret(daretId, ['admin', 'payer', 'recipient'], 'admin', 3, 'actif', 'approved');
  await db.collection('darets').doc(daretId).update({currentPeriode: 1});
  await seedPeriodDoc(daretId, 1, 'admin', 'current');
  await seedPeriodDoc(daretId, 2, 'payer', 'upcoming');
  await seedPeriodDoc(daretId, 3, 'recipient', 'upcoming');
  await seedCurrentContributions(daretId, 1, 'admin', ['payer', 'recipient']);
}

async function seedReplaceDaret(daretId: string): Promise<void> {
  // Arrangeable: still on the first tour, no payment recorded yet. payer is the
  // current (period 1) recipient; admin/recipient hold upcoming turns.
  await seedUser('admin', 'Admin');
  await seedUser('payer', 'Payer');
  await seedUser('recipient', 'Recipient');
  await seedUser('newcomer', 'Newcomer');
  await seedDraftDaret(daretId, ['admin', 'payer', 'recipient'], 'admin', 3, 'actif', 'approved');
  await db.collection('darets').doc(daretId).update({currentPeriode: 1});
  await seedPeriodDoc(daretId, 1, 'payer', 'current');
  await seedPeriodDoc(daretId, 2, 'admin', 'upcoming');
  await seedPeriodDoc(daretId, 3, 'recipient', 'upcoming');
  await seedCurrentContributions(daretId, 1, 'payer', ['admin', 'recipient']);
}

function expectCode(callback: () => unknown, code: string): void {
  try {
    callback();
  } catch (error) {
    expect((error as HttpsError).code).toBe(code);
    return;
  }
  throw new Error(`Expected ${code}.`);
}

async function expectCodeAsync(promise: Promise<unknown>, code: string): Promise<void> {
  try {
    await promise;
  } catch (error) {
    expect((error as HttpsError).code).toBe(code);
    return;
  }
  throw new Error(`Expected ${code}.`);
}

async function clearFirestore(firestore: Firestore): Promise<void> {
  const collections = await firestore.listCollections();
  for (const collection of collections) {
    await deleteCollection(collection);
  }
}

async function deleteCollection(collection: CollectionReference): Promise<void> {
  const docs = await collection.listDocuments();
  for (const doc of docs) {
    await deleteDocument(doc);
  }
}

async function deleteDocument(doc: DocumentReference): Promise<void> {
  const collections = await doc.listCollections();
  for (const collection of collections) {
    await deleteCollection(collection);
  }
  await doc.delete();
}
