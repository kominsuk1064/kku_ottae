import 'package:flutter_test/flutter_test.dart';
import 'package:kku_ottae/features/profile/data/user_profile_document_parser.dart';
import 'package:kku_ottae/features/profile/domain/user_profile.dart';

void main() {
  group('parseUserProfileDocument', () {
    test('문서가 없으면 null을 반환한다', () {
      final profile = parseUserProfileDocument(userId: 'user-1', data: null);

      expect(profile, isNull);
    });

    test('Firestore 필드를 사용자 프로필로 변환한다', () {
      final profile = parseUserProfileDocument(
        userId: 'user-1',
        data: const {
          'name': '홍길동',
          'studentId': '20240001',
          'email': 'student@kku.ac.kr',
        },
      );

      expect(
        profile,
        const UserProfile(
          userId: 'user-1',
          name: '홍길동',
          studentId: '20240001',
          email: 'student@kku.ac.kr',
        ),
      );
    });

    test('누락되거나 문자열이 아닌 필드를 안전한 기본값으로 변환한다', () {
      final profile = parseUserProfileDocument(
        userId: 'user-1',
        data: const {'name': 123, 'studentId': null, 'email': false},
      );

      expect(
        profile,
        const UserProfile(
          userId: 'user-1',
          name: '',
          studentId: '',
          email: null,
        ),
      );
    });
  });
}
