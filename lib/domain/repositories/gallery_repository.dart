/// 갤러리 Repository (API 조합 + 캐싱)
library;

import 'dart:convert';

import '../../core/app_config.dart';
import '../../data/data.dart';

class GalleryRepository {
  // ─── 내장 LRU 캐시 ───
  final Map<int, GalleryDetail> _cache = {};
  final Map<int, DateTime> _timestamps = {};

  GalleryDetail? _getFromCache(int id) {
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

  void _setCache(int id, GalleryDetail detail) {
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

  /// 갤러리 목록 조회 (리스트 + 전체 갤러리 수 반환)
  Future<(List<GalleryDetail>, int)> getListWithTotal({
    int page = 1,
    String lang = 'korean',
  }) async {
    try {
      final start = (page - 1) * AppConfig.nozomiRangeBytes;
      final end = page * AppConfig.nozomiRangeBytes - 1;
      final res = await HitomiClient.getWithRange(
        '${AppConfig.cdnBase}/index-$lang.nozomi',
        start,
        end,
      );
      if (res.statusCode != 200 && res.statusCode != 206)
        return (<GalleryDetail>[], 0);

      // Content-Range 헤더에서 전체 갤러리 수 파싱
      int totalCount = 0;
      final contentRange = res.headers['content-range'];
      if (contentRange != null) {
        final match = RegExp(r'/(\d+)$').firstMatch(contentRange);
        if (match != null) {
          final totalBytes = int.tryParse(match.group(1)!) ?? 0;
          totalCount = totalBytes ~/ 4; // nozomi는 4바이트(Int32) 배열
        }
      }

      final ids = HitomiClient.parseNozomi(res.bodyBytes);
      final details = await Future.wait(
        ids.map((id) async {
          try {
            return await getDetail(id);
          } catch (_) {
            return null;
          }
        }),
      );
      return (details.whereType<GalleryDetail>().toList(), totalCount);
    } catch (_) {
      return (<GalleryDetail>[], 0);
    }
  }

  /// 갤러리 목록 조회 (기존 호환성용)
  Future<List<GalleryDetail>> getList({
    int page = 1,
    String lang = 'korean',
  }) async {
    final result = await getListWithTotal(page: page, lang: lang);
    return result.$1;
  }

  /// 전체 갤러리 수 조회 (nozomi 파일 크기 기반)
  Future<int> getTotalCount({String lang = 'korean'}) async {
    try {
      final contentLength = await HitomiClient.getTotalContentLength(
        '${AppConfig.cdnBase}/index-$lang.nozomi',
      );
      if (contentLength != null) {
        // nozomi는 4바이트(Int32) 배열
        return contentLength ~/ 4;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// 갤러리 상세 조회 (캐시 지원)
  Future<GalleryDetail> getDetail(int id) async {
    final cached = _getFromCache(id);
    if (cached != null) return cached;

    final result = await getDetailWithJson(id);
    if (result.$1.id != 0) _setCache(id, result.$1);
    return result.$1;
  }

  /// 갤러리 상세 + 원본 JSON
  Future<(GalleryDetail, Map<String, dynamic>)> getDetailWithJson(
    int id,
  ) async {
    final res = await HitomiClient.fetch(
      '${AppConfig.cdnBase}/galleries/$id.js',
    );
    final text = res.body.replaceFirst('var galleryinfo = ', '');
    final json = jsonDecode(text) as Map<String, dynamic>;

    final files = (json['files'] as List?) ?? [];
    String thumb = '';
    if (files.isNotEmpty) {
      thumb = HitomiClient.buildThumbUrl(files[0]['hash']);
    }

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
      pageCount: files.length, // 파일 수로 페이지 수 설정
    );

    return (detail, json);
  }

  /// 리더용 상세 조회 (이미지 포함, 캐시 지원)
  Future<GalleryDetail> getReader(int id) async {
    final cached = _getFromCache(id);
    if (cached != null && cached.images.isNotEmpty) return cached;

    final responses = await Future.wait([
      HitomiClient.fetch('${AppConfig.cdnBase}/galleries/$id.js'),
      HitomiClient.fetch('${AppConfig.cdnBase}/gg.js'),
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
                url: HitomiClient.buildImageUrl(f['hash'], gg),
              ),
            )
            .toList() ??
        [];

    String thumb = '';
    if (files != null && files.isNotEmpty) {
      thumb = HitomiClient.buildThumbUrl(files[0]['hash']);
    }

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
      images: images,
    );

    if (detail.id != 0) _setCache(id, detail);
    return detail;
  }

  /// 태그 자동완성
  Future<List<TagSuggestion>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    final clean = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.isEmpty) return [];

    try {
      final path = clean.split('').join('/');
      final res = await HitomiClient.fetch(
        '${AppConfig.tagIndexBase}/global/$path.json',
      );
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as List;
      return json.take(20).map((x) => TagSuggestion.fromJson(x)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 검색 (결과 리스트 + 전체 검색 결과 수 반환)
  Future<(List<GalleryDetail>, int)> search(
    String query, {
    int page = 1,
    String defaultLang = 'all',
  }) async {
    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return (<GalleryDetail>[], 0);

    final hasLang = terms.any((t) => t.startsWith('language:'));
    final lang = hasLang ? 'all' : defaultLang;

    Future<Set<int>> fetchIds(String term) async {
      final parts = term.split(':');
      final area = parts[0];
      final tag = parts.sublist(1).join(':').replaceAll('_', ' ');

      if (area == 'language') {
        final res = await HitomiClient.get(
          '${AppConfig.cdnBase}/index-$tag.nozomi',
        );
        return res.statusCode == 200
            ? HitomiClient.parseNozomi(res.bodyBytes)
            : {};
      }

      String url;
      if (area == 'female' || area == 'male') {
        url =
            '${AppConfig.cdnBase}/tag/$area:${Uri.encodeComponent(tag)}-$lang.nozomi';
      } else {
        url =
            '${AppConfig.cdnBase}/$area/${Uri.encodeComponent(tag)}-$lang.nozomi';
      }

      try {
        var res = await HitomiClient.get(url);
        if (res.statusCode == 200) {
          return HitomiClient.parseNozomi(res.bodyBytes);
        } else if (res.statusCode == 404 && lang != 'all') {
          final fallbackUrl =
              '${AppConfig.cdnBase}/$area/${Uri.encodeComponent(tag)}-all.nozomi';
          res = await HitomiClient.get(fallbackUrl);
          return res.statusCode == 200
              ? HitomiClient.parseNozomi(res.bodyBytes)
              : {};
        }
        return {};
      } catch (_) {
        return {};
      }
    }

    final idSets = await Future.wait(terms.map(fetchIds));
    if (idSets.any((s) => s.isEmpty)) return (<GalleryDetail>[], 0);

    idSets.sort((a, b) => a.length.compareTo(b.length));

    Set<int> common = idSets[0];
    for (int i = 1; i < idSets.length; i++) {
      common = common.intersection(idSets[i]);
    }

    final sortedIds = common.toList()..sort((a, b) => b.compareTo(a));
    final totalCount = sortedIds.length;

    final start = (page - 1) * AppConfig.pageSize;
    if (start >= totalCount) return (<GalleryDetail>[], totalCount);
    final end = (start + AppConfig.pageSize).clamp(0, totalCount);

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
    return (details.whereType<GalleryDetail>().toList(), totalCount);
  }
}
