import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/model_manager/model_manager_screen.dart';
import 'features/learned/learned_commands_screen.dart';

class AdaptiveAssistantApp extends ConsumerWidget {
  const AdaptiveAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF1F5B5E),
      brightness: Brightness.light,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'AdaptiveAssistant',
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        textTheme: base.textTheme.apply(
          bodyColor: const Color(0xFF101417),
          displayColor: const Color(0xFF101417),
        ),
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/setup': (_) => const SetupScreen(),
        '/model-manager': (_) => const ModelManagerScreen(),
        '/learned': (_) => const LearnedCommandsScreen(),
      },
    );
  }
}
