import 'package:akadex/features/learn/data/payments_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DepositResult', () {
    test('ACCEPTED n’est pas completed', () {
      final r = DepositResult.fromJson({
        'deposit_id': 'abc',
        'status': 'ACCEPTED',
        'message': 'ok',
        'pawapay_status': 'ACCEPTED',
      });
      expect(r.accepted, isTrue);
      expect(r.completed, isFalse);
      expect(r.failed, isFalse);
      expect(r.isTerminal, isFalse);
    });

    test('COMPLETED avec granted_course_ids', () {
      final r = DepositResult.fromJson({
        'deposit_id': 'abc',
        'status': 'COMPLETED',
        'message': 'done',
        'access_granted': true,
        'granted_course_ids': [12, '34'],
        'course_ids': ['12', '34'],
      });
      expect(r.completed, isTrue);
      expect(r.accessGranted, isTrue);
      expect(r.grantedCourseIds, ['12', '34']);
      expect(r.isTerminal, isTrue);
    });

    test('FAILED est terminal', () {
      final r = DepositResult.fromJson({
        'deposit_id': 'abc',
        'status': 'FAILED',
        'failure_message': 'PIN refusé',
        'message': '',
      });
      expect(r.failed, isTrue);
      expect(r.completed, isFalse);
      expect(r.failureMessage, 'PIN refusé');
    });
  });
}
