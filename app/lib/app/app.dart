import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'strings.dart';
import 'theme.dart';

class KidsPaintApp extends StatefulWidget {
  const KidsPaintApp({super.key});

  @override
  State<KidsPaintApp> createState() => _KidsPaintAppState();
}

class _KidsPaintAppState extends State<KidsPaintApp> {
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: KidTheme.light(),
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    );
  }
}
