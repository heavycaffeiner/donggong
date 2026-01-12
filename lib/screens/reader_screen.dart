import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../models/types.dart';
import '../presentation/state/reader_state.dart';
import '../presentation/state/navigation_state.dart';
import '../presentation/state/favorite_state.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          GestureDetector(
            onTap: () {
              readerState.toggleControls();
            },
            child: ListView.builder(
              itemCount: gallery.images.length,
              cacheExtent: 3000,
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
                          // readerState.clear(); // Optional: clear on close
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
                              '${gallery.images.length} pages',
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

class _ReaderImageState extends State<ReaderImage> {
  int _retryKey = 0;

  void _retry() {
    setState(() {
      _retryKey++;
    });
    CachedNetworkImageProvider(widget.img.url).evict();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final height = (widget.img.height / widget.img.width) * screenWidth;

    return CachedNetworkImage(
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
    );
  }
}
