import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/core/sde/sde_database.dart';
import 'package:pocket_hangar/core/sde/sde_models.dart';
import 'package:pocket_hangar/core/sde/sde_repository.dart';
import 'package:pocket_hangar/core/search/name_search.dart';
import 'package:pocket_hangar/features/fitting/fit.dart';

import 'support/fixture.dart';

int score(String query, String en, [String? zh]) => NameQuery(query).score(en, zh);
int scoreWithTypos(String query, String en, [String? zh]) => NameQuery(query).score(en, zh, typos: true);

const afterburner = ('1MN Afterburner II', '1MN加力燃烧器 II');
const mwd = ('5MN Microwarpdrive II', '5MN微型跃迁推进器 II');

void main() {
  group('folding', () {
    test('lower case, no punctuation, Chinese and Latin split apart', () {
      expect(foldWords('Co-Processor II'), ['co', 'processor', 'ii']);
      expect(foldWords('1MN加力燃烧器 II'), ['1mn', '加力燃烧器', 'ii']);
      expect(foldWords('Y-T8紧凑型5MN微型跃迁推进器'), ['y', 't8', '紧凑型', '5mn', '微型跃迁推进器']);
      expect(foldWords('“裂谷级”（测试）·一'), ['裂谷级', '测试', '一']);
      expect(foldWords('ＲＩＦＴＥＲ　２'), ['rifter', '2']);
    });

    test('a query of only spaces and punctuation is empty', () {
      expect(NameQuery('  ').isEmpty, isTrue);
      expect(NameQuery(' -·—（）').isEmpty, isTrue);
      expect(NameQuery('裂').isEmpty, isFalse);
    });
  });

  group('matching', () {
    test('case, spaces, hyphens and full-width letters do not matter', () {
      for (final q in ['co-processor ii', 'COPROCESSOR II', 'co processor ii', 'ＣＯ－ＰＲＯＣＥＳＳＯＲ ＩＩ']) {
        expect(score(q, 'Co-Processor II', '协处理器 II'), score('Co-Processor II', 'Co-Processor II'), reason: q);
      }
    });

    test('English and Chinese names both match, and a query may mix them', () {
      final (en, zh) = afterburner;
      expect(score('afterburner', en, zh), greaterThan(0));
      expect(score('加力燃烧器', en, zh), greaterThan(0));
      expect(score('1mn加力', en, zh), greaterThan(0));
      expect(score('加力 1mn', en, zh), greaterThan(0));
      expect(score('afterburner 加力', en, zh), greaterThan(0));
      expect(score('加力', mwd.$1, mwd.$2), 0);
    });

    test('tokens match in any order', () {
      final (en, zh) = afterburner;
      expect(score('afterburner 1mn', en, zh), greaterThan(0));
      expect(score('ii 1mn afterb', en, zh), greaterThan(0));
      expect(score('afterburner 5mn', en, zh), 0);
    });

    test('abbreviations: initials, letters from a word start, ab and mwd', () {
      expect(score('lse', 'Large Shield Extender II'), greaterThan(0));
      expect(score('lar shi ext', 'Large Shield Extender II'), greaterThan(0));
      expect(score('dc', 'Damage Control II'), greaterThan(0));
      expect(score('mwd', mwd.$1, mwd.$2), greaterThan(0));
      expect(score('1mn ab', afterburner.$1, afterburner.$2), greaterThan(0));
      expect(score('1mn ab', mwd.$1, mwd.$2), 0);
      expect(score('mwd', afterburner.$1, afterburner.$2), 0);
      // Initials beat letters that merely appear in order.
      expect(score('lse', 'Large Shield Extender II'), greaterThan(score('lse', 'Light Missile Specialization')));
    });

    test('Roman numerals match digits', () {
      for (final q in ['dc2', 'dc 2', 'damage control 2', 'Damage Control II']) {
        expect(score(q, 'Damage Control II', '损伤控制 II'), greaterThan(0), reason: q);
      }
      expect(score('损伤控制2', 'Damage Control II', '损伤控制 II'), greaterThan(0));
      expect(score('dc2', 'Damage Control I'), 0);
    });

    test('Chinese characters in order match, out of order they do not', () {
      final (en, zh) = afterburner;
      expect(score('加燃', en, zh), greaterThan(0));
      expect(score('燃加', en, zh), 0);
    });

    void expectRanked(String query, List<String> names) {
      final scores = [for (final n in names) score(query, n)];
      for (var i = 0; i < names.length; i++) {
        expect(scores[i], greaterThan(0), reason: '$query: ${names[i]}');
        if (i > 0) expect(scores[i], lessThan(scores[i - 1]), reason: '$query: ${names[i]} after ${names[i - 1]}');
      }
    }

    test('ranking: exact, prefix, word, word start, part, letters in order', () {
      expectRanked('rifter', ['Rifter', 'Rifter Blueprint', 'Republic Fleet Rifter', 'Old Rifters', 'Starifter', 'Ribbed Fighter']);
      // Within the same kind of match the shorter name comes first.
      expect(score('rifter', 'Rifter Blueprint'), greaterThan(score('rifter', 'Rifter Krusual SKIN')));
    });

    test('ranking: initials before longer pieces and fewer skipped words', () {
      expectRanked('lse', [
        'Large Shield Extender II',
        'Republic Fleet Large Shield Extender',
        'Standup L-Set Bomb Aimer I',
        'Pulse Laser',
        'Light Missile Specialization',
      ]);
    });

    test('ranking: tokens typed together rank above the same words apart', () {
      expectRanked('shield extender', ['Large Shield Extender II', 'Extender for Shield']);
    });

    test('typos are only accepted when asked for', () {
      final (en, zh) = afterburner;
      expect(score('afterbruner', en, zh), 0);
      expect(scoreWithTypos('afterbruner', en, zh), greaterThan(0));
      expect(score('rfiter', 'Rifter'), 0);
      expect(scoreWithTypos('rfiter', 'Rifter'), greaterThan(0));
      expect(score('列谷级', 'Rifter', '裂谷级'), 0);
      expect(scoreWithTypos('列谷级', 'Rifter', '裂谷级'), greaterThan(0));
      expect(scoreWithTypos('damge controll', 'Damage Control II'), greaterThan(0));
      // Short tokens get no typos, and a typo ranks below any strict match.
      expect(scoreWithTypos('rfi', 'Rifter'), 0);
      expect(scoreWithTypos('xyzzy', 'Rifter', '裂谷级'), 0);
      expect(scoreWithTypos('rfiter', 'Rifter'), lessThan(score('rftr', 'Rifter')));
    });

    test('rankByName keeps strict matches and falls back to typos when they are few', () {
      final names = ['EMP S', 'Fusion S', 'Phased Plasma S', 'Republic Fleet EMP S', 'Titanium Sabot S'];
      expect(rankByName(names, '', (n) => (n, null)), names);
      expect(rankByName(names, 'emp', (n) => (n, null)), ['EMP S', 'Republic Fleet EMP S']);
      expect(rankByName(names, 'plasam', (n) => (n, null)), ['Phased Plasma S']);
      expect(rankByName(names, 'zzzz', (n) => (n, null)), isEmpty);
    });
  });

  group('SDE queries (fixture)', () {
    late SdeRepository sde;
    setUpAll(() => sde = openFixture());
    tearDownAll(() => sde.db.close());

    Future<List<int>> ids(Future<List<TypeInfo>> result) async => [for (final t in await result) t.typeId];

    test('market search in English and Chinese', () async {
      expect((await ids(sde.searchTypes('rifter', marketOnly: true))).first, 587);
      expect((await ids(sde.searchTypes(' RIFTER ', marketOnly: true))).first, 587);
      expect((await ids(sde.searchTypes('裂谷', marketOnly: true))).first, 587);
      expect(await ids(sde.searchTypes('1mn ab', marketOnly: true)), contains(438));
      expect(await ids(sde.searchTypes('加力 1mn', marketOnly: true)), contains(438));
      expect(await ids(sde.searchTypes('dc2', marketOnly: true)), contains(2048));
      expect(await sde.searchTypes(' - ', marketOnly: true), isEmpty);
    });

    test('typos are tried when the strict search finds little', () async {
      expect(await ids(sde.searchTypes('rfiter', marketOnly: true)), contains(587));
      expect(await ids(sde.searchTypes('列谷级', marketOnly: true)), contains(587));
    });

    test('ship picker search', () async {
      final ships = await sde.searchTypes('小鹰', marketOnly: true, categories: {Categories.ship});
      expect(ships.first.typeId, 603);
      expect(ships.every((t) => t.categoryId == Categories.ship), isTrue);
    });

    test('the SQL prefilter drops no row the scoring would keep', () async {
      final rows = await sde.db
          .customSelect('SELECT type_id, name_en, name_zh FROM inv_types WHERE market_group_id IS NOT NULL ORDER BY type_id')
          .get();
      final all = [for (final r in rows) (r.read<int>('type_id'), r.read<String>('name_en'), r.readNullable<String>('name_zh'))];
      for (final q in [
        'rifter', '裂谷', ' RIFTER ', '1mn ab', 'ab', 'mwd', 'lse', 'dc2', 'dc 2', 'co-processor', 'ii',
        '1mn加力', '加力 1mn', '加燃', 'x', 'rfiter', '列谷级', 'afterbruner', 'damge controll', 'plasam',
      ]) {
        final viaSql = await ids(sde.searchTypes(q, marketOnly: true, limit: 1000));
        final inDart = [for (final (id, _, _) in rankByName(all, q, (t) => (t.$2, t.$3))) id];
        expect(viaSql, inDart, reason: q);
      }
    });

    test('module picker search keeps the slot filter', () async {
      final mids = await ids(sde.fittableTypes(slotEffectId: slotEffectFor(SlotType.mid), query: 'mwd'));
      expect(mids, contains(440));
      expect(await ids(sde.fittableTypes(slotEffectId: slotEffectFor(SlotType.mid), query: '微型跃迁')), contains(440));
      expect(await ids(sde.fittableTypes(slotEffectId: slotEffectFor(SlotType.low), query: 'mwd')), isNot(contains(440)));
      final all = await sde.fittableTypes(slotEffectId: slotEffectFor(SlotType.mid), limit: 500);
      expect(all.length, greaterThan(mids.length));
      // Browsing is alphabetical, ignoring case and the quotes of named modules.
      String bare(TypeInfo t) => t.name.en.replaceFirst(RegExp('^[\'"]+'), '').toLowerCase();
      for (var i = 1; i < all.length; i++) {
        expect(bare(all[i - 1]).compareTo(bare(all[i])), lessThanOrEqualTo(0), reason: all[i].name.en);
      }
    });
  });

  // Speed on the whole database; runs when SDE_DB points at a built eve-sde-<build>.sqlite.
  final full = Platform.environment['SDE_DB'];
  test('search speed on the full SDE', () async {
    final sde = SdeRepository(SdeDatabase.openFileSync(File(full!)));
    addTearDown(sde.db.close);
    for (final q in ['rifter', '裂谷', '1mn ab', 'mwd', 'lse', 'afterbruner', '列谷级', 'damge controll', 'x']) {
      final watch = Stopwatch()..start();
      final result = await sde.searchTypes(q, marketOnly: true);
      watch.stop();
      // ignore: avoid_print
      print('$q: ${watch.elapsedMilliseconds} ms, ${result.length} results, first ${result.take(3).map((t) => t.name.en).toList()}');
      expect(watch.elapsedMilliseconds, lessThan(2000));
    }
  }, skip: full == null ? 'SDE_DB not set' : false);
}
