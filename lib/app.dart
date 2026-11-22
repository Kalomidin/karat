import 'dart:async';

import 'package:karat/l10n/app_text.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/l10n/russian_material.dart';
import 'package:karat/screens/shop_shell.dart';
import 'package:karat/screens/sign_in_screen.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/karat_mark.dart';
import 'package:material_ui/material_ui.dart';

class KaratApp extends StatefulWidget {
  const KaratApp({super.key, required this.controller, this.locales});

  final KaratController controller;
  final LocaleController? locales;

  @override
  State<KaratApp> createState() => _KaratAppState();
}

enum _Phase { boot, signedOut, signedIn }

class _KaratAppState extends State<KaratApp> {
  late final ThemeData _theme = karatTheme();
  late final LocaleController _locales;
  late final bool _ownsLocales;
  late _Phase _phase = _phaseOf(widget.controller);

  @override
  void initState() {
    super.initState();
    _ownsLocales = widget.locales == null;
    _locales =
        widget.locales ?? LocaleController(store: PreferencesLanguageStore());
    widget.controller.addListener(_onController);
    _locales.addListener(_onLocale);
    unawaited(widget.controller.bootstrap());
    unawaited(_locales.load());
  }

  @override
  void dispose() {
    widget.controller
      ..removeListener(_onController)
      ..dispose();
    _locales.removeListener(_onLocale);
    if (_ownsLocales) _locales.dispose();
    super.dispose();
  }

  void _onController() {
    final next = _phaseOf(widget.controller);
    if (next != _phase) setState(() => _phase = next);
  }

  void _onLocale() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final chosen = _locales.override;
    return MaterialApp(
      title: 'Karat',
      theme: _theme,
      themeMode: ThemeMode.light,
      locale: chosen,
      supportedLocales: const [Locale('en'), Locale('ru')],
      localeResolutionCallback: (device, _) =>
          resolveKaratLocale(device, chosen),
      localizationsDelegates: const [
        AppText.delegate,
        KaratMaterialLocalizationsDelegate(),
        KaratCupertinoLocalizationsDelegate(),
      ],
      home: switch (_phase) {
        _Phase.boot => const _BootScreen(),
        _Phase.signedOut => SignInScreen(
          controller: widget.controller,
          locales: _locales,
        ),
        _Phase.signedIn => ShopShell(
          controller: widget.controller,
          locales: _locales,
        ),
      },
    );
  }
}

_Phase _phaseOf(KaratController controller) {
  if (!controller.ready) return _Phase.boot;
  if (controller.user == null) return _Phase.signedOut;
  return _Phase.signedIn;
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: KaratMark(size: 72)));
  }
}
