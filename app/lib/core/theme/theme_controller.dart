import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light / dark / follow-the-phone choice, saved on the device.
class ThemeController extends ChangeNotifier {
  ThemeController([this._mode = ThemeMode.system]);

  static const _key = 'theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  static Future<ThemeController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      return ThemeController(ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system));
    } on Exception {
      return ThemeController();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } on Exception {
      // Not saved; the choice still applies for this session.
    }
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({super.key, required ThemeController controller, required super.child}) : super(notifier: controller);

  static ThemeController of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}
