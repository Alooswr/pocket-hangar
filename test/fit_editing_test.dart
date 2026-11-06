import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/features/fitting/dogma/dogma_data.dart';
import 'package:pocket_hangar/features/fitting/eft.dart';
import 'package:pocket_hangar/features/fitting/fit.dart';
import 'package:pocket_hangar/features/fitting/fit_editing.dart';

import 'support/fixture.dart';

void main() {
  late FitBench bench;

  setUpAll(() async => bench = await FitBench.open());
  tearDownAll(() => bench.close());

  group('adding modules', () {
    test('a second afterburner comes in online (maxGroupActive 1)', () async {
      final fit = await bench.fit('Rifter', ['1MN Afterburner II', '1MN Afterburner II']);
      expect(fit.modules.map((m) => m.state), [ModuleState.active, ModuleState.online]);
    });

    test('passive modules start online', () async {
      final fit = await bench.fit('Rifter', ['Damage Control II']);
      expect(fit.modules.single.state, ModuleState.online);
      expect(fit.modules.single.slot, SlotType.low);
    });

    test('no free slot once the mids are full', () async {
      final fit = await bench.fit('Rifter', ['Warp Scrambler II', 'Stasis Webifier II', '1MN Afterburner II']);
      final c = bench.compute(fit);
      final web = bench.data.type(await bench.id('Stasis Webifier II'));
      final problem = fitProblem(
        fit: fit,
        ship: bench.data.type(fit.shipTypeId),
        module: web,
        data: bench.data,
        slotTotals: c.slotTotals,
      );
      expect(problem?.kind, FitProblemKind.noFreeSlot);
    });

    test('one damage control per ship (maxGroupFitted)', () async {
      final fit = await bench.fit('Rifter', ['Damage Control II']);
      final problem = fitProblem(
        fit: fit,
        ship: bench.data.type(fit.shipTypeId),
        module: bench.data.type(await bench.id('Damage Control II')),
        data: bench.data,
        slotTotals: bench.compute(fit).slotTotals,
      );
      expect(problem?.kind, FitProblemKind.groupLimit);
      expect(problem?.limit, 1);
    });

    test('Legion subsystems do not fit a Rifter', () async {
      final subs = await bench.sde.searchTypes('Legion', categories: {32}, limit: 5);
      await bench.data.ensureTypes([subs.first.typeId]);
      final rifter = bench.data.type(await bench.id('Rifter'));
      expect(canFitShip(bench.data.type(subs.first.typeId), rifter, bench.data), isFalse);
    });

    test('a subsystem replaces the one in the same subsystem slot', () async {
      final subs = await bench.sde.searchTypes('Legion Offensive', categories: {32}, limit: 10);
      expect(subs.length, greaterThanOrEqualTo(2));
      await bench.data.ensureTypes(subs.map((s) => s.typeId));
      var fit = Fit(shipTypeId: await bench.id('Legion'), name: 't3');
      fit = addModule(fit, bench.data.type(subs[0].typeId), bench.data);
      fit = addModule(fit, bench.data.type(subs[1].typeId), bench.data);
      expect(fit.modules.map((m) => m.typeId), [subs[1].typeId]);
    });

    test('small rigs fit a frigate', () async {
      final rig = bench.data.type(await bench.id('Small Ancillary Current Router I'));
      expect(canFitShip(rig, bench.data.type(await bench.id('Rifter')), bench.data), isTrue);
    });
  });

  group('module states', () {
    test('activating the second afterburner turns the first one off', () async {
      var fit = await bench.fit('Rifter', ['1MN Afterburner II', '1MN Afterburner II']);
      fit = setModuleState(fit, 1, ModuleState.active, bench.data);
      expect(fit.modules.map((m) => m.state), [ModuleState.online, ModuleState.active]);
    });

    test('tap toggles online/active for active modules and online/offline for passive ones', () async {
      final ab = bench.data.type(await bench.id('1MN Afterburner II'));
      final dc = bench.data.type(await bench.id('Damage Control II'));
      expect(toggledState(ModuleState.online, ab, bench.data), ModuleState.active);
      expect(toggledState(ModuleState.active, ab, bench.data), ModuleState.online);
      expect(toggledState(ModuleState.online, dc, bench.data), ModuleState.offline);
      expect(toggledState(ModuleState.offline, dc, bench.data), ModuleState.online);
    });

    test('states offered per module', () async {
      final ab = bench.data.type(await bench.id('1MN Afterburner II'));
      final dc = bench.data.type(await bench.id('Damage Control II'));
      final rig = bench.data.type(await bench.id('Small Ancillary Current Router I'));
      expect(availableStates(ab, bench.data), ModuleState.values);
      expect(availableStates(dc, bench.data), [ModuleState.offline, ModuleState.online]);
      expect(availableStates(rig, bench.data), [ModuleState.online]);
    });
  });

  group('ESI fitting body', () {
    test('slot flags, drones and charges in cargo', () async {
      var fit = await bench.fit(
        'Rifter',
        ['200mm AutoCannon II', '200mm AutoCannon II', 'Damage Control II', '1MN Afterburner II'],
        charges: {'200mm AutoCannon II': 'EMP S'},
      );
      fit = fit.copyWith(drones: [FitStack(await bench.id('Warrior II'), 2)]);
      final body = toEsiFitting(fit, bench.data, name: 'Rifter PvP');
      final items = body['items']! as List<Map<String, Object?>>;
      final flags = items.map((i) => i['flag']).toList();
      expect(flags, containsAllInOrder(['HiSlot0', 'HiSlot1', 'LoSlot0', 'MedSlot0']));
      expect(items.firstWhere((i) => i['flag'] == 'DroneBay')['quantity'], 2);
      final emp = await bench.id('EMP S');
      final cannon = await bench.id('200mm AutoCannon II');
      final perGun = (bench.raw(cannon, A.capacity) / bench.raw(emp, A.volume)).floor();
      // The helper loads EMP S in both guns; the cargo carries one full load per gun.
      expect(fit.modules.where((m) => m.chargeTypeId == emp).length, 2);
      final cargo = items.where((i) => i['flag'] == 'Cargo' && i['type_id'] == emp).single;
      expect(cargo['quantity'], perGun * fit.modules.where((m) => m.chargeTypeId == emp).length);
      expect(body['name'], 'Rifter PvP');
      expect(body['ship_type_id'], fit.shipTypeId);
      expect(body.containsKey('description'), isTrue);
    });

    test('names longer than 50 characters are cut', () async {
      final fit = await bench.fit('Rifter', ['Damage Control II']);
      final body = toEsiFitting(fit, bench.data, name: 'x' * 80);
      expect((body['name']! as String).length, 50);
    });
  });

  group('stored form', () {
    test('JSON round trip keeps states and charges', () async {
      var fit = await bench.fit('Rifter', ['200mm AutoCannon II', 'Damage Control II'], charges: {
        '200mm AutoCannon II': 'EMP S',
      });
      fit = setModuleState(fit, 1, ModuleState.offline, bench.data)
          .copyWith(drones: [FitStack(await bench.id('Warrior II'), 3)], name: '小号 Rifter');
      final back = Fit.fromJson(jsonDecode(jsonEncode(fit.toJson())) as Map<String, Object?>);
      expect(back.name, '小号 Rifter');
      expect(back.shipTypeId, fit.shipTypeId);
      expect(back.modules.map((m) => (m.typeId, m.slot, m.state, m.chargeTypeId)),
          fit.modules.map((m) => (m.typeId, m.slot, m.state, m.chargeTypeId)));
      expect(back.drones.single.quantity, 3);
    });
  });

  group('EFT', () {
    const sample = '''
[Rifter, Test fit]
Damage Control II
Gyrostabilizer II /OFFLINE

1MN Afterburner II
Warp Scrambler II
Stasis Webifier II

200mm AutoCannon II, EMP S
200mm AutoCannon II, EMP S
[Empty High slot]
Light Missile Launcher II, Scourge Light Missile

Small Ancillary Current Router I


Warrior II x3
EMP S x1000
Not A Real Item
''';

    test('import', () async {
      final result = await parseEft(sample, lookup: bench.sde.typeByName, data: bench.data);
      final fit = result.fit;
      expect(fit.shipTypeId, await bench.id('Rifter'));
      expect(fit.name, 'Test fit');
      expect(result.skipped, ['Not A Real Item']);
      expect(fit.inSlot(SlotType.low).length, 2);
      expect(fit.inSlot(SlotType.mid).length, 3);
      expect(fit.inSlot(SlotType.high).length, 3);
      expect(fit.inSlot(SlotType.rig).length, 1);
      final gyro = await bench.id('Gyrostabilizer II');
      expect(fit.modules.firstWhere((m) => m.typeId == gyro).state, ModuleState.offline);
      expect(fit.inSlot(SlotType.mid).first.state, ModuleState.active); // afterburner
      expect(fit.inSlot(SlotType.high).first.chargeTypeId, await bench.id('EMP S'));
      expect(fit.drones.single.quantity, 3);
      expect(fit.cargo.single.quantity, 1000);
    });

    test('export and import again gives the same fit', () async {
      final first = (await parseEft(sample, lookup: bench.sde.typeByName, data: bench.data)).fit;
      final text = exportEft(first, bench.data, slotTotals: bench.compute(first).slotTotals);
      // The Rifter has 4 low slots (SDE 3670638), two of them used here.
      expect('[Empty Low slot]'.allMatches(text).length, 2);
      expect(text, isNot(contains('[Empty High slot]')));
      expect(text, contains('Gyrostabilizer II /OFFLINE'));
      final second = (await parseEft(text, lookup: bench.sde.typeByName, data: bench.data)).fit;
      expect(second.modules.map((m) => (m.typeId, m.slot, m.state, m.chargeTypeId)),
          first.modules.map((m) => (m.typeId, m.slot, m.state, m.chargeTypeId)));
      expect(second.drones.map((d) => (d.typeId, d.quantity)), first.drones.map((d) => (d.typeId, d.quantity)));
      expect(second.cargo.map((d) => (d.typeId, d.quantity)), first.cargo.map((d) => (d.typeId, d.quantity)));
    });

    test('errors', () async {
      Future<void> parse(String s) => parseEft(s, lookup: bench.sde.typeByName, data: bench.data);
      await expectLater(parse('  '), throwsA(isA<EftFormatException>().having((e) => e.kind, 'kind', EftError.empty)));
      await expectLater(
        parse('Rifter\nDamage Control II'),
        throwsA(isA<EftFormatException>().having((e) => e.kind, 'kind', EftError.badHeader)),
      );
      await expectLater(
        parse('[Not A Ship, x]'),
        throwsA(isA<EftFormatException>().having((e) => e.detail, 'detail', 'Not A Ship')),
      );
    });
  });
}
