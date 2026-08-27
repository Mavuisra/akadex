import 'package:flutter_test/flutter_test.dart';

import 'package:akadex/core/constants/app_constants.dart';

void main() {
  test('legal URLs are absolute https for store listings', () {
    expect(AppConstants.privacyPolicyUrl, startsWith('https://'));
    expect(AppConstants.termsOfServiceUrl, startsWith('https://'));
    expect(AppConstants.deleteAccountUrl, startsWith('https://'));
    expect(AppConstants.privacyPolicyUrl, contains('/legal/privacy/'));
    expect(AppConstants.deleteAccountUrl, contains('/legal/delete-account/'));
  });
}
