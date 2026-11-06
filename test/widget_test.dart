import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/app/theme.dart';
import 'package:pocket_hangar/core/auth/accounts.dart';
import 'package:pocket_hangar/core/db/app_database.dart';
import 'package:pocket_hangar/core/providers.dart';
import 'package:pocket_hangar/features/fitting/fit.dart';
import 'package:pocket_hangar/features/fitting/fit_editor_screen.dart';
import 'package:pocket_hangar/features/fitting/fitting_providers.dart';
import 'package:pocket_hangar/features/market/item_market_screen.dart';
import 'package:pocket_hangar/features/market/market_data.dart';
import 'package:pocket_hangar/features/update/sde_controller.dart';
import 'package:pocket_hangar/l10n/app_localizations.dart';

import 'support/fixture.dart';

Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: buildDarkTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  testWidgets('price history states the change over the chosen window', (tester) async {
    final start = DateTime.utc(2026, 8, 1);
    final days = [
      for (var i = 0; i < 100; i++)
        HistoryDay(
          date: start.add(Duration(days: i)),
          average: 100 + i.toDouble(),
          highest: 110,
          lowest: 90,
          volume: 1000,
          orderCount: 10,
        ),
    ];
    var window = 30;
    await tester.pumpWidget(host(Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: PriceHistory(days: days, window: window, onWindow: (d) => setState(() => window = d)),
        ),
      ),
    )));
    // Last 30 days: 170 -> 199 is +17.1 %.
    expect(find.text('+17.1% over 30 days'), findsOneWidget);
    // Axis labels sit on the grid lines only. The padded axis ends (165.65 and 203.35) used to
    // get labels too, drawn over the nearest grid label.
    expect(find.text('165.65'), findsNothing);
    expect(find.text('203.35'), findsNothing);
    expect(find.text('180.00'), findsOneWidget);
    await tester.tap(find.text('90d'));
    await tester.pumpAndSettle();
    expect(find.textContaining('over 90 days'), findsOneWidget);
  });

  group('fit editor', () {
    late FitBench bench;
    late AppDatabase db;

    setUp(() async {
      bench = await FitBench.open();
      await bench.data.ensureTypes([587]);
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
      await bench.close();
    });

    Future<void> pumpEditor(WidgetTester tester, {Locale locale = const Locale('en')}) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sdeRepositoryProvider.overrideWithValue(bench.sde),
          dogmaDataProvider.overrideWith((ref) async => bench.data),
          appDatabaseProvider.overrideWithValue(db),
          activeAccountProvider.overrideWithValue(null),
        ],
        retry: (_, _) => null,
        child: host(FitEditorScreen(initial: const Fit(shipTypeId: 587, name: 'Test')), locale: locale),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows slots, resources and stats of an empty Rifter', (tester) async {
      await pumpEditor(tester);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Rifter'), findsOneWidget);
      expect(find.text('All skills V'), findsOneWidget);
      expect(find.text('0.0 / 162.5'), findsOneWidget); // CPU meter
      expect(find.text('High slots'), findsOneWidget);
      expect(find.text('Empty slot'), findsWidgets);

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('0.0 / 51.3 MW'), findsOneWidget);
      expect(find.text('312.5 GJ'), findsOneWidget);
      expect(find.text('Stable at 100.0%'), findsOneWidget);
    });

    testWidgets('Chinese UI shows Chinese item names', (tester) async {
      await pumpEditor(tester, locale: const Locale('zh'));
      expect(find.text('全技能 5 级'), findsOneWidget);
      expect(find.text('高槽'), findsOneWidget);
      expect(find.text(bench.data.type(587).name.zh!), findsOneWidget);
    });
  });
}
