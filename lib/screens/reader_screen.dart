import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../models/types.dart';
import '../core/app_config.dart';
import '../presentation/state/reader_state.dart';
import '../presentation/state/navigation_state.dart';
import '../presentation/state/favorite_state.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pageController = PageController();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
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
    // Listen to ReaderState for gallery data
    final readerState = Provider.of<ReaderState>(context);
    final navState = Provider.of<NavigationState>(context, listen: false);
    final favState = Provider.of<FavoriteState>(context);

    final gallery = readerState.gallery;
    final theme = Theme.of(context);

    if (gallery == null || readerState.loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFav = favState.isFavorite('gallery', gallery.id);
    final totalPages = gallery.images.length;

    // Precache initial nearby images on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheNearbyImages(gallery.images, _currentPage);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content - PageView
          GestureDetector(
            onTap: () {
              readerState.toggleControls();
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: totalPages,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _precacheNearbyImages(gallery.images, index);
              },
              itemBuilder: (context, index) {
                final img = gallery.images[index];
                return ReaderImage(img: img);
              },
            ),
          ),

          // Overlay (Top Bar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: readerState.controlsVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          navState.closeReader();
                        },
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
                              '${_currentPage + 1} / $totalPages',
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
                          color: isFav
                              ? theme.colorScheme.primary
                              : Colors.white,
                        ),
                        onPressed: () => favState.toggleFavorite(
                          'gallery',
                          gallery.id.toString(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {
                          // formatting options
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Page Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: readerState.controlsVisible ? 0 : -60,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                            _pageController.jumpToPage(value.round());
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
          ),
        ],
      ),
    );
  }
}

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

  static const double _minScale = AppConfig.minImageScale;
  static const double _maxScale = AppConfig.maxImageScale;

  void _retry() {
    setState(() {
      _retryKey++;
    });
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    Matrix4 endMatrix;
    if (currentScale > _minScale) {
      // Zoom out
      endMatrix = Matrix4.identity();
    } else {
      // Zoom in to the tapped position
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
        panEnabled: _transformController.value.getMaxScaleOnAxis() > 1.0,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
