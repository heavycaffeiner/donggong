import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/recent_state.dart';
import '../state/navigation_state.dart';
import '../widgets/common/gallery_list_view.dart';
import '../models/types.dart' show CustomScreen;

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  late NavigationState _navState;

  @override
  void initState() {
    super.initState();
    _navState = Provider.of<NavigationState>(context, listen: false);
    _navState.addListener(_onNavigationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _navState.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    // Load when switching to recent tab
    if (_navState.screen == CustomScreen.recentViewed &&
        _navState.previousScreen != CustomScreen.reader) {
      _loadIfNeeded();
    }
  }

  void _loadIfNeeded() {
    final recentState = Provider.of<RecentState>(context, listen: false);
    recentState.loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    final recentState = Provider.of<RecentState>(context);

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
                onDismissed: (id) => recentState.removeRecent(id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
