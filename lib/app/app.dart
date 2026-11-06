import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/assets/ships_screen.dart';
import '../features/fitting/fitting_screen.dart';
import '../features/market/market_screen.dart';
import '../features/skills/skills_screen.dart';
import '../features/update/sde_controller.dart';
import '../features/update/sde_installer.dart';
import '../features/update/update_widgets.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common.dart';
import 'locale.dart';
import 'theme.dart';

class PocketHangarApp extends ConsumerWidget {
  const PocketHangarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).value;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        if (device?.languageCode == 'zh') return const Locale('zh');
        return const Locale('en');
      },
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  // Tabs are built the first time they are opened and then kept alive.
  final _built = <int>{0};

  static const _tabs = <Widget>[SkillsScreen(), MarketScreen(), ShipsScreen(), FittingScreen()];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sde = ref.watch(sdeControllerProvider);
    ref.listen(sdeControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.lastInstalled != null && next.lastInstalled != previous?.lastInstalled) {
        messenger.showSnackBar(SnackBar(content: Text(l.sdeInstalled(next.lastInstalled!))));
      }
      if (next.error != null && next.error != previous?.error && next.installed && next.error is SdeInstallException) {
        messenger.showSnackBar(SnackBar(content: Text(sdeErrorText(context, next.error!))));
      }
    });
    if (!sde.installed) return const SdeOnboarding();

    return Scaffold(
      body: Column(
        children: [
          const UpdateBanner(),
          Expanded(
            // This Scaffold already keeps its body above the keyboard. The tab screens are
            // Scaffolds as well and would take the keyboard height off a second time, which left
            // two result rows visible while typing in the market search.
            child: MediaQuery(
              data: MediaQuery.of(context).removeViewInsets(removeBottom: true).removePadding(removeTop: sde.updateAvailable),
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < _tabs.length; i++) _built.contains(i) ? _tabs[i] : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.tokens.hairline, width: hairlineWidth))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            _built.add(i);
          }),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.school_outlined), label: l.tabSkills),
            NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: l.tabMarket),
            NavigationDestination(icon: const Icon(Icons.rocket_outlined), label: l.tabAssets),
            NavigationDestination(icon: const Icon(Icons.build_outlined), label: l.tabFitting),
          ],
        ),
      ),
    );
  }
}
