import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearance { light, dark, liquidGlass }

extension AppAppearanceLabel on AppAppearance {
  String get label => switch (this) {
    AppAppearance.light => 'Light',
    AppAppearance.dark => 'Dark',
    AppAppearance.liquidGlass => 'Liquid glass',
  };

  IconData get icon => switch (this) {
    AppAppearance.light => Icons.light_mode_outlined,
    AppAppearance.dark => Icons.dark_mode_outlined,
    AppAppearance.liquidGlass => Icons.blur_on_rounded,
  };
}

class AppearanceController extends ChangeNotifier {
  AppearanceController({AppAppearance initial = AppAppearance.dark})
    : _appearance = initial;

  static const _preferenceKey = 'app_appearance';
  AppAppearance _appearance;

  AppAppearance get appearance => _appearance;

  static Future<AppearanceController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_preferenceKey);
    AppAppearance? appearance;
    for (final mode in AppAppearance.values) {
      if (mode.name == stored) appearance = mode;
    }
    return AppearanceController(initial: appearance ?? AppAppearance.dark);
  }

  Future<void> setAppearance(AppAppearance value) async {
    if (_appearance == value) return;
    _appearance = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, value.name);
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppearanceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}
