import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/akadex_theme.dart';
import 'core/theme/theme_mode_provider.dart';
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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Akadex',
      debugShowCheckedModeBanner: false,
      theme: AkadexTheme.light(),
      darkTheme: AkadexTheme.dark(),
      themeMode: themeMode,
      scrollBehavior: AkadexScrollBehavior(),
      routerConfig: router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: brightness,
            primaryColor: isDark
                ? AkadexColors.primaryOnDark
                : AkadexColors.primary,
            scaffoldBackgroundColor: isDark
                ? AkadexColors.backgroundDark
                : AkadexColors.background,
            barBackgroundColor: isDark
                ? const Color(0xF01A1A1A)
                : const Color(0xF0F9F9F9),
            textTheme: CupertinoTextThemeData(
              primaryColor: isDark
                  ? AkadexColors.primaryOnDark
                  : AkadexColors.primary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
