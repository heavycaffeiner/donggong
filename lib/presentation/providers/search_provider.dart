import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data.dart';
import '../../domain/domain.dart';

part 'search_provider.g.dart';

class SearchUIState {
  final String query;
  final List<TagSuggestion> suggestions;
  final bool showSuggestions;

  const SearchUIState({
    this.query = '',
    this.suggestions = const [],
    this.showSuggestions = false,
  });

  SearchUIState copyWith({
    String? query,
    List<TagSuggestion>? suggestions,
    bool? showSuggestions,
  }) => SearchUIState(
    query: query ?? this.query,
    suggestions: suggestions ?? this.suggestions,
    showSuggestions: showSuggestions ?? this.showSuggestions,
  );
}

@riverpod
GalleryRepository galleryRepository(Ref ref) => GalleryRepository();

@riverpod
class Search extends _$Search {
  @override
  SearchUIState build() => const SearchUIState();

  void setQuery(String q) {
    state = state.copyWith(query: q);
    if (q.isNotEmpty) {
      final lastToken = q.trim().split(' ').last;
      if (lastToken.isNotEmpty) {
        _fetchSuggestions(lastToken);
      } else {
        state = state.copyWith(suggestions: [], showSuggestions: false);
      }
    } else {
      state = state.copyWith(suggestions: [], showSuggestions: false);
    }
  }

  Future<void> _fetchSuggestions(String q) async {
    final repo = ref.read(galleryRepositoryProvider);
    final suggestions = await repo.getSuggestions(q);
    state = state.copyWith(
      suggestions: suggestions,
      showSuggestions: suggestions.isNotEmpty,
    );
  }

  void setShowSuggestions(bool v) => state = state.copyWith(showSuggestions: v);
  void clear() => state = const SearchUIState();
}
