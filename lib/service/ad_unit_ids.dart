import 'dart:io';
import 'package:flutter/foundation.dart';

class AdUnitIds {
  static String get rewarded {
    if (kDebugMode) {
      // ✅ 테스트 보상형 광고
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }

    // ✅ 릴리즈(실사용) 보상형 광고
    return Platform.isAndroid
        ? 'ca-app-pub-9790456886445737/1793891334' // Android 보상형 (실)
        : 'ca-app-pub-9790456886445737/6552212239'; // iOS 보상형 (실)
  }
}
