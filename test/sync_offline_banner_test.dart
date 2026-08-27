import 'package:akadex/data/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyncState.isOfflineVisible', () {
    expect(const SyncState(status: SyncStatus.online).isOfflineVisible, isFalse);
    expect(const SyncState(status: SyncStatus.idle).isOfflineVisible, isFalse);
    expect(
      const SyncState(status: SyncStatus.offline).isOfflineVisible,
      isTrue,
    );
    expect(const SyncState(status: SyncStatus.error).isOfflineVisible, isTrue);
  });
}
