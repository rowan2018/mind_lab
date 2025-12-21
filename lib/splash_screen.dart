// lib/pages/splash_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 사용
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:rowan_mind_lab/routers/routers.dart'; // Routes 정의된 파일 경로

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkVersion(); // 앱 시작 시 버전 체크 실행
  }

  Future<void> _checkVersion() async {
    try {
      // 1. 내 앱 버전 확인
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. 서버 JSON 확인
      final url = Uri.parse('https://www.rowanzone.co.kr/mind/version.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 점검 모드 체크
        if (data['maintenance_mode'] == true) {
          _showBlockingDialog("점검 중", "현재 서비스 점검 중입니다. 잠시 후 다시 접속해 주세요.");
          return;
        }

        // OS별 설정 가져오기
        Map<String, dynamic> config;
        if (Platform.isAndroid) {
          config = data['android'];
        } else if (Platform.isIOS) {
          config = data['ios'];
        } else {
          _moveToMain(); return; // 에뮬레이터나 웹 등은 통과
        }

        String minVersion = config['min_version'];
        String storeUrl = config['store_url'];
        String msg = config['force_update_message'];

        // 버전 비교
        if (_isUpdateNeeded(currentVersion, minVersion)) {
          // 업데이트 필요함 -> 강제 팝업 띄우기
          _showUpdateDialog(storeUrl, msg);
        } else {
          // 최신 버전임 -> 메인으로 이동
          _moveToMain();
        }
      } else {
        // 서버 파일 못 읽음 -> 일단 통과
        _moveToMain();
      }
    } catch (e) {
      // 인터넷 에러 등 -> 일단 통과
      print("버전 체크 실패: $e");
      _moveToMain();
    }
  }

  // 다음 화면으로 이동 (GetX 사용)
  void _moveToMain() {
    // 0.5초 딜레이 (로고 보여줄 시간 확보)
    Future.delayed(const Duration(milliseconds: 500), () {
      // 기존: Navigator.pushReplacement...
      // 변경: Get.offAllNamed (이전 기록 지우고 이동)

      // ★ 중요: 여기에 원래 가려던 페이지 경로를 넣으세요 (예: Routes.HOME 또는 Routes.LOGIN)
      Get.offAllNamed('/home');
    });
  }

  // 버전 비교 로직
  bool _isUpdateNeeded(String current, String min) {
    List<int> c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> m = min.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < m.length; i++) {
      int cp = (i < c.length) ? c[i] : 0;
      if (cp < m[i]) return true;
      if (cp > m[i]) return false;
    }
    return false;
  }

  // 강제 업데이트 팝업 (닫기 불가)
  void _showUpdateDialog(String url, String msg) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // 뒤로가기 방지
        child: AlertDialog(
          title: const Text("업데이트 알림"),
          content: Text(msg),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text("업데이트 하러가기"),
            ),
          ],
        ),
      ),
      barrierDismissible: false, // 배경 클릭 방지
    );
  }

  // 점검 중 팝업
  void _showBlockingDialog(String title, String content) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(title),
          content: Text(content),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 디자인은 자유롭게 구성 (로고 중앙 배치 등)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 (assets에 있다면)
            // Image.asset('assets/images/logo.png', width: 100),
            const SizedBox(height: 20),
            const CircularProgressIndicator(), // 로딩 돌아가는 것
          ],
        ),
      ),
    );
  }
}