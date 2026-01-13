import 'package:flutter/material.dart';
import '../../models/types.dart';
import 'detail_header.dart';
import 'detail_actions.dart';
import 'detail_metadata.dart';

class DetailBottomSheet extends StatefulWidget {
  final GalleryDetail item;

  const DetailBottomSheet({super.key, required this.item});

  @override
  State<DetailBottomSheet> createState() => _DetailBottomSheetState();
}

class _DetailBottomSheetState extends State<DetailBottomSheet> {
  double _dragOffset = 0;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      // 위쪽 overscroll (아래로 당길 때) - overscroll 값이 음수
      if (notification.overscroll < 0) {
        setState(() {
          _dragOffset += notification.overscroll.abs() * 0.8;
        });
      }
    } else if (notification is ScrollEndNotification) {
      _checkDismiss();
    }
    return false;
  }

  void _checkDismiss() {
    if (_dragOffset > 80) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: _dragOffset > 0
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _dragOffset, 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle - 직접 드래그 가능
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 0) {
                      setState(() => _dragOffset += details.delta.dy);
                    } else {
                      setState(
                        () => _dragOffset = (_dragOffset + details.delta.dy)
                            .clamp(0, double.infinity),
                      );
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (_dragOffset > 80 ||
                        details.velocity.pixelsPerSecond.dy > 500) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _dragOffset = 0);
                    }
                  },
                  child: _buildDragHandle(context),
                ),
                Flexible(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DetailHeader(item: widget.item),
                          DetailActions(item: widget.item),
                          const SizedBox(height: 16),
                          DetailMetadata(item: widget.item),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
