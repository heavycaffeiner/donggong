// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Gallery)
final galleryProvider = GalleryProvider._();

final class GalleryProvider extends $NotifierProvider<Gallery, GalleryState> {
  GalleryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galleryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galleryHash();

  @$internal
  @override
  Gallery create() => Gallery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GalleryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GalleryState>(value),
    );
  }
}

String _$galleryHash() => r'56090c4a78543395cd8ad944f4354d5d45efa045';

abstract class _$Gallery extends $Notifier<GalleryState> {
  GalleryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GalleryState, GalleryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GalleryState, GalleryState>,
              GalleryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
