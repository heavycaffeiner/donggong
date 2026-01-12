import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/types.dart';

class ApiService {
  static const String cdn = 'https://ltn.gold-usergeneratedcontent.net';
  static const MethodChannel _channel = MethodChannel('com.donggong/dpi');

  static const Map<String, String> _headers = {
    'Referer': 'https://hitomi.la/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  // ─── 내장 LRU 캐시 ───
  static final Map<int, GalleryDetail> _cache = {};
  static final Map<int, DateTime> _timestamps = {};
  static const Duration _maxAge = Duration(hours: 1);
  static const int _maxSize = 100;

  static GalleryDetail? _getFromCache(int id) {
    if (!_cache.containsKey(id)) return null;
    final age = DateTime.now().difference(_timestamps[id]!);
    if (age > _maxAge) {
      _cache.remove(id);
      _timestamps.remove(id);
      return null;
    }
    _timestamps[id] = DateTime.now();
    return _cache[id];
  }

  static void _setCache(int id, GalleryDetail detail) {
    if (_cache.length >= _maxSize && _timestamps.isNotEmpty) {
      final oldest = _timestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldest);
      _timestamps.remove(oldest);
    }
    _cache[id] = detail;
    _timestamps[id] = DateTime.now();
  }

  /// 캐시 지원 getDetail (State에서 직접 사용)
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

  // ─── 공통 파싱 헬퍼 ───
  static List<String> _parseTags(List? tagsJson) {
    return tagsJson
            ?.map((t) {
              final tag = t['tag'] as String;
              if (t['female'] == '1') return 'female:$tag';
              if (t['male'] == '1') return 'male:$tag';
              return 'tag:$tag';
            })
            .toList()
            .cast<String>() ??
        [];
  }

  static List<String> _parseArtists(List? artistsJson) {
    return artistsJson?.map((a) => a['artist'] as String).toList() ?? [];
  }

  // Switch to use Native Fetch for hitomi.la/galleries logic to bypass DPI
  static Future<http.Response> _fetch(String url) async {
    // We only use native fetch for strings (json/js).
    // The native module returns string body.
    try {
      final String body = await _channel.invokeMethod('fetch', {
        'url': url,
        'headers': _headers,
      });
      return http.Response(body, 200);
    } on PlatformException catch (_) {
      // Fallback to standard HTTP on native fetch failure
      return http.get(Uri.parse(url), headers: _headers);
    } catch (e) {
      return http.get(Uri.parse(url), headers: _headers);
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

  // List always uses .nozomi which is binary. Native module in reference `DpiBypassModule.kt` returns String.
  // Converting binary to string and back in Java/C++ is risky,
  // but usually .nozomi files are generic CDN files and might NOT be DPI blocked as aggressively as the .js logic?
  // Reference lib.ts uses `fetch` (standard) for .nozomi and `fetchSNI` (native) for .js
  // So we KEEP standard http.get for getList (.nozomi)
  static Future<List<GalleryItem>> getList({
    int page = 1,
    String lang = 'korean',
  }) async {
    try {
      final rangeHeader = {
        'Range': 'bytes=${(page - 1) * 100}-${page * 100 - 1}',
      };
      // Standard HTTP for nozomi (binary)
      final res = await http.get(
        Uri.parse('$cdn/index-$lang.nozomi'),
        headers: {..._headers, ...rangeHeader},
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

  // Detail uses .js which IS fetched via SNI in reference.
  static Future<GalleryDetail> getDetail(int id) async {
    final result = await getDetailWithOriginalJson(id);
    return result.$1;
  }

  static Future<(GalleryDetail, Map<String, dynamic>)>
  getDetailWithOriginalJson(int id) async {
    final res = await _fetch('$cdn/galleries/$id.js'); // Uses native fetch
    final text = res.body.replaceFirst('var galleryinfo = ', '');
    final json = jsonDecode(text) as Map<String, dynamic>;

    final tags = _parseTags(json['tags'] as List?);
    final artists = _parseArtists(json['artists'] as List?);

    final files = (json['files'] as List?) ?? [];
    String thumb = '';
    if (files.isNotEmpty) {
      thumb = buildThumbUrl(files[0]['hash']);
    }

    final detail = GalleryDetail(
      id: id,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      language: json['language'],
      artists: artists,
      tags: tags,
      thumbnail: thumb,
      images: [],
    );

    return (detail, json);
  }

  static Future<GalleryDetail> getReader(int id) async {
    // Both gallery.js and gg.js use Native fetch in reference
    final responses = await Future.wait([
      _fetch('$cdn/galleries/$id.js'),
      _fetch('$cdn/gg.js'),
    ]);

    final galleryRes = responses[0];
    final ggRes = responses[1];

    final galleryText = galleryRes.body.replaceFirst('var galleryinfo = ', '');
    final json = jsonDecode(galleryText);
    final gg = ggRes.body;

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

    final tags = _parseTags(json['tags'] as List?);
    final artists = _parseArtists(json['artists'] as List?);
    String thumb = '';
    if (files != null && files.isNotEmpty) {
      thumb = buildThumbUrl(files[0]['hash']);
    }

    return GalleryDetail(
      id: id,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      language: json['language'],
      artists: artists,
      tags: tags,
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
      // Suggestions also use SNI in reference
      final res = await _fetch('https://tagindex.hitomi.la/global/$path.json');
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as List;
      final result = json
          .take(20)
          .map((x) => TagSuggestion.fromJson(x))
          .toList();
      return result;
    } catch (e) {
      return [];
    }
  }

  static Future<List<GalleryItem>> search(
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
          // Nozomi -> Standard HTTP
          final res = await http.get(
            Uri.parse('$cdn/index-$val.nozomi'),
            headers: _headers,
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

      final url = '$cdn/$area/${Uri.encodeComponent(tag)}-$lang.nozomi';
      try {
        var res = await http.get(Uri.parse(url), headers: _headers);
        if (res.statusCode == 200) {
          return _parseNozomi(res.bodyBytes);
        } else if (res.statusCode == 404 && lang != 'all') {
          // Fallback to 'all' if specific language not found
          final fallbackUrl =
              '$cdn/$area/${Uri.encodeComponent(tag)}-all.nozomi';
          res = await http.get(Uri.parse(fallbackUrl), headers: _headers);
          return res.statusCode == 200 ? _parseNozomi(res.bodyBytes) : {};
        }
        return {};
      } catch (e) {
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

    final start = (page - 1) * 25;
    if (start >= sortedIds.length) return [];
    final end = (start + 25) > sortedIds.length
        ? sortedIds.length
        : (start + 25);

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
