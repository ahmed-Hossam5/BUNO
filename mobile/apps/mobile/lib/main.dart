import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_routes.dart';
import 'l10n/buno_locale.dart';
import 'theme/buno_tokens.dart';
import 'theme/buno_tokens_ext.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: const Color(0x00000000),
    systemNavigationBarColor: BunoDark.background,
  ));
  runApp(const BunoApp(initialRoute: AppRoutes.splash));
}

class BunoApp extends StatefulWidget {
  const BunoApp({super.key, this.initialRoute = AppRoutes.home});

  /// The app itself starts on /splash; tests pump straight to Home.
  final String initialRoute;

  @override
  State<BunoApp> createState() => _BunoAppState();
}

class _BunoAppState extends State<BunoApp> {
  @override
  void initState() {
    super.initState();
    BunoLocale.current.addListener(_onLocale);
  }

  @override
  void dispose() {
    BunoLocale.current.removeListener(_onLocale);
    super.dispose();
  }

  /// Strings come from `tr()`, not from an InheritedWidget, so a language
  /// change marks every element dirty (const widgets included) once.
  void _onLocale() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (mounted) (context as Element).visitChildren(mark);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buno',
      debugShowCheckedModeBanner: false,
      // Arabic => Flutter lays the whole tree out right-to-left;
      // English => left-to-right.
      locale: BunoLocale.current.value,
      supportedLocales: BunoLocale.supported,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: BunoFonts.readex,
        scaffoldBackgroundColor: BunoDark.background,
        colorScheme: const ColorScheme.dark(
          primary: BunoColors.primary,
          onPrimary: BunoDark.on_primary,
          surface: BunoDark.surface,
          onSurface: BunoDark.text_primary,
          error: BunoColors.error,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: BunoColors.primary,
          selectionHandleColor: BunoColors.primary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: BunoDark.elevated,
          contentTextStyle: BunoType.body,
        ),
      ),
      // `flutter run --route /login` etc. opens a screen directly
      // (on web: `/#/login`). See AppRoutes for the list.
      initialRoute: widget.initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
