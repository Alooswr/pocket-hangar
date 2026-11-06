import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// null = follow the system language.
class LocaleNotifier extends AsyncNotifier<Locale?> {
  static const _key = 'locale';

  @override
  Future<Locale?> build() async {
    final value = await ref.watch(appDatabaseProvider).getValue(_key);
    return switch (value) {
      'en' => const Locale('en'),
      'zh' => const Locale('zh'),
      _ => null,
    };
  }

  Future<void> set(Locale? locale) async {
    await ref.read(appDatabaseProvider).setValue(_key, locale?.languageCode);
    state = AsyncData(locale);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
