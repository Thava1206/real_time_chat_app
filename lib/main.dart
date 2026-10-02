import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'theme/appearance_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';
import 'widgets/liquid_glass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Require a fresh login every launch instead of persisting the session.
  await FirebaseAuth.instance.signOut();
  final appearanceController = await AppearanceController.load();
  runApp(MyApp(appearanceController: appearanceController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.appearanceController});

  final AppearanceController appearanceController;

  @override
  Widget build(BuildContext context) {
    return AppearanceScope(
      controller: appearanceController,
      child: AnimatedBuilder(
        animation: appearanceController,
        builder: (context, _) {
          final theme = switch (appearanceController.appearance) {
            AppAppearance.light => lightAppTheme,
            AppAppearance.dark => darkAppTheme,
            AppAppearance.liquidGlass => liquidGlassTheme,
          };
          return MaterialApp(
            title: 'Real Time Chat',
            debugShowCheckedModeBanner: false,
            theme: theme,
            themeAnimationDuration: const Duration(milliseconds: 450),
            themeAnimationCurve: Curves.easeOutCubic,
            builder: (context, child) =>
                LiquidGlassBackground(child: child ?? const SizedBox.shrink()),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
