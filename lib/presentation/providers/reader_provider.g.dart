// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentRepository)
final recentRepositoryProvider = RecentRepositoryProvider._();

final class RecentRepositoryProvider
    extends
        $FunctionalProvider<
          RecentRepository,
          RecentRepository,
          RecentRepository
        >
    with $Provider<RecentRepository> {
  RecentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecentRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecentRepository create(Ref ref) {
    return recentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentRepository>(value),
    );
  }
}

String _$recentRepositoryHash() => r'44b90e43de994b4ac709dbb4f06cdbc5e543cc98';

@ProviderFor(Reader)
final readerProvider = ReaderProvider._();

final class ReaderProvider
    extends $AsyncNotifierProvider<Reader, GalleryDetail?> {
  ReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerHash();

  @$internal
  @override
  Reader create() => Reader();
}

String _$readerHash() => r'141f65cd5ae7cbcb5e71b5f1dc435d2a1d842f42';

abstract class _$Reader extends $AsyncNotifier<GalleryDetail?> {
  FutureOr<GalleryDetail?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GalleryDetail?>, GalleryDetail?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GalleryDetail?>, GalleryDetail?>,
              AsyncValue<GalleryDetail?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ReaderControls)
final readerControlsProvider = ReaderControlsProvider._();

final class ReaderControlsProvider
    extends $NotifierProvider<ReaderControls, bool> {
  ReaderControlsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerControlsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerControlsHash();

  @$internal
  @override
  ReaderControls create() => ReaderControls();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$readerControlsHash() => r'a38ca2db7557d50d2a144f893701e7196490e1cf';

abstract class _$ReaderControls extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
