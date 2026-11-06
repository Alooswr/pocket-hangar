import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/accounts.dart';
import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../core/sde/sde_models.dart';
import '../../core/sde/sde_repository.dart';
import '../skills/skills_data.dart';
import '../update/sde_controller.dart';
import 'dogma/dogma_data.dart';
import 'dogma/dogma_engine.dart';
import 'dogma/fit_stats.dart';
import 'fit.dart';

/// Attribute, effect and modifier definitions plus every skill type. Loaded once per game data
/// build; a data update replaces the repository and with it this provider.
final dogmaDataProvider = FutureProvider<DogmaData>((ref) async {
  final data = await DogmaData.load(requireSde(ref));
  await data.skillIds();
  return data;
});

enum SkillSource { allV, character }

/// Skill levels used for the fit: every skill at V, or the active character's trained levels.
final fitSkillLevelsProvider = FutureProvider.autoDispose.family<Map<int, int>, SkillSource>((ref, source) async {
  final account = source == SkillSource.character ? ref.watch(activeAccountProvider) : null;
  final data = await ref.watch(dogmaDataProvider.future);
  final ids = await data.skillIds();
  if (source == SkillSource.allV) return {for (final id in ids) id: 5};
  if (account == null) throw StateError('no character signed in');
  return ref.watch(characterSkillLevelsProvider(account.characterId).future);
});

class FitComputation {
  const FitComputation(this.dogma, this.stats);

  final DogmaFit dogma;
  final FitStats stats;

  Map<SlotType, int> get slotTotals => {for (final e in stats.slots.entries) e.key: e.value.total.round()};
}

/// Builds the dogma tree and the stats. Types of the fit must be loaded in [data].
FitComputation computeFit(DogmaData data, Fit fit, Map<int, int> skillLevels) {
  final dogma = DogmaFit.build(data: data, fit: fit, skillLevels: skillLevels);
  return FitComputation(dogma, computeStats(dogma));
}

// ---------------------------------------------------------------- saved fits

final savedFitsProvider = StreamProvider<List<SavedFit>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.savedFits)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
});

Fit decodeSavedFit(SavedFit row) => Fit.fromJson(jsonDecode(row.fitJson) as Map<String, Object?>);

/// Inserts (no [id]) or updates a saved fit; returns its id.
Future<int> saveFit(AppDatabase db, Fit fit, {int? id}) async {
  final json = jsonEncode(fit.toJson());
  if (id == null) {
    return db.into(db.savedFits).insert(
          SavedFitsCompanion.insert(name: fit.name, shipTypeId: fit.shipTypeId, fitJson: json),
        );
  }
  await (db.update(db.savedFits)..where((t) => t.id.equals(id))).write(
    SavedFitsCompanion(name: Value(fit.name), fitJson: Value(json), updatedAt: Value(DateTime.now())),
  );
  return id;
}

Future<void> deleteSavedFit(AppDatabase db, int id) => (db.delete(db.savedFits)..where((t) => t.id.equals(id))).go();

// ---------------------------------------------------------------- pickers

final shipSearchProvider = FutureProvider.autoDispose.family<List<TypeInfo>, String>((ref, query) {
  return requireSde(ref).searchTypes(query, marketOnly: true, categories: {Categories.ship}, limit: 80);
});

typedef ModuleQuery = ({SlotType slot, String query, int shipTypeId, int? rigSize});

final fittableTypesProvider = FutureProvider.autoDispose.family<List<TypeInfo>, ModuleQuery>((ref, q) {
  return requireSde(ref).fittableTypes(
    slotEffectId: slotEffectFor(q.slot),
    query: q.query,
    rigSize: q.slot == SlotType.rig ? q.rigSize : null,
    fitsToShipType: q.slot == SlotType.subsystem ? q.shipTypeId : null,
    limit: 150,
  );
});

/// Charges a module can load (charge groups and size from the module's attributes).
final chargesProvider = FutureProvider.autoDispose.family<List<TypeInfo>, int>((ref, moduleTypeId) async {
  final sde = requireSde(ref);
  final data = await ref.watch(dogmaDataProvider.future);
  await data.ensureTypes([moduleTypeId]);
  final module = data.typeOrNull(moduleTypeId);
  return module == null ? const [] : sde.chargesFor(module.attributes);
});

/// Whether the module takes charges at all, without querying for them.
bool takesCharges(TypeDef module) => AttrIds.chargeGroups.any((a) => (module.attributes[a] ?? 0) > 0);
