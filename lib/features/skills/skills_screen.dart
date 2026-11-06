import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/auth/accounts.dart';
import '../../core/images/eve_image.dart';
import '../../core/sde/sde_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../account/account_widgets.dart';
import 'skill_math.dart';
import 'skills_data.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final account = ref.watch(activeAccountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(account?.name ?? l.skillsTitle), actions: const [AccountButton()]),
      body: account == null
          ? const SignInPrompt()
          : NeedsSde(child: _SkillsBody(characterId: account.characterId)),
    );
  }
}

class _SkillsBody extends ConsumerStatefulWidget {
  const _SkillsBody({required this.characterId});

  final int characterId;

  @override
  ConsumerState<_SkillsBody> createState() => _SkillsBodyState();
}

class _SkillsBodyState extends ConsumerState<_SkillsBody> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Remaining times count down on screen; data itself is only refetched when ESI's cache expires.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = skillOverviewProvider(widget.characterId);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: AsyncBody(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        builder: (o) => _SkillsList(characterId: widget.characterId, overview: o),
      ),
    );
  }
}

class _SkillsList extends StatelessWidget {
  const _SkillsList({required this.characterId, required this.overview});

  final int characterId;
  final SkillOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final now = DateTime.now();
    final o = overview;
    final rate = o.effectiveRate;
    final end = o.queueEnd;
    final mismatch = o.rateMismatchPercent;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
          child: Row(
            children: [
              EveImage.character(characterId, size: 56),
              const SizedBox(width: Space.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.totalSp(formatInt(o.totalSp)), style: context.text.titleMedium!.copyWith(fontFeatures: tabular)),
                    if (o.unallocatedSp > 0)
                      Text(l.unallocatedSp(formatInt(o.unallocatedSp)), style: context.text.bodySmall),
                    if (rate != null)
                      Text(l.trainingRate(formatFixed(rate, 1)), style: context.text.bodySmall!.copyWith(fontFeatures: tabular)),
                  ],
                ),
              ),
            ],
          ),
        ),
        FreshnessLine(fetchedAt: o.fetchedAt, stale: o.stale),
        if (o.clone == CloneGuess.alpha) _Note(icon: Icons.info_outline, text: l.alphaClone),
        if (mismatch != null && mismatch.abs() >= 2)
          _Note(icon: Icons.info_outline, text: l.rateFromServer(formatFixed(mismatch.abs(), 0))),
        SectionTitle(
          l.skillQueue,
          trailing: o.paused
              ? Text(l.queuePaused, style: context.text.bodySmall!.copyWith(color: t.warning))
              : null,
        ),
        if (o.queue.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Text(l.queueEmpty, style: context.text.bodyMedium!.copyWith(color: t.textMuted)),
          )
        else ...[
          if (end != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
              child: Text(
                '${l.queueFinishesIn(formatDuration(end.difference(now), l))}  ${l.queueFinishesAt(formatDateTime(end))}',
                style: context.text.bodySmall!.copyWith(fontFeatures: tabular),
              ),
            ),
          for (final (i, item) in o.queue.indexed) _QueueRow(item: item, first: i == 0, now: now),
        ],
        SectionTitle(l.attributes),
        for (final id in CharacterAttributes.order) _AttributeRow(attributes: o.attributes, attributeId: id),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: context.tokens.textMuted),
            const SizedBox(width: Space.s),
            Expanded(child: Text(text, style: context.text.bodySmall)),
          ],
        ),
      );
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item, required this.first, required this.now});

  final QueueItem item;
  final bool first;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final finish = item.finish;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '${item.name.of(zh: context.zh)} ${romanLevel(item.level)}',
                  style: context.text.bodyMedium!.copyWith(fontWeight: first ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
              if (finish != null)
                Text(
                  l.skillLeft(formatDuration(finish.difference(now), l)),
                  style: context.text.bodySmall!.copyWith(fontFeatures: tabular, color: t.text),
                ),
            ],
          ),
          if (finish != null)
            Text(
              '${l.skillFinishes(formatDateTime(finish))}${item.estimated ? ' *' : ''}',
              style: context.text.bodySmall!.copyWith(fontFeatures: tabular),
            ),
          if (first) ...[
            const SizedBox(height: Space.s),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: item.progress(now), minHeight: 4),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.attributes, required this.attributeId});

  final CharacterAttributes attributes;
  final int attributeId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = switch (attributeId) {
      AttrIds.intelligence => l.attrIntelligence,
      AttrIds.memory => l.attrMemory,
      AttrIds.perception => l.attrPerception,
      AttrIds.willpower => l.attrWillpower,
      _ => l.attrCharisma,
    };
    final bonus = attributes.implantBonus[attributeId] ?? 0;
    return StatRow(
      label: label,
      value: bonus > 0
          ? '${formatFixed(attributes.effective(attributeId), 0)}  (${l.implantBonus(formatFixed(bonus, 0))})'
          : formatFixed(attributes.effective(attributeId), 0),
    );
  }
}
