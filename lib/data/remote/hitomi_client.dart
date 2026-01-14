/// 순수 네트워크 클라이언트 (Hitomi API)
library;

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../core/app_config.dart';

class HitomiClient {
  static const MethodChannel _channel = MethodChannel('com.donggong/dpi');

  /// DPI bypass fetch
  static Future<http.Response> fetch(String url) async {
    try {
      final String body = await _channel.invokeMethod('fetch', {
        'url': url,
        'headers': AppConfig.defaultHeaders,
      });
      return http.Response(body, 200);
    } on PlatformException catch (_) {
      return http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
    } catch (_) {
      return http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
    }
  }

  /// Standard HTTP GET
  static Future<http.Response> get(String url, {Map<String, String>? headers}) {
    return http.get(
      Uri.parse(url),
      headers: headers ?? AppConfig.defaultHeaders,
    );
  }

  /// Standard HTTP GET with Range header
  static Future<http.Response> getWithRange(String url, int start, int end) {
    return http.get(
      Uri.parse(url),
      headers: {...AppConfig.defaultHeaders, 'Range': 'bytes=$start-$end'},
    );
  }

  /// Parse nozomi binary (Big Endian Int32 array)
  static Set<int> parseNozomi(Uint8List buf) {
    final ids = <int>{};
    final view = ByteData.sublistView(buf);
    for (int i = 0; i < buf.lengthInBytes; i += 4) {
      ids.add(view.getInt32(i, Endian.big));
    }
    return ids;
  }

  /// Build image URL from hash and gg.js content
  static String buildImageUrl(String hash, String gg) {
    final s =
        hash.substring(hash.length - 1) +
        hash.substring(hash.length - 3, hash.length - 1);
    final imageId = int.parse(s, radix: 16);

    final defaultDomainMatch = RegExp(r'var o = (\d)').firstMatch(gg);
    final defaultDomain =
        (int.tryParse(defaultDomainMatch?.group(1) ?? '0') ?? 0) + 1;

    final offsetDomainMatch = RegExp(r'o = (\d); break;').firstMatch(gg);
    final offsetDomain =
        (int.tryParse(offsetDomainMatch?.group(1) ?? '0') ?? 0) + 1;

    final commonKeyMatch = RegExp(r"b: '(\d+)/").firstMatch(gg);
    final commonKey = commonKeyMatch?.group(1) ?? '';

    final offsets = <int, int>{};
    final caseMatches = RegExp(r'case (\d+):').allMatches(gg);
    for (final m in caseMatches) {
      offsets[int.parse(m.group(1)!)] = offsetDomain;
    }

    final domain = offsets[imageId] ?? defaultDomain;
    return 'https://w$domain.gold-usergeneratedcontent.net/$commonKey/$imageId/$hash.webp';
  }

  /// Build thumbnail URL from hash
  static String buildThumbUrl(String hash) {
    final suffix = hash.substring(hash.length - 1);
    final mid = hash.substring(hash.length - 3, hash.length - 1);
    return 'https://tn.gold-usergeneratedcontent.net/webpbigtn/$suffix/$mid/$hash.webp';
  }
}
