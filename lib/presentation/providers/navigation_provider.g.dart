// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Navigation)
final navigationProvider = NavigationProvider._();

final class NavigationProvider
    extends $NotifierProvider<Navigation, CustomScreen> {
  NavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationHash();

  @$internal
  @override
  Navigation create() => Navigation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomScreen value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomScreen>(value),
    );
  }
}

String _$navigationHash() => r'a93eefc10c52fe32ff002fe11b42c1ff32cadfcc';

abstract class _$Navigation extends $Notifier<CustomScreen> {
  CustomScreen build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CustomScreen, CustomScreen>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CustomScreen, CustomScreen>,
              CustomScreen,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
