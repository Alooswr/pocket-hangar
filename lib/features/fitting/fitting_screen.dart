import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/db/app_database.dart';
import '../../core/images/eve_image.dart';
import '../../core/providers.dart';
import '../../core/sde/sde_models.dart';
import '../../widgets/common.dart';
import '../account/account_widgets.dart';
import '../market/market_data.dart';
import '../update/sde_controller.dart';
import 'eft.dart';
import 'fit.dart';
import 'fit_editor_screen.dart';
import 'fitting_providers.dart';
import 'pickers.dart';

class FittingScreen extends ConsumerWidget {
  const FittingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ready = ref.watch(sdeRepositoryProvider) != null;
    // Start loading the dogma definitions as soon as the tab is opened, so the editor is quick.
    if (ready) ref.listen(dogmaDataProvider, (_, _) {});
    return Scaffold(
      appBar: AppBar(
        title: Text(l.fittingTitle),
        actions: [
          IconButton(
            tooltip: l.importEft,
            icon: const Icon(Icons.content_paste_outlined),
            onPressed: ready ? () => _importEft(context, ref) : null,
          ),
          const AccountButton(),
        ],
      ),
      floatingActionButton: ready
          ? FloatingActionButton.extended(
              onPressed: () => _newFit(context),
              icon: const Icon(Icons.add),
              label: Text(l.newFit),
            )
          : null,
      body: const NeedsSde(child: _SavedFitList()),
    );
  }

  Future<void> _newFit(BuildContext context) async {
    final l = context.l10n;
    final ship = await Navigator.of(context).push<TypeInfo>(
      MaterialPageRoute(
        builder: (_) => TypePickerScreen(
          title: l.chooseShip,
          searchHint: l.searchShips,
          emptyQueryMessage: l.shipSearchHint,
          results: (ref, q) => ref.watch(shipSearchProvider(q)),
        ),
      ),
    );
    if (ship == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FitEditorScreen(initial: Fit(shipTypeId: ship.typeId, name: ''))),
    );
  }

  Future<void> _importEft(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final text = await showEftImportSheet(context);
    final sde = ref.read(sdeRepositoryProvider);
    if (text == null || sde == null || !context.mounted) return;
    try {
      final data = await ref.read(dogmaDataProvider.future);
      final result = await parseEft(text, lookup: sde.typeByName, data: data);
      if (!context.mounted) return;
      if (result.skipped.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l.eftSkipped(result.skipped.toSet().join(', ')))));
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FitEditorScreen(initial: result.fit, dirty: true)),
      );
    } on EftFormatException catch (e) {
      final reason = switch (e.kind) {
        EftError.empty => l.eftErrorEmpty,
        EftError.badHeader => l.eftErrorHeader,
        EftError.unknownShip => l.eftErrorShip(e.detail),
      };
      messenger.showSnackBar(SnackBar(content: Text(l.eftImportFailed(reason))));
    } on Object catch (e) {
      if (context.mounted) messenger.showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
    }
  }
}

class _SavedFitList extends ConsumerWidget {
  const _SavedFitList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AsyncBody(
      value: ref.watch(savedFitsProvider),
      builder: (fits) => fits.isEmpty
          ? MessageView(message: l.savedFitsEmpty, icon: Icons.build_outlined)
          : ListView.builder(
              // Room for the floating button over the last row.
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: fits.length + 1,
              itemBuilder: (context, i) => i == 0 ? SectionTitle(l.savedFits) : _SavedFitTile(row: fits[i - 1]),
            ),
    );
  }
}

class _SavedFitTile extends ConsumerWidget {
  const _SavedFitTile({required this.row});

  final SavedFit row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final ship = ref.watch(typeInfoProvider(row.shipTypeId)).value;
    return Dismissible(
      key: ValueKey(row.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: t.surface2,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: Space.xl),
            child: Icon(Icons.delete_outline, color: t.danger),
          ),
        ),
      ),
      confirmDismiss: (_) => confirmAction(context, message: l.deleteFitConfirm(row.name), action: l.delete),
      onDismissed: (_) => deleteSavedFit(ref.read(appDatabaseProvider), row.id),
      child: ListTile(
        leading: EveImage.type(row.shipTypeId, size: 40),
        title: Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: ship == null ? null : Text(ship.name.of(zh: context.zh), maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          final Fit fit;
          try {
            fit = decodeSavedFit(row);
          } on Object catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => FitEditorScreen(initial: fit, savedId: row.id)),
          );
        },
      ),
    );
  }
}
