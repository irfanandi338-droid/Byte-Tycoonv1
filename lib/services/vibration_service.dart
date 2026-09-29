import 'package:flutter/services.dart';

class VibrationService {
  VibrationService._();
  static bool vibrationOn = true;

  static void light() {
    if (vibrationOn) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (vibrationOn) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (vibrationOn) HapticFeedback.heavyImpact();
  }
}
