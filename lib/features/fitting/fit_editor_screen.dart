import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/auth/accounts.dart';
import '../../core/images/eve_image.dart';
import '../../core/providers.dart';
import '../../core/sde/sde_models.dart';
import '../../core/search/name_search.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import 'dogma/dogma_data.dart';
import 'dogma/fit_stats.dart';
import 'eft.dart';
import 'fit.dart';
import 'fit_editing.dart';
import 'fitting_providers.dart';
import 'pickers.dart';

/// Strategic cruisers get their slots from subsystems, so those come first.
const _slotOrder = [SlotType.subsystem, SlotType.high, SlotType.mid, SlotType.low, SlotType.rig];

String slotLabel(AppLocalizations l, SlotType slot) => switch (slot) {
      SlotType.high => l.slotHigh,
      SlotType.mid => l.slotMid,
      SlotType.low => l.slotLow,
      SlotType.rig => l.slotRig,
      SlotType.subsystem => l.slotSubsystem,
    };

String stateLabel(AppLocalizations l, ModuleState s) => switch (s) {
      ModuleState.offline => l.stateOffline,
      ModuleState.online => l.stateOnline,
      ModuleState.active => l.stateActive,
      ModuleState.overheated => l.stateOverheated,
    };

class FitEditorScreen extends ConsumerStatefulWidget {
  const FitEditorScreen({required this.initial, this.savedId, this.dirty = false, super.key});

  final Fit initial;
  final int? savedId;

  /// True for fits that are not saved yet but hold work (an EFT import).
  final bool dirty;

  @override
  ConsumerState<FitEditorScreen> createState() => _FitEditorScreenState();
}

enum _MenuAction { rename, copyEft, upload, delete }

class _FitEditorScreenState extends ConsumerState<FitEditorScreen> {
  late Fit _fit = widget.initial;
  late int? _savedId = widget.savedId;
  late bool _dirty = widget.dirty;
  SkillSource _skills = SkillSource.allV;

  DogmaData? _typesRequestedFor;
  bool _typesLoading = false;

  // The last computation, reused while the fit, the skill levels and the data are unchanged.
  (Fit, Map<int, int>, DogmaData)? _memoKey;
  FitComputation? _memo;

  void _update(Fit fit) => setState(() {
        _fit = fit;
        _dirty = true;
      });

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  /// Loads the types of the fit into [data] once (opening a saved fit, or after a data update).
  void _ensureTypes(DogmaData data) {
    if (identical(_typesRequestedFor, data)) return;
    _typesRequestedFor = data;
    final missing = _fit.typeIds.where((id) => data.typeOrNull(id) == null).toList();
    if (missing.isEmpty) return;
    _typesLoading = true;
    data.ensureTypes(missing).whenComplete(() {
      if (mounted) setState(() => _typesLoading = false);
    });
  }

  FitComputation? _compute(DogmaData data, Map<int, int> levels) {
    final key = _memoKey;
    if (key != null && identical(key.$1, _fit) && identical(key.$2, levels) && identical(key.$3, data)) {
      return _memo;
    }
    if (data.typeOrNull(_fit.shipTypeId) == null) return null;
    _memoKey = (_fit, levels, data);
    return _memo = computeFit(data, _fit, levels);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final account = ref.watch(activeAccountProvider);
    final source = account == null ? SkillSource.allV : _skills;
    final dataValue = ref.watch(dogmaDataProvider);
    final levelsValue = ref.watch(fitSkillLevelsProvider(source));
    final skillsFailed = source == SkillSource.character && levelsValue.hasError && !levelsValue.hasValue;
    final levels = skillsFailed ? ref.watch(fitSkillLevelsProvider(SkillSource.allV)).value : levelsValue.value;
    final data = dataValue.value;

    Widget body;
    FitComputation? c;
    if (dataValue.hasError && data == null) {
      body = ErrorView(error: dataValue.error!, onRetry: () => ref.invalidate(dogmaDataProvider));
    } else if (data == null || levels == null || (!skillsFailed && levelsValue.isLoading && !levelsValue.hasValue)) {
      body = const LoadingView();
    } else {
      _ensureTypes(data);
      c = _compute(data, levels);
      if (c == null) {
        body = _typesLoading ? const LoadingView() : MessageView(message: l.unknownShip, icon: Icons.error_outline);
      } else {
        body = DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _Header(
                ship: data.type(_fit.shipTypeId),
                stats: c.stats,
                skillSelector: _skillSelector(account, source),
                notice: skillsFailed ? l.skillsLoadFailed(account?.name ?? '') : null,
              ),
              TabBar(tabs: [Tab(text: l.tabModules), Tab(text: l.tabStats)]),
              Expanded(
                child: TabBarView(
                  children: [_modulesTab(data, c), _StatsTab(stats: c.stats)],
                ),
              ),
            ],
          ),
        );
      }
    }

    final shipName = data?.typeOrNull(_fit.shipTypeId)?.name.of(zh: context.zh) ?? '';
    final ready = data != null && c != null;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirmAction(context, message: l.unsavedChanges, action: l.discard);
        if (!discard || !context.mounted) return;
        setState(() => _dirty = false);
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_fit.name.isEmpty ? shipName : _fit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: l.save,
              icon: const Icon(Icons.save_outlined),
              onPressed: ready && (_dirty || _savedId == null) ? () => _save(data) : null,
            ),
            PopupMenuButton<_MenuAction>(
              enabled: ready,
              onSelected: (a) => switch (a) {
                _MenuAction.rename => _rename(),
                _MenuAction.copyEft => _copyEft(data!),
                _MenuAction.upload => _upload(data!),
                _MenuAction.delete => _delete(),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: _MenuAction.rename, child: Text(l.rename)),
                PopupMenuItem(value: _MenuAction.copyEft, child: Text(l.exportEft)),
                PopupMenuItem(value: _MenuAction.upload, child: Text(l.uploadFitToGame)),
                if (_savedId != null) PopupMenuItem(value: _MenuAction.delete, child: Text(l.deleteFit)),
              ],
            ),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _skillSelector(Account? account, SkillSource source) {
    final l = context.l10n;
    final t = context.tokens;
    final label = source == SkillSource.character && account != null ? l.skillsOf(account.name) : l.skillsAllV;
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall);
    if (account == null) return text;
    return PopupMenuButton<SkillSource>(
      initialValue: source,
      tooltip: l.skillsAllV,
      onSelected: (s) => setState(() => _skills = s),
      itemBuilder: (_) => [
        PopupMenuItem(value: SkillSource.allV, child: Text(l.skillsAllV)),
        PopupMenuItem(value: SkillSource.character, child: Text(l.skillsOf(account.name))),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: text),
            const SizedBox(width: Space.xs),
            Icon(Icons.expand_more, size: 16, color: t.textMuted),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- modules tab

  Widget _modulesTab(DogmaData data, FitComputation c) {
    final l = context.l10n;
    final t = context.tokens;
    final totals = c.slotTotals;
    final rows = <Widget>[];
    for (final slot in _slotOrder) {
      final indexes = [
        for (var i = 0; i < _fit.modules.length; i++)
          if (_fit.modules[i].slot == slot) i,
      ];
      final total = totals[slot] ?? 0;
      if (total == 0 && indexes.isEmpty) continue;
      rows.add(SectionTitle(
        slotLabel(l, slot),
        trailing: Text(
          '${indexes.length} / $total',
          style: context.text.bodySmall!.copyWith(
            fontFeatures: tabular,
            color: indexes.length > total ? t.danger : null,
          ),
        ),
      ));
      for (final (n, i) in indexes.indexed) {
        rows.add(_moduleRow(data, i, over: n >= total));
      }
      for (var n = indexes.length; n < total; n++) {
        rows.add(ListTile(
          leading: SizedBox.square(dimension: 32, child: Icon(Icons.add, size: 20, color: t.textMuted)),
          title: Text(l.emptySlot, style: TextStyle(color: t.textMuted)),
          onTap: () => _addModule(slot, data),
        ));
      }
    }
    for (final (title, stacks, isDrones) in [(l.drones, _fit.drones, true), (l.cargo, _fit.cargo, false)]) {
      if (stacks.isEmpty) continue;
      rows.add(SectionTitle(title));
      for (final (i, s) in stacks.indexed) {
        rows.add(ListTile(
          leading: EveImage.type(s.typeId, size: 32),
          title: Text(
            data.typeOrNull(s.typeId)?.name.of(zh: context.zh) ?? '${s.typeId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('x${s.quantity}', style: const TextStyle(fontFeatures: tabular)),
          trailing: IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              final list = [...stacks]..removeAt(i);
              _update(isDrones ? _fit.copyWith(drones: list) : _fit.copyWith(cargo: list));
            },
          ),
        ));
      }
    }
    return ListView(padding: const EdgeInsets.only(bottom: Space.xxxl), children: rows);
  }

  Widget _moduleRow(DogmaData data, int index, {required bool over}) {
    final t = context.tokens;
    final m = _fit.modules[index];
    final type = data.typeOrNull(m.typeId);
    final chargeId = m.chargeTypeId;
    final charge = chargeId == null ? null : data.typeOrNull(chargeId)?.name.of(zh: context.zh);
    final states = type == null ? const [ModuleState.online] : availableStates(type, data);
    return ListTile(
      leading: EveImage.type(m.typeId, size: 32),
      title: Text(
        type?.name.of(zh: context.zh) ?? '${m.typeId}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: over ? t.danger : (m.state == ModuleState.offline ? t.textMuted : null)),
      ),
      subtitle: charge == null ? null : Text(charge, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: states.length > 1 && type != null
          ? _StateButton(
              state: m.state,
              onPressed: () => _update(setModuleState(_fit, index, toggledState(m.state, type, data), data)),
            )
          : null,
      onTap: type == null ? null : () => _openModuleSheet(data, index),
    );
  }

  Future<void> _addModule(SlotType slot, DogmaData data) async {
    final l = context.l10n;
    final ship = data.type(_fit.shipTypeId);
    ModuleQuery query(String q) =>
        (slot: slot, query: q, shipTypeId: ship.typeId, rigSize: ship.attributes[A.rigSize]?.round());
    final picked = await Navigator.of(context).push<TypeInfo>(
      MaterialPageRoute(
        builder: (_) => TypePickerScreen(
          title: slotLabel(l, slot),
          searchHint: l.chooseModule,
          results: (ref, q) => ref.watch(fittableTypesProvider(query(q))),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await data.ensureTypes([picked.typeId]);
    if (!mounted) return;
    final module = data.typeOrNull(picked.typeId);
    final c = _memo;
    if (module == null || c == null) return;
    final problem = fitProblem(fit: _fit, ship: ship, module: module, data: data, slotTotals: c.slotTotals);
    if (problem != null) {
      _snack(_problemText(problem, module));
      return;
    }
    _update(addModule(_fit, module, data));
  }

  String _problemText(FitProblem p, TypeDef module) {
    final l = context.l10n;
    final name = module.name.of(zh: context.zh);
    return switch (p.kind) {
      FitProblemKind.noFreeSlot => l.fitNoFreeSlot(name),
      FitProblemKind.wrongShip => l.fitWrongShip(name),
      FitProblemKind.groupLimit => l.fitGroupLimit(p.limit, name),
    };
  }

  Future<void> _openModuleSheet(DogmaData data, int index) async {
    final m = _fit.modules[index];
    final type = data.type(m.typeId);
    final c = _memo;
    final canFill = c != null &&
        m.slot != SlotType.subsystem &&
        fitProblem(fit: _fit, ship: data.type(_fit.shipTypeId), module: type, data: data, slotTotals: c.slotTotals) ==
            null;
    final action = await showModalBottomSheet<_ModuleAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ModuleSheet(
        typeId: m.typeId,
        name: type.name.of(zh: context.zh),
        state: m.state,
        states: availableStates(type, data),
        chargeable: takesCharges(type),
        hasCharge: m.chargeTypeId != null,
        canFill: canFill,
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _SetState(:final state):
        _update(setModuleState(_fit, index, state, data));
      case _ChooseCharge():
        await _chooseCharge(data, index);
      case _UnloadCharge():
        _update(setCharge(_fit, index, null));
      case _Fill():
        _fill(data, index);
      case _Remove():
        _update(removeModule(_fit, index));
    }
  }

  /// Picks a charge and loads it in every module of the same type, as grouped weapons would.
  Future<void> _chooseCharge(DogmaData data, int index) async {
    final l = context.l10n;
    final moduleTypeId = _fit.modules[index].typeId;
    final picked = await Navigator.of(context).push<TypeInfo>(
      MaterialPageRoute(
        builder: (_) => TypePickerScreen(
          title: l.chooseCharge,
          results: (ref, q) => ref
              .watch(chargesProvider(moduleTypeId))
              .whenData((list) => rankByName(list, q, (t) => (t.name.en, t.name.zh))),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await data.ensureTypes([picked.typeId]);
    if (!mounted) return;
    var fit = _fit;
    for (var i = 0; i < fit.modules.length; i++) {
      if (fit.modules[i].typeId == moduleTypeId) fit = setCharge(fit, i, picked.typeId);
    }
    _update(fit);
  }

  /// Copies module [index] (with its charge) into every free slot it is allowed in.
  void _fill(DogmaData data, int index) {
    final source = _fit.modules[index];
    final module = data.type(source.typeId);
    final ship = data.type(_fit.shipTypeId);
    final totals = _memo?.slotTotals;
    if (totals == null) return;
    var fit = _fit;
    for (var guard = 0; guard < 8; guard++) {
      if (fitProblem(fit: fit, ship: ship, module: module, data: data, slotTotals: totals) != null) break;
      fit = addModule(fit, module, data);
      if (source.chargeTypeId != null) fit = setCharge(fit, fit.modules.length - 1, source.chargeTypeId);
    }
    _update(fit);
  }

  // ---------------------------------------------------------------- app bar actions

  Future<void> _save(DogmaData data) async {
    final l = context.l10n;
    var fit = _fit;
    if (fit.name.trim().isEmpty) fit = fit.copyWith(name: data.type(fit.shipTypeId).name.of(zh: context.zh));
    final id = await saveFit(ref.read(appDatabaseProvider), fit, id: _savedId);
    if (!mounted) return;
    setState(() {
      _fit = fit;
      _savedId = id;
      _dirty = false;
    });
    _snack(l.fitSaved);
  }

  Future<void> _rename() async {
    final l = context.l10n;
    final name = await showTextDialog(context, title: l.rename, initial: _fit.name, confirm: l.save);
    if (name == null || !mounted || name == _fit.name) return;
    _update(_fit.copyWith(name: name));
  }

  Future<void> _copyEft(DogmaData data) async {
    final l = context.l10n;
    final text = exportEft(
      _fit,
      data,
      slotTotals: _memo?.slotTotals,
      defaultName: data.type(_fit.shipTypeId).name.en,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack(l.copied);
  }

  Future<void> _upload(DogmaData data) async {
    final l = context.l10n;
    final account = ref.read(activeAccountProvider);
    if (account == null) return _snack(l.uploadNeedsCharacter);
    if (_fit.modules.isEmpty && _fit.drones.isEmpty && _fit.cargo.isEmpty) return _snack(l.fitEmptyCannotUpload);
    final name = _fit.name.trim().isEmpty ? data.type(_fit.shipTypeId).name.en : _fit.name;
    try {
      await ref.read(eveApiProvider).saveFitting(account.characterId, toEsiFitting(_fit, data, name: name));
      if (mounted) _snack(l.fitUploaded(account.name));
    } on Object catch (e) {
      if (mounted) _snack(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final id = _savedId;
    if (id == null) return;
    final ok = await confirmAction(context, message: l.deleteFitConfirm(_fit.name), action: l.delete);
    if (!ok || !mounted) return;
    await deleteSavedFit(ref.read(appDatabaseProvider), id);
    if (!mounted) return;
    setState(() => _dirty = false);
    Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({required this.ship, required this.stats, required this.skillSelector, this.notice});

  final TypeDef ship;
  final FitStats stats;
  final Widget skillSelector;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final problems = [
      if (stats.cpu.over) l.fitTooMuchCpu(formatFixed(-stats.cpu.left, 1)),
      if (stats.power.over) l.fitTooMuchPower(formatFixed(-stats.power.left, 1)),
      if (stats.calibration.over) l.fitTooMuchCalibration(formatFixed(-stats.calibration.left, 0)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EveImage.type(ship.typeId, size: 40),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ship.name.of(zh: context.zh),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    skillSelector,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              Expanded(child: _Meter(label: l.statCpu, usage: stats.cpu)),
              const SizedBox(width: Space.m),
              Expanded(child: _Meter(label: l.statPowergrid, usage: stats.power)),
              const SizedBox(width: Space.m),
              Expanded(child: _Meter(label: l.statCalibration, usage: stats.calibration, decimals: 0)),
            ],
          ),
          if (problems.isNotEmpty) ...[
            const SizedBox(height: Space.s),
            Text(problems.join('\n'), style: context.text.bodySmall!.copyWith(color: t.danger)),
          ],
          if (notice != null) ...[
            const SizedBox(height: Space.s),
            Text(notice!, style: context.text.bodySmall!.copyWith(color: t.warning)),
          ],
        ],
      ),
    );
  }
}

/// Compact used / total with a bar, for three meters side by side on a phone.
class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.usage, this.decimals});

  final String label;
  final Usage usage;
  final int? decimals;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final d = decimals ?? (usage.total >= 1000 ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
        Text(
          '${formatFixed(usage.used, d)} / ${formatFixed(usage.total, d)}',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: context.text.bodySmall!.copyWith(fontFeatures: tabular, color: usage.over ? t.danger : t.text),
        ),
        const SizedBox(height: Space.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: usage.fraction),
            duration: Motion.fast,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              color: usage.over ? t.danger : t.accent,
              backgroundColor: t.surface3,
            ),
          ),
        ),
      ],
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({required this.state, required this.onPressed});

  final ModuleState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (icon, color) = switch (state) {
      ModuleState.offline => (Icons.power_off_outlined, t.textMuted),
      ModuleState.online => (Icons.power_outlined, t.text),
      ModuleState.active => (Icons.play_circle_outline, t.accent),
      ModuleState.overheated => (Icons.local_fire_department_outlined, t.warning),
    };
    return IconButton(
      tooltip: stateLabel(context.l10n, state),
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: Motion.fast,
        child: Icon(icon, key: ValueKey(state), color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------- module sheet

sealed class _ModuleAction {
  const _ModuleAction();
}

class _SetState extends _ModuleAction {
  const _SetState(this.state);

  final ModuleState state;
}

class _ChooseCharge extends _ModuleAction {
  const _ChooseCharge();
}

class _UnloadCharge extends _ModuleAction {
  const _UnloadCharge();
}

class _Fill extends _ModuleAction {
  const _Fill();
}

class _Remove extends _ModuleAction {
  const _Remove();
}

class _ModuleSheet extends StatelessWidget {
  const _ModuleSheet({
    required this.typeId,
    required this.name,
    required this.state,
    required this.states,
    required this.chargeable,
    required this.hasCharge,
    required this.canFill,
  });

  final int typeId;
  final String name;
  final ModuleState state;
  final List<ModuleState> states;
  final bool chargeable;
  final bool hasCharge;
  final bool canFill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    void pop(_ModuleAction a) => Navigator.of(context).pop(a);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
            child: Row(
              children: [
                EveImage.type(typeId, size: 40),
                const SizedBox(width: Space.m),
                Expanded(child: Text(name, style: context.text.titleSmall)),
              ],
            ),
          ),
          if (states.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
              child: SegmentedButton<ModuleState>(
                showSelectedIcon: false,
                segments: [for (final s in states) ButtonSegment(value: s, label: Text(stateLabel(l, s)))],
                selected: {state},
                onSelectionChanged: (s) => pop(_SetState(s.first)),
              ),
            ),
          if (chargeable)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(l.chooseCharge),
              onTap: () => pop(const _ChooseCharge()),
            ),
          if (hasCharge)
            ListTile(
              leading: const Icon(Icons.eject_outlined),
              title: Text(l.removeCharge),
              onTap: () => pop(const _UnloadCharge()),
            ),
          if (canFill)
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(l.fillSlots),
              onTap: () => pop(const _Fill()),
            ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: t.danger),
            title: Text(l.removeModule, style: TextStyle(color: t.danger)),
            onTap: () => pop(const _Remove()),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- stats tab

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats});

  final FitStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final s = stats;
    final cap = s.capacitor;
    String n1(double v) => formatFixed(v, 1);
    String usage(Usage u, int decimals, String unit) =>
        '${formatFixed(u.used, decimals)} / ${formatFixed(u.total, decimals)}${unit.isEmpty ? '' : ' $unit'}';
    final capState = cap.stable
        ? l.capStable(n1(cap.stableFraction! * 100))
        : l.capLasts(formatDuration(Duration(milliseconds: (cap.secondsToEmpty! * 1000).round()), l));
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxxl),
      children: [
        SectionTitle(l.statFitting),
        StatRow(label: l.statCpu, value: usage(s.cpu, 1, 'tf'), valueColor: s.cpu.over ? t.danger : null),
        StatRow(label: l.statPowergrid, value: usage(s.power, 1, 'MW'), valueColor: s.power.over ? t.danger : null),
        StatRow(
          label: l.statCalibration,
          value: usage(s.calibration, 0, ''),
          valueColor: s.calibration.over ? t.danger : null,
        ),
        StatRow(label: l.statTurrets, value: usage(s.turrets, 0, ''), valueColor: s.turrets.over ? t.danger : null),
        StatRow(
          label: l.statLaunchers,
          value: usage(s.launchers, 0, ''),
          valueColor: s.launchers.over ? t.danger : null,
        ),
        SectionTitle(l.statCapacitor),
        StatRow(label: l.capCapacity, value: '${n1(cap.capacity)} GJ'),
        StatRow(label: l.capRechargeTime, value: l.secondsValue(n1(cap.rechargeSeconds))),
        StatRow(label: l.capStatus, value: capState, valueColor: cap.stable ? null : t.warning),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
          child: Text(
            l.capDelta(n1(math.max(0, cap.drainPerSecond)), n1(cap.peakRecharge)),
            style: context.text.bodySmall!.copyWith(fontFeatures: tabular),
          ),
        ),
        SectionTitle(l.statDefense),
        _ResistTable(stats: s),
        StatRow(label: l.ehpUniform, value: formatInt(s.ehpUniform.round())),
        SectionTitle(l.statNavigation),
        StatRow(label: l.maxVelocity, value: '${n1(s.maxVelocity)} m/s'),
        StatRow(label: l.alignTime, value: l.secondsValue(formatFixed(s.alignTime, 2))),
        StatRow(label: l.signatureRadius, value: '${n1(s.signatureRadius)} m'),
        StatRow(label: l.mass, value: '${formatInt(s.mass.round())} kg'),
      ],
    );
  }
}

/// Resists per layer (percent) and raw HP; numbers right-aligned in tabular figures.
class _ResistTable extends StatelessWidget {
  const _ResistTable({required this.stats});

  final FitStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final numberStyle = context.text.bodyMedium!.copyWith(fontFeatures: tabular);
    Widget header(String text) => Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: Text(text, textAlign: TextAlign.right, maxLines: 1, style: context.text.bodySmall),
        );
    Widget resist(double resonance) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Text('${formatFixed((1 - resonance) * 100, 1)}%', textAlign: TextAlign.right, style: numberStyle),
        );
    TableRow row(String label, DefenseLayer layer) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Text(label, style: context.text.bodyMedium!.copyWith(color: t.textMuted)),
            ),
            resist(layer.em),
            resist(layer.thermal),
            resist(layer.kinetic),
            resist(layer.explosive),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Text(formatInt(layer.hp.round()), textAlign: TextAlign.right, style: numberStyle),
            ),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.xs),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FlexColumnWidth(),
          5: FlexColumnWidth(1.3),
        },
        children: [
          TableRow(
            children: [
              const SizedBox.shrink(),
              header(l.damageEmShort),
              header(l.damageThermalShort),
              header(l.damageKineticShort),
              header(l.damageExplosiveShort),
              header(l.hpColumn),
            ],
          ),
          row(l.layerShield, stats.shield),
          row(l.layerArmor, stats.armor),
          row(l.layerHull, stats.hull),
        ],
      ),
    );
  }
}
