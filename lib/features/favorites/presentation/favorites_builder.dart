import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/favorites_controller.dart';
import '../application/favorites_state.dart';

typedef FavoritesWidgetBuilder =
    Widget Function(
      BuildContext context,
      Set<String> favorites,
      ValueChanged<String> toggleFavorite,
    );

class FavoritesBuilder extends ConsumerWidget {
  const FavoritesBuilder({super.key, required this.builder});

  final FavoritesWidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(
      favoritesControllerProvider.select((state) => state.favorites),
    );

    return builder(
      context,
      favorites,
      (key) =>
          unawaited(ref.read(favoritesControllerProvider.notifier).toggle(key)),
    );
  }
}

class FavoritesErrorListener extends ConsumerStatefulWidget {
  const FavoritesErrorListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FavoritesErrorListener> createState() =>
      _FavoritesErrorListenerState();
}

class _FavoritesErrorListenerState
    extends ConsumerState<FavoritesErrorListener> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      favoritesControllerProvider,
      _handleStateChange,
      fireImmediately: true,
    );
  }

  void _handleStateChange(FavoritesState? previous, FavoritesState next) {
    final message = next.errorMessage;
    if (message == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => unawaited(
                ref.read(favoritesControllerProvider.notifier).retry(),
              ),
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
