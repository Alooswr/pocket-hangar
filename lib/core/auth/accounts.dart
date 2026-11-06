import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../providers.dart';

class Account {
  const Account({required this.characterId, required this.name, required this.needsRelogin});

  final int characterId;
  final String name;
  final bool needsRelogin;
}

class AccountsState {
  const AccountsState({required this.accounts, required this.activeId});

  final List<Account> accounts;
  final int? activeId;

  Account? get active {
    for (final a in accounts) {
      if (a.characterId == activeId) return a;
    }
    return accounts.isEmpty ? null : accounts.first;
  }
}

const _activeKey = 'activeCharacterId';

/// Characters signed in on this device and which one is selected.
class AccountsNotifier extends AsyncNotifier<AccountsState> {
  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  Future<AccountsState> build() async {
    final signal = ref.watch(reloginSignalProvider);
    void onSignal() {
      final id = signal.value;
      if (id != null) unawaited(markNeedsRelogin(id));
    }

    signal.addListener(onSignal);
    ref.onDispose(() => signal.removeListener(onSignal));
    return _load();
  }

  Future<AccountsState> _load() async {
    final rows = await (_db.select(_db.characters)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.addedAt)]))
        .get();
    final active = int.tryParse(await _db.getValue(_activeKey) ?? '');
    return AccountsState(
      accounts: [
        for (final r in rows) Account(characterId: r.characterId, name: r.name, needsRelogin: r.needsRelogin),
      ],
      activeId: active ?? (rows.isEmpty ? null : rows.first.characterId),
    );
  }

  /// Opens the EVE login page. Returns false when the user cancelled.
  Future<bool> addCharacter() async {
    final claims = await ref.read(authServiceProvider).signIn();
    if (claims == null) return false;
    await _db.into(_db.characters).insertOnConflictUpdate(
          CharactersCompanion.insert(
            characterId: Value(claims.characterId),
            name: claims.name,
            scopes: Value(claims.scopes.join(' ')),
            needsRelogin: const Value(false),
          ),
        );
    await _db.setValue(_activeKey, '${claims.characterId}');
    state = AsyncData(await _load());
    return true;
  }

  Future<void> setActive(int characterId) async {
    await _db.setValue(_activeKey, '$characterId');
    state = AsyncData(await _load());
  }

  Future<void> remove(int characterId) async {
    await ref.read(authServiceProvider).signOut(characterId);
    await (_db.delete(_db.characters)..where((t) => t.characterId.equals(characterId))).go();
    await ref.read(esiCacheProvider).deleteForCharacter(characterId);
    final current = state.value?.activeId;
    if (current == characterId) await _db.setValue(_activeKey, null);
    state = AsyncData(await _load());
  }

  Future<void> markNeedsRelogin(int characterId) async {
    await (_db.update(_db.characters)..where((t) => t.characterId.equals(characterId)))
        .write(const CharactersCompanion(needsRelogin: Value(true)));
    state = AsyncData(await _load());
  }
}

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, AccountsState>(AccountsNotifier.new);

/// The selected character, or null when none is signed in.
final activeAccountProvider = Provider<Account?>((ref) => ref.watch(accountsProvider).value?.active);
