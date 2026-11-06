import 'dart:io';

import 'package:pocket_hangar/core/sde/sde_database.dart';
import 'package:pocket_hangar/core/sde/sde_models.dart';
import 'package:pocket_hangar/core/sde/sde_repository.dart';
import 'package:pocket_hangar/features/fitting/dogma/dogma_data.dart';
import 'package:pocket_hangar/features/fitting/fit.dart';
import 'package:pocket_hangar/features/fitting/fit_editing.dart';
import 'package:pocket_hangar/features/fitting/fitting_providers.dart';

/// Slice of SDE build 3670638 made by pipeline/tools/make_test_fixture.py.
final fixtureFile = File('test/fixtures/sde_test.sqlite');

SdeRepository openFixture() => SdeRepository(SdeDatabase.openFileSync(fixtureFile));

/// Dogma data with every skill loaded, plus helpers to build fits by item name.
class FitBench {
  FitBench._(this.sde, this.data, this.allV);

  final SdeRepository sde;
  final DogmaData data;
  final Map<int, int> allV;

  static Future<FitBench> open() async {
    final sde = openFixture();
    final data = await DogmaData.load(sde);
    final ids = await data.skillIds();
    return FitBench._(sde, data, {for (final id in ids) id: 5});
  }

  Future<void> close() => sde.db.close();

  Future<TypeInfo> type(String name) async {
    final t = await sde.typeByName(name);
    if (t == null) throw StateError('$name is not in the fixture');
    await data.ensureTypes([t.typeId]);
    return t;
  }

  Future<int> id(String name) async => (await type(name)).typeId;

  /// Builds a fit the way the editor does (slot from the module, default state, limits).
  Future<Fit> fit(String ship, List<String> modules, {Map<String, String> charges = const {}}) async {
    var fit = Fit(shipTypeId: await id(ship), name: 'test');
    for (final name in modules) {
      fit = addModule(fit, data.type(await id(name)), data);
      final charge = charges[name];
      if (charge != null) fit = setCharge(fit, fit.modules.length - 1, await id(charge));
    }
    return fit;
  }

  FitComputation compute(Fit fit, {Map<int, int>? skills}) => computeFit(data, fit, skills ?? allV);

  /// Raw attribute value of a type as stored in the SDE (no skills, no modules).
  double raw(int typeId, int attributeId) =>
      data.type(typeId).attributes[attributeId] ?? data.attributes[attributeId]!.defaultValue;
}
