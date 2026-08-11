class TagoBusResponseException implements Exception {
  const TagoBusResponseException(this.message);

  final String message;

  @override
  String toString() => 'TagoBusResponseException: $message';
}

class TagoBusHttpException implements Exception {
  const TagoBusHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'TagoBusHttpException: HTTP $statusCode';
}
