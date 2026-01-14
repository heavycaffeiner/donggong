// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Recent)
final recentProvider = RecentProvider._();

final class RecentProvider extends $NotifierProvider<Recent, RecentState> {
  RecentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentHash();

  @$internal
  @override
  Recent create() => Recent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentState>(value),
    );
  }
}

String _$recentHash() => r'd3b08b6a68c84300f78a05d54986ad2a74eca8a3';

abstract class _$Recent extends $Notifier<RecentState> {
  RecentState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RecentState, RecentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecentState, RecentState>,
              RecentState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
