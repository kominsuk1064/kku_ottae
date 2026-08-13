import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _appName = '건대어때';
const _bundleId = 'com.kominsuk1064.kkuottae';

void main() {
  group('iOS 앱 메타데이터', () {
    test('표시 이름과 번들 이름이 정식 앱 이름을 사용한다', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(_plistString(infoPlist, 'CFBundleDisplayName'), _appName);
      expect(_plistString(infoPlist, 'CFBundleName'), _appName);
      expect(infoPlist, isNot(contains('Ottae Fixed')));
      expect(infoPlist, isNot(contains('ottae_fixed')));
    });

    test('앱과 테스트 타깃의 모든 빌드 구성이 정식 Bundle ID를 사용한다', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      const appSetting = 'PRODUCT_BUNDLE_IDENTIFIER = $_bundleId;';
      const testSetting = 'PRODUCT_BUNDLE_IDENTIFIER = $_bundleId.RunnerTests;';

      expect(_occurrences(project, appSetting), 3);
      expect(_occurrences(project, testSetting), 3);
      expect(project, isNot(contains('com.example.ottaeFixed')));
    });
  });
}

String? _plistString(String source, String key) {
  final match = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<string>([^<]*)</string>',
  ).firstMatch(source);
  return match?.group(1);
}

int _occurrences(String source, String value) =>
    RegExp(RegExp.escape(value)).allMatches(source).length;
