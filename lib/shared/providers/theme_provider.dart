import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _boxName = 'settings';
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final box = Hive.box(_boxName);
    final stored = box.get(_key, defaultValue: 'system') as String;
    switch (stored) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    final box = Hive.box(_boxName);
    switch (mode) {
      case ThemeMode.dark:
        box.put(_key, 'dark');
      case ThemeMode.light:
        box.put(_key, 'light');
      case ThemeMode.system:
        box.put(_key, 'system');
    }
  }

  void toggle() {
    setTheme(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
