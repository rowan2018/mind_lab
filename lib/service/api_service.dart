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

    // 1) 캐시 먼저(있으면 즉시 보여주기)
    if (allowCache) {
      final cached = prefs.getString(_testsCacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final list = (jsonDecode(cached) as List).cast<dynamic>();
          // 캐시가 있어도 서버 최신을 시도할 거라서, 여기서 바로 return 하지 않고
          // UX 취향에 따라: "캐시 즉시 return" vs "캐시 임시값 저장"
          // -> 너는 시간절약/안정성 우선이니 "캐시 즉시 return" 추천
          return list.map((e) => TestItem.fromJson(e)).toList();
        } catch (_) {
          // 캐시가 깨졌으면 무시하고 아래에서 서버 fetch
        }
      }
    }

    // 2) 서버 fetch
    final url = "$domain/tests.json";
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        return [];
      }

      final body = utf8.decode(res.bodyBytes);
      final decoded = jsonDecode(body);

      if (decoded is! List) return [];

      // 캐시 저장(성공한 경우에만)
      await prefs.setString(_testsCacheKey, body);
      await prefs.setInt(_testsCacheAtKey, DateTime.now().millisecondsSinceEpoch);

      return decoded.map((e) => TestItem.fromJson(e)).toList();
    } catch (_) {
      // 3) 서버 실패 시 캐시 fallback
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
    final url = "$domain/daily.json";
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

  static Future<String> sendToGenieChat(
      String question, {
        required String langCode,
      }) async {
    final url = "$domain/ask-mirror"; // ✅ 기존 상담 엔드포인트

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
    final url = "$domain/ask-mirror-result"; // ✅ 결과 전용 엔드포인트

    final payload = <String, dynamic>{
      "question": question, // 짧게: "핵심만 현실적으로 조언해줘"
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

          .timeout(const Duration(seconds: 20)); // 결과는 살짝 더 여유
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
