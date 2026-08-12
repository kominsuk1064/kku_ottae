import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CampusMapTimerFactory =
    Timer Function(Duration duration, void Function() callback);

final campusMapLoadTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 20),
);

final campusMapTimerFactoryProvider = Provider<CampusMapTimerFactory>(
  (ref) =>
      (duration, callback) => Timer(duration, callback),
);
