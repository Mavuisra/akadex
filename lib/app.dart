import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/akadex_theme.dart';
import 'data/sync/sync_service.dart';

class AkadexApp extends ConsumerStatefulWidget {
  const AkadexApp({super.key});

  @override
  ConsumerState<AkadexApp> createState() => _AkadexAppState();
}

class _AkadexAppState extends ConsumerState<AkadexApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncStateProvider.notifier).syncNow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Akadex',
      debugShowCheckedModeBanner: false,
      theme: AkadexTheme.light(),
      themeMode: ThemeMode.light,
      scrollBehavior: AkadexScrollBehavior(),
      routerConfig: router,
      builder: (context, child) {
        return CupertinoTheme(
          data: const CupertinoThemeData(
            primaryColor: AkadexColors.primary,
            scaffoldBackgroundColor: AkadexColors.background,
            barBackgroundColor: Color(0xF0F9F9F9),
            textTheme: CupertinoTextThemeData(
              primaryColor: AkadexColors.primary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
