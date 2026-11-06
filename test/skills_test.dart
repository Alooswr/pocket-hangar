import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/core/sde/sde_models.dart';
import 'package:pocket_hangar/core/sde/sde_repository.dart';
import 'package:pocket_hangar/features/skills/skill_math.dart';
import 'package:pocket_hangar/features/skills/skills_data.dart';

void main() {
  group('skill points per level', () {
    test('rank 1: 250, 1415, 8000, 45255, 256000', () {
      expect([for (var l = 1; l <= 5; l++) spForLevel(l, 1)], [250, 1415, 8000, 45255, 256000]);
    });

    test('scales with rank', () {
      expect(spForLevel(5, 3), 768000);
      expect(spForLevel(0, 5), 0);
      expect(spForLevel(4, 8), 362039);
    });
  });

  group('training speed', () {
    test('primary + secondary / 2, half for Alpha', () {
      expect(spPerMinute(primary: 27, secondary: 21), 37.5);
      expect(spPerMinute(primary: 27, secondary: 21, alpha: true), 18.75);
    });

    test('training time', () {
      expect(trainingTime(spNeeded: 45000, spPerMinute: 30), const Duration(hours: 25));
      expect(trainingTime(spNeeded: 0, spPerMinute: 30), Duration.zero);
    });

    test('clone guess from the server rate', () {
      expect(guessClone(serverRate: 18.75, omegaRate: 37.5), CloneGuess.alpha);
      expect(guessClone(serverRate: 37.4, omegaRate: 37.5), CloneGuess.omega);
      expect(guessClone(serverRate: 45, omegaRate: 37.5), CloneGuess.unknown); // booster or remap
      expect(guessClone(serverRate: null, omegaRate: 37.5), CloneGuess.unknown);
    });
  });

  group('skill overview', () {
    final now = DateTime.utc(2026, 11, 6, 12);
    // Spaceship Command (rank 1, perception / willpower) and Gunnery (rank 1, perception / willpower).
    final info = {
      3327: const SkillTypeInfo(
        typeId: 3327,
        groupId: 257,
        name: LocalName('Spaceship Command', '星舰操控'),
        rank: 1,
        primaryAttributeId: AttrIds.perception,
        secondaryAttributeId: AttrIds.willpower,
      ),
      3300: const SkillTypeInfo(
        typeId: 3300,
        groupId: 255,
        name: LocalName('Gunnery', '射击学'),
        rank: 1,
        primaryAttributeId: AttrIds.perception,
        secondaryAttributeId: AttrIds.willpower,
      ),
    };
    const attributes = {'charisma': 17, 'intelligence': 20, 'memory': 20, 'perception': 27, 'willpower': 17};
    // perception 27 + 3 (implant) = 30, willpower 17 -> 38.5 SP/min
    final implants = {
      9899: {AttrIds.implantBonusToAttribute.keys.firstWhere((k) => AttrIds.implantBonusToAttribute[k] == AttrIds.perception): 3.0},
    };

    test('training queue: times from ESI, attributes with implants, Omega detected', () {
      final start = now.subtract(const Duration(minutes: 100));
      // Level IV of a rank 1 skill: 8000 -> 45255. Started at 8000 SP, 38.5 SP/min.
      final finish = start.add(Duration(milliseconds: ((45255 - 8000) / 38.5 * 60000).round()));
      final o = buildSkillOverview(
        skillsJson: {
          'total_sp': 5000000,
          'unallocated_sp': 0,
          'skills': [
            {'skill_id': 3327, 'skillpoints_in_skill': 8000, 'active_skill_level': 3, 'trained_skill_level': 3},
          ],
        },
        queueJson: [
          {
            'skill_id': 3327,
            'finished_level': 4,
            'queue_position': 0,
            'start_date': start.toIso8601String(),
            'finish_date': finish.toIso8601String(),
            'training_start_sp': 8000,
            'level_start_sp': 8000,
            'level_end_sp': 45255,
          },
          {
            'skill_id': 3327,
            'finished_level': 5,
            'queue_position': 1,
            'start_date': finish.toIso8601String(),
            'finish_date': finish.add(Duration(milliseconds: ((256000 - 45255) / 38.5 * 60000).round())).toIso8601String(),
            'level_start_sp': 45255,
            'level_end_sp': 256000,
          },
        ],
        attributesJson: attributes,
        skillInfo: info,
        implantAttributes: implants,
        now: now,
        fetchedAt: now,
      );
      expect(o.attributes.effective(AttrIds.perception), 30);
      expect(o.omegaRate, closeTo(38.5, 1e-9));
      expect(o.serverRate, closeTo(38.5, 0.01));
      expect(o.clone, CloneGuess.omega);
      expect(o.paused, isFalse);
      expect(o.queue.length, 2);
      expect(o.queue.every((q) => !q.estimated), isTrue);
      expect(o.queueEnd, o.queue.last.finish);
      expect(o.queue.first.progress(now), closeTo(100 * 38.5 / (45255 - 8000), 1e-3));
    });

    test('paused queue: times estimated locally from the attributes', () {
      final o = buildSkillOverview(
        skillsJson: {
          'total_sp': 1000,
          'skills': [
            {'skill_id': 3300, 'skillpoints_in_skill': 250, 'active_skill_level': 1, 'trained_skill_level': 1},
          ],
        },
        queueJson: [
          {'skill_id': 3300, 'finished_level': 2, 'queue_position': 0, 'level_start_sp': 250, 'level_end_sp': 1415},
        ],
        attributesJson: attributes,
        skillInfo: info,
        implantAttributes: const {},
        now: now,
        fetchedAt: now,
      );
      expect(o.paused, isTrue);
      final item = o.queue.single;
      expect(item.estimated, isTrue);
      // perception 27 + willpower 17 / 2 = 35.5 SP/min for 1165 SP
      expect(item.finish!.difference(now), trainingTime(spNeeded: 1415 - 250, spPerMinute: 35.5));
    });

    test('entries that finished after ESI cached the queue are dropped', () {
      final o = buildSkillOverview(
        skillsJson: {'total_sp': 1000, 'skills': const []},
        queueJson: [
          {
            'skill_id': 3300,
            'finished_level': 1,
            'queue_position': 0,
            'start_date': now.subtract(const Duration(hours: 2)).toIso8601String(),
            'finish_date': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'training_start_sp': 0,
            'level_start_sp': 0,
            'level_end_sp': 250,
          },
        ],
        attributesJson: attributes,
        skillInfo: info,
        implantAttributes: const {},
        now: now,
        fetchedAt: now,
      );
      expect(o.queue, isEmpty);
    });
  });
}
