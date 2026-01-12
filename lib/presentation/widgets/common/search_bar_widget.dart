import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/types.dart';
import '../../../services/api_service.dart';
import '../../state/search_state.dart';
import '../../state/gallery_state.dart';
import '../../state/navigation_state.dart';
import '../../state/favorite_state.dart';
import '../../state/reader_state.dart';
import '../../state/settings_state.dart';

class SearchBarWidget extends StatefulWidget {
  final bool allowDirectId;

  const SearchBarWidget({super.key, this.allowDirectId = false});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<TagSuggestion> _suggestions = [];
  late SearchState _searchState;

  @override
  void initState() {
    super.initState();
    _searchState = Provider.of<SearchState>(context, listen: false);
    _controller.text = _searchState.query;
    _searchState.addListener(_onSearchStateChanged);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      }
    });
  }

  void _onSearchStateChanged() {
    // Sync controller text when SearchState.query changes externally (e.g., TagChip click)
    if (!_focusNode.hasFocus && _controller.text != _searchState.query) {
      setState(() {
        _controller.text = _searchState.query;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _searchState.removeListener(_onSearchStateChanged);
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
    if (_suggestions.isEmpty) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_suggestions.isEmpty) {
      _hideOverlay();
    } else if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else {
      _showOverlay();
    }
  }

  Future<void> _onTextChanged(String text) async {
    final searchState = Provider.of<SearchState>(context, listen: false);
    searchState.setQuery(text);

    if (text.isEmpty) {
      setState(() => _suggestions = []);
      _hideOverlay();
      return;
    }

    final lastToken = text.trim().split(' ').last;
    if (lastToken.isEmpty) {
      setState(() => _suggestions = []);
      _hideOverlay();
      return;
    }

    try {
      final suggestions = await ApiService.getSuggestions(lastToken);
      if (mounted) {
        setState(() => _suggestions = suggestions);
        _updateOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _suggestions = []);
        _hideOverlay();
      }
    }
  }

  void _onSuggestionSelected(TagSuggestion selection) {
    final currentText = _controller.text;
    final tokens = currentText.trim().split(' ');

    if (tokens.isNotEmpty) tokens.removeLast();

    final prefix = selection.type == 'tag' ? '' : '${selection.type}:';
    final fullTag = '$prefix${selection.tag.replaceAll(' ', '_')}';
    tokens.add(fullTag);

    final newQuery = '${tokens.join(' ')} ';

    _controller.text = newQuery;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newQuery.length),
    );

    // SearchState ?숆린??
    final searchState = Provider.of<SearchState>(context, listen: false);
    searchState.setQuery(newQuery);

    // Suggestions 珥덇린??諛??ㅻ쾭?덉씠 ?リ린
    setState(() => _suggestions = []);
    _hideOverlay();

    _performSearch(context, reload: true);
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
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return _buildSuggestionTile(item, theme, colorScheme);
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

    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 48,
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
                  onSubmitted: (text) => _onSubmit(context, text),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _controller.clear();
                    final searchState = Provider.of<SearchState>(
                      context,
                      listen: false,
                    );
                    searchState.clear();
                    setState(() => _suggestions = []);
                    _hideOverlay();
                    _performSearch(context, reload: true);
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context, String text) {
    _hideOverlay();
    final searchState = Provider.of<SearchState>(context, listen: false);

    if (widget.allowDirectId && RegExp(r'^\d+$').hasMatch(text.trim())) {
      final readerState = Provider.of<ReaderState>(context, listen: false);
      final navState = Provider.of<NavigationState>(context, listen: false);
      readerState.loadGallery(int.parse(text.trim()));
      navState.setScreen(CustomScreen.reader);
    } else {
      searchState.setQuery(text);
      _performSearch(context, reload: true);
    }
  }

  void _performSearch(BuildContext context, {bool reload = false}) {
    final navState = Provider.of<NavigationState>(context, listen: false);
    final galleryState = Provider.of<GalleryState>(context, listen: false);
    final favState = Provider.of<FavoriteState>(context, listen: false);
    final searchState = Provider.of<SearchState>(context, listen: false);
    final settingsState = Provider.of<SettingsState>(context, listen: false);

    if (navState.screen == CustomScreen.favorites) {
      favState.loadFavorites(query: searchState.query);
    } else {
      if (navState.screen != CustomScreen.home) {
        navState.setScreen(CustomScreen.home);
      }
      if (reload) {
        galleryState.loadGalleries(
          reset: true,
          query: searchState.query,
          defaultLang: settingsState.settings.defaultLanguage,
        );
      }
    }
  }
}
