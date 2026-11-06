import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/auth/accounts.dart';
import '../../core/images/eve_image.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../account/account_widgets.dart';
import 'assets_data.dart';

class ShipsScreen extends ConsumerWidget {
  const ShipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final account = ref.watch(activeAccountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.assetsTitle), actions: const [AccountButton()]),
      body: account == null ? const SignInPrompt() : NeedsSde(child: _ShipsBody(characterId: account.characterId)),
    );
  }
}

class _ShipsBody extends ConsumerWidget {
  const _ShipsBody({required this.characterId});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = shipsProvider(characterId);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: AsyncBody(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        builder: (overview) => _ShipList(overview: overview),
      ),
    );
  }
}

class _ShipList extends StatelessWidget {
  const _ShipList({required this.overview});

  final ShipsOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (overview.ships.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [MessageView(message: l.noShips)],
      );
    }
    final current = overview.current;
    final groups = <String, List<ShipEntry>>{};
    for (final s in overview.ships.where((s) => !s.isCurrent)) {
      (groups[s.place.groupKey] ??= []).add(s);
    }
    final ordered = groups.values.toList()
      ..sort((a, b) => _placeTitle(context, a.first.place).compareTo(_placeTitle(context, b.first.place)));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        FreshnessLine(fetchedAt: overview.fetchedAt, stale: overview.stale),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, 0),
          child: Text(l.shipCount(overview.ships.fold<int>(0, (n, s) => n + s.quantity)), style: context.text.bodySmall),
        ),
        if (current != null) ...[
          SectionTitle(l.currentShip),
          _ShipTile(ship: current, showPlace: true),
        ],
        for (final ships in ordered) ...[
          _PlaceHeader(place: ships.first.place),
          for (final s in ships..sort((a, b) => a.type.name.en.compareTo(b.type.name.en))) _ShipTile(ship: s),
        ],
      ],
    );
  }
}

String _placeTitle(BuildContext context, Place place) {
  final l = context.l10n;
  return switch (place.kind) {
    PlaceKind.station => place.name?.of(zh: context.zh) ?? '${place.id}',
    PlaceKind.structure => place.name?.of(zh: context.zh) ?? l.unknownStructure,
    PlaceKind.space => l.inSpace,
    PlaceKind.unknown => l.unknownStructure,
  };
}

class _PlaceHeader extends StatelessWidget {
  const _PlaceHeader({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final system = place.system;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_placeTitle(context, place), style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          if (system == null)
            Text(l.unknownSystem, style: context.text.bodySmall)
          else
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: formatSecurity(system.security),
                  style: TextStyle(color: _securityColor(t, system.security), fontFeatures: tabular),
                ),
                TextSpan(text: '  ${system.name.of(zh: context.zh)}  ${system.regionName.of(zh: context.zh)}'),
              ]),
              style: context.text.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// High-sec, low-sec and null-sec read differently in game; the number is always shown with it.
Color _securityColor(AppTokens t, double security) {
  final shown = double.parse(formatSecurity(security));
  if (shown >= 0.5) return t.success;
  if (shown > 0) return t.warning;
  return t.danger;
}

class _ShipTile extends StatelessWidget {
  const _ShipTile({required this.ship, this.showPlace = false});

  final ShipEntry ship;
  final bool showPlace;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final typeName = ship.type.name.of(zh: context.zh);
    final details = <String>[
      if (ship.customName != null && ship.customName != typeName) typeName,
      if (ship.packaged) ship.quantity > 1 ? '${l.packaged} x${ship.quantity}' : l.packaged,
      if (ship.container != null) l.insideContainer(ship.container!),
      if (showPlace) _placeTitle(context, ship.place),
    ];
    return ListTile(
      leading: EveImage.type(ship.type.typeId, size: 40),
      title: Text(ship.customName ?? typeName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: details.isEmpty ? null : Text(details.join('\n'), maxLines: 3),
    );
  }
}
