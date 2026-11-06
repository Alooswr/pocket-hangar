import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../core/auth/accounts.dart';
import '../../core/images/eve_image.dart';
import '../../widgets/common.dart';
import '../settings/settings_screen.dart';

/// App bar action: the active character's portrait; opens the character sheet.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeAccountProvider);
    return IconButton(
      tooltip: context.l10n.characters,
      onPressed: () => showAccountSheet(context),
      icon: active == null
          ? const Icon(Icons.account_circle_outlined)
          : EveImage.character(active.characterId, size: 28),
    );
  }
}

Future<void> showAccountSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AccountSheet(),
    );

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final state = ref.watch(accountsProvider).value;
    final accounts = state?.accounts ?? const <Account>[];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
            child: Text(l.characters, style: context.text.titleMedium),
          ),
          for (final a in accounts)
            ListTile(
              leading: EveImage.character(a.characterId, size: 36),
              title: Text(a.name),
              subtitle: a.needsRelogin ? Text(l.errorReloginNeeded(a.name), style: TextStyle(color: t.danger)) : null,
              selected: a.characterId == state?.active?.characterId,
              selectedColor: t.text,
              selectedTileColor: t.surface3,
              trailing: a.needsRelogin
                  ? TextButton(onPressed: () => _login(context, ref), child: Text(l.signInAgain))
                  : IconButton(
                      tooltip: l.removeCharacter(a.name),
                      icon: const Icon(Icons.logout_outlined),
                      onPressed: () => _confirmRemove(context, ref, a),
                    ),
              onTap: () async {
                await ref.read(accountsProvider.notifier).setActive(a.characterId);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_outlined),
            title: Text(l.addCharacter),
            onTap: () => _login(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(height: Space.s),
        ],
      ),
    );
  }
}

Future<void> _login(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  if (AppConfig.ssoClientId.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l.clientIdMissing)));
    return;
  }
  try {
    final added = await ref.read(accountsProvider.notifier).addCharacter();
    if (!added) messenger.showSnackBar(SnackBar(content: Text(l.loginCancelled)));
  } on PlatformException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.loginFailed(e.message ?? e.code))));
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.loginFailed('$e'))));
  }
}

Future<void> _confirmRemove(BuildContext context, WidgetRef ref, Account account) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.removeCharacter(account.name)),
      content: Text(l.removeCharacterConfirm(account.name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.tokens.danger),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.removeCharacterAction),
        ),
      ],
    ),
  );
  if (ok == true) await ref.read(accountsProvider.notifier).remove(account.characterId);
}

/// Placeholder for character-only tabs when nobody is signed in.
class SignInPrompt extends ConsumerWidget {
  const SignInPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.noCharacterTitle, style: context.text.titleMedium),
            const SizedBox(height: Space.s),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                l.noCharacterBody,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium!.copyWith(color: context.tokens.textMuted),
              ),
            ),
            const SizedBox(height: Space.xl),
            FilledButton.icon(
              onPressed: () => _login(context, ref),
              icon: const Icon(Icons.login, size: 18),
              label: Text(l.addCharacter),
            ),
          ],
        ),
      ),
    );
  }
}
