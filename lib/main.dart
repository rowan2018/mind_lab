import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rowan_mind_lab/l10n/app_localizations.dart';
import 'routers/routers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Rowan Mind Lab', // 앱 이름 변경
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            fontFamily: 'Pretendard',
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate, // 우리가 만든 거
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', ''), // 한국어
            Locale('en', ''), // 영어
            Locale('ja', ''), // 일본어
          ],

          // 앱 시작 시, 핸드폰 언어가 지원 목록에 없으면 영어로 설정
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return const Locale('en', ''); // 기본값
          },
          // 여기가 핵심!
          initialRoute: AppPages.INITIAL, // '/' 대신 상수로 사용
          getPages: AppPages.routes,      // routers.dart에서 가져옴
        );
      },
    );
  }
}