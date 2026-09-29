import '../config/game_config.dart';
import 'economy_service.dart';

class OfflineResult {
  final int elapsedSeconds; // capped
  final double coins;
  OfflineResult(this.elapsedSeconds, this.coins);
}

class OfflineIncomeService {
  OfflineIncomeService._();

  static OfflineResult compute({
    required DateTime lastOnline,
    required DateTime now,
    required double incomePerSecond,
  }) {
    var elapsed = now.difference(lastOnline).inSeconds;
    if (elapsed < 0) elapsed = 0; // clock changed backwards -> no exploit, no crash
    final capped = elapsed.clamp(0, GameConfig.offlineMaxSeconds);
    return OfflineResult(capped, EconomyService.offlineIncome(incomePerSecond, capped));
  }
}
