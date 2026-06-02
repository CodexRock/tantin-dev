import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

enum ContributionActorRole {
  payer,
  recipient,
  admin,
  scheduler,
  other,
}

enum ContributionAction {
  declarePaid,
  confirmReceived,
  adminConfirm,
  markOverdue,
  sendNudge,
}

enum DashboardActionType {
  payContribution,
  receiveCurrentPot,
  receiveSoon,
}

class InvalidContributionTransition implements Exception {
  const InvalidContributionTransition({
    required this.current,
    required this.actorRole,
    required this.action,
  });

  final ContributionState current;
  final ContributionActorRole actorRole;
  final ContributionAction action;

  @override
  String toString() {
    return 'InvalidContributionTransition('
        '${current.firestoreValue}, ${actorRole.name}, ${action.name})';
  }
}

class PeriodProgress {
  const PeriodProgress({
    required this.paidCount,
    required this.totalCount,
  });

  final int paidCount;
  final int totalCount;

  double get ratio => totalCount == 0 ? 0 : paidCount / totalCount;
}

class DashboardNextAction {
  const DashboardNextAction({
    required this.type,
    required this.daretId,
    required this.amount,
    required this.date,
  });

  final DashboardActionType type;
  final String daretId;
  final int amount;
  final DateTime date;
}

int cagnotteParPeriode({
  required int montant,
  required int memberCount,
}) {
  if (montant <= 0 || memberCount <= 0) {
    throw ArgumentError('montant and memberCount must be positive');
  }
  return montant * memberCount;
}

List<DateTime> generateSchedule({
  required DateTime startDate,
  required DaretFrequency frequency,
  required int periodesCount,
  required int echeanceDay,
}) {
  if (periodesCount <= 0) {
    throw ArgumentError.value(periodesCount, 'periodesCount');
  }
  if (echeanceDay < 1 || echeanceDay > 31) {
    throw ArgumentError.value(echeanceDay, 'echeanceDay');
  }

  return List<DateTime>.generate(periodesCount, (index) {
    if (frequency == DaretFrequency.hebdomadaire) {
      return DateTime(
        startDate.year,
        startDate.month,
        startDate.day + (index * DateTime.daysPerWeek),
      );
    }

    final monthStart = DateTime(startDate.year, startDate.month + index);
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    return DateTime(
      monthStart.year,
      monthStart.month,
      echeanceDay > lastDay ? lastDay : echeanceDay,
    );
  }, growable: false);
}

Map<String, int> equalShares(List<String> recipientUids) {
  if (recipientUids.isEmpty) {
    throw ArgumentError.value(recipientUids, 'recipientUids');
  }
  final baseShare = 100 ~/ recipientUids.length;
  final remainder = 100 % recipientUids.length;
  return <String, int>{
    for (var index = 0; index < recipientUids.length; index++)
      recipientUids[index]: baseShare + (index < remainder ? 1 : 0),
  };
}

bool hasValidShares(Map<String, int> shares) {
  return shares.isNotEmpty &&
      shares.values.every((share) => share > 0) &&
      shares.values.fold<int>(0, (sum, share) => sum + share) == 100;
}

ContributionState nextContributionState({
  required ContributionState current,
  required ContributionActorRole actorRole,
  required ContributionAction action,
}) {
  final next = switch ((current, actorRole, action)) {
    (
      ContributionState.apayer || ContributionState.retard,
      ContributionActorRole.payer,
      ContributionAction.declarePaid,
    ) =>
      ContributionState.attente,
    (
      ContributionState.attente,
      ContributionActorRole.recipient || ContributionActorRole.admin,
      ContributionAction.confirmReceived,
    ) =>
      ContributionState.confirme,
    (
      ContributionState.apayer ||
          ContributionState.retard ||
          ContributionState.attente,
      ContributionActorRole.admin,
      ContributionAction.adminConfirm,
    ) =>
      ContributionState.confirme,
    (
      ContributionState.apayer,
      ContributionActorRole.scheduler,
      ContributionAction.markOverdue,
    ) =>
      ContributionState.retard,
    (_, _, ContributionAction.sendNudge) => current,
    _ => null,
  };

  if (next == null) {
    throw InvalidContributionTransition(
      current: current,
      actorRole: actorRole,
      action: action,
    );
  }
  return next;
}

PeriodProgress periodProgress(Iterable<Contribution> contributions) {
  final contributionList = contributions.toList(growable: false);
  return PeriodProgress(
    paidCount: contributionList
        .where((item) => item.state == ContributionState.confirme)
        .length,
    totalCount: contributionList
        .where((item) => item.state != ContributionState.recipient)
        .length,
  );
}

bool isYourTurn(DaretPeriod period, String uid) {
  return period.recipientUids.contains(uid);
}

int? yourTurnIndex(Iterable<DaretPeriod> periods, String uid) {
  for (final period in periods) {
    if (isYourTurn(period, uid)) return period.index;
  }
  return null;
}

DashboardNextAction? nextDashboardAction({
  required String uid,
  required Iterable<Daret> darets,
  required Map<String, List<DaretPeriod>> periodsByDaret,
  required Map<String, List<Contribution>> currentContributionsByDaret,
  required DateTime now,
}) {
  final candidates = <DashboardNextAction>[];
  for (final daret in darets.where(
    (item) => item.statut == DaretStatus.actif,
  )) {
    final periods = periodsByDaret[daret.id] ?? const [];
    final currentPeriod = periods
        .where((period) => period.index == daret.currentPeriode)
        .firstOrNull;
    if (currentPeriod == null) continue;

    final contribution = (currentContributionsByDaret[daret.id] ?? const [])
        .where((item) => item.payerUid == uid)
        .firstOrNull;
    if (contribution != null &&
        {
          ContributionState.apayer,
          ContributionState.retard,
        }.contains(contribution.state)) {
      candidates.add(
        DashboardNextAction(
          type: DashboardActionType.payContribution,
          daretId: daret.id,
          amount: contribution.amount,
          date: currentPeriod.scheduledDate,
        ),
      );
      continue;
    }

    if (isYourTurn(currentPeriod, uid)) {
      candidates.add(
        DashboardNextAction(
          type: DashboardActionType.receiveCurrentPot,
          daretId: daret.id,
          amount: currentPeriod.potAmount,
          date: currentPeriod.scheduledDate,
        ),
      );
      continue;
    }

    final upcomingTurns = periods.where(
      (period) =>
          period.index > daret.currentPeriode &&
          isYourTurn(period, uid) &&
          !period.scheduledDate.isBefore(now),
    );
    if (upcomingTurns.isNotEmpty) {
      final upcoming = upcomingTurns.reduce(
        (first, second) =>
            first.scheduledDate.isBefore(second.scheduledDate) ? first : second,
      );
      candidates.add(
        DashboardNextAction(
          type: DashboardActionType.receiveSoon,
          daretId: daret.id,
          amount: upcoming.potAmount,
          date: upcoming.scheduledDate,
        ),
      );
    }
  }

  if (candidates.isEmpty) return null;
  return candidates.reduce((first, second) {
    return first.date.isBefore(second.date) ? first : second;
  });
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
