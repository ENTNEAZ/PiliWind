import 'package:flutter/services.dart';

class OrientationLock {
  static const MethodChannel _ch = MethodChannel('app.orientation/lock');

  static Future<void> lockLandscape() async {
    await _ch.invokeMethod('lockLandscape');
  }

  static Future<void> unlockPortraitFirst() async {
    await _ch.invokeMethod('unlockPortraitFirst');
  }
}
