import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../core/sde/sde_models.dart';
import '../update/sde_controller.dart';

class MarketOrder {
  const MarketOrder({
    required this.orderId,
    required this.isBuy,
    required this.price,
    required this.volumeRemain,
    required this.locationId,
    required this.systemId,
    required this.issued,
    required this.range,
    required this.minVolume,
  });

  factory MarketOrder.fromJson(Map<String, dynamic> j) => MarketOrder(
        orderId: (j['order_id'] as num).toInt(),
        isBuy: j['is_buy_order'] as bool,
        price: (j['price'] as num).toDouble(),
        volumeRemain: (j['volume_remain'] as num).toInt(),
        locationId: (j['location_id'] as num).toInt(),
        systemId: (j['system_id'] as num).toInt(),
        issued: DateTime.parse(j['issued'] as String),
        range: j['range'] as String,
        minVolume: (j['min_volume'] as num?)?.toInt() ?? 1,
      );

  final int orderId;
  final bool isBuy;
  final double price;
  final int volumeRemain;
  final int locationId;
  final int systemId;
  final DateTime issued;
  final String range;
  final int minVolume;
}

class OrderBook {
  const OrderBook({
    required this.sells,
    required this.buys,
    required this.stations,
    required this.systems,
    required this.fetchedAt,
    required this.stale,
  });

  /// Lowest price first.
  final List<MarketOrder> sells;

  /// Highest price first.
  final List<MarketOrder> buys;
  final Map<int, StationInfo> stations;
  final Map<int, SolarSystemInfo> systems;
  final DateTime fetchedAt;
  final bool stale;

  static bool isNpcStation(int locationId) => locationId >= 60000000 && locationId < 64000000;

  OrderBook filtered({int? locationId}) {
    if (locationId == null) return this;
    return OrderBook(
      sells: sells.where((o) => o.locationId == locationId).toList(),
      buys: buys.where((o) => o.locationId == locationId).toList(),
      stations: stations,
      systems: systems,
      fetchedAt: fetchedAt,
      stale: stale,
    );
  }
}

/// All orders for one type in The Forge. The region endpoint is paginated (X-Pages); with
/// type_id set it is usually a single page, but every page is read.
final marketOrdersProvider = FutureProvider.autoDispose.family<OrderBook, int>((ref, typeId) async {
  final sde = requireSde(ref);
  final resp = await ref.watch(eveApiProvider).marketOrders(typeId);
  final orders = [for (final o in resp.data) MarketOrder.fromJson(o as Map<String, dynamic>)];
  final sells = orders.where((o) => !o.isBuy).toList()..sort((a, b) => a.price.compareTo(b.price));
  final buys = orders.where((o) => o.isBuy).toList()..sort((a, b) => b.price.compareTo(a.price));
  final stationIds = orders.map((o) => o.locationId).where(OrderBook.isNpcStation);
  return OrderBook(
    sells: sells,
    buys: buys,
    stations: await sde.stations(stationIds),
    systems: await sde.solarSystems(orders.map((o) => o.systemId)),
    fetchedAt: resp.fetchedAt,
    stale: resp.isStale,
  );
});

class HistoryDay {
  const HistoryDay({
    required this.date,
    required this.average,
    required this.highest,
    required this.lowest,
    required this.volume,
    required this.orderCount,
  });

  factory HistoryDay.fromJson(Map<String, dynamic> j) => HistoryDay(
        date: DateTime.parse(j['date'] as String),
        average: (j['average'] as num).toDouble(),
        highest: (j['highest'] as num).toDouble(),
        lowest: (j['lowest'] as num).toDouble(),
        volume: (j['volume'] as num).toInt(),
        orderCount: (j['order_count'] as num).toInt(),
      );

  final DateTime date;
  final double average;
  final double highest;
  final double lowest;
  final int volume;
  final int orderCount;
}

final marketHistoryProvider = FutureProvider.autoDispose.family<List<HistoryDay>, int>((ref, typeId) async {
  final resp = await ref.watch(eveApiProvider).marketHistory(typeId);
  final days = [for (final d in (resp.data as List<dynamic>? ?? const [])) HistoryDay.fromJson(d as Map<String, dynamic>)]
    ..sort((a, b) => a.date.compareTo(b.date));
  return days;
});

final regionNameProvider = FutureProvider.family<LocalName?, int>((ref, regionId) async {
  return requireSde(ref).regionName(regionId);
});

final theForgeNameProvider = Provider<AsyncValue<LocalName?>>(
  (ref) => ref.watch(regionNameProvider(AppConfig.theForgeRegionId)),
);

final typeSearchProvider = FutureProvider.autoDispose.family<List<TypeInfo>, String>((ref, query) async {
  return requireSde(ref).searchTypes(query, marketOnly: true);
});

final typeInfoProvider = FutureProvider.family<TypeInfo?, int>((ref, typeId) async => requireSde(ref).type(typeId));

/// Favorite type ids, newest first, kept in the app database.
final favoriteIdsProvider = StreamProvider<List<int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.favoriteTypes)..orderBy([(t) => OrderingTerm.desc(t.addedAt)]);
  return query.watch().map((rows) => [for (final r in rows) r.typeId]);
});

final favoriteTypesProvider = FutureProvider.autoDispose<List<TypeInfo>>((ref) async {
  final ids = await ref.watch(favoriteIdsProvider.future);
  final types = await requireSde(ref).types(ids);
  return [for (final id in ids) ?types[id]];
});

Future<void> toggleFavorite(WidgetRef ref, int typeId, {required bool favorite}) async {
  final db = ref.read(appDatabaseProvider);
  if (favorite) {
    await db.into(db.favoriteTypes).insertOnConflictUpdate(FavoriteTypesCompanion.insert(typeId: Value(typeId)));
  } else {
    await (db.delete(db.favoriteTypes)..where((t) => t.typeId.equals(typeId))).go();
  }
}
