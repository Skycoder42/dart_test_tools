@TestOn('dart-vm')
library;

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/auto_export/yaml_serializable.dart';
import 'package:dart_test_tools/src/renovate/models/bump_rule.dart';
import 'package:dart_test_tools/src/renovate/models/message_template.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:test/scaffolding.dart';

void main() {
  const nativeUpgrade = RenovateUpgrade(
    manager: 'regex',
    depName: 'native-lib',
    packageFile: 'packages/b/lib/src/native/version.txt',
    currentValue: '1.0.21+202610010000',
    newValue: '1.0.22+202611181006',
    newVersion: '1.0.22',
    updateType: 'patch',
  );

  group('$BumpRule', () {
    group('matches', () {
      BumpRule rule({
        List<String> manager = const ['regex'],
        List<String> name = const ['native-lib'],
        List<RenovateUpdateType> updateTypes = const [],
      }) => BumpRule(
        manager: ListOrValue.list(manager),
        name: ListOrValue.list(name),
        updateTypes: ListOrValue.list(updateTypes),
        message: MessageTemplate.parse('m'),
      );

      test('matches manager and name', () {
        check(rule().matches(nativeUpgrade)).isTrue;
        check(rule(manager: ['npm', 'regex']).matches(nativeUpgrade)).isTrue;
        check(rule(name: ['x', 'native-lib']).matches(nativeUpgrade)).isTrue;
      });

      test('does not match other managers or names', () {
        check(rule(manager: ['npm']).matches(nativeUpgrade)).isFalse;
        check(rule(manager: ['custom.regex']).matches(nativeUpgrade)).isFalse;
        check(rule(name: ['native']).matches(nativeUpgrade)).isFalse;
        check(rule(name: ['Native-Lib']).matches(nativeUpgrade)).isFalse;
      });

      test('matches update types if given', () {
        check(
          rule(updateTypes: [RenovateUpdateType.patch]).matches(nativeUpgrade),
        ).isTrue;
        check(
          rule(
            updateTypes: [RenovateUpdateType.minor, RenovateUpdateType.digest],
          ).matches(nativeUpgrade),
        ).isFalse;
      });

      test('matches a missing update type only without update_types', () {
        final upgrade = nativeUpgrade.copyWith(updateType: null);
        check(rule().matches(upgrade)).isTrue;
        check(rule(updateTypes: RenovateUpdateType.values).matches(upgrade))
            .isFalse;
      });
    });
  });
}
