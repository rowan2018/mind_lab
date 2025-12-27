import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'routers/routers.dart';
import 'package:rowan_mind_lab/service/notification_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// 👇 [추가됨] 권한 요청 패키지
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'package:rowan_mind_lab/service/ad_manager.dart';
import 'package:rowan_mind_lab/controller/home_controller.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MobileAds.instance.initialize();
  AdManager.loadInterstitial();
  await GetStorage.init();
  Get.put(HomeController(), permanent: true);
  await NotificationService().init();
  await NotificationService().scheduleWeeklyNotification(true);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const MyApp());
}

// 👇 [변경됨] Stateless -> StatefulWidget으로 변경 (팝업 띄우기 위해)
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    // 👇 [추가됨] 앱 실행 시 권한 요청 팝업 실행
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAppTrackingTransparency());
  }

  // 👇 [추가됨] 권한 요청 함수
  Future<void> _initAppTrackingTransparency() async {
    // 시스템 로딩 대기 (1초)
    await Future.delayed(const Duration(seconds: 1));
    // 팝업 띄우기!
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    print("iOS 추적 권한 상태: $status");
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Rowan Mind',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            fontFamily: 'Pretendard',
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', ''),
            Locale('en', ''),
            Locale('ja', ''),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return const Locale('en', '');
          },
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
        );
      },
    );
  }
}