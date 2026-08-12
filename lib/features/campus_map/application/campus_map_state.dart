enum CampusMapStatus { loading, success, error }

final class CampusMapState {
  const CampusMapState._({
    required this.status,
    required this.progress,
    required this.errorMessage,
  }) : assert(progress >= 0 && progress <= 100);

  const CampusMapState.loading({int progress = 0})
    : this._(
        status: CampusMapStatus.loading,
        progress: progress,
        errorMessage: null,
      );

  const CampusMapState.success()
    : this._(
        status: CampusMapStatus.success,
        progress: 100,
        errorMessage: null,
      );

  const CampusMapState.error({required String message})
    : this._(status: CampusMapStatus.error, progress: 0, errorMessage: message);

  final CampusMapStatus status;
  final int progress;
  final String? errorMessage;

  bool get isLoading => status == CampusMapStatus.loading;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CampusMapState &&
            status == other.status &&
            progress == other.progress &&
            errorMessage == other.errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, progress, errorMessage);
}
