import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import 'auth_providers.dart';
import 'auth_session_state.dart';

final authSessionControllerProvider =
    NotifierProvider.autoDispose<AuthSessionController, AuthSessionState>(
      AuthSessionController.new,
    );

final class AuthSessionController extends Notifier<AuthSessionState> {
  late final AuthRepository _repository;
  bool _operationInFlight = false;
  bool _disposed = false;

  @override
  AuthSessionState build() {
    _repository = ref.read(authRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    return const AuthSessionState.idle();
  }

  Future<void> signOut() async {
    if (_disposed || _operationInFlight) {
      return;
    }

    _operationInFlight = true;
    state = const AuthSessionState.signingOut();
    try {
      await _repository.signOut();
      if (_disposed) {
        return;
      }
      state = const AuthSessionState.signedOut();
    } on AuthFailure catch (error, stackTrace) {
      _reportAuthFailure(error, stackTrace);
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(error, stackTrace);
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> retry() {
    if (state.status != AuthSessionStatus.failure) {
      return Future<void>.value();
    }
    return signOut();
  }

  void _reportAuthFailure(AuthFailure error, StackTrace stackTrace) {
    developer.log(
      '로그아웃 실패',
      name: 'kku_ottae.auth',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = AuthSessionState.failure(
      message: switch (error.reason) {
        AuthFailureReason.networkUnavailable => '네트워크 연결을 확인해주세요.',
        AuthFailureReason.tooManyRequests => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
        _ => '로그아웃하지 못했습니다. 다시 시도해주세요.',
      },
    );
  }

  void _reportUnexpectedFailure(Object error, StackTrace stackTrace) {
    developer.log(
      '예상하지 못한 로그아웃 오류',
      name: 'kku_ottae.auth',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = const AuthSessionState.failure(message: '로그아웃하지 못했습니다. 다시 시도해주세요.');
  }
}
