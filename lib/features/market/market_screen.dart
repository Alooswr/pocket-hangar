import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/images/eve_image.dart';
import '../../core/sde/sde_models.dart';
import '../../widgets/common.dart';
import '../account/account_widgets.dart';
import 'item_market_screen.dart';
import 'market_data.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.marketTitle), actions: const [AccountButton()]),
      body: NeedsSde(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.searchItems,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.close,
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(child: _query.isEmpty ? const _Favorites() : _SearchResults(query: _query)),
          ],
        ),
      ),
    );
  }
}

class _Favorites extends ConsumerWidget {
  const _Favorites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AsyncBody(
      value: ref.watch(favoriteTypesProvider),
      builder: (types) => types.isEmpty
          ? MessageView(message: l.favoritesEmpty, icon: Icons.star_outline)
          : ListView(
              children: [
                SectionTitle(l.favorites),
                for (final t in types) TypeTile(type: t),
              ],
            ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncBody(
        value: ref.watch(typeSearchProvider(query)),
        builder: (types) => types.isEmpty
            ? MessageView(message: context.l10n.noResults(query))
            : ListView.builder(
                itemCount: types.length,
                itemExtent: 56,
                itemBuilder: (context, i) => TypeTile(type: types[i]),
              ),
      );
}

class TypeTile extends StatelessWidget {
  const TypeTile({required this.type, super.key});

  final TypeInfo type;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: EveImage.type(type.typeId, categoryId: type.categoryId, size: 32),
        title: Text(type.name.of(zh: context.zh), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: context.zh && type.name.zh != null
            ? Text(type.name.en, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ItemMarketScreen(type: type)),
        ),
      );
}
