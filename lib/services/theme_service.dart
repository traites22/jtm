import 'package:hive_flutter/hive_flutter.dart';

class ThemeService {
  static const _box = 'settingsBox';
  static const _key = 'theme';

  static String get current {
    final box = Hive.box(_box);
    return box.get(_key, defaultValue: 'cyber_neon') as String;
  }

  static Future<void> setTheme(String key) async {
    final box = Hive.box(_box);
    await box.put(_key, key);
  }
}
