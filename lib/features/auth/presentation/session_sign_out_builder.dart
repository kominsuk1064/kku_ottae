import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_session_controller.dart';
import '../application/auth_session_state.dart';

typedef SessionSignOutWidgetBuilder =
    Widget Function(
      BuildContext context,
      AuthSessionState state,
      VoidCallback signOut,
    );

class SessionSignOutBuilder extends ConsumerWidget {
  const SessionSignOutBuilder({
    super.key,
    required this.onSignedOut,
    required this.builder,
  });

  final VoidCallback onSignedOut;
  final SessionSignOutWidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authSessionControllerProvider);
    final controller = ref.read(authSessionControllerProvider.notifier);

    ref.listen<AuthSessionState>(authSessionControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == AuthSessionStatus.signedOut &&
          previous?.status != AuthSessionStatus.signedOut) {
        onSignedOut();
        return;
      }
      if (next.status == AuthSessionStatus.failure &&
          (previous?.status != AuthSessionStatus.failure ||
              previous?.message != next.message)) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message ?? '로그아웃하지 못했습니다.'),
              action: SnackBarAction(
                label: '다시 시도',
                onPressed: () => unawaited(controller.retry()),
              ),
            ),
          );
      }
    });

    return builder(context, state, () => unawaited(controller.signOut()));
  }
}
