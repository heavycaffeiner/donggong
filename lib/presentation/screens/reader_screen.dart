import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_config.dart';
import '../../data/data.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late PageController _pageController;
  late ScrollController _webtoonScrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pageController = PageController();
    _webtoonScrollController = ScrollController();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _webtoonScrollController.dispose();
    super.dispose();
  }

  void _precacheNearbyImages(List<GalleryImage> images, int currentIndex) {
    const range = AppConfig.readerPreloadRange;
    for (int i = currentIndex - range; i <= currentIndex + range; i++) {
      if (i >= 0 && i < images.length && i != currentIndex) {
        precacheImage(
          CachedNetworkImageProvider(
            images[i].url,
            headers: AppConfig.defaultHeaders,
          ),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerAsync = ref.watch(readerProvider);
    final controlsVisible = ref.watch(readerControlsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value;
    final readerMode = settings?.readerMode ?? 'verticalPage';
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return readerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (gallery) {
        if (gallery == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final favoritesAsync = ref.watch(favoriteDataProvider);
        final isFav =
            favoritesAsync.value?.favoriteId.contains(gallery.id) ?? false;
        final totalPages = gallery.images.length;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _precacheNearbyImages(gallery.images, _currentPage);
        });

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => ref.read(readerControlsProvider.notifier).toggle(),
                child: _buildReaderContent(
                  gallery: gallery,
                  readerMode: readerMode,
                  isTablet: isTablet,
                ),
              ),

              // Top Bar
              _buildTopBar(
                context: context,
                gallery: gallery,
                controlsVisible: controlsVisible,
                isFav: isFav,
                theme: theme,
                readerMode: readerMode,
              ),

              // Bottom Slider
              _buildBottomBar(
                controlsVisible: controlsVisible,
                totalPages: totalPages,
                readerMode: readerMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReaderContent({
    required GalleryDetail gallery,
    required String readerMode,
    required bool isTablet,
  }) {
    if (readerMode == 'webtoon') {
      return _buildWebtoonMode(gallery);
    } else {
      return _buildPageMode(
        gallery: gallery,
        isHorizontal: readerMode == 'horizontalPage',
        isTablet: isTablet,
      );
    }
  }

  Widget _buildPageMode({
    required GalleryDetail gallery,
    required bool isHorizontal,
    required bool isTablet,
  }) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      physics: isTablet
          ? const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            )
          : const PageScrollPhysics(),
      itemCount: gallery.images.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        _precacheNearbyImages(gallery.images, index);
      },
      itemBuilder: (context, index) {
        final img = gallery.images[index];
        return ReaderImage(img: img);
      },
    );
  }

  Widget _buildWebtoonMode(GalleryDetail gallery) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final pixels = notification.metrics.pixels;
          final totalHeight = notification.metrics.maxScrollExtent;
          if (totalHeight > 0) {
            final progress = pixels / totalHeight;
            final newPage = (progress * (gallery.images.length - 1)).round();
            if (newPage != _currentPage) {
              setState(() => _currentPage = newPage);
            }
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: _webtoonScrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: gallery.images.length,
        itemBuilder: (context, index) {
          final img = gallery.images[index];
          return WebtoonImage(img: img);
        },
      ),
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required GalleryDetail gallery,
    required bool controlsVisible,
    required bool isFav,
    required ThemeData theme,
    required String readerMode,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      top: controlsVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).closeReader(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gallery.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_currentPage + 1} / ${gallery.images.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? theme.colorScheme.primary : Colors.white,
                  ),
                  onPressed: () => ref
                      .read(favoriteProvider.notifier)
                      .toggleFavorite('gallery', gallery.id.toString()),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'detail') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DetailBottomSheet(item: gallery),
                      );
                    } else if (value == 'mode_vertical') {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('readerMode', 'verticalPage');
                    } else if (value == 'mode_horizontal') {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('readerMode', 'horizontalPage');
                    } else if (value == 'mode_webtoon') {
                      ref
                          .read(settingsProvider.notifier)
                          .setSetting('readerMode', 'webtoon');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'detail',
                      child: Text('작품 상세정보'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'mode_vertical',
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_vert,
                            color: readerMode == 'verticalPage'
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '세로 페이지',
                            style: TextStyle(
                              color: readerMode == 'verticalPage'
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'mode_horizontal',
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: readerMode == 'horizontalPage'
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '가로 페이지',
                            style: TextStyle(
                              color: readerMode == 'horizontalPage'
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'mode_webtoon',
                      child: Row(
                        children: [
                          Icon(
                            Icons.view_day,
                            color: readerMode == 'webtoon'
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '웹툰 (연속 스크롤)',
                            style: TextStyle(
                              color: readerMode == 'webtoon'
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required bool controlsVisible,
    required int totalPages,
    required String readerMode,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      bottom: controlsVisible ? 0 : -60,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${_currentPage + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _currentPage.toDouble(),
                    min: 0,
                    max: (totalPages - 1).toDouble(),
                    onChanged: (value) {
                      final page = value.round();
                      if (readerMode == 'webtoon') {
                        // 웹툰 모드에서는 스크롤 위치 조정
                        final scrollFraction = page / (totalPages - 1);
                        final targetOffset =
                            _webtoonScrollController.position.maxScrollExtent *
                            scrollFraction;
                        _webtoonScrollController.jumpTo(targetOffset);
                      } else {
                        _pageController.jumpToPage(page);
                      }
                    },
                  ),
                ),
                Text(
                  '$totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 페이지 모드용 이미지 위젯 (세로/가로 페이지)
class ReaderImage extends StatefulWidget {
  final GalleryImage img;
  const ReaderImage({super.key, required this.img});

  @override
  State<ReaderImage> createState() => _ReaderImageState();
}

class _ReaderImageState extends State<ReaderImage>
    with SingleTickerProviderStateMixin {
  int _retryKey = 0;
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  static const double _minScale = AppConfig.minImageScale;
  static const double _maxScale = AppConfig.maxImageScale;

  void _retry() {
    setState(() => _retryKey++);
    CachedNetworkImageProvider(widget.img.url).evict();
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          if (_animation != null) {
            _transformController.value = _animation!.value;
          }
        });
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.05; // 약간의 여유
    if (_isZoomed != isZoomed) {
      // 렌더링 루프 에러 방지 위해 microtask
      Future.microtask(() {
        if (mounted) setState(() => _isZoomed = isZoomed);
      });
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) =>
      _doubleTapDetails = details;

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    Matrix4 endMatrix;
    if (currentScale > _minScale) {
      endMatrix = Matrix4.identity();
    } else {
      const scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      endMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
    }

    _animation = Matrix4Tween(begin: _transformController.value, end: endMatrix)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final height = (widget.img.height / widget.img.width) * screenWidth;

    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: _minScale,
        maxScale: _maxScale,
        panEnabled: _isZoomed,
        scaleEnabled: true,
        child: CachedNetworkImage(
          key: ValueKey('${widget.img.url}_$_retryKey'),
          imageUrl: widget.img.url,
          httpHeaders: const {'Referer': 'https://hitomi.la/'},
          width: screenWidth,
          height: height,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => SizedBox(
            height: height > 500 ? 500 : height,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.3),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _retry();
            });
            return Container(
              height: 300,
              color: Colors.grey[900],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.white54, size: 40),
                  SizedBox(height: 8),
                  Text('Retrying...', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 웹툰 모드용 이미지 위젯 (연속 스크롤 + 줌 제스처 충돌 해결)
class WebtoonImage extends StatefulWidget {
  final GalleryImage img;
  const WebtoonImage({super.key, required this.img});

  @override
  State<WebtoonImage> createState() => _WebtoonImageState();
}

class _WebtoonImageState extends State<WebtoonImage>
    with SingleTickerProviderStateMixin {
  int _retryKey = 0;
  bool _isZoomed = false;
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  static const double _minScale = 1.0;
  static const double _maxScale = AppConfig.maxImageScale;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          if (_animation != null) {
            _transformController.value = _animation!.value;
          }
        });

    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.05; // 약간의 여유
    if (_isZoomed != isZoomed) {
      Future.microtask(() {
        if (mounted) setState(() => _isZoomed = isZoomed);
      });
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _retryKey++);
    CachedNetworkImageProvider(widget.img.url).evict();
  }

  void _handleDoubleTapDown(TapDownDetails details) =>
      _doubleTapDetails = details;

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    Matrix4 endMatrix;
    if (currentScale > _minScale) {
      // 줌 해제
      endMatrix = Matrix4.identity();
    } else {
      // 줌 인
      const scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      endMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
    }

    _animation = Matrix4Tween(begin: _transformController.value, end: endMatrix)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final height = (widget.img.height / widget.img.width) * screenWidth;

    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: _minScale,
        maxScale: _maxScale,
        panEnabled: _isZoomed,
        scaleEnabled: true,
        child: CachedNetworkImage(
          key: ValueKey('${widget.img.url}_$_retryKey'),
          imageUrl: widget.img.url,
          httpHeaders: const {'Referer': 'https://hitomi.la/'},
          width: screenWidth,
          height: height,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => SizedBox(
            height: height > 500 ? 500 : height,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.3),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _retry();
            });
            return Container(
              height: 300,
              color: Colors.grey[900],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.white54, size: 40),
                  SizedBox(height: 8),
                  Text('Retrying...', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
