import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:donggong/data/data.dart';
import 'package:donggong/domain/domain.dart';
import 'package:donggong/shared/shared.dart';
import 'package:donggong/presentation/providers/providers.dart';
import '../chips/common_chip.dart';

class FavoriteChipItem {
  final String label;
  final String searchTag;
  final String type;
  final String value;
  FavoriteChipItem(this.label, this.searchTag, this.type, this.value);
}

class SearchBarWidget extends ConsumerStatefulWidget {
  final bool allowDirectId;

  const SearchBarWidget({super.key, this.allowDirectId = false});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<TagSuggestion> _suggestions = [];

  List<FavoriteChipItem> _getFavoriteChips(FavoritesData data) {
    final items = <FavoriteChipItem>[];

    String format(String type, String val) {
      if (val.startsWith('$type:')) return val;
      return '$type:$val';
    }

    for (var t in data.favoriteTag) {
      final parts = t.split(':');
      final type = parts[0];
      final value = parts[1];
      items.add(FavoriteChipItem(t, t, type, value));
    }
    for (var t in data.favoriteGroup) {
      final label = format('group', t);
      items.add(FavoriteChipItem(label, label, 'group', t));
    }
    for (var t in data.favoriteParody) {
      final label = t.startsWith('series:') ? t : 'series:$t';
      items.add(FavoriteChipItem(label, label, 'series', t));
    }
    for (var t in data.favoriteCharacter) {
      final label = format('character', t);
      items.add(FavoriteChipItem(label, label, 'character', t));
    }
    for (var t in data.favoriteArtist) {
      final label = format('artist', t);
      items.add(FavoriteChipItem(label, label, 'artist', t));
    }
    for (var t in data.favoriteLanguage) {
      final label = format('language', t);
      items.add(FavoriteChipItem(label, label, 'language', t));
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchProvider).query;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _onTextChanged(_controller.text);
      } else {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _hideOverlay();
    final favData = ref.read(favoriteProvider).favoritesData;
    if (_suggestions.isEmpty && _getFavoriteChips(favData).isEmpty) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    final favData = ref.read(favoriteProvider).favoritesData;
    if (_suggestions.isEmpty && _getFavoriteChips(favData).isEmpty) {
      _hideOverlay();
    } else if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else {
      _showOverlay();
    }
  }

  Future<void> _onTextChanged(String text) async {
    setState(() {});
    if (text.isEmpty) {
      final recent = await ref.read(recentSearchProvider.future);
      setState(() {
        _suggestions = recent
            .map((e) => TagSuggestion(tag: e, type: 'recent', count: 0))
            .toList();
      });
      _updateOverlay();
      return;
    }

    final lastToken = text.split(' ').last;
    if (lastToken.isEmpty) {
      final recent = await ref.read(recentSearchProvider.future);
      setState(() {
        _suggestions = recent
            .map((e) => TagSuggestion(tag: e, type: 'recent', count: 0))
            .toList();
      });
      _updateOverlay();
      return;
    }

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final suggestions = await repo.getSuggestions(lastToken);
      if (mounted) {
        setState(() => _suggestions = suggestions);
        _updateOverlay();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _suggestions = []);
        _hideOverlay();
      }
    }
  }

  void _addTagToQuery(String tag) {
    final currentText = _controller.text;
    final tokens = currentText.split(' ');
    if (tokens.isNotEmpty) tokens.removeLast();

    tokens.add(tag);

    final newQuery = '${tokens.join(' ')} ';
    _controller.text = newQuery;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newQuery.length),
    );

    _focusNode.requestFocus();
    _onTextChanged(newQuery);
  }

  void _onSuggestionSelected(TagSuggestion selection) {
    final fullTag = '${selection.type}:${selection.tag.replaceAll(' ', '_')}';
    _addTagToQuery(fullTag);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(16, size.height + 4),
          child: Material(
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Consumer(
                builder: (context, ref, _) {
                  final favState = ref.watch(favoriteProvider);
                  final favData = favState.favoritesData;
                  final favChips = _getFavoriteChips(favData);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (favChips.isNotEmpty)
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            itemCount: favChips.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 4),
                            itemBuilder: (context, index) {
                              final chip = favChips[index];
                              return Center(
                                child: CommonChip(
                                  label: chip.label,
                                  icon: Icons.star,
                                  iconColor: Colors.amber,
                                  onTap: () => _addTagToQuery(chip.searchTag),
                                  onLongPress: () =>
                                      _deleteFavorite(chip.type, chip.value),
                                ),
                              );
                            },
                          ),
                        ),
                      if (favChips.isNotEmpty)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      Flexible(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final item = _suggestions[index];
                            return _buildSuggestionTile(
                              item,
                              theme,
                              colorScheme,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(
    TagSuggestion item,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    Color typeColor = colorScheme.outline;
    IconData icon = Icons.label_outline;

    if (item.type == 'recent') {
      return InkWell(
        onTap: () {
          _addTagToQuery(item.tag);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.history, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.tag,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await ref
                      .read(recentSearchProvider.notifier)
                      .remove(item.tag);
                  // 리스트 갱신을 위해 provider를 refresh
                  final recent = await ref.read(recentSearchProvider.future);
                  if (mounted) {
                    setState(() {
                      _suggestions = recent
                          .map(
                            (e) =>
                                TagSuggestion(tag: e, type: 'recent', count: 0),
                          )
                          .toList();
                    });
                    _updateOverlay();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (item.type == 'female') {
      typeColor = Colors.pinkAccent;
      icon = Icons.female;
    } else if (item.type == 'male') {
      typeColor = Colors.blueAccent;
      icon = Icons.male;
    } else if (item.type == 'artist') {
      typeColor = Colors.orangeAccent;
      icon = Icons.brush;
    } else if (item.type == 'series') {
      typeColor = Colors.purpleAccent;
      icon = Icons.book;
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 16, color: typeColor),
      title: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          children: [
            TextSpan(
              text: '${item.type}: ',
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            TextSpan(text: item.tag),
          ],
        ),
      ),
      trailing: Text(
        item.count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
      ),
      onTap: () => _onSuggestionSelected(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(navigationProvider, (prev, next) {
      // 화면 전환 시 항상 오버레이 정리
      if (prev != next) {
        _hideOverlay();
        _focusNode.unfocus();
      }
    });

    ref.listen(searchProvider, (prev, next) {
      if (!_focusNode.hasFocus && _controller.text != next.query) {
        _controller.text = next.query;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        setState(() {});
      }
    });

    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 48,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.allowDirectId
                        ? 'Search or enter ID...'
                        : 'Search tags...',
                    hintStyle: TextStyle(color: colorScheme.outline),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: (text) => _onSubmit(text),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: colorScheme.outline),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchProvider.notifier).clear();
                    _hideOverlay();
                    _focusNode.unfocus();
                    _performSearch(reload: true, force: true);
                    setState(() {});
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              if (_controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        onPressed: () => _onSubmit(_controller.text),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit(String text) {
    _hideOverlay();
    _focusNode.unfocus();

    if (widget.allowDirectId && RegExp(r'^\d+$').hasMatch(text.trim())) {
      ref.read(readerProvider.notifier).loadGallery(int.parse(text.trim()));
      ref.read(navigationProvider.notifier).setScreen(CustomScreen.reader);
    } else {
      ref.read(recentSearchProvider.notifier).add(text.trim());
      ref.read(searchProvider.notifier).setQuery(text);
      _performSearch(reload: true);
    }
  }

  void _performSearch({bool reload = false, bool force = false}) {
    final screen = ref.read(navigationProvider);
    final searchState = ref.read(searchProvider);
    final settingsAsync = ref.read(settingsProvider);
    final settings = settingsAsync.value ?? SettingsData.defaults();

    if (screen == CustomScreen.favorites) {
      ref
          .read(favoriteProvider.notifier)
          .loadFavorites(query: searchState.query);
    } else {
      if (screen != CustomScreen.home) {
        ref.read(navigationProvider.notifier).setScreen(CustomScreen.home);
      }
      if (reload) {
        ref
            .read(galleryProvider.notifier)
            .loadGalleries(
              reset: true,
              query: searchState.query,
              defaultLang: settings.defaultLanguage,
              force: force,
            );
      }
    }
  }

  Future<void> _deleteFavorite(String type, String value) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('즐겨찾기 삭제'),
        content: Text("'$type:$value' 항목을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(favoriteProvider.notifier).toggleFavorite(type, value);
      if (mounted) {
        setState(() {}); // Rebuild to refresh overlay
        _updateOverlay();
      }
    }
  }
}
