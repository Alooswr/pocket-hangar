import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../core/images/eve_image.dart';
import '../../core/sde/sde_models.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import 'market_data.dart';

enum _View { sell, buy, history }

class ItemMarketScreen extends ConsumerStatefulWidget {
  const ItemMarketScreen({required this.type, super.key});

  final TypeInfo type;

  @override
  ConsumerState<ItemMarketScreen> createState() => _ItemMarketScreenState();
}

class _ItemMarketScreenState extends ConsumerState<ItemMarketScreen> {
  _View _view = _View.sell;
  bool _jitaOnly = true;
  int _days = 90;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final type = widget.type;
    final favorite = ref.watch(favoriteIdsProvider).value?.contains(type.typeId) ?? false;
    final ordersProvider = marketOrdersProvider(type.typeId);
    final historyProvider = marketHistoryProvider(type.typeId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            EveImage.type(type.typeId, categoryId: type.categoryId, size: 28),
            const SizedBox(width: Space.m),
            Expanded(child: Text(type.name.of(zh: context.zh), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: favorite ? l.removeFavorite : l.addFavorite,
            icon: Icon(favorite ? Icons.star : Icons.star_outline, color: favorite ? context.tokens.like : null),
            onPressed: () => toggleFavorite(ref, type.typeId, favorite: !favorite),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          ref.invalidate(historyProvider);
          await ref.read(ordersProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Summary(typeId: type.typeId, jitaOnly: _jitaOnly)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
                child: SegmentedButton<_View>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: _View.sell, label: Text(l.sellOrders)),
                    ButtonSegment(value: _View.buy, label: Text(l.buyOrders)),
                    ButtonSegment(value: _View.history, label: Text(l.history)),
                  ],
                  selected: {_view},
                  onSelectionChanged: (s) => setState(() => _view = s.first),
                ),
              ),
            ),
            if (_view != _View.history)
              SliverToBoxAdapter(
                child: SwitchListTile(
                  dense: true,
                  title: Text(l.jitaOnly, style: context.text.bodyMedium),
                  value: _jitaOnly,
                  onChanged: (v) => setState(() => _jitaOnly = v),
                ),
              ),
            if (_view == _View.history)
              SliverToBoxAdapter(
                child: AsyncBody(
                  value: ref.watch(historyProvider),
                  onRetry: () => ref.invalidate(historyProvider),
                  builder: (days) => PriceHistory(
                    days: days,
                    window: _days,
                    onWindow: (d) => setState(() => _days = d),
                  ),
                ),
              )
            else
              _OrderList(typeId: type.typeId, buy: _view == _View.buy, jitaOnly: _jitaOnly),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
          ],
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.typeId, required this.jitaOnly});

  final int typeId;
  final bool jitaOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final book = ref.watch(marketOrdersProvider(typeId)).value;
    final filtered = book?.filtered(locationId: jitaOnly ? AppConfig.jita44StationId : null);
    final sell = filtered?.sells.firstOrNull?.price;
    final buy = filtered?.buys.firstOrNull?.price;
    Widget cell(String label, double? price) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.bodySmall),
              const SizedBox(height: Space.xs),
              Text(
                price == null ? '—' : formatIsk(price),
                style: context.text.titleMedium!.copyWith(fontFeatures: tabular),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 0),
          child: Row(children: [cell(l.lowestSell, sell), const SizedBox(width: Space.l), cell(l.highestBuy, buy)]),
        ),
        if (book != null) FreshnessLine(fetchedAt: book.fetchedAt, stale: book.stale),
      ],
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.typeId, required this.buy, required this.jitaOnly});

  final int typeId;
  final bool buy;
  final bool jitaOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final provider = marketOrdersProvider(typeId);
    final value = ref.watch(provider);
    final region = ref.watch(theForgeNameProvider).value?.of(zh: context.zh) ?? 'The Forge';
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const SliverToBoxAdapter(child: LoadingView()),
      error: (e, _) => SliverToBoxAdapter(child: ErrorView(error: e, onRetry: () => ref.invalidate(provider))),
      data: (book) {
        final view = book.filtered(locationId: jitaOnly ? AppConfig.jita44StationId : null);
        final orders = buy ? view.buys : view.sells;
        if (orders.isEmpty) return SliverToBoxAdapter(child: MessageView(message: l.noOrders));
        return SliverList.builder(
          itemCount: orders.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xs),
                child: Text(jitaOnly ? l.ordersAtJita(orders.length) : l.ordersIn(orders.length, region), style: context.text.bodySmall),
              );
            }
            final o = orders[i - 1];
            final station = book.stations[o.locationId];
            final system = book.systems[o.systemId];
            final location = station?.name.of(zh: context.zh) ??
                '${l.playerStructure}${system == null ? '' : '  ${system.name.of(zh: context.zh)}'}';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(color: t.text),
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatIsk(o.price), style: context.text.bodyMedium!.copyWith(fontFeatures: tabular)),
                      Text(formatInt(o.volumeRemain), style: context.text.bodySmall!.copyWith(fontFeatures: tabular)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Average price per day. One series, no legend; the last value is labelled at the end of the
/// line and the title states the change over the window.
class PriceHistory extends StatelessWidget {
  const PriceHistory({required this.days, required this.window, required this.onWindow, super.key});

  final List<HistoryDay> days;
  final int window;
  final ValueChanged<int> onWindow;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    if (days.isEmpty) return MessageView(message: l.noHistory);
    final cutoff = days.last.date.subtract(Duration(days: window));
    final shown = days.where((d) => d.date.isAfter(cutoff)).toList();
    final first = shown.first.average;
    final last = shown.last.average;
    final change = first == 0 ? 0.0 : (last / first - 1) * 100;
    final minY = shown.map((d) => d.average).reduce((a, b) => a < b ? a : b);
    final maxY = shown.map((d) => d.average).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) == 0 ? maxY * 0.05 + 1 : (maxY - minY) * 0.15;
    final x0 = shown.first.date;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.priceHistoryTitle(window), style: context.text.titleSmall),
          Text(
            l.priceChange('${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%', window),
            style: context.text.bodySmall!.copyWith(fontFeatures: tabular),
          ),
          const SizedBox(height: Space.l),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minY - pad,
                maxY: maxY + pad,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final d in shown) FlSpot(d.date.difference(x0).inDays.toDouble(), d.average),
                    ],
                    color: t.text,
                    barWidth: 1.5,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, bar) => spot == bar.spots.last,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(radius: 3, color: t.text, strokeWidth: 0),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: t.hairline, strokeWidth: hairlineWidth),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      // Labels only on the grid lines. The padded axis ends got labels of their
                      // own by default, which landed on top of the nearest grid label.
                      minIncluded: false,
                      maxIncluded: false,
                      reservedSize: 64,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(_short(value), style: context.text.bodySmall!.copyWith(fontFeatures: tabular)),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => t.surface3,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${formatDateTime(x0.add(Duration(days: s.x.round()))).split(' ').first}\n${formatIsk(s.y)}',
                          context.text.bodySmall!.copyWith(color: t.text, fontFeatures: tabular),
                        ),
                    ],
                  ),
                ),
              ),
              duration: Motion.fast,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(formatIsk(last), style: context.text.bodySmall!.copyWith(color: t.text, fontFeatures: tabular)),
          ),
          const SizedBox(height: Space.m),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 30, label: Text('30d')),
              ButtonSegment(value: 90, label: Text('90d')),
              ButtonSegment(value: 365, label: Text('1y')),
            ],
            selected: {window},
            onSelectionChanged: (s) => onWindow(s.first),
          ),
        ],
      ),
    );
  }

  static String _short(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}
