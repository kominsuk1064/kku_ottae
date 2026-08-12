import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/user_profile_failure.dart';
import '../domain/user_profile_repository.dart';
import 'profile_providers.dart';
import 'user_profile_state.dart';

final userProfileControllerProvider =
    NotifierProvider.autoDispose<UserProfileController, UserProfileState>(
      UserProfileController.new,
    );

final class UserProfileController extends Notifier<UserProfileState> {
  static const signedOutMessage = '로그인 정보를 확인할 수 없습니다.';
  static const permissionDeniedMessage = '프로필을 불러올 권한이 없습니다.';
  static const unavailableMessage = '프로필 서버에 연결할 수 없습니다.';
  static const unknownErrorMessage = '프로필을 불러오지 못했습니다.';

  late final AuthRepository _authRepository;
  late final UserProfileRepository _profileRepository;
  Future<void>? _loadOperation;
  bool _disposed = false;

  @override
  UserProfileState build() {
    _authRepository = ref.read(authRepositoryProvider);
    _profileRepository = ref.read(userProfileRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(load));
    return const UserProfileState.loading();
  }

  Future<void> load() {
    if (_disposed) {
      return Future<void>.value();
    }

    final activeOperation = _loadOperation;
    if (activeOperation != null) {
      return activeOperation;
    }

    late final Future<void> operation;
    operation = _performLoad();
    _loadOperation = operation;
    return operation.whenComplete(() {
      if (identical(_loadOperation, operation)) {
        _loadOperation = null;
      }
    });
  }

  Future<void> retry() {
    return switch (state.status) {
      UserProfileStatus.empty || UserProfileStatus.failure => load(),
      UserProfileStatus.loading ||
      UserProfileStatus.success => Future<void>.value(),
    };
  }

  Future<void> _performLoad() async {
    state = const UserProfileState.loading();

    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      state = const UserProfileState.failure(message: signedOutMessage);
      return;
    }

    try {
      final profile = await _profileRepository.fetchProfile(
        userId: currentUser.id,
      );
      if (_disposed) {
        return;
      }
      state = profile == null
          ? const UserProfileState.empty()
          : UserProfileState.success(profile);
    } on UserProfileFailure catch (error, stackTrace) {
      _reportProfileFailure(error, stackTrace);
    } catch (error, stackTrace) {
      _reportUnexpectedFailure(error, stackTrace);
    }
  }

  void _reportProfileFailure(UserProfileFailure error, StackTrace stackTrace) {
    developer.log(
      '회원 프로필 조회 실패',
      name: 'kku_ottae.profile',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = UserProfileState.failure(
      message: switch (error.reason) {
        UserProfileFailureReason.permissionDenied ||
        UserProfileFailureReason.unauthenticated => permissionDeniedMessage,
        UserProfileFailureReason.temporarilyUnavailable => unavailableMessage,
        UserProfileFailureReason.unknown => unknownErrorMessage,
      },
    );
  }

  void _reportUnexpectedFailure(Object error, StackTrace stackTrace) {
    developer.log(
      '예상하지 못한 회원 프로필 조회 오류',
      name: 'kku_ottae.profile',
      error: error,
      stackTrace: stackTrace,
    );
    if (_disposed) {
      return;
    }
    state = const UserProfileState.failure(message: unknownErrorMessage);
  }
}
