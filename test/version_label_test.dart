import 'package:countdowns/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

PackageInfo _info(String version, String build) => PackageInfo(
  appName: 'Soon & Since',
  packageName: 'com.chrisstayte.countdowns',
  version: version,
  buildNumber: build,
);

void main() {
  test('shows the version with its build number', () {
    expect(versionLabel(_info('3.0.0', '6')), '3.0.0 (6)');
  });

  test('leaves out an empty build number', () {
    expect(versionLabel(_info('3.0.0', '')), '3.0.0');
  });

  test('is empty before the package info loads', () {
    expect(versionLabel(null), '');
  });
}
