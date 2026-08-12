enum ChangePasswordStatus { idle, loading, success, failure }

final class ChangePasswordState {
  const ChangePasswordState._({required this.status, required this.message});

  const ChangePasswordState.idle()
    : this._(status: ChangePasswordStatus.idle, message: null);

  const ChangePasswordState.loading()
    : this._(status: ChangePasswordStatus.loading, message: null);

  const ChangePasswordState.success({required String message})
    : this._(status: ChangePasswordStatus.success, message: message);

  const ChangePasswordState.failure({required String message})
    : this._(status: ChangePasswordStatus.failure, message: message);

  final ChangePasswordStatus status;
  final String? message;

  bool get isLoading => status == ChangePasswordStatus.loading;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChangePasswordState &&
            status == other.status &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(status, message);
}
