import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:byte_tycoon/config/game_config.dart';
import 'package:byte_tycoon/services/save_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const primaryKey = 'bt_save_primary';
  const backupKey = 'bt_save_backup';

  test('save then load round-trips the data unchanged', () async {
    SharedPreferences.setMockInitialValues({});
    final data = {'saveVersion': GameConfig.saveVersion, 'player': {'coins': 1234.0}};

    await SaveService.saveGame(data);
    final (loaded, hadError) = await SaveService.loadGame();

    expect(hadError, false);
    expect(loaded, isNotNull);
    expect(loaded!['player']['coins'], 1234.0);
  });

  test('saving twice rotates the previous primary into backup', () async {
    SharedPreferences.setMockInitialValues({});
    await SaveService.saveGame({'saveVersion': 1, 'v': 'first'});
    await SaveService.saveGame({'saveVersion': 1, 'v': 'second'});

    final prefs = await SharedPreferences.getInstance();
    final backup = jsonDecode(prefs.getString(backupKey)!);
    final primary = jsonDecode(prefs.getString(primaryKey)!);
    expect(backup['v'], 'first');
    expect(primary['v'], 'second');
  });

  test('corrupt primary falls back to backup, flags hadError, never throws', () async {
    final goodSave = jsonEncode({'saveVersion': 1, 'v': 'good-backup'});
    SharedPreferences.setMockInitialValues({
      primaryKey: '{not valid json!!!',
      backupKey: goodSave,
    });

    final (loaded, hadError) = await SaveService.loadGame();

    expect(hadError, true);
    expect(loaded, isNotNull);
    expect(loaded!['v'], 'good-backup');
  });

  test('both primary and backup corrupt -> null (fresh start), never throws', () async {
    SharedPreferences.setMockInitialValues({
      primaryKey: '{not valid json!!!',
      backupKey: 'also not valid!!!',
    });

    final (loaded, hadError) = await SaveService.loadGame();

    expect(loaded, isNull);
    expect(hadError, true);
  });

  test('no existing save at all -> null, no error flag', () async {
    SharedPreferences.setMockInitialValues({});

    final (loaded, hadError) = await SaveService.loadGame();

    expect(loaded, isNull);
    expect(hadError, false);
  });

  test('resetGame clears both primary and backup', () async {
    SharedPreferences.setMockInitialValues({
      primaryKey: jsonEncode({'v': 1}),
      backupKey: jsonEncode({'v': 0}),
    });

    await SaveService.resetGame();
    final (loaded, hadError) = await SaveService.loadGame();

    expect(loaded, isNull);
    expect(hadError, false);
  });
}
