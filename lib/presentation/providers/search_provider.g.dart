// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(galleryRepository)
final galleryRepositoryProvider = GalleryRepositoryProvider._();

final class GalleryRepositoryProvider
    extends
        $FunctionalProvider<
          GalleryRepository,
          GalleryRepository,
          GalleryRepository
        >
    with $Provider<GalleryRepository> {
  GalleryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galleryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galleryRepositoryHash();

  @$internal
  @override
  $ProviderElement<GalleryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GalleryRepository create(Ref ref) {
    return galleryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GalleryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GalleryRepository>(value),
    );
  }
}

String _$galleryRepositoryHash() => r'4ea38355f1bd16b1ccb3010426dd1e43a25e31a2';

@ProviderFor(Search)
final searchProvider = SearchProvider._();

final class SearchProvider extends $NotifierProvider<Search, SearchUIState> {
  SearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHash();

  @$internal
  @override
  Search create() => Search();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchUIState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchUIState>(value),
    );
  }
}

String _$searchHash() => r'b4a590de1bbb251625d3a8d350ca1c7a6aa8a28f';

abstract class _$Search extends $Notifier<SearchUIState> {
  SearchUIState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchUIState, SearchUIState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchUIState, SearchUIState>,
              SearchUIState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
