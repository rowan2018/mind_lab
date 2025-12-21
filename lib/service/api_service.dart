import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart'; // 폰 언어 확인용
import 'package:rowan_mind_lab/data/models.dart';

class ApiService {
  // ✅ HTTPS 적용된 대표님 도메인
  static const String domain = "https://www.rowanzone.co.kr/mind";

  // 1. 명언 가져오기
  static Future<List<DailyQuote>> fetchQuotes() async {
    try {
      final url = "$domain/daily.json";
      print("명언 요청: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        String body = utf8.decode(response.bodyBytes);
        List<dynamic> list = jsonDecode(body);
        return list.map((e) => DailyQuote.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("명언 에러: $e");
      return [];
    }
  }

  // 2. 테스트 목록 가져오기
  static Future<List<TestItem>> fetchTests() async {
    try {
      final url = "$domain/tests.json";
      print("테스트 요청: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        String body = utf8.decode(response.bodyBytes);
        List<dynamic> list = jsonDecode(body);
        return list.map((e) => TestItem.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("테스트 에러: $e");
      return [];
    }
  }

  // ⭐ 3. [신규 추가] 지니에게 직접 소원 빌기 (채팅)
  static Future<String> sendToGenie(String question) async {
    try {
      // server.js의 경로는 '/ask-mirror' 입니다.
      // Nginx 설정상 /mind 경로를 통해 3000번 포트로 연결된다면 아래 주소가 맞습니다.
      final url = "$domain/ask-mirror";

      print("🧞‍♂️ 지니 호출: $url");

      // 현재 폰 언어 감지 (ko, en, ja)
      String langCode = Get.deviceLocale?.languageCode ?? 'ko';

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": question,
          "lang": langCode // 언어 정보도 같이 보냄 (지니가 알아서 통역!)
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer']; // 지니의 답변 리턴
      } else {
        return "지니가 응답하지 않는구나... (통신 오류: ${response.statusCode})";
      }
    } catch (e) {
      print("지니 통신 에러: $e");
      return "마력이 부족해... 인터넷 연결을 확인하거라.";
    }
  }
}