// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoriteRepository)
final favoriteRepositoryProvider = FavoriteRepositoryProvider._();

final class FavoriteRepositoryProvider
    extends
        $FunctionalProvider<
          FavoriteRepository,
          FavoriteRepository,
          FavoriteRepository
        >
    with $Provider<FavoriteRepository> {
  FavoriteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoriteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoriteRepository create(Ref ref) {
    return favoriteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteRepository>(value),
    );
  }
}

String _$favoriteRepositoryHash() =>
    r'f216db6d6af388a84b2e9ba5408243c4fae9b1ad';

/// 앱 시작 시 자동으로 FavoritesData를 로드하는 provider

@ProviderFor(favoriteData)
final favoriteDataProvider = FavoriteDataProvider._();

/// 앱 시작 시 자동으로 FavoritesData를 로드하는 provider

final class FavoriteDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<FavoritesData>,
          FavoritesData,
          FutureOr<FavoritesData>
        >
    with $FutureModifier<FavoritesData>, $FutureProvider<FavoritesData> {
  /// 앱 시작 시 자동으로 FavoritesData를 로드하는 provider
  FavoriteDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteDataHash();

  @$internal
  @override
  $FutureProviderElement<FavoritesData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FavoritesData> create(Ref ref) {
    return favoriteData(ref);
  }
}

String _$favoriteDataHash() => r'38ff18693c3193b7293512a9e44ebf565bfcda28';

@ProviderFor(Favorite)
final favoriteProvider = FavoriteProvider._();

final class FavoriteProvider
    extends $NotifierProvider<Favorite, FavoriteState> {
  FavoriteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteHash();

  @$internal
  @override
  Favorite create() => Favorite();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteState>(value),
    );
  }
}

String _$favoriteHash() => r'cfba0ba27df234452810ea9983c06086accccd44';

abstract class _$Favorite extends $Notifier<FavoriteState> {
  FavoriteState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FavoriteState, FavoriteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FavoriteState, FavoriteState>,
              FavoriteState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
