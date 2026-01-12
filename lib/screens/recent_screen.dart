import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/state/recent_state.dart';
import '../presentation/widgets/common/gallery_list_view.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recentState = Provider.of<RecentState>(context, listen: false);
      recentState.clear();
      recentState.loadRecents();
    });
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
