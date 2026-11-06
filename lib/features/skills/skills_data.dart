import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/esi/esi_client.dart';
import '../../core/providers.dart';
import '../../core/sde/sde_models.dart';
import '../../core/sde/sde_repository.dart';
import '../update/sde_controller.dart';
import 'skill_math.dart';

class QueueItem {
  const QueueItem({
    required this.skillId,
    required this.name,
    required this.level,
    required this.start,
    required this.finish,
    required this.levelStartSp,
    required this.levelEndSp,
    required this.trainingStartSp,
    required this.estimated,
  });

  final int skillId;
  final LocalName name;
  final int level;
  final DateTime? start;
  final DateTime? finish;
  final int levelStartSp;
  final int levelEndSp;
  final int trainingStartSp;

  /// True when the times were computed locally (paused queue), not taken from ESI.
  final bool estimated;

  /// Share of this level already trained at [now] (0..1).
  double progress(DateTime now) {
    final s = start;
    final f = finish;
    final span = levelEndSp - levelStartSp;
    if (span <= 0) return 0;
    var sp = trainingStartSp.toDouble();
    if (s != null && f != null && !estimated && now.isAfter(s)) {
      final t = (now.difference(s).inMilliseconds / f.difference(s).inMilliseconds).clamp(0.0, 1.0);
      sp = trainingStartSp + (levelEndSp - trainingStartSp) * t;
    }
    return ((sp - levelStartSp) / span).clamp(0.0, 1.0);
  }
}

class CharacterAttributes {
  const CharacterAttributes(this.base, this.implantBonus);

  /// ESI /characters/{id}/attributes values.
  final Map<int, double> base;

  /// Sum of the active implants' attribute bonuses, per attribute.
  final Map<int, double> implantBonus;

  double effective(int attributeId) => (base[attributeId] ?? 0) + (implantBonus[attributeId] ?? 0);

  static const order = [
    AttrIds.intelligence,
    AttrIds.memory,
    AttrIds.perception,
    AttrIds.willpower,
    AttrIds.charisma,
  ];
}

class SkillOverview {
  const SkillOverview({
    required this.totalSp,
    required this.unallocatedSp,
    required this.attributes,
    required this.queue,
    required this.paused,
    required this.clone,
    required this.omegaRate,
    required this.serverRate,
    required this.fetchedAt,
    required this.stale,
  });

  final int totalSp;
  final int unallocatedSp;
  final CharacterAttributes attributes;
  final List<QueueItem> queue;
  final bool paused;
  final CloneGuess clone;

  /// SP/min of the first skill in the queue for an Omega clone, from attributes + implants.
  final double? omegaRate;

  /// SP/min the server is actually training at (from the queue dates), when training.
  final double? serverRate;
  final DateTime fetchedAt;
  final bool stale;

  DateTime? get queueEnd => queue.isEmpty ? null : queue.last.finish;

  /// The rate shown to the user: what the server trains at, else our estimate.
  double? get effectiveRate => serverRate ?? (omegaRate == null ? null : omegaRate! * (clone == CloneGuess.alpha ? 0.5 : 1));

  /// Difference between server rate and our Omega/Alpha estimate, in percent, when notable.
  double? get rateMismatchPercent {
    final server = serverRate;
    final omega = omegaRate;
    if (server == null || omega == null || omega <= 0 || clone != CloneGuess.unknown) return null;
    return (server / omega - 1) * 100;
  }
}

/// Builds the overview from the four ESI responses (pure, so tests can feed fixtures).
SkillOverview buildSkillOverview({
  required Map<String, dynamic> skillsJson,
  required List<dynamic> queueJson,
  required Map<String, dynamic> attributesJson,
  required Map<int, SkillTypeInfo> skillInfo,
  required Map<int, Map<int, double>> implantAttributes,
  required DateTime now,
  required DateTime fetchedAt,
  bool stale = false,
}) {
  final base = <int, double>{
    AttrIds.charisma: (attributesJson['charisma'] as num?)?.toDouble() ?? 0,
    AttrIds.intelligence: (attributesJson['intelligence'] as num?)?.toDouble() ?? 0,
    AttrIds.memory: (attributesJson['memory'] as num?)?.toDouble() ?? 0,
    AttrIds.perception: (attributesJson['perception'] as num?)?.toDouble() ?? 0,
    AttrIds.willpower: (attributesJson['willpower'] as num?)?.toDouble() ?? 0,
  };
  final bonus = <int, double>{};
  for (final attrs in implantAttributes.values) {
    for (final e in AttrIds.implantBonusToAttribute.entries) {
      final v = attrs[e.key];
      if (v != null && v != 0) bonus[e.value] = (bonus[e.value] ?? 0) + v;
    }
  }
  final attributes = CharacterAttributes(base, bonus);

  final currentSp = <int, int>{
    for (final s in (skillsJson['skills'] as List<dynamic>? ?? const []))
      ((s as Map<String, dynamic>)['skill_id'] as num).toInt(): (s['skillpoints_in_skill'] as num).toInt(),
  };

  double rateFor(int skillId) {
    final info = skillInfo[skillId];
    if (info == null) return 0;
    return spPerMinute(
      primary: attributes.effective(info.primaryAttributeId),
      secondary: attributes.effective(info.secondaryAttributeId),
    );
  }

  final entries = [
    for (final e in queueJson) e as Map<String, dynamic>,
  ]..sort((a, b) => (a['queue_position'] as num).compareTo(b['queue_position'] as num));
  DateTime? date(Object? v) => v is String ? DateTime.parse(v).toLocal() : null;
  final active = entries.any((e) => e['finish_date'] != null);

  // Server rate from the entry training right now.
  double? serverRate;
  double? omegaRate;
  for (final e in entries) {
    final start = date(e['start_date']);
    final finish = date(e['finish_date']);
    if (start != null && finish != null && finish.isAfter(now)) {
      serverRate = impliedRate(
        trainingStartSp: (e['training_start_sp'] as num?)?.toInt(),
        levelEndSp: (e['level_end_sp'] as num?)?.toInt(),
        start: start,
        finish: finish,
      );
      omegaRate = rateFor((e['skill_id'] as num).toInt());
      break;
    }
  }
  if (omegaRate == null && entries.isNotEmpty) omegaRate = rateFor((entries.first['skill_id'] as num).toInt());
  final clone = guessClone(serverRate: serverRate, omegaRate: omegaRate ?? 0);
  final alpha = clone == CloneGuess.alpha;

  final queue = <QueueItem>[];
  var cursor = now;
  final spAfter = Map<int, int>.of(currentSp);
  for (final e in entries) {
    final skillId = (e['skill_id'] as num).toInt();
    final level = (e['finished_level'] as num).toInt();
    final info = skillInfo[skillId];
    final rank = info?.rank ?? 1;
    final levelStart = (e['level_start_sp'] as num?)?.toInt() ?? spForLevel(level - 1, rank);
    final levelEnd = (e['level_end_sp'] as num?)?.toInt() ?? spForLevel(level, rank);
    var start = date(e['start_date']);
    var finish = date(e['finish_date']);
    var trainingStart = (e['training_start_sp'] as num?)?.toInt() ?? spAfter[skillId] ?? levelStart;
    if (trainingStart < levelStart) trainingStart = levelStart;
    if (finish != null && !finish.isAfter(now)) {
      spAfter[skillId] = levelEnd; // finished since ESI cached the queue
      continue;
    }
    var estimated = false;
    if (!active || finish == null) {
      estimated = true;
      final rate = spPerMinute(
        primary: attributes.effective(info?.primaryAttributeId ?? AttrIds.intelligence),
        secondary: attributes.effective(info?.secondaryAttributeId ?? AttrIds.memory),
        alpha: alpha,
      );
      final needed = levelEnd - (spAfter[skillId] ?? trainingStart).clamp(levelStart, levelEnd);
      start = cursor;
      finish = cursor.add(trainingTime(spNeeded: needed, spPerMinute: rate));
    }
    cursor = finish;
    spAfter[skillId] = levelEnd;
    queue.add(QueueItem(
      skillId: skillId,
      name: info?.name ?? LocalName('Skill $skillId', null),
      level: level,
      start: start,
      finish: finish,
      levelStartSp: levelStart,
      levelEndSp: levelEnd,
      trainingStartSp: trainingStart,
      estimated: estimated,
    ));
  }

  return SkillOverview(
    totalSp: (skillsJson['total_sp'] as num?)?.toInt() ?? 0,
    unallocatedSp: (skillsJson['unallocated_sp'] as num?)?.toInt() ?? 0,
    attributes: attributes,
    queue: queue,
    paused: !active && queue.isNotEmpty,
    clone: clone,
    omegaRate: omegaRate,
    serverRate: serverRate,
    fetchedAt: fetchedAt,
    stale: stale,
  );
}

final skillOverviewProvider = FutureProvider.autoDispose.family<SkillOverview, int>((ref, characterId) async {
  final sde = requireSde(ref);
  final api = ref.watch(eveApiProvider);
  final responses = await Future.wait<EsiResponse<Object?>>([
    api.skills(characterId),
    api.skillQueue(characterId),
    api.attributes(characterId),
    api.implants(characterId),
  ]);
  final skillsJson = responses[0].data as Map<String, dynamic>;
  final queueJson = responses[1].data as List<dynamic>? ?? const [];
  final implants = [for (final i in (responses[3].data as List<dynamic>? ?? const [])) (i as num).toInt()];
  final skillIds = {for (final e in queueJson) ((e as Map<String, dynamic>)['skill_id'] as num).toInt()};
  return buildSkillOverview(
    skillsJson: skillsJson,
    queueJson: queueJson,
    attributesJson: responses[2].data as Map<String, dynamic>,
    skillInfo: await sde.skillTypes(skillIds),
    implantAttributes: await sde.typeAttributes(implants),
    now: DateTime.now(),
    fetchedAt: responses.map((r) => r.fetchedAt).reduce((a, b) => a.isBefore(b) ? a : b),
    stale: responses.any((r) => r.isStale),
  );
});

/// Trained skill levels of a character (for the fitting screen), from ESI /skills.
final characterSkillLevelsProvider = FutureProvider.autoDispose.family<Map<int, int>, int>((ref, characterId) async {
  final resp = await ref.watch(eveApiProvider).skills(characterId);
  final skills = (resp.data as Map<String, dynamic>)['skills'] as List<dynamic>? ?? const [];
  return {
    for (final s in skills)
      ((s as Map<String, dynamic>)['skill_id'] as num).toInt(): (s['active_skill_level'] as num).toInt(),
  };
});
