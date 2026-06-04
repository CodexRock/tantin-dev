import {getApps, initializeApp} from 'firebase-admin/app';
import {
  DocumentReference,
  DocumentSnapshot,
  FieldValue,
  Firestore,
  QueryDocumentSnapshot,
  Timestamp,
  Transaction,
  WriteBatch,
  getFirestore,
} from 'firebase-admin/firestore';
import {logger} from 'firebase-functions';
import {onDocumentCreated, onDocumentWritten} from 'firebase-functions/v2/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {z} from 'zod';

if (getApps().length === 0) {
  initializeApp();
}

const REGION = 'europe-west1';
const INVITE_TTL_MS = 14 * 24 * 60 * 60 * 1000;
const REMINDER_DAY_MS = 24 * 60 * 60 * 1000;
const UID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
const DARET_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
const INVITE_CODE_PATTERN = /^TANTIN-[A-Z0-9]{4,8}$/;
const PENDING_MEMBER_PREFIX = 'pending_';
// App Check enforcement is OFF in dev: the test devices' Play Integrity is
// unreliable ("Too many attempts") and blocks every callable. Auth + Firestore
// rules still protect all data. RE-ENABLE before release (S6). See DECISIONS.
const enforceAppCheck: boolean = false;
const callableOptions = {region: REGION, enforceAppCheck};

type ErrorCode =
  | 'invalid-argument'
  | 'unauthenticated'
  | 'failed-precondition'
  | 'permission-denied'
  | 'not-found'
  | 'internal';

type FirestoreData = Record<string, unknown>;

type DaretStatus = 'brouillon' | 'attente' | 'actif' | 'termine';
type PeriodStatus = 'upcoming' | 'current' | 'closed';
type ContributionState = 'apayer' | 'attente' | 'confirme' | 'retard' | 'recipient';
type ActivityType = 'paiement' | 'tour' | 'rappel' | 'membre' | 'demarre' | 'cloture';

interface CallableEnvelope {
  data: unknown;
  auth?: {
    uid?: string;
  };
  app?: {
    appId?: string;
  };
}

interface HandlerContext<T> {
  uid: string;
  appId: string;
  data: T;
}

interface HandlerDeps {
  db: Firestore;
  now: () => Timestamp;
  randomCode: () => string;
  projectId: string;
}

interface PersonProfile {
  uid: string;
  prenom: string;
  nom: string;
  name: string;
  initials: string;
  phone: string;
  avatarPalette: string[];
}

interface PeriodPlan {
  id: string;
  index: number;
  recipientUids: string[];
  shares: Record<string, number>;
  scheduledDate: Timestamp;
  potAmount: number;
  status: PeriodStatus;
}

interface DraftExpansion {
  memberUids: string[];
  memberDocs: FirestoreData[];
  periodPlans: PeriodPlan[];
}

const daretIdSchema = z
  .string()
  .trim()
  .min(1)
  .max(128)
  .regex(DARET_ID_PATTERN);
const uidSchema = z.string().trim().min(1).max(128).regex(UID_PATTERN);
const inviteCodeSchema = z
  .string()
  .trim()
  .transform((value) => value.toUpperCase())
  .pipe(z.string().regex(INVITE_CODE_PATTERN));

const daretIdInput = z.object({daretId: daretIdSchema}).strict();
const inviteInput = z.object({code: inviteCodeSchema}).strict();
const closePeriodInput = z
  .object({daretId: daretIdSchema, periodIndex: z.number().int().min(1).max(99)})
  .strict();
const sendNudgeInput = z
  .object({
    daretId: daretIdSchema,
    periodIndex: z.number().int().min(1).max(99),
    targetUid: uidSchema,
  })
  .strict();
const seedDevInput = z.object({}).strict();

type DaretIdInput = z.infer<typeof daretIdInput>;
type InviteInput = z.infer<typeof inviteInput>;
type ClosePeriodInput = z.infer<typeof closePeriodInput>;
type SendNudgeInput = z.infer<typeof sendNudgeInput>;
type SeedDevInput = z.infer<typeof seedDevInput>;

function defaultDeps(): HandlerDeps {
  return {
    db: getFirestore(),
    now: () => Timestamp.now(),
    randomCode: randomInviteCode,
    projectId: process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? '',
  };
}

function fail(code: ErrorCode, message: string): never {
  throw new HttpsError(code, message);
}

export function parseCallable<T>(
  schema: z.ZodType<T>,
  request: CallableEnvelope,
): HandlerContext<T> {
  const uid = request.auth?.uid;
  if (typeof uid !== 'string' || uid.length === 0) {
    fail('unauthenticated', 'Authentication is required.');
  }
  const appId = request.app?.appId ?? '';
  if (enforceAppCheck && appId.length === 0) {
    fail('failed-precondition', 'App Check is required.');
  }
  const parsed = schema.safeParse(request.data);
  if (!parsed.success) {
    fail('invalid-argument', parsed.error.issues.map((issue) => issue.message).join('; '));
  }
  return {uid, appId, data: parsed.data};
}

function makeCallable<T, R>(
  schema: z.ZodType<T>,
  handler: (context: HandlerContext<T>, deps: HandlerDeps) => Promise<R>,
) {
  return onCall(callableOptions, async (request) => {
    return handler(parseCallable(schema, request as CallableEnvelope), defaultDeps());
  });
}

export const startDaret = makeCallable(daretIdInput, startDaretHandler);
export const createInvite = makeCallable(daretIdInput, createInviteHandler);
export const previewDaret = makeCallable(inviteInput, previewDaretHandler);
export const joinDaret = makeCallable(inviteInput, joinDaretHandler);
export const approveDaret = makeCallable(daretIdInput, approveDaretHandler);
export const advancePeriod = makeCallable(daretIdInput, advancePeriodHandler);
export const closePeriod = makeCallable(closePeriodInput, closePeriodHandler);
export const closeDaret = makeCallable(daretIdInput, closeDaretHandler);
export const sendNudge = makeCallable(sendNudgeInput, sendNudgeHandler);
export const seedDev = makeCallable(seedDevInput, seedDevHandler);

export const onContributionWritten = onDocumentWritten(
  {
    region: REGION,
    document: 'darets/{daretId}/periods/{periodId}/contributions/{payerUid}',
  },
  async (event) => {
    const daretId = event.params.daretId;
    const periodId = event.params.periodId;
    const payerUid = event.params.payerUid;
    const before = event.data?.before.exists ? event.data.before.data() : undefined;
    const after = event.data?.after.exists ? event.data.after.data() : undefined;
    await onContributionWrittenHandler(
      {
        daretId,
        periodId,
        payerUid,
        before: beforeData(before),
        after: beforeData(after),
      },
      defaultDeps(),
    );
  },
);

export const onMemberCreated = onDocumentCreated(
  {
    region: REGION,
    document: 'darets/{daretId}/members/{memberUid}',
  },
  async (event) => {
    const data = event.data?.data();
    if (data === undefined) {
      return;
    }
    await onMemberCreatedHandler(
      {
        daretId: event.params.daretId,
        memberUid: event.params.memberUid,
        member: recordValue(data, 'member'),
      },
      defaultDeps(),
    );
  },
);

export const dailyReminders = onSchedule(
  {
    schedule: 'every day 08:00',
    timeZone: 'Africa/Casablanca',
    region: REGION,
  },
  async () => {
    await dailyRemindersHandler(defaultDeps());
  },
);

async function startDaretHandler(
  context: HandlerContext<DaretIdInput>,
  deps: HandlerDeps,
): Promise<{status: DaretStatus; currentPeriode: number}> {
  const {db} = deps;
  const now = deps.now();
  const daretRef = db.collection('darets').doc(context.data.daretId);

  return db.runTransaction(async (transaction) => {
    const daretSnapshot = await transaction.get(daretRef);
    const daret = requireExistingData(daretSnapshot, 'daret');
    requireAdmin(daret, context.uid);
    const status = requireStatus(daret);
    if (status !== 'brouillon' && status !== 'attente') {
      fail('failed-precondition', 'Only draft or pending darets can be started.');
    }

    let memberUids = requireStringArray(daret, 'memberUids');
    if (memberUids.length === 0) {
      fail('failed-precondition', 'A daret must have at least one member.');
    }
    const periodesCount = requirePositiveInteger(daret, 'periodesCount');

    const membersSnapshot = await transaction.get(daretRef.collection('members'));
    const existingPeriods = await transaction.get(daretRef.collection('periods'));
    let memberDocs = membersSnapshot.docs.map((doc) => dataWithId(doc));
    let periodPlans: PeriodPlan[];
    let draftExpansion: DraftExpansion | undefined;
    if (hasDraftPlan(daret)) {
      if (!membersSnapshot.empty || !existingPeriods.empty) {
        fail('failed-precondition', 'Draft payload cannot be mixed with existing server-owned docs.');
      }
      draftExpansion = await expandDraftPlan(transaction, db, daret, context.uid, now);
      memberUids = draftExpansion.memberUids;
      memberDocs = draftExpansion.memberDocs;
      periodPlans = draftExpansion.periodPlans;
    } else {
      ensureMemberDocs(memberUids, memberDocs);
      periodPlans =
        existingPeriods.empty
          ? buildDefaultPeriods(daret, memberUids, now)
          : existingPeriods.docs.map(readPeriodPlan);
    }
    validatePeriodPlans(periodPlans, memberUids, periodesCount);

    const allApproved = memberDocs.every(
      (member) => optionalString(member, 'approvalStatus') === 'approved',
    );
    const nextStatus: DaretStatus = allApproved ? 'actif' : 'attente';
    const currentPlan = periodPlans.find((plan) => plan.index === 1);
    if (currentPlan === undefined) {
      fail('failed-precondition', 'Period 1 is missing.');
    }

    if (draftExpansion !== undefined) {
      for (const member of draftExpansion.memberDocs) {
        const uid = requireString(member, 'uid');
        transaction.set(daretRef.collection('members').doc(uid), member, {merge: false});
      }
    }
    for (const plan of periodPlans) {
      transaction.set(
        daretRef.collection('periods').doc(plan.id),
        periodDocument(plan, nextStatus === 'actif' && plan.index === 1 ? 'current' : 'upcoming', null),
        {merge: true},
      );
    }
    const montant = requirePositiveInteger(daret, 'montant');
    if (nextStatus === 'actif') {
      setContributionsInTransaction(
        transaction,
        daretRef,
        currentPlan,
        memberUids,
        montant,
        periodPlans,
      );
    }
    transaction.set(
      daretRef.collection('activity').doc('start'),
      activityDocument({
        type: 'demarre',
        actorUid: context.uid,
        text: `${requireString(daret, 'nom')} a démarré`,
        createdAt: now,
      }),
      {merge: false},
    );
    transaction.update(daretRef, {
      statut: nextStatus,
      memberUids,
      cagnotteParPeriode: grossCagnotteAmount(montant, periodesCount),
      currentPeriode: 1,
      prochaineDate: currentPlan.scheduledDate,
      startedAt: nextStatus === 'actif' ? now : null,
      updatedAt: now,
      draftMembers: FieldValue.delete(),
      draftPeriods: FieldValue.delete(),
    });
    logger.info('startDaret completed', {
      daretId: context.data.daretId,
      uid: context.uid,
      status: nextStatus,
    });
    return {status: nextStatus, currentPeriode: 1};
  });
}

async function createInviteHandler(
  context: HandlerContext<DaretIdInput>,
  deps: HandlerDeps,
): Promise<{code: string}> {
  const {db} = deps;
  const daretRef = db.collection('darets').doc(context.data.daretId);
  const now = deps.now();

  return db.runTransaction(async (transaction) => {
    const daretSnapshot = await transaction.get(daretRef);
    const daret = requireExistingData(daretSnapshot, 'daret');
    requireAdmin(daret, context.uid);
    if (requireStatus(daret) === 'termine') {
      fail('failed-precondition', 'Closed darets cannot create invites.');
    }

    const existingCode = optionalString(daret, 'inviteCode');
    if (existingCode !== undefined) {
      const existingInvite = await transaction.get(db.collection('invites').doc(existingCode));
      if (existingInvite.exists) {
        const invite = requireExistingData(existingInvite, 'invite');
        if (isInviteActive(invite, now)) {
          return {code: existingCode};
        }
      }
    }

    const code = await reserveInviteCode(transaction, deps);
    const expiresAt = Timestamp.fromMillis(now.toMillis() + INVITE_TTL_MS);
    transaction.set(db.collection('invites').doc(code), {
      daretId: context.data.daretId,
      createdByUid: context.uid,
      active: true,
      expiresAt,
      createdAt: now,
    });
    transaction.update(daretRef, {inviteCode: code, updatedAt: now});
    logger.info('createInvite completed', {daretId: context.data.daretId, uid: context.uid});
    return {code};
  });
}

async function previewDaretHandler(
  context: HandlerContext<InviteInput>,
  deps: HandlerDeps,
): Promise<FirestoreData> {
  const invite = await getValidInvite(deps.db, context.data.code, deps.now());
  const daretSnapshot = await deps.db.collection('darets').doc(invite.daretId).get();
  const daret = requireExistingData(daretSnapshot, 'daret');
  return {
    daretId: invite.daretId,
    nom: requireString(daret, 'nom'),
    cover: requireString(daret, 'cover'),
    accent: requireString(daret, 'accent'),
    montant: requirePositiveInteger(daret, 'montant'),
    frequence: requireString(daret, 'frequence'),
    periodesCount: requirePositiveInteger(daret, 'periodesCount'),
    membersCount: requireStringArray(daret, 'memberUids').length,
    pendingInvitesCount: requireStringArray(daret, 'memberUids').filter(isPendingMemberUid).length,
    statut: requireStatus(daret),
  };
}

async function joinDaretHandler(
  context: HandlerContext<InviteInput>,
  deps: HandlerDeps,
): Promise<{daretId: string; joined: boolean}> {
  const {db} = deps;
  const now = deps.now();

  return db.runTransaction(async (transaction) => {
    const inviteSnapshot = await transaction.get(db.collection('invites').doc(context.data.code));
    const invite = requireExistingData(inviteSnapshot, 'invite');
    requireValidInvite(invite, now);

    const daretId = requireString(invite, 'daretId');
    const daretRef = db.collection('darets').doc(daretId);
    const daretSnapshot = await transaction.get(daretRef);
    const daret = requireExistingData(daretSnapshot, 'daret');
    const status = requireStatus(daret);
    if (status !== 'brouillon' && status !== 'attente') {
      fail('failed-precondition', 'This invite is no longer joinable.');
    }

    const memberUids = requireStringArray(daret, 'memberUids');
    if (memberUids.includes(context.uid)) {
      return {daretId, joined: false};
    }
    const periodesCount = requirePositiveInteger(daret, 'periodesCount');
    const placeholderUid = memberUids.find(isPendingMemberUid);
    if (memberUids.length >= periodesCount && placeholderUid === undefined) {
      fail('failed-precondition', 'This daret is full.');
    }

    const profileSnapshot = await transaction.get(db.collection('users').doc(context.uid));
    const profile = readRequiredProfile(context.uid, profileSnapshot);
    const memberRef = daretRef.collection('members').doc(context.uid);
    const periodsSnapshot =
      placeholderUid === undefined ? undefined : await transaction.get(daretRef.collection('periods'));
    if (placeholderUid !== undefined && periodsSnapshot !== undefined) {
      const nextMemberUids = memberUids.map((uid) => (uid === placeholderUid ? context.uid : uid));
      for (const periodSnapshot of periodsSnapshot.docs) {
        const plan = readPeriodPlan(periodSnapshot);
        if (!plan.recipientUids.includes(placeholderUid) && plan.shares[placeholderUid] === undefined) {
          continue;
        }
        const recipientUids = plan.recipientUids.map((uid) => (uid === placeholderUid ? context.uid : uid));
        const shares = {...plan.shares};
        if (shares[placeholderUid] !== undefined) {
          shares[context.uid] = shares[placeholderUid] ?? 0;
          delete shares[placeholderUid];
        }
        transaction.update(periodSnapshot.ref, {recipientUids, shares});
      }
      transaction.delete(daretRef.collection('members').doc(placeholderUid));
      transaction.update(daretRef, {
        memberUids: nextMemberUids,
        updatedAt: now,
      });
    } else {
      transaction.update(daretRef, {
        memberUids: FieldValue.arrayUnion(context.uid),
        updatedAt: now,
      });
    }
    transaction.set(memberRef, memberDocument(profile, 'member', 'pending', now), {merge: false});
    transaction.set(
      daretRef.collection('activity').doc(`member-${context.uid}`),
      activityDocument({
        type: 'membre',
        actorUid: context.uid,
        text: `${profile.prenom} a rejoint ${requireString(daret, 'nom')}`,
        createdAt: now,
      }),
      {merge: true},
    );
    transaction.set(
      db.collection('notifications').doc(requireString(daret, 'adminUid')).collection('items').doc(
        `member-${daretId}-${context.uid}`,
      ),
      notificationDocument({
        icon: 'user',
        text: `${profile.prenom} a rejoint ${requireString(daret, 'nom')}`,
        action: 'member',
        daretId,
        createdAt: now,
      }),
      {merge: true},
    );
    logger.info('joinDaret completed', {daretId, uid: context.uid});
    return {daretId, joined: true};
  });
}

async function approveDaretHandler(
  context: HandlerContext<DaretIdInput>,
  deps: HandlerDeps,
): Promise<{activated: boolean}> {
  const {db} = deps;
  const now = deps.now();
  const daretRef = db.collection('darets').doc(context.data.daretId);

  return db.runTransaction(async (transaction) => {
    const daretSnapshot = await transaction.get(daretRef);
    const daret = requireExistingData(daretSnapshot, 'daret');
    const status = requireStatus(daret);
    if (status !== 'attente' && status !== 'brouillon') {
      fail('failed-precondition', 'Only pending darets can be approved.');
    }
    const memberRef = daretRef.collection('members').doc(context.uid);
    const memberSnapshot = await transaction.get(memberRef);
    const member = requireExistingData(memberSnapshot, 'member');
    if (optionalString(member, 'approvalStatus') === 'approved') {
      return {activated: false};
    }

    const membersSnapshot = await transaction.get(daretRef.collection('members'));
    const allApproved = membersSnapshot.docs.every((doc) => {
      if (doc.id === context.uid) {
        return true;
      }
      return optionalString(doc.data(), 'approvalStatus') === 'approved';
    });
    if (!allApproved || status !== 'attente') {
      transaction.update(memberRef, {approvalStatus: 'approved'});
      return {activated: false};
    }

    const currentPeriode = requirePositiveInteger(daret, 'currentPeriode');
    if (currentPeriode !== 1) {
      fail('failed-precondition', 'Pending darets must start at period 1.');
    }
    const periodsSnapshot = await transaction.get(daretRef.collection('periods'));
    const periodPlans = periodsSnapshot.docs.map(readPeriodPlan);
    const currentPlan = periodPlans.find((plan) => plan.index === 1);
    if (currentPlan === undefined) {
      fail('failed-precondition', 'Period 1 is missing.');
    }
    transaction.update(memberRef, {approvalStatus: 'approved'});
    setContributionsInTransaction(
      transaction,
      daretRef,
      currentPlan,
      requireStringArray(daret, 'memberUids'),
      requirePositiveInteger(daret, 'montant'),
      periodPlans,
    );
    transaction.update(daretRef, {statut: 'actif', startedAt: now, updatedAt: now});
    transaction.update(daretRef.collection('periods').doc('01'), {status: 'current'});
    logger.info('approveDaret activated', {daretId: context.data.daretId, uid: context.uid});
    return {activated: true};
  });
}

async function advancePeriodHandler(
  context: HandlerContext<DaretIdInput>,
  deps: HandlerDeps,
): Promise<{closed: boolean; nextPeriode?: number}> {
  const daretSnapshot = await deps.db.collection('darets').doc(context.data.daretId).get();
  const daret = requireExistingData(daretSnapshot, 'daret');
  return closePeriodCore(
    {
      uid: context.uid,
      daretId: context.data.daretId,
      periodIndex: requirePositiveInteger(daret, 'currentPeriode'),
    },
    deps,
  );
}

async function closePeriodHandler(
  context: HandlerContext<ClosePeriodInput>,
  deps: HandlerDeps,
): Promise<{closed: boolean; nextPeriode?: number}> {
  return closePeriodCore(
    {
      uid: context.uid,
      daretId: context.data.daretId,
      periodIndex: context.data.periodIndex,
    },
    deps,
  );
}

async function closePeriodCore(
  input: {uid: string; daretId: string; periodIndex: number},
  deps: HandlerDeps,
): Promise<{closed: boolean; nextPeriode?: number}> {
  const {db} = deps;
  const now = deps.now();
  const daretRef = db.collection('darets').doc(input.daretId);
  const currentPeriodId = periodId(input.periodIndex);

  return db.runTransaction(async (transaction) => {
    const daretSnapshot = await transaction.get(daretRef);
    const daret = requireExistingData(daretSnapshot, 'daret');
    requireAdmin(daret, input.uid);
    if (requireStatus(daret) !== 'actif') {
      fail('failed-precondition', 'Only active darets can advance periods.');
    }
    if (requirePositiveInteger(daret, 'currentPeriode') !== input.periodIndex) {
      fail('failed-precondition', 'Only the current period can be closed.');
    }

    const periodRef = daretRef.collection('periods').doc(currentPeriodId);
    const periodsSnapshot = await transaction.get(daretRef.collection('periods'));
    const periodPlans = periodsSnapshot.docs.map(readPeriodPlan);
    const currentPlan = periodPlans.find((plan) => plan.index === input.periodIndex);
    if (currentPlan === undefined) {
      fail('failed-precondition', 'Current period is missing.');
    }
    if (currentPlan.status !== 'current') {
      fail('failed-precondition', 'Only the current period can be closed.');
    }

    const contributionsSnapshot = await transaction.get(periodRef.collection('contributions'));
    const contributionCounts = countContributions(contributionsSnapshot.docs.map((doc) => doc.data()));
    if (contributionCounts.paidCount < contributionCounts.totalCount) {
      fail('failed-precondition', 'All required contributions must be confirmed first.');
    }

    const periodesCount = requirePositiveInteger(daret, 'periodesCount');
    const nextIndex = input.periodIndex + 1;
    const nextPeriodRef = daretRef.collection('periods').doc(periodId(nextIndex));
    const nextPeriodSnapshot =
      input.periodIndex >= periodesCount ? undefined : await transaction.get(nextPeriodRef);

    transaction.update(periodRef, {
      status: 'closed',
      paidCount: contributionCounts.paidCount,
      totalCount: contributionCounts.totalCount,
      closedAt: now,
    });
    incrementRecipientStats(transaction, db, currentPlan);

    if (input.periodIndex >= periodesCount) {
      transaction.update(daretRef, {
        statut: 'termine',
        closedAt: now,
        updatedAt: now,
      });
      transaction.set(
        daretRef.collection('activity').doc('closed'),
        activityDocument({
          type: 'cloture',
          actorUid: input.uid,
          text: `${requireString(daret, 'nom')} est clôturé`,
          createdAt: now,
        }),
        {merge: true},
      );
      logger.info('closePeriod closed daret', {daretId: input.daretId, uid: input.uid});
      return {closed: true};
    }

    if (nextPeriodSnapshot === undefined) {
      fail('failed-precondition', 'Next period is missing.');
    }
    const nextPlan = readPeriodPlan(requiredDoc(nextPeriodSnapshot, 'period'));
    transaction.update(nextPeriodRef, {status: 'current'});
    setContributionsInTransaction(
      transaction,
      daretRef,
      nextPlan,
      requireStringArray(daret, 'memberUids'),
      requirePositiveInteger(daret, 'montant'),
      periodPlans,
    );
    transaction.update(daretRef, {
      currentPeriode: nextIndex,
      prochaineDate: nextPlan.scheduledDate,
      updatedAt: now,
    });
    logger.info('closePeriod advanced', {daretId: input.daretId, uid: input.uid, nextIndex});
    return {closed: true, nextPeriode: nextIndex};
  });
}

async function closeDaretHandler(
  context: HandlerContext<DaretIdInput>,
  deps: HandlerDeps,
): Promise<{closed: boolean}> {
  const {db} = deps;
  const now = deps.now();
  const daretRef = db.collection('darets').doc(context.data.daretId);

  return db.runTransaction(async (transaction) => {
    const daretSnapshot = await transaction.get(daretRef);
    const daret = requireExistingData(daretSnapshot, 'daret');
    requireAdmin(daret, context.uid);
    if (requireStatus(daret) === 'termine') {
      return {closed: false};
    }
    transaction.update(daretRef, {statut: 'termine', closedAt: now, updatedAt: now});
    transaction.set(
      daretRef.collection('activity').doc('closed'),
      activityDocument({
        type: 'cloture',
        actorUid: context.uid,
        text: `${requireString(daret, 'nom')} est clôturé`,
        createdAt: now,
      }),
      {merge: true},
    );
    logger.info('closeDaret completed', {daretId: context.data.daretId, uid: context.uid});
    return {closed: true};
  });
}

async function sendNudgeHandler(
  context: HandlerContext<SendNudgeInput>,
  deps: HandlerDeps,
): Promise<{sent: boolean}> {
  const {db} = deps;
  const now = deps.now();
  const daretRef = db.collection('darets').doc(context.data.daretId);
  const periodRef = daretRef.collection('periods').doc(periodId(context.data.periodIndex));

  return db.runTransaction(async (transaction) => {
    const daretSnapshot = await transaction.get(daretRef);
    const daret = requireExistingData(daretSnapshot, 'daret');
    const periodSnapshot = await transaction.get(periodRef);
    const period = requireExistingData(periodSnapshot, 'period');
    const contributionSnapshot = await transaction.get(
      periodRef.collection('contributions').doc(context.data.targetUid),
    );
    const contribution = requireExistingData(contributionSnapshot, 'contribution');
    const actorIsAdmin = requireString(daret, 'adminUid') === context.uid;
    const actorIsRecipient = requireStringArray(period, 'recipientUids').includes(context.uid);
    if (!actorIsAdmin && !actorIsRecipient) {
      fail('permission-denied', 'Only the admin or period recipient can nudge.');
    }
    if (optionalString(contribution, 'state') === 'confirme') {
      fail('failed-precondition', 'Confirmed contributions cannot be nudged.');
    }

    const activityId = `nudge-${periodId(context.data.periodIndex)}-${context.data.targetUid}-${dateKey(
      now,
    )}`;
    transaction.set(
      daretRef.collection('activity').doc(activityId),
      activityDocument({
        type: 'rappel',
        actorUid: context.uid,
        text: `Rappel envoyé pour ${requireString(daret, 'nom')}`,
        periodIndex: context.data.periodIndex,
        createdAt: now,
      }),
      {merge: true},
    );
    transaction.set(
      db.collection('notifications').doc(context.data.targetUid).collection('items').doc(activityId),
      notificationDocument({
        icon: 'clock',
        text: `Rappel: payez ${requirePositiveInteger(daret, 'montant')} DH pour ${requireString(
          daret,
          'nom',
        )}`,
        action: 'pay',
        daretId: context.data.daretId,
        createdAt: now,
      }),
      {merge: true},
    );
    logger.info('sendNudge completed', {
      daretId: context.data.daretId,
      targetUid: context.data.targetUid,
      uid: context.uid,
    });
    return {sent: true};
  });
}

async function onContributionWrittenHandler(
  event: {
    daretId: string;
    periodId: string;
    payerUid: string;
    before?: FirestoreData;
    after?: FirestoreData;
  },
  deps: HandlerDeps,
): Promise<void> {
  if (event.after === undefined) {
    return;
  }
  const {db} = deps;
  const now = deps.now();
  const periodRef = db
    .collection('darets')
    .doc(event.daretId)
    .collection('periods')
    .doc(event.periodId);
  const contributionsSnapshot = await periodRef.collection('contributions').get();
  const counts = countContributions(contributionsSnapshot.docs.map((doc) => doc.data()));
  const batch = db.batch();
  batch.set(periodRef, {paidCount: counts.paidCount, totalCount: counts.totalCount}, {merge: true});

  const beforeState = optionalString(event.before ?? {}, 'state');
  const afterState = optionalString(event.after, 'state');
  if (beforeState !== 'confirme' && afterState === 'confirme') {
    const periodIndex = Number.parseInt(event.periodId, 10);
    batch.set(
      db.collection('darets').doc(event.daretId).collection('activity').doc(
        `payment-${event.periodId}-${event.payerUid}`,
      ),
      activityDocument({
        type: 'paiement',
        actorUid: event.payerUid,
        text: 'Paiement confirmé',
        amount: positiveInteger(event.after.amount, 'amount'),
        periodIndex,
        createdAt: now,
      }),
      {merge: true},
    );
  }
  await batch.commit();
  logger.info('onContributionWritten recomputed aggregate', {
    daretId: event.daretId,
    periodId: event.periodId,
    paidCount: counts.paidCount,
    totalCount: counts.totalCount,
  });
}

async function onMemberCreatedHandler(
  event: {daretId: string; memberUid: string; member: FirestoreData},
  deps: HandlerDeps,
): Promise<void> {
  const now = deps.now();
  const daretSnapshot = await deps.db.collection('darets').doc(event.daretId).get();
  if (!daretSnapshot.exists) {
    return;
  }
  const daret = requireExistingData(daretSnapshot, 'daret');
  await deps.db
    .collection('darets')
    .doc(event.daretId)
    .collection('activity')
    .doc(`member-${event.memberUid}`)
    .set(
      activityDocument({
        type: 'membre',
        actorUid: event.memberUid,
        text: `${requireString(event.member, 'prenom')} a rejoint ${requireString(daret, 'nom')}`,
        createdAt: now,
      }),
      {merge: true},
    );
  logger.info('onMemberCreated wrote activity', {daretId: event.daretId, memberUid: event.memberUid});
}

async function dailyRemindersHandler(deps: HandlerDeps): Promise<void> {
  const {db} = deps;
  const now = deps.now();
  const activeDarets = await db.collection('darets').where('statut', '==', 'actif').get();
  const batch = db.batch();
  let writes = 0;

  for (const daretDoc of activeDarets.docs) {
    const daret = daretDoc.data();
    const currentPeriode = optionalNumber(daret, 'currentPeriode');
    if (currentPeriode === undefined || currentPeriode <= 0) {
      continue;
    }
    const periodRef = daretDoc.ref.collection('periods').doc(periodId(currentPeriode));
    const periodSnapshot = await periodRef.get();
    if (!periodSnapshot.exists) {
      continue;
    }
    const period = requireExistingData(periodSnapshot, 'period');
    const scheduledDate = requireTimestamp(period, 'scheduledDate');
    const settings = requireRecord(daret, 'settings');
    const graceDays = optionalNumber(settings, 'graceDays') ?? 0;
    const dueAt = scheduledDate.toMillis() + graceDays * REMINDER_DAY_MS;
    const contributions = await periodRef.collection('contributions').get();

    for (const contributionDoc of contributions.docs) {
      const contribution = contributionDoc.data();
      const state = optionalString(contribution, 'state');
      if (state === 'recipient' || state === 'confirme') {
        continue;
      }
      if (state === 'apayer' && now.toMillis() > dueAt) {
        batch.update(contributionDoc.ref, {state: 'retard'});
        writes += 1;
      }
      const notificationId = `reminder-${daretDoc.id}-${periodId(currentPeriode)}-${contributionDoc.id}-${dateKey(
        now,
      )}`;
      batch.set(
        db.collection('notifications').doc(contributionDoc.id).collection('items').doc(notificationId),
        notificationDocument({
          icon: state === 'retard' ? 'clock' : 'bell',
          text: `Payez ${requirePositiveInteger(daret, 'montant')} DH pour ${requireString(
            daret,
            'nom',
          )}`,
          action: 'pay',
          daretId: daretDoc.id,
          createdAt: now,
        }),
        {merge: true},
      );
      writes += 1;
    }
  }

  if (writes > 0) {
    await batch.commit();
  }
  logger.info('dailyReminders completed', {writes});
}

async function seedDevHandler(
  context: HandlerContext<SeedDevInput>,
  deps: HandlerDeps,
): Promise<{seeded: boolean; yasmineUid: string; darets: number}> {
  if (deps.projectId !== 'tantin-dev' && deps.projectId !== 'tantin-rules-test') {
    fail('failed-precondition', 'seedDev is available only on dev projects.');
  }
  const batch = deps.db.batch();
  const now = deps.now();
  const seed = buildSeedDataset(context.uid, now);

  for (const person of seed.people) {
    batch.set(deps.db.collection('users').doc(person.uid), userDocument(person, now, person.stats));
  }
  for (const daret of seed.darets) {
    const daretRef = deps.db.collection('darets').doc(daret.id);
    batch.set(daretRef, daret.root);
    for (const member of daret.members) {
      batch.set(daretRef.collection('members').doc(requireString(member, 'uid')), member);
    }
    for (const period of daret.periods) {
      const periodRef = daretRef.collection('periods').doc(period.id);
      batch.set(periodRef, period.root);
      for (const contribution of period.contributions) {
        batch.set(
          periodRef.collection('contributions').doc(requireString(contribution, 'payerUid')),
          contribution,
        );
      }
    }
    for (const event of daret.activity) {
      batch.set(daretRef.collection('activity').doc(event.id), event.root);
    }
  }
  for (const notification of seed.notifications) {
    batch.set(
      deps.db.collection('notifications').doc(context.uid).collection('items').doc(notification.id),
      notification.root,
    );
  }
  await batch.commit();
  logger.info('seedDev completed', {yasmineUid: context.uid, darets: seed.darets.length});
  return {seeded: true, yasmineUid: context.uid, darets: seed.darets.length};
}

async function getValidInvite(
  db: Firestore,
  code: string,
  now: Timestamp,
): Promise<{daretId: string; invite: FirestoreData}> {
  const inviteSnapshot = await db.collection('invites').doc(code).get();
  const invite = requireExistingData(inviteSnapshot, 'invite');
  requireValidInvite(invite, now);
  return {daretId: requireString(invite, 'daretId'), invite};
}

function requireValidInvite(invite: FirestoreData, now: Timestamp): void {
  if (!isInviteActive(invite, now)) {
    fail('failed-precondition', 'Invite is inactive or expired.');
  }
}

function isInviteActive(invite: FirestoreData, now: Timestamp): boolean {
  const active = invite.active;
  if (active !== true) {
    return false;
  }
  const expiresAt = requireTimestamp(invite, 'expiresAt');
  return expiresAt.toMillis() > now.toMillis();
}

async function reserveInviteCode(transaction: Transaction, deps: HandlerDeps): Promise<string> {
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const code = deps.randomCode();
    const inviteSnapshot = await transaction.get(deps.db.collection('invites').doc(code));
    if (!inviteSnapshot.exists) {
      return code;
    }
  }
  fail('internal', 'Could not allocate an invite code.');
}

function randomInviteCode(): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let suffix = '';
  for (let index = 0; index < 4; index += 1) {
    suffix += alphabet[Math.floor(Math.random() * alphabet.length)] ?? 'A';
  }
  return `TANTIN-${suffix}`;
}

function requireAdmin(daret: FirestoreData, uid: string): void {
  if (requireString(daret, 'adminUid') !== uid) {
    fail('permission-denied', 'Only the daret admin can perform this action.');
  }
}

function requireStatus(data: FirestoreData): DaretStatus {
  const status = requireString(data, 'statut');
  if (status === 'brouillon' || status === 'attente' || status === 'actif' || status === 'termine') {
    return status;
  }
  fail('failed-precondition', 'Unsupported daret status.');
}

function requirePeriodStatus(data: FirestoreData): PeriodStatus {
  const status = requireString(data, 'status');
  if (status === 'upcoming' || status === 'current' || status === 'closed') {
    return status;
  }
  fail('failed-precondition', 'Unsupported period status.');
}

function requireExistingData(snapshot: DocumentSnapshot, label: string): FirestoreData {
  if (!snapshot.exists) {
    fail('not-found', `${label} not found.`);
  }
  const data = beforeData(snapshot.data());
  if (data === undefined) {
    fail('failed-precondition', `${label} has no data.`);
  }
  return data;
}

function requiredDoc<T extends DocumentSnapshot>(snapshot: T, label: string): T {
  if (!snapshot.exists) {
    fail('not-found', `${label} not found.`);
  }
  return snapshot;
}

function beforeData(value: unknown): FirestoreData | undefined {
  if (value === undefined) {
    return undefined;
  }
  return recordValue(value, 'document');
}

function dataWithId(snapshot: QueryDocumentSnapshot): FirestoreData {
  return {...snapshot.data(), id: snapshot.id};
}

function readRequiredProfile(uid: string, snapshot: DocumentSnapshot): PersonProfile {
  const data = requireExistingData(snapshot, 'user profile');
  return {
    uid,
    prenom: requireString(data, 'prenom'),
    nom: requireString(data, 'nom'),
    name: requireString(data, 'name'),
    initials: requireString(data, 'initials'),
    phone: requireString(data, 'phone'),
    avatarPalette: requireStringArray(data, 'avatarPalette'),
  };
}

function ensureMemberDocs(memberUids: string[], memberDocs: FirestoreData[]): void {
  const seen = new Set(memberDocs.map((member) => requireString(member, 'uid')));
  for (const uid of memberUids) {
    if (!seen.has(uid)) {
      fail('failed-precondition', `Missing member document for ${uid}.`);
    }
  }
}

function hasDraftPlan(daret: FirestoreData): boolean {
  return daret.draftMembers !== undefined || daret.draftPeriods !== undefined;
}

async function expandDraftPlan(
  transaction: Transaction,
  db: Firestore,
  daret: FirestoreData,
  adminUid: string,
  now: Timestamp,
): Promise<DraftExpansion> {
  const draftMembers = requireRecordArray(daret, 'draftMembers');
  const draftPeriods = requireRecordArray(daret, 'draftPeriods');
  const periodesCount = requirePositiveInteger(daret, 'periodesCount');
  if (draftMembers.length < periodesCount) {
    fail('failed-precondition', 'Every period needs an assigned member or invite.');
  }

  const memberProfiles: PersonProfile[] = [];
  const seen = new Set<string>();
  for (const draftMember of draftMembers) {
    const uid = requireString(draftMember, 'uid');
    validateDraftMemberUid(uid);
    if (seen.has(uid)) {
      fail('failed-precondition', 'Draft members must be unique.');
    }
    seen.add(uid);
    if (isPendingMemberUid(uid)) {
      memberProfiles.push(readPendingDraftProfile(draftMember));
      continue;
    }
    const profileSnapshot = await transaction.get(db.collection('users').doc(uid));
    memberProfiles.push(readRequiredProfile(uid, profileSnapshot));
  }
  if (!seen.has(adminUid)) {
    fail('failed-precondition', 'The admin must be included in draft members.');
  }

  const memberDocs = memberProfiles.map((profile) => {
    const isAdmin = profile.uid === adminUid;
    return memberDocument(profile, isAdmin ? 'admin' : 'member', isAdmin ? 'approved' : 'pending', now);
  });
  const memberUids = memberProfiles.map((profile) => profile.uid);
  const periodPlans = readDraftPeriodPlans(daret, draftPeriods, now);
  return {memberUids, memberDocs, periodPlans};
}

function readDraftPeriodPlans(
  daret: FirestoreData,
  draftPeriods: FirestoreData[],
  now: Timestamp,
): PeriodPlan[] {
  const startDate = optionalTimestamp(daret, 'prochaineDate') ?? now;
  const frequence = requireString(daret, 'frequence');
  const montant = requirePositiveInteger(daret, 'montant');
  const periodesCount = requirePositiveInteger(daret, 'periodesCount');
  return draftPeriods.map((period) => {
    const index = requirePositiveInteger(period, 'index');
    return {
      id: periodId(index),
      index,
      recipientUids: requireStringArray(period, 'recipientUids'),
      shares: requireNumberMap(period, 'shares'),
      scheduledDate: scheduleDate(startDate, frequence, index - 1),
      potAmount: payoutFromOtherSharesAmount(montant, periodesCount),
      status: 'upcoming',
    };
  });
}

function readPendingDraftProfile(member: FirestoreData): PersonProfile {
  const uid = requireString(member, 'uid');
  const index = optionalNumber(member, 'inviteIndex') ?? 1;
  const prenom = optionalString(member, 'prenom') ?? `Invitation ${index}`;
  const nom = optionalString(member, 'nom') ?? '';
  const name = optionalString(member, 'name') ?? (nom.length > 0 ? `${prenom} ${nom}` : prenom);
  const initials = optionalString(member, 'initials') ?? 'IN';
  const avatarPalette = requireStringArray(member, 'avatarPalette');
  return {
    uid,
    prenom,
    nom,
    name,
    initials,
    phone: '',
    avatarPalette,
  };
}

function validateDraftMemberUid(uid: string): void {
  if (!UID_PATTERN.test(uid)) {
    fail('failed-precondition', 'Draft member uid is invalid.');
  }
}

function isPendingMemberUid(uid: string): boolean {
  return uid.startsWith(PENDING_MEMBER_PREFIX);
}

function buildDefaultPeriods(
  daret: FirestoreData,
  memberUids: string[],
  now: Timestamp,
): PeriodPlan[] {
  const periodesCount = requirePositiveInteger(daret, 'periodesCount');
  const startDate = optionalTimestamp(daret, 'prochaineDate') ?? now;
  const frequence = requireString(daret, 'frequence');
  const montant = requirePositiveInteger(daret, 'montant');
  const plans: PeriodPlan[] = [];
  for (let index = 1; index <= periodesCount; index += 1) {
    const recipientUid = memberUids[index - 1];
    if (recipientUid === undefined) {
      fail('failed-precondition', 'Every generated period needs a recipient.');
    }
    plans.push({
      id: periodId(index),
      index,
      recipientUids: [recipientUid],
      shares: {[recipientUid]: 100},
      scheduledDate: scheduleDate(startDate, frequence, index - 1),
      potAmount: payoutFromOtherSharesAmount(montant, periodesCount),
      status: 'upcoming',
    });
  }
  return plans;
}

function readPeriodPlan(snapshot: DocumentSnapshot | QueryDocumentSnapshot): PeriodPlan {
  const data = requireExistingData(snapshot, 'period');
  return {
    id: snapshot.id,
    index: requirePositiveInteger(data, 'index'),
    recipientUids: requireStringArray(data, 'recipientUids'),
    shares: requireNumberMap(data, 'shares'),
    scheduledDate: requireTimestamp(data, 'scheduledDate'),
    potAmount: requirePositiveInteger(data, 'potAmount'),
    status: requirePeriodStatus(data),
  };
}

function validatePeriodPlans(plans: PeriodPlan[], memberUids: string[], periodesCount: number): void {
  if (plans.length !== periodesCount) {
    fail('failed-precondition', 'The number of periods must match periodesCount.');
  }
  const memberSet = new Set(memberUids);
  const recipientsSeen = new Set<string>();
  for (let expectedIndex = 1; expectedIndex <= periodesCount; expectedIndex += 1) {
    const plan = plans.find((item) => item.index === expectedIndex);
    if (plan === undefined || plan.id !== periodId(expectedIndex)) {
      fail('failed-precondition', 'Periods must use zero-padded ordered IDs.');
    }
    if (plan.recipientUids.length === 0) {
      fail('failed-precondition', 'Every period needs a recipient.');
    }
    let shareSum = 0;
    for (const uid of plan.recipientUids) {
      if (!memberSet.has(uid)) {
        fail('failed-precondition', 'Period recipient must be a member.');
      }
      if (recipientsSeen.has(uid)) {
        fail('failed-precondition', 'Every member can be assigned only once.');
      }
      const share = plan.shares[uid];
      if (share === undefined || !Number.isInteger(share) || share <= 0) {
        fail('failed-precondition', 'Every recipient needs a positive share.');
      }
      recipientsSeen.add(uid);
      shareSum += share;
    }
    if (shareSum !== 100) {
      fail('failed-precondition', 'Period recipient shares must sum to 100.');
    }
  }
  for (const uid of memberUids) {
    if (!recipientsSeen.has(uid)) {
      fail('failed-precondition', 'Every member must be assigned to a period.');
    }
  }
}

function periodDocument(plan: PeriodPlan, status: PeriodStatus, closedAt: Timestamp | null): FirestoreData {
  return {
    index: plan.index,
    recipientUids: plan.recipientUids,
    shares: plan.shares,
    scheduledDate: plan.scheduledDate,
    potAmount: plan.potAmount,
    status,
    paidCount: 0,
    totalCount: 0,
    closedAt,
  };
}

function setContributionsInTransaction(
  transaction: Transaction,
  daretRef: DocumentReference,
  period: PeriodPlan,
  memberUids: string[],
  amount: number,
  periodPlans: PeriodPlan[],
): void {
  const recipientSet = new Set(period.recipientUids);
  const counts = {paidCount: 0, totalCount: 0};
  for (const uid of memberUids) {
    const isRecipient = recipientSet.has(uid);
    if (!isRecipient) {
      counts.totalCount += 1;
    }
    transaction.set(
      daretRef.collection('periods').doc(period.id).collection('contributions').doc(uid),
      contributionDocument(
        uid,
        isRecipient ? 'recipient' : 'apayer',
        isRecipient ? 0 : contributionAmountForMember(uid, amount, periodPlans),
      ),
      {merge: false},
    );
  }
  transaction.set(
    daretRef.collection('periods').doc(period.id),
    {paidCount: counts.paidCount, totalCount: counts.totalCount},
    {merge: true},
  );
}

function incrementRecipientStats(transaction: Transaction, db: Firestore, period: PeriodPlan): void {
  for (const uid of period.recipientUids) {
    const share = period.shares[uid] ?? 0;
    transaction.set(
      db.collection('users').doc(uid),
      {
        stats: {
          totalRecuVie: FieldValue.increment(amountForShare(period.potAmount, share)),
        },
        updatedAt: Timestamp.now(),
      },
      {merge: true},
    );
  }
}

function grossCagnotteAmount(amount: number, periodesCount: number): number {
  return amount * periodesCount;
}

function payoutFromOtherSharesAmount(amount: number, periodesCount: number): number {
  return amount * Math.max(periodesCount - 1, 0);
}

function contributionAmountForMember(uid: string, amount: number, periodPlans: PeriodPlan[]): number {
  for (const plan of periodPlans) {
    const share = plan.shares[uid];
    if (share !== undefined) {
      return amountForShare(amount, share);
    }
  }
  fail('failed-precondition', 'Every member must have a contribution share.');
}

function amountForShare(amount: number, share: number): number {
  return Math.round((amount * share) / 100);
}

function countContributions(contributions: FirestoreData[]): {paidCount: number; totalCount: number} {
  let paidCount = 0;
  let totalCount = 0;
  for (const contribution of contributions) {
    const state = optionalString(contribution, 'state');
    if (state === 'recipient') {
      continue;
    }
    totalCount += 1;
    if (state === 'confirme') {
      paidCount += 1;
    }
  }
  return {paidCount, totalCount};
}

function contributionDocument(
  payerUid: string,
  state: ContributionState,
  amount: number,
  overrides: Partial<{
    paidDeclaredAt: Timestamp | null;
    confirmedAt: Timestamp | null;
    confirmedByUid: string | null;
  }> = {},
): FirestoreData {
  return {
    payerUid,
    state,
    amount,
    paidDeclaredAt: overrides.paidDeclaredAt ?? null,
    confirmedAt: overrides.confirmedAt ?? null,
    confirmedByUid: overrides.confirmedByUid ?? null,
  };
}

function memberDocument(
  profile: PersonProfile,
  role: 'admin' | 'member',
  approvalStatus: 'pending' | 'approved',
  joinedAt: Timestamp,
  groupePart: number | null = null,
): FirestoreData {
  return {
    uid: profile.uid,
    role,
    joinedAt,
    approvalStatus,
    name: profile.name,
    prenom: profile.prenom,
    initials: profile.initials,
    avatarPalette: profile.avatarPalette,
    groupePart,
  };
}

function userDocument(
  profile: PersonProfile,
  now: Timestamp,
  stats: {daretsActifs: number; totalRecuVie: number} = {daretsActifs: 0, totalRecuVie: 0},
): FirestoreData {
  return {
    prenom: profile.prenom,
    nom: profile.nom,
    name: profile.name,
    initials: profile.initials,
    phone: profile.phone,
    photoUrl: null,
    avatarPalette: profile.avatarPalette,
    fcmTokens: [],
    settings: {
      defaultEcheanceDay: 5,
      graceDays: 2,
      lang: 'fr',
      notifPrefs: {contributions: true, reminders: true, turns: true},
    },
    stats,
    createdAt: now,
    updatedAt: now,
  };
}

function activityDocument(input: {
  type: ActivityType;
  actorUid: string;
  text: string;
  createdAt: Timestamp;
  amount?: number;
  periodIndex?: number;
}): FirestoreData {
  return {
    type: input.type,
    actorUid: input.actorUid,
    text: input.text,
    amount: input.amount ?? null,
    periodIndex: input.periodIndex ?? null,
    createdAt: input.createdAt,
  };
}

function notificationDocument(input: {
  icon: string;
  text: string;
  createdAt: Timestamp;
  action?: string;
  daretId?: string;
}): FirestoreData {
  return {
    icon: input.icon,
    text: input.text,
    action: input.action ?? null,
    daretId: input.daretId ?? null,
    unread: true,
    createdAt: input.createdAt,
  };
}

function scheduleDate(startDate: Timestamp, frequence: string, zeroBasedIndex: number): Timestamp {
  const start = startDate.toDate();
  if (frequence === 'Hebdomadaire') {
    return Timestamp.fromDate(
      new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth(), start.getUTCDate() + zeroBasedIndex * 7)),
    );
  }
  return Timestamp.fromDate(
    new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth() + zeroBasedIndex, start.getUTCDate())),
  );
}

function periodId(index: number): string {
  return index.toString().padStart(2, '0');
}

function dateKey(timestamp: Timestamp): string {
  const date = timestamp.toDate();
  const year = date.getUTCFullYear().toString();
  const month = (date.getUTCMonth() + 1).toString().padStart(2, '0');
  const day = date.getUTCDate().toString().padStart(2, '0');
  return `${year}${month}${day}`;
}

function recordValue(value: unknown, field: string): FirestoreData {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    fail('failed-precondition', `${field} must be an object.`);
  }
  return value as FirestoreData;
}

function requireRecord(data: FirestoreData, field: string): FirestoreData {
  return recordValue(data[field], field);
}

function requireString(data: FirestoreData, field: string): string {
  const value = data[field];
  if (typeof value !== 'string' || value.length === 0) {
    fail('failed-precondition', `${field} must be a string.`);
  }
  return value;
}

function optionalString(data: FirestoreData, field: string): string | undefined {
  const value = data[field];
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== 'string') {
    fail('failed-precondition', `${field} must be a string.`);
  }
  return value;
}

function optionalNumber(data: FirestoreData, field: string): number | undefined {
  const value = data[field];
  if (value === undefined || value === null) {
    return undefined;
  }
  return positiveInteger(value, field);
}

function requirePositiveInteger(data: FirestoreData, field: string): number {
  return positiveInteger(data[field], field);
}

function positiveInteger(value: unknown, field: string): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < 0) {
    fail('failed-precondition', `${field} must be a non-negative integer.`);
  }
  return value;
}

function requireStringArray(data: FirestoreData, field: string): string[] {
  const value = data[field];
  if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) {
    fail('failed-precondition', `${field} must be a string array.`);
  }
  return value as string[];
}

function requireRecordArray(data: FirestoreData, field: string): FirestoreData[] {
  const value = data[field];
  if (!Array.isArray(value)) {
    fail('failed-precondition', `${field} must be an array.`);
  }
  return value.map((item, index) => recordValue(item, `${field}.${index}`));
}

function requireNumberMap(data: FirestoreData, field: string): Record<string, number> {
  const record = requireRecord(data, field);
  const result: Record<string, number> = {};
  for (const [key, value] of Object.entries(record)) {
    if (typeof value !== 'number' || !Number.isInteger(value)) {
      fail('failed-precondition', `${field}.${key} must be an integer.`);
    }
    result[key] = value;
  }
  return result;
}

function requireTimestamp(data: FirestoreData, field: string): Timestamp {
  const timestamp = optionalTimestamp(data, field);
  if (timestamp === undefined) {
    fail('failed-precondition', `${field} must be a Timestamp.`);
  }
  return timestamp;
}

function optionalTimestamp(data: FirestoreData, field: string): Timestamp | undefined {
  const value = data[field];
  if (value === undefined || value === null) {
    return undefined;
  }
  if (value instanceof Timestamp) {
    return value;
  }
  if (value instanceof Date) {
    return Timestamp.fromDate(value);
  }
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    const candidate = value as {toDate: () => Date};
    return Timestamp.fromDate(candidate.toDate());
  }
  fail('failed-precondition', `${field} must be a Timestamp.`);
}

interface SeedPerson extends PersonProfile {
  id: number;
  stats: {daretsActifs: number; totalRecuVie: number};
}

interface SeedDaret {
  id: string;
  root: FirestoreData;
  members: FirestoreData[];
  periods: Array<{
    id: string;
    root: FirestoreData;
    contributions: FirestoreData[];
  }>;
  activity: Array<{id: string; root: FirestoreData}>;
}

interface SeedDataset {
  people: SeedPerson[];
  darets: SeedDaret[];
  notifications: Array<{id: string; root: FirestoreData}>;
}

function buildSeedDataset(yasmineUid: string, now: Timestamp): SeedDataset {
  const palettes = [
    ['#5247E6', '#E7E5FB'],
    ['#F5A623', '#FBEFD6'],
    ['#C75B39', '#F6E1D7'],
    ['#2E9E6B', '#DCF0E6'],
    ['#352DA8', '#E7E5FB'],
    ['#D2483F', '#F8DAD7'],
  ];
  const yasmine = seedPerson(0, yasmineUid, 'Yasmine', 'Benali', palettes[0] ?? [], '+212 6 61 24 88 07');
  yasmine.stats = {daretsActifs: 2, totalRecuVie: 4800};
  const people = [
    yasmine,
    seedPerson(1, 'seed-person-01', 'Karim', 'Tazi', palettes[0] ?? [], phoneFor(1)),
    seedPerson(2, 'seed-person-02', 'Salma', 'Idrissi', palettes[1] ?? [], phoneFor(2)),
    seedPerson(3, 'seed-person-03', 'Mehdi', 'Alaoui', palettes[2] ?? [], phoneFor(3)),
    seedPerson(4, 'seed-person-04', 'Nadia', 'Bennani', palettes[3] ?? [], phoneFor(4)),
    seedPerson(5, 'seed-person-05', 'Omar', 'Cherkaoui', palettes[4] ?? [], phoneFor(5)),
    seedPerson(6, 'seed-person-06', 'Aïcha', 'Fassi', palettes[5] ?? [], phoneFor(6)),
    seedPerson(7, 'seed-person-07', 'Reda', 'Lahlou', palettes[0] ?? [], phoneFor(7)),
    seedPerson(8, 'seed-person-08', 'Sofia', 'Berrada', palettes[1] ?? [], phoneFor(8)),
    seedPerson(9, 'seed-person-09', 'Younes', 'Sebti', palettes[2] ?? [], phoneFor(9)),
    seedPerson(10, 'seed-person-10', 'Lina', 'Chraibi', palettes[3] ?? [], phoneFor(10)),
    seedPerson(11, 'seed-person-11', 'Hamza', 'Naciri', palettes[4] ?? [], phoneFor(11)),
    seedPerson(12, 'seed-person-12', 'Imane', 'Kettani', palettes[5] ?? [], phoneFor(12)),
  ];
  const byId = new Map(people.map((person) => [person.id, person]));

  const d1Members = [0, 1, 2, 4, 6, 7, 8, 10, 11, 3, 5, 9];
  const d2Members = [0, 2, 4, 6, 8, 10, 11, 12];
  const d3Members = [0, 1, 5, 7, 9, 12];
  const d4Members = [0, 2, 4, 6, 8, 10];

  const darets = [
    buildSeedDaret({
      id: 'd1',
      nom: 'Daret Famille',
      cover: '🏡',
      accent: '#5247E6',
      montant: 1500,
      frequence: 'Mensuel',
      periodesCount: 12,
      statut: 'actif',
      adminId: 0,
      currentPeriode: 4,
      prochaineDate: ts('2026-06-05T00:00:00Z'),
      createdAt: ts('2026-02-20T00:00:00Z'),
      startedAt: ts('2026-03-05T00:00:00Z'),
      memberIds: d1Members,
      approvedIds: d1Members,
      order: [
        [3],
        [6],
        [9],
        [1],
        [0],
        [2],
        [4],
        [5],
        [7, 8],
        [10],
        [11],
        [12],
      ],
      dates: [
        '2026-03-05T00:00:00Z',
        '2026-04-05T00:00:00Z',
        '2026-05-05T00:00:00Z',
        '2026-06-05T00:00:00Z',
        '2026-07-05T00:00:00Z',
        '2026-08-05T00:00:00Z',
        '2026-09-05T00:00:00Z',
        '2026-10-05T00:00:00Z',
        '2026-11-05T00:00:00Z',
        '2026-12-05T00:00:00Z',
        '2027-01-05T00:00:00Z',
        '2027-02-05T00:00:00Z',
      ],
      currentStates: new Map([
        [3, 'confirme'],
        [6, 'confirme'],
        [9, 'confirme'],
        [2, 'confirme'],
        [4, 'confirme'],
        [5, 'confirme'],
        [7, 'confirme'],
        [8, 'attente'],
        [0, 'apayer'],
        [10, 'apayer'],
        [11, 'retard'],
        [12, 'apayer'],
      ]),
      peopleById: byId,
    }),
    buildSeedDaret({
      id: 'd2',
      nom: 'Daret des Copines',
      cover: '💕',
      accent: '#C75B39',
      montant: 2000,
      frequence: 'Mensuel',
      periodesCount: 8,
      statut: 'actif',
      adminId: 2,
      currentPeriode: 3,
      prochaineDate: ts('2026-06-03T00:00:00Z'),
      createdAt: ts('2026-03-20T00:00:00Z'),
      startedAt: ts('2026-04-03T00:00:00Z'),
      memberIds: d2Members,
      approvedIds: d2Members,
      order: [[2], [4], [0], [6], [8], [10], [11], [12]],
      dates: [
        '2026-04-03T00:00:00Z',
        '2026-05-03T00:00:00Z',
        '2026-06-03T00:00:00Z',
        '2026-07-03T00:00:00Z',
        '2026-08-03T00:00:00Z',
        '2026-09-03T00:00:00Z',
        '2026-10-03T00:00:00Z',
        '2026-11-03T00:00:00Z',
      ],
      currentStates: new Map([
        [2, 'confirme'],
        [4, 'confirme'],
        [6, 'confirme'],
        [8, 'confirme'],
        [10, 'attente'],
        [11, 'confirme'],
        [12, 'apayer'],
        [0, 'recipient'],
      ]),
      peopleById: byId,
    }),
    buildSeedDaret({
      id: 'd3',
      nom: 'Collègues du Bureau',
      cover: '💼',
      accent: '#2E9E6B',
      montant: 1000,
      frequence: 'Mensuel',
      periodesCount: 6,
      statut: 'attente',
      adminId: 1,
      currentPeriode: 0,
      prochaineDate: null,
      createdAt: ts('2026-06-01T00:00:00Z'),
      startedAt: null,
      memberIds: d3Members,
      approvedIds: [1, 5, 0],
      order: [[1], [5], [0], [7], [9], [12]],
      dates: [
        '2026-07-05T00:00:00Z',
        '2026-08-05T00:00:00Z',
        '2026-09-05T00:00:00Z',
        '2026-10-05T00:00:00Z',
        '2026-11-05T00:00:00Z',
        '2026-12-05T00:00:00Z',
      ],
      currentStates: new Map(),
      peopleById: byId,
    }),
    buildSeedDaret({
      id: 'd4',
      nom: 'Cagnotte Voyage',
      cover: '✈️',
      accent: '#F5A623',
      montant: 800,
      frequence: 'Mensuel',
      periodesCount: 6,
      statut: 'termine',
      adminId: 0,
      currentPeriode: 6,
      prochaineDate: null,
      createdAt: ts('2025-08-01T00:00:00Z'),
      startedAt: ts('2025-09-05T00:00:00Z'),
      closedAt: ts('2026-03-05T00:00:00Z'),
      memberIds: d4Members,
      approvedIds: d4Members,
      order: [[0], [2], [4], [6], [8], [10]],
      dates: [
        '2025-09-05T00:00:00Z',
        '2025-10-05T00:00:00Z',
        '2025-11-05T00:00:00Z',
        '2025-12-05T00:00:00Z',
        '2026-01-05T00:00:00Z',
        '2026-02-05T00:00:00Z',
      ],
      currentStates: new Map(),
      peopleById: byId,
    }),
  ];

  const notifications = [
    notificationSeed('n1', 'bell', 'Payez 1 500 DH pour Daret Famille avant le 5 juin', now, 'pay', 'd1'),
    notificationSeed('n2', 'gift', "C'est presque votre tour dans Daret des Copines !", ts('2026-06-02T07:00:00Z'), 'payout', 'd2'),
    notificationSeed('n3', 'check', 'Reda a confirmé son paiement', ts('2026-06-01T21:00:00Z'), undefined, 'd1', false),
    notificationSeed('n4', 'user', 'Omar a rejoint Collègues du Bureau', ts('2026-06-01T12:00:00Z'), undefined, 'd3', false),
    notificationSeed('n5', 'clock', 'Hamza est en retard de paiement', ts('2026-06-01T08:00:00Z'), undefined, 'd1', false),
  ];

  attachActivity(darets, people);
  return {people, darets, notifications};
}

function seedPerson(
  id: number,
  uid: string,
  prenom: string,
  nom: string,
  avatarPalette: string[],
  phone: string,
): SeedPerson {
  return {
    id,
    uid,
    prenom,
    nom,
    name: `${prenom} ${nom}`,
    initials: `${prenom[0] ?? ''}${nom[0] ?? ''}`.toUpperCase(),
    phone,
    avatarPalette,
    stats: {daretsActifs: 0, totalRecuVie: 0},
  };
}

function phoneFor(id: number): string {
  const n = (id * 7349117 + 12830561) % 100000000;
  const s = n.toString().padStart(8, '0');
  return `+212 6 ${s.slice(0, 2)} ${s.slice(2, 4)} ${s.slice(4, 6)} ${s.slice(6, 8)}`;
}

function buildSeedDaret(input: {
  id: string;
  nom: string;
  cover: string;
  accent: string;
  montant: number;
  frequence: string;
  periodesCount: number;
  statut: DaretStatus;
  adminId: number;
  currentPeriode: number;
  prochaineDate: Timestamp | null;
  createdAt: Timestamp;
  startedAt: Timestamp | null;
  closedAt?: Timestamp | null;
  memberIds: number[];
  approvedIds: number[];
  order: number[][];
  dates: string[];
  currentStates: Map<number, ContributionState>;
  peopleById: Map<number, SeedPerson>;
}): SeedDaret {
  const memberUids = input.memberIds.map((id) => requireSeedPerson(input.peopleById, id).uid);
  const admin = requireSeedPerson(input.peopleById, input.adminId);
  const root: FirestoreData = {
    nom: input.nom,
    cover: input.cover,
    accent: input.accent,
    montant: input.montant,
    frequence: input.frequence,
    periodesCount: input.periodesCount,
    cagnotteParPeriode: grossCagnotteAmount(input.montant, input.periodesCount),
    statut: input.statut,
    adminUid: admin.uid,
    memberUids,
    currentPeriode: input.currentPeriode,
    prochaineDate: input.prochaineDate,
    inviteCode: null,
    settings: {echeanceDay: 5, graceDays: 2},
    createdAt: input.createdAt,
    startedAt: input.startedAt,
    closedAt: input.closedAt ?? null,
    updatedAt: input.createdAt,
  };
  const members = input.memberIds.map((id) => {
    const person = requireSeedPerson(input.peopleById, id);
    return memberDocument(
      person,
      id === input.adminId ? 'admin' : 'member',
      input.approvedIds.includes(id) ? 'approved' : 'pending',
      input.createdAt,
    );
  });
  const periods = input.order.map((recipientIds, zeroBasedIndex) => {
    const index = zeroBasedIndex + 1;
    const recipients = recipientIds.map((id) => requireSeedPerson(input.peopleById, id));
    const shares = equalShares(recipients.map((person) => person.uid));
    const status = periodSeedStatus(input.statut, index, input.currentPeriode);
    const plan: PeriodPlan = {
      id: periodId(index),
      index,
      recipientUids: recipients.map((person) => person.uid),
      shares,
      scheduledDate: ts(input.dates[zeroBasedIndex] ?? input.dates[0] ?? '2026-06-05T00:00:00Z'),
      potAmount: payoutFromOtherSharesAmount(input.montant, input.periodesCount),
      status,
    };
    const contributions = buildSeedContributions(input, plan, memberUids, input.peopleById);
    const counts = countContributions(contributions);
    return {
      id: plan.id,
      root: {
        ...periodDocument(plan, status, status === 'closed' ? plan.scheduledDate : null),
        paidCount: counts.paidCount,
        totalCount: counts.totalCount,
      },
      contributions,
    };
  });
  return {id: input.id, root, members, periods, activity: []};
}

function buildSeedContributions(
  input: {
    montant: number;
    currentPeriode: number;
    statut: DaretStatus;
    currentStates: Map<number, ContributionState>;
    memberIds: number[];
    order: number[][];
  },
  plan: PeriodPlan,
  memberUids: string[],
  peopleById: Map<number, SeedPerson>,
): FirestoreData[] {
  if (input.statut === 'attente') {
    return [];
  }
  const recipientSet = new Set(plan.recipientUids);
  const currentIdToState = new Map<string, ContributionState>();
  for (const [id, state] of input.currentStates.entries()) {
    currentIdToState.set(requireSeedPerson(peopleById, id).uid, state);
  }
  return memberUids.map((uid) => {
    const isRecipient = recipientSet.has(uid);
    let state: ContributionState = isRecipient ? 'recipient' : 'apayer';
    if (plan.status === 'closed' && !isRecipient) {
      state = 'confirme';
    }
    if (plan.status === 'current') {
      state = currentIdToState.get(uid) ?? state;
    }
    const amount = isRecipient
      ? 0
      : amountForShare(input.montant, seedMemberShare(uid, input.memberIds, input.order, peopleById));
    return contributionDocument(uid, state, amount, {
      paidDeclaredAt: state === 'attente' || state === 'confirme' ? plan.scheduledDate : null,
      confirmedAt: state === 'confirme' ? plan.scheduledDate : null,
      confirmedByUid: state === 'confirme' ? plan.recipientUids[0] ?? null : null,
    });
  });
}

function seedMemberShare(
  uid: string,
  memberIds: number[],
  order: number[][],
  peopleById: Map<number, SeedPerson>,
): number {
  for (const recipientIds of order) {
    const recipients = recipientIds.map((id) => requireSeedPerson(peopleById, id));
    const shares = equalShares(recipients.map((person) => person.uid));
    const share = shares[uid];
    if (share !== undefined) {
      return share;
    }
  }
  if (memberIds.some((id) => requireSeedPerson(peopleById, id).uid === uid)) {
    fail('internal', `Seed member ${uid} is not assigned to a period.`);
  }
  fail('internal', `Unknown seed member ${uid}.`);
}

function periodSeedStatus(daretStatus: DaretStatus, index: number, currentPeriode: number): PeriodStatus {
  if (daretStatus === 'termine') {
    return 'closed';
  }
  if (daretStatus !== 'actif') {
    return 'upcoming';
  }
  if (index < currentPeriode) {
    return 'closed';
  }
  if (index === currentPeriode) {
    return 'current';
  }
  return 'upcoming';
}

function equalShares(uids: string[]): Record<string, number> {
  if (uids.length === 0) {
    return {};
  }
  const base = Math.floor(100 / uids.length);
  let remainder = 100 - base * uids.length;
  const shares: Record<string, number> = {};
  for (const uid of uids) {
    shares[uid] = base + (remainder > 0 ? 1 : 0);
    remainder -= 1;
  }
  return shares;
}

function attachActivity(darets: SeedDaret[], people: SeedPerson[]): void {
  const byDaret = new Map(darets.map((daret) => [daret.id, daret]));
  const byId = new Map(people.map((person) => [person.id, person]));
  const entries = [
    activitySeed('a1', 'd1', 'paiement', 1, 'a confirmé le paiement de Reda', ts('2026-06-02T08:48:00Z'), 1500),
    activitySeed('a2', 'd2', 'tour', 0, 'Votre tour approche - vous recevez bientôt', ts('2026-06-02T08:00:00Z'), 16000),
    activitySeed('a3', 'd1', 'rappel', 11, 'Rappel envoyé à Hamza', ts('2026-06-02T06:00:00Z')),
    activitySeed('a4', 'd3', 'membre', 5, 'Omar a rejoint Collègues du Bureau', ts('2026-06-01T12:00:00Z')),
    activitySeed('a5', 'd1', 'paiement', 6, 'a confirmé le paiement de Nadia', ts('2026-06-01T10:00:00Z'), 1500),
    activitySeed('a6', 'd2', 'demarre', 2, 'Daret des Copines a démarré', ts('2026-04-03T08:00:00Z')),
    activitySeed('a7', 'd4', 'cloture', 0, 'Cagnotte Voyage est clôturé', ts('2026-03-05T08:00:00Z')),
  ];
  for (const entry of entries) {
    const daret = byDaret.get(entry.daretId);
    const person = byId.get(entry.actorId);
    if (daret === undefined || person === undefined) {
      continue;
    }
    daret.activity.push({
      id: entry.id,
      root: activityDocument({
        type: entry.type,
        actorUid: person.uid,
        text: entry.text,
        amount: entry.amount,
        createdAt: entry.createdAt,
      }),
    });
  }
}

function activitySeed(
  id: string,
  daretId: string,
  type: ActivityType,
  actorId: number,
  text: string,
  createdAt: Timestamp,
  amount?: number,
): {id: string; daretId: string; type: ActivityType; actorId: number; text: string; createdAt: Timestamp; amount?: number} {
  return {id, daretId, type, actorId, text, createdAt, amount};
}

function notificationSeed(
  id: string,
  icon: string,
  text: string,
  createdAt: Timestamp,
  action?: string,
  daretId?: string,
  unread = true,
): {id: string; root: FirestoreData} {
  return {
    id,
    root: {
      ...notificationDocument({icon, text, action, daretId, createdAt}),
      unread,
    },
  };
}

function requireSeedPerson(peopleById: Map<number, SeedPerson>, id: number): SeedPerson {
  const person = peopleById.get(id);
  if (person === undefined) {
    fail('internal', `Missing seed person ${id}.`);
  }
  return person;
}

function ts(isoDate: string): Timestamp {
  return Timestamp.fromDate(new Date(isoDate));
}

export const __testables = {
  parseCallable,
  startDaretHandler,
  createInviteHandler,
  previewDaretHandler,
  joinDaretHandler,
  approveDaretHandler,
  advancePeriodHandler,
  closePeriodHandler,
  closeDaretHandler,
  sendNudgeHandler,
  onContributionWrittenHandler,
  onMemberCreatedHandler,
  dailyRemindersHandler,
  seedDevHandler,
  buildSeedDataset,
  periodId,
  schemas: {
    daretIdInput,
    inviteInput,
    closePeriodInput,
    sendNudgeInput,
    seedDevInput,
  },
};
