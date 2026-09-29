import 'package:audioplayers/audioplayers.dart';

/// All sounds are local files in assets/sounds/. No network audio, ever.
class AudioService {
  AudioService._();

  static final AudioPlayer _player = AudioPlayer();
  static bool soundOn = true;
  static bool musicOn = false;

  static Future<void> play(String name) async {
    if (!soundOn) return;
    try {
      await _player.play(AssetSource('sounds/$name.wav'), volume: 0.5);
    } catch (_) {
      // missing/corrupt asset must never crash the game
    }
  }

  static void click() => play('click');
  static void purchase() => play('purchase');
  static void upgrade() => play('upgrade');
  static void merge() => play('merge');
  static void achievement() => play('achievement');
  static void prestige() => play('prestige');
  static void coin() => play('coin');
}
