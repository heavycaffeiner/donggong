import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/shared.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class RecentScreen extends ConsumerStatefulWidget {
  const RecentScreen({super.key});

  @override
  ConsumerState<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends ConsumerState<RecentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfNeeded();
    });
  }

  void _loadIfNeeded() {
    ref.read(recentProvider.notifier).loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    final recentState = ref.watch(recentProvider);

    ref.listen(navigationProvider, (prev, next) {
      if (next == CustomScreen.recentViewed && prev != CustomScreen.reader) {
        _loadIfNeeded();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            if (recentState.loading && recentState.recents.isNotEmpty)
              const LinearProgressIndicator(),
            Expanded(
              child: GalleryListView(
                items: recentState.recents,
                isLoading: recentState.loading,
                emptyMessage: 'No recent history',
                isDismissible: true,
                onDismissed: (id) =>
                    ref.read(recentProvider.notifier).removeRecent(id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
