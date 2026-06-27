import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/playlist_provider.dart';
import 'services/storage_service.dart';

class ChuyassiApp extends StatefulWidget {
  const ChuyassiApp({super.key});

  @override
  State<ChuyassiApp> createState() => _ChuyassiAppState();
}

class _ChuyassiAppState extends State<ChuyassiApp> {
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
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
    // Watch auth so the router rebuilds on login/logout
    context.watch<AuthProvider>();
    final storage = StorageService();
    final langCode = storage.getLanguage();

    return MaterialApp.router(
      title: 'Chuyassi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: buildRouter(auth),
      locale: Locale(langCode),
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
