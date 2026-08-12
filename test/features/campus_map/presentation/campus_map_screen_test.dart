import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/campus_map/application/campus_map_controller.dart';
import 'package:kku_ottae/features/campus_map/application/campus_map_providers.dart';
import 'package:kku_ottae/features/campus_map/presentation/campus_map_browser.dart';
import 'package:kku_ottae/features/campus_map/presentation/campus_map_screen.dart';

void main() {
  group('CampusMapScreen', () {
    testWidgets('첫 로드 중 loading과 진행률을 표시하고 완료되면 지도를 보여준다', (tester) async {
      final browser = await _pumpScreen(tester);

      expect(browser.loadCount, 1);
      expect(
        browser.loadedUri,
        Uri.parse('https://www.kku.ac.kr/campusMap.do'),
      );
      expect(find.byKey(const ValueKey('campus-map-loading')), findsOneWidget);
      expect(find.text('학교 지도를 불러오는 중입니다.'), findsOneWidget);
      expect(_refreshButton(tester).onPressed, isNull);

      browser.reportProgress(35);
      await tester.pump();
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.35);

      browser.finish();
      await tester.pump();

      expect(find.byKey(const ValueKey('campus-map-loading')), findsNothing);
      expect(find.byKey(const ValueKey('fake-campus-map')), findsOneWidget);
      expect(_refreshButton(tester).onPressed, isNotNull);
    });

    testWidgets('주 프레임 오류를 숨긴 메시지로 표시하고 재시도 후 복구한다', (tester) async {
      final browser = await _pumpScreen(tester);

      browser.fail(
        description: 'net::ERR_NAME_NOT_RESOLVED',
        isForMainFrame: true,
      );
      await tester.pump();

      expect(find.text(CampusMapController.loadFailureMessage), findsOneWidget);
      expect(find.text('net::ERR_NAME_NOT_RESOLVED'), findsNothing);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      expect(browser.reloadCount, 1);
      expect(find.byKey(const ValueKey('campus-map-loading')), findsOneWidget);

      browser.finish();
      await tester.pump();
      expect(find.byKey(const ValueKey('campus-map-error')), findsNothing);
    });

    testWidgets('하위 리소스 오류는 error 화면으로 전환하지 않는다', (tester) async {
      final browser = await _pumpScreen(tester);

      browser.fail(description: 'marker image failed', isForMainFrame: false);
      await tester.pump();

      expect(find.byKey(const ValueKey('campus-map-error')), findsNothing);
      expect(find.byKey(const ValueKey('campus-map-loading')), findsOneWidget);

      browser.finish();
      await tester.pump();
      expect(find.byKey(const ValueKey('campus-map-loading')), findsNothing);
    });

    testWidgets('작은 화면에서도 오류와 재시도 버튼을 스크롤할 수 있다', (tester) async {
      tester.view.physicalSize = const Size(320, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final browser = await _pumpScreen(tester);

      browser.fail(description: 'network failure', isForMainFrame: true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });
  });
}

Future<_FakeCampusMapBrowser> _pumpScreen(WidgetTester tester) async {
  late _FakeCampusMapBrowser browser;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        campusMapTimerFactoryProvider.overrideWithValue(
          (duration, callback) => _NoopTimer(),
        ),
      ],
      child: MaterialApp(
        home: CampusMapScreen(
          browserFactory: (callbacks) {
            browser = _FakeCampusMapBrowser(callbacks);
            return browser;
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return browser;
}

IconButton _refreshButton(WidgetTester tester) {
  return tester.widget<IconButton>(
    find.widgetWithIcon(IconButton, Icons.refresh).first,
  );
}

final class _FakeCampusMapBrowser implements CampusMapBrowser {
  _FakeCampusMapBrowser(this.callbacks);

  final CampusMapBrowserCallbacks callbacks;

  int loadCount = 0;
  int reloadCount = 0;
  Uri? loadedUri;

  @override
  Widget buildView() {
    return const ColoredBox(
      key: ValueKey('fake-campus-map'),
      color: Colors.green,
    );
  }

  @override
  Future<void> load(Uri uri) async {
    loadCount++;
    loadedUri = uri;
  }

  @override
  Future<void> reload() async {
    reloadCount++;
  }

  void reportProgress(int progress) => callbacks.onProgress(progress);

  void finish() => callbacks.onPageFinished();

  void fail({required String description, required bool? isForMainFrame}) {
    callbacks.onWebResourceError(
      CampusMapBrowserError(
        description: description,
        isForMainFrame: isForMainFrame,
      ),
    );
  }
}

final class _NoopTimer implements Timer {
  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;

  @override
  void cancel() {
    _isActive = false;
  }
}
