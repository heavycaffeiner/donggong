// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentSearchRepository)
final recentSearchRepositoryProvider = RecentSearchRepositoryProvider._();

final class RecentSearchRepositoryProvider
    extends
        $FunctionalProvider<
          RecentSearchRepository,
          RecentSearchRepository,
          RecentSearchRepository
        >
    with $Provider<RecentSearchRepository> {
  RecentSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecentSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentSearchRepository create(Ref ref) {
    return recentSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentSearchRepository>(value),
    );
  }
}

String _$recentSearchRepositoryHash() =>
    r'56c8d90ed3d72891b157cce26a82b32776d44858';

@ProviderFor(RecentSearch)
final recentSearchProvider = RecentSearchProvider._();

final class RecentSearchProvider
    extends $AsyncNotifierProvider<RecentSearch, List<String>> {
  RecentSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchHash();

  @$internal
  @override
  RecentSearch create() => RecentSearch();
}

String _$recentSearchHash() => r'de13400b1668b043682aa5d32f258f96f65cfc00';

abstract class _$RecentSearch extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
