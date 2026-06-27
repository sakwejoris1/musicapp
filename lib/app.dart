import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/playlist_provider.dart';
import 'services/audio_service.dart';

class ChuyassiApp extends StatefulWidget {
  const ChuyassiApp({super.key, required this.audioHandler});
  final ChuyassiAudioHandler audioHandler;

  @override
  State<ChuyassiApp> createState() => _ChuyassiAppState();
}

class _ChuyassiAppState extends State<ChuyassiApp> {
  late final AuthProvider _auth;
  late final LocaleProvider _locale;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _locale = LocaleProvider();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _locale),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(widget.audioHandler)),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: _AppView(auth: _auth),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({required this.auth});
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp.router(
      title: 'Chuyassi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: buildRouter(auth),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
