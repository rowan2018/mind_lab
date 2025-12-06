import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart'; // 디바이스 언어 확인용
import 'package:rowan_mind_lab/data/models.dart';
class ApiService {
  // 기본 도메인 (뒤에 /ko, /en 등이 붙을 예정)
  static const String domain = "http://www.rowanzone.co.kr/mind";

  // ⭐ 현재 언어에 맞는 URL을 만들어주는 함수
  // ⭐ 현재 언어에 맞는 URL을 만들어주는 함수
  static String getBaseUrl() {
    // 1. 핸드폰 시스템 언어 코드 가져오기 (실패 시 영어 'en'으로 설정)
    String langCode = Get.deviceLocale?.languageCode ?? 'en';

    // 2. 혹시라도 'kr'로 인식되면 'ko'로 고쳐줌 (안전장치)
    if (langCode == 'kr') langCode = 'ko';

    // 3. 지원하는 언어(한국어, 일본어)가 아니면 영어(en)로 통일
    if (langCode != 'ko' && langCode != 'ja') {
      langCode = 'en';
    }

    // 디버깅용: 실제 어떤 주소로 가는지 로그 출력 (Run 탭에서 확인 가능)
    print("현재 언어 코드: $langCode -> 요청 주소: $domain/$langCode");

    // 결과: http://www.rowanzone.co.kr/mind/ko
    return "$domain/$langCode";
  }

  // 명언 가져오기
  static Future<List<DailyQuote>> fetchQuotes() async {
    try {
      // getBaseUrl()을 사용해서 동적으로 주소 생성
      final url = "${getBaseUrl()}/daily.json";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        String body = utf8.decode(response.bodyBytes);
        List<dynamic> list = jsonDecode(body);
        return list.map((e) => DailyQuote.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("명언 로드 실패: $e");
      return [];
    }
  }

  // 테스트 목록 가져오기
  static Future<List<TestItem>> fetchTests() async {
    try {
      // 여기도 getBaseUrl() 사용
      final url = "${getBaseUrl()}/tests.json";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "Mozilla/5.0",
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        String body = utf8.decode(response.bodyBytes);
        List<dynamic> list = jsonDecode(body);
        return list.map((e) => TestItem.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("테스트 목록 로드 실패: $e");
      return [];
    }
  }
}