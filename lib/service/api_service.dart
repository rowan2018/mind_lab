import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rowan_mind_lab/data/models.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String domain = "https://www.rowanzone.co.kr/mind";
  static const _testsCacheKey = "tests_json_cache_v1";
  static const _testsCacheAtKey = "tests_json_cache_at_v1";

  static Future<List<TestItem>> fetchTests({bool allowCache = true}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1) 캐시 먼저 보여주기 (빠른 로딩을 위해 유지)
    if (allowCache) {
      final cached = prefs.getString(_testsCacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final list = (jsonDecode(cached) as List).cast<dynamic>();
          // 일단 캐시된 옛날 리스트를 반환하지만,
          // 아래에서 서버 요청은 계속 진행됨 (UI 갱신은 나중에 될 수 있음)
          // *주의*: 만약 앱이 'FutureBuilder' 하나만 쓰고 있다면,
          // 여기서 return 해버리면 서버 데이터를 못 받아올 수도 있습니다.
          // 확실하게 최신 데이터를 보려면 여기선 return 하지 않는 게 안전합니다.
          // (사장님 앱 구조상 여기서 return 하면 서버 요청 안 함)

          // 🔥 [수정] 여기서는 return 하지 않고 넘어갑니다!
          // 그래야 아래 서버 요청 코드가 실행되어 최신 15개를 받아옵니다.
        } catch (_) {}
      }
    }

    // 2) 서버 fetch (🔥 캐시 방지 코드 추가됨)
    // URL 뒤에 무작위 숫자(시간)를 붙여서 매번 새로운 파일인 척 요청함
    final url = "$domain/tests.json?t=${DateTime.now().millisecondsSinceEpoch}";

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        // 서버 실패 시 빈 리스트 반환 (혹은 아래 캐시 fallback으로 이동)
        throw Exception("Server Error");
      }

      final body = utf8.decode(res.bodyBytes);
      final decoded = jsonDecode(body);

      if (decoded is! List) return [];

      // 성공했으니 최신 데이터로 캐시 덮어쓰기
      await prefs.setString(_testsCacheKey, body);
      await prefs.setInt(_testsCacheAtKey, DateTime.now().millisecondsSinceEpoch);

      return decoded.map((e) => TestItem.fromJson(e)).toList();

    } catch (_) {
      // 3) 서버 실패 시에만 캐시된 옛날 데이터 사용 (Fallback)
      final cached = prefs.getString(_testsCacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final list = (jsonDecode(cached) as List).cast<dynamic>();
          return list.map((e) => TestItem.fromJson(e)).toList();
        } catch (_) {}
      }
      return [];
    }
  }

  static Future<List<DailyQuote>> fetchQuotes() async {
    // 명언도 캐시 방지 (선택 사항)
    final url = "$domain/daily.json?t=${DateTime.now().millisecondsSinceEpoch}";
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return [];

      final body = utf8.decode(res.bodyBytes);
      final decoded = jsonDecode(body);

      if (decoded is! List) return [];
      return decoded.map((e) => DailyQuote.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ... (나머지 sendToGenieChat, sendToGenieResult 함수는 그대로 두셔도 됩니다) ...
  static Future<String> sendToGenieChat(
      String question, {
        required String langCode,
      }) async {
    final url = "http://www.rowanzone.co.kr:3000/ask-mirror"; // ✅ 포트 3000 명시 (혹은 도메인에 맞게)

    try {
      final res = await http
          .post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": question, "lang": langCode}),
      )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        return "지니가 응답하지 않는구나... (통신 오류: ${res.statusCode})";
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final answer = data is Map ? data["answer"] : null;

      return (answer is String && answer.trim().isNotEmpty)
          ? answer
          : "지니가 헛소리를 하는군. 다시 빌어라.";
    } catch (_) {
      return "마력이 부족해... 인터넷 연결을 확인하거라.";
    }
  }

  static Future<String> sendToGenieResult(
      String question, {
        required String langCode,
        required String title,
        required String desc,
      }) async {
    final url = "http://www.rowanzone.co.kr:3000/ask-mirror-result"; // ✅ 포트 3000 명시

    final payload = <String, dynamic>{
      "question": question,
      "lang": langCode,
      "title": title.trim(),
      "desc": desc.trim(),
    };

    try {
      final res = await http
          .post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 20));
      debugPrint("✅ genie result status=${res.statusCode}");

      if (res.statusCode != 200) {
        return "지니가 응답하지 않는구나... (통신 오류: ${res.statusCode})";
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final answer = data is Map ? data["answer"] : null;

      return (answer is String && answer.trim().isNotEmpty)
          ? answer
          : "지니가 헛소리를 하는군. 다시 빌어라.";

    } catch (_) {
      return "마력이 부족해... 인터넷 연결을 확인하거라.";
    }
  }
}