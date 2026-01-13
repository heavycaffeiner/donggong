import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/types.dart';
import '../core/app_config.dart';

class ApiService {
  static const MethodChannel _channel = MethodChannel('com.donggong/dpi');

  // ─── 내장 LRU 캐시 ───
  static final Map<int, GalleryDetail> _cache = {};
  static final Map<int, DateTime> _timestamps = {};

  static GalleryDetail? _getFromCache(int id) {
    if (!_cache.containsKey(id)) return null;
    final age = DateTime.now().difference(_timestamps[id]!);
    if (age > AppConfig.cacheTtl) {
      _cache.remove(id);
      _timestamps.remove(id);
      return null;
    }
    _timestamps[id] = DateTime.now();
    return _cache[id];
  }

  static void _setCache(int id, GalleryDetail detail) {
    if (_cache.length >= AppConfig.cacheMaxSize && _timestamps.isNotEmpty) {
      final oldest = _timestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldest);
      _timestamps.remove(oldest);
    }
    _cache[id] = detail;
    _timestamps[id] = DateTime.now();
  }

  /// 캐시 지원 getDetail
  static Future<GalleryDetail> getDetailCached(int id) async {
    final cached = _getFromCache(id);
    if (cached != null) return cached;

    final detail = await getDetail(id);
    if (detail.id != 0) _setCache(id, detail);
    return detail;
  }

  /// 캐시 지원 getReader (이미지 포함)
  static Future<GalleryDetail> getReaderCached(int id) async {
    final cached = _getFromCache(id);
    if (cached != null && cached.images.isNotEmpty) return cached;

    final detail = await getReader(id);
    if (detail.id != 0) _setCache(id, detail);
    return detail;
  }

  // ─── Native Fetch for DPI bypass ───
  static Future<http.Response> _fetch(String url) async {
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

  // Parse nozomi binary (Big Endian Int32 array)
  static Set<int> _parseNozomi(Uint8List buf) {
    final ids = <int>{};
    final view = ByteData.sublistView(buf);
    for (int i = 0; i < buf.lengthInBytes; i += 4) {
      ids.add(view.getInt32(i, Endian.big));
    }
    return ids;
  }

  // Build image URL
  static String _buildImageUrl(String hash, String gg) {
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

  static String buildThumbUrl(String hash) {
    final suffix = hash.substring(hash.length - 1);
    final mid = hash.substring(hash.length - 3, hash.length - 1);
    return 'https://tn.gold-usergeneratedcontent.net/webpbigtn/$suffix/$mid/$hash.webp';
  }

  // ─── API 메서드들 ───

  static Future<List<GalleryDetail>> getList({
    int page = 1,
    String lang = 'korean',
  }) async {
    try {
      final start = (page - 1) * AppConfig.nozomiRangeSize;
      final end = page * AppConfig.nozomiRangeSize - 1;
      final res = await http.get(
        Uri.parse('${AppConfig.cdnBase}/index-$lang.nozomi'),
        headers: {...AppConfig.defaultHeaders, 'Range': 'bytes=$start-$end'},
      );
      if (res.statusCode != 200 && res.statusCode != 206) return [];

      final ids = _parseNozomi(res.bodyBytes);
      final details = await Future.wait(
        ids.map((id) async {
          try {
            return await getDetail(id);
          } catch (_) {
            return null;
          }
        }),
      );
      return details.whereType<GalleryDetail>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<GalleryDetail> getDetail(int id) async {
    final result = await getDetailWithOriginalJson(id);
    return result.$1;
  }

  static Future<(GalleryDetail, Map<String, dynamic>)>
  getDetailWithOriginalJson(int id) async {
    final res = await _fetch('${AppConfig.cdnBase}/galleries/$id.js');
    final text = res.body.replaceFirst('var galleryinfo = ', '');
    final json = jsonDecode(text) as Map<String, dynamic>;

    final files = (json['files'] as List?) ?? [];
    String thumb = '';
    if (files.isNotEmpty) {
      thumb = buildThumbUrl(files[0]['hash']);
    }

    // parseTagList 함수 사용 (types.dart에서 정의)
    final detail = GalleryDetail(
      id: id,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      language: json['language'],
      artists: parseTagList(json['artists']),
      groups: parseTagList(json['groups']),
      characters: parseTagList(json['characters']),
      parodys: parseTagList(json['parodys']),
      tags: parseTagList(json['tags'], isTag: true),
      thumbnail: thumb,
    );

    return (detail, json);
  }

  static Future<GalleryDetail> getReader(int id) async {
    final responses = await Future.wait([
      _fetch('${AppConfig.cdnBase}/galleries/$id.js'),
      _fetch('${AppConfig.cdnBase}/gg.js'),
    ]);

    final galleryText = responses[0].body.replaceFirst(
      'var galleryinfo = ',
      '',
    );
    final json = jsonDecode(galleryText);
    final gg = responses[1].body;

    final files = (json['files'] as List?);
    final images =
        files
            ?.map(
              (f) => GalleryImage(
                width: f['width'],
                height: f['height'],
                url: _buildImageUrl(f['hash'], gg),
              ),
            )
            .toList() ??
        [];

    String thumb = '';
    if (files != null && files.isNotEmpty) {
      thumb = buildThumbUrl(files[0]['hash']);
    }

    return GalleryDetail(
      id: id,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      language: json['language'],
      artists: parseTagList(json['artists']),
      groups: parseTagList(json['groups']),
      characters: parseTagList(json['characters']),
      parodys: parseTagList(json['parodys']),
      tags: parseTagList(json['tags'], isTag: true),
      thumbnail: thumb,
      images: images,
    );
  }

  static Future<List<TagSuggestion>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    final clean = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.isEmpty) return [];

    try {
      final path = clean.split('').join('/');
      final res = await _fetch('${AppConfig.tagIndexBase}/global/$path.json');
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as List;
      return json.take(20).map((x) => TagSuggestion.fromJson(x)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<GalleryDetail>> search(
    String query, {
    int page = 1,
    String defaultLang = 'all',
  }) async {
    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return [];

    final hasLang = terms.any((t) => t.startsWith('language:'));
    final lang = hasLang ? 'all' : defaultLang;

    Future<Set<int>> fetchIds(String term) async {
      String area = 'tag';
      String tag = term;

      if (term.contains(':')) {
        final parts = term.split(':');
        final ns = parts[0];
        final val = parts.sublist(1).join(':').replaceAll('_', ' ');

        if (ns == 'language') {
          final res = await http.get(
            Uri.parse('${AppConfig.cdnBase}/index-$val.nozomi'),
            headers: AppConfig.defaultHeaders,
          );
          return res.statusCode == 200 ? _parseNozomi(res.bodyBytes) : {};
        }

        if (ns == 'female' || ns == 'male') {
          area = 'tag';
          tag = '$ns:$val';
        } else {
          area = ns;
          tag = val;
        }
      } else {
        area = 'tag';
        tag = term.replaceAll('_', ' ');
      }

      final url =
          '${AppConfig.cdnBase}/$area/${Uri.encodeComponent(tag)}-$lang.nozomi';
      try {
        var res = await http.get(
          Uri.parse(url),
          headers: AppConfig.defaultHeaders,
        );
        if (res.statusCode == 200) {
          return _parseNozomi(res.bodyBytes);
        } else if (res.statusCode == 404 && lang != 'all') {
          final fallbackUrl =
              '${AppConfig.cdnBase}/$area/${Uri.encodeComponent(tag)}-all.nozomi';
          res = await http.get(
            Uri.parse(fallbackUrl),
            headers: AppConfig.defaultHeaders,
          );
          return res.statusCode == 200 ? _parseNozomi(res.bodyBytes) : {};
        }
        return {};
      } catch (_) {
        return {};
      }
    }

    final idSets = await Future.wait(terms.map(fetchIds));
    if (idSets.any((s) => s.isEmpty)) return [];

    idSets.sort((a, b) => a.length.compareTo(b.length));

    Set<int> common = idSets[0];
    for (int i = 1; i < idSets.length; i++) {
      common = common.intersection(idSets[i]);
    }

    final sortedIds = common.toList()..sort((a, b) => b.compareTo(a));

    final start = (page - 1) * AppConfig.pageSize;
    if (start >= sortedIds.length) return [];
    final end = (start + AppConfig.pageSize).clamp(0, sortedIds.length);

    final pagedIds = sortedIds.sublist(start, end);
    final details = await Future.wait(
      pagedIds.map((id) async {
        try {
          return await getDetail(id);
        } catch (_) {
          return null;
        }
      }),
    );
    return details.whereType<GalleryDetail>().toList();
  }
}
