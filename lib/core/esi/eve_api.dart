import '../../app/config.dart';
import 'esi_client.dart';

/// The ESI routes the app uses, checked against the compatibility-date 2026-08-18 OpenAPI spec
/// (esi.evetech.net/meta/openapi.json?compatibility_date=2026-08-18).
class EveApi {
  EveApi(this.esi);

  final EsiClient esi;

  Future<EsiResponse<Object?>> skills(int c) => esi.get('/characters/$c/skills', characterId: c);

  Future<EsiResponse<Object?>> skillQueue(int c) => esi.get('/characters/$c/skillqueue', characterId: c);

  Future<EsiResponse<Object?>> attributes(int c) => esi.get('/characters/$c/attributes', characterId: c);

  Future<EsiResponse<Object?>> implants(int c) => esi.get('/characters/$c/implants', characterId: c);

  Future<EsiResponse<List<Object?>>> assets(int c) => esi.getAllPages('/characters/$c/assets', characterId: c);

  /// Custom names of assembled items; at most 1000 ids per call.
  Future<Object?> assetNames(int c, List<int> itemIds) =>
      esi.post('/characters/$c/assets/names', itemIds, characterId: c);

  Future<EsiResponse<Object?>> location(int c) => esi.get('/characters/$c/location', characterId: c);

  Future<EsiResponse<Object?>> ship(int c) => esi.get('/characters/$c/ship', characterId: c);

  /// Needs esi-universe.read_structures.v1 and docking access; 403 otherwise.
  Future<EsiResponse<Object?>> structure(int c, int structureId) =>
      esi.get('/universe/structures/$structureId', characterId: c);

  Future<EsiResponse<List<Object?>>> marketOrders(int typeId, {int regionId = AppConfig.theForgeRegionId}) =>
      esi.getAllPages('/markets/$regionId/orders', query: {'order_type': 'all', 'type_id': typeId});

  Future<EsiResponse<Object?>> marketHistory(int typeId, {int regionId = AppConfig.theForgeRegionId}) =>
      esi.get('/markets/$regionId/history', query: {'type_id': typeId});

  Future<EsiResponse<Object?>> fittings(int c) => esi.get('/characters/$c/fittings', characterId: c);

  Future<Object?> saveFitting(int c, Map<String, Object?> fitting) =>
      esi.post('/characters/$c/fittings', fitting, characterId: c);

  /// Resolves ids of many kinds (characters, types, systems, NPC stations...); at most 1000.
  Future<Object?> universeNames(List<int> ids) => esi.post('/universe/names', ids);
}
