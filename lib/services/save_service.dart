import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/game_config.dart';

/// SaveManager: primary + backup JSON saves, versioned, crash-safe.
/// If primary is corrupt -> backup. If both corrupt -> null (fresh start, no crash).
class SaveService {
  static const String _kPrimary = 'bt_save_primary';
  static const String _kBackup = 'bt_save_backup';

  static Future<void> saveGame(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data);
    // rotate: current primary becomes backup
    final existing = prefs.getString(_kPrimary);
    if (existing != null) {
      await prefs.setString(_kBackup, existing);
    }
    await prefs.setString(_kPrimary, jsonStr);
  }

  /// Returns (data, hadError). hadError=true means primary was corrupt and backup was used.
  static Future<(Map<String, dynamic>?, bool)> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    var hadError = false;

    Map<String, dynamic>? tryParse(String? s) {
      if (s == null) return null;
      try {
        final j = jsonDecode(s);
        if (j is Map<String, dynamic>) return j;
        return null;
      } catch (_) {
        return null;
      }
    }

    final primary = tryParse(prefs.getString(_kPrimary));
    if (primary != null) return (primary, false);

    hadError = prefs.getString(_kPrimary) != null;
    final backup = tryParse(prefs.getString(_kBackup));
    if (backup != null) return (backup, true);

    return (null, hadError);
  }

  static Future<void> resetGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrimary);
    await prefs.remove(_kBackup);
  }

  static int versionOf(Map<String, dynamic> data) {
    final v = data['saveVersion'];
    return v is num ? v.toInt() : 0;
  }

  /// Migration hook for future updates.
  static Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final v = versionOf(data);
    if (v < GameConfig.saveVersion) {
      data['saveVersion'] = GameConfig.saveVersion;
      // future migrations go here
    }
    return data;
  }
}
