import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rowan_mind_lab/service/ad_unit_ids.dart';
import 'package:flutter/material.dart';


class AdManager {
static void loadInterstitial() {
// 전면광고 미사용
}

static Future<void> showInterstitialAd({required void Function() onAdClosed}) async {
// 전면광고 미사용 → 바로 다음 로직 진행
onAdClosed();
}
}

