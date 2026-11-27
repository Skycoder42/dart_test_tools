@TestOn('dart-vm')
library;

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/renovate/models/message_template.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:mustache_template/mustache_template.dart';
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

  group('$MessageTemplate', () {
    test('renders text without placeholders as is', () {
      final sut = MessageTemplate.parse(r'Updated ${native} $binaries {x}');
      check(sut.render(nativeUpgrade))
          .equals(r'Updated ${native} $binaries {x}');
    });

    test('renders raw values of placeholders', () {
      final sut = MessageTemplate.parse(
        'Updated {{depName}} from {{currentValue}} to {{ newValue }}',
      );
      check(sut.render(nativeUpgrade)).equals(
        'Updated native-lib from 1.0.21+202610010000 to 1.0.22+202611181006',
      );
    });

    test('escapes values as HTML', () {
      final sut = MessageTemplate.parse('{{packageName}}');
      check(
        sut.render(nativeUpgrade.copyWith(packageName: 'https://a.b/<c>&"d"')),
      ).equals('https:&#x2F;&#x2F;a.b&#x2F;&lt;c&gt;&amp;&quot;d&quot;');
    });

    test('inserts raw values with triple mustaches and ampersands', () {
      final sut = MessageTemplate.parse('{{{packageName}}} {{&packageName}}');
      check(
        sut.render(nativeUpgrade.copyWith(packageName: 'https://a.b/<c>&"d"')),
      ).equals('https://a.b/<c>&"d" https://a.b/<c>&"d"');
    });

    test('supports all placeholders', () {
      const upgrade = RenovateUpgrade(
        manager: 'm',
        depName: 'dn',
        packageFile: 'pf',
        depType: 'dt',
        currentValue: 'cv',
        newValue: 'nv',
        updateType: 'ut',
        currentVersion: 'cver',
        newVersion: 'nver',
        currentDigest: 'cd',
        newDigest: 'nd',
        newDigestShort: 'nds',
        packageName: 'pn',
        datasource: 'ds',
        releaseTimestamp: 'rt',
      );
      final sut = MessageTemplate.parse(
        MessageTemplate.placeholders.keys.map((n) => '{{$n}}').join('|'),
      );

      check(sut.render(upgrade))
          .equals('m|dn|pf|dt|cv|nv|ut|cver|nver|cd|nd|nds|pn|ds|rt');
    });

    test('supports sections of present values', () {
      final sut = MessageTemplate.parse(
        'Updated{{#newVersion}} to {{newVersion}}{{/newVersion}}',
      );
      check(sut.render(nativeUpgrade)).equals('Updated to 1.0.22');
    });

    test('rejects unknown placeholders with a list of valid ones', () {
      check(() => MessageTemplate.parse('Version {{version}}'))
          .throws<FormatException>()
          .has('message', (e) => e.message)
        ..contains('version')
        ..contains('newVersion');
    });

    test('rejects unknown placeholders in sections', () {
      check(
        () =>
            MessageTemplate.parse('{{#newVersion}}{{version}}{{/newVersion}}'),
      ).throws<FormatException>();
      check(() => MessageTemplate.parse('{{#version}}x{{/version}}'))
          .throws<FormatException>();
    });

    test('rejects placeholders with the wrong case', () {
      check(() => MessageTemplate.parse('{{newversion}}'))
          .throws<FormatException>();
    });

    test('rejects invalid templates', () {
      check(() => MessageTemplate.parse('Version {{newVersion'))
          .throws<FormatException>();
      check(() => MessageTemplate.parse('{{#newVersion}}x'))
          .throws<FormatException>();
      check(() => MessageTemplate.parse('{{> partial}}'))
          .throws<FormatException>();
    });

    test('rejects empty and multi line messages', () {
      check(() => MessageTemplate.parse('')).throws<FormatException>();
      check(() => MessageTemplate.parse('  ')).throws<FormatException>();
      check(() => MessageTemplate.parse('a\nb')).throws<FormatException>();
      check(() => MessageTemplate.parse('a\r\nb')).throws<FormatException>();
    });

    test('throws for missing values', () {
      final sut = MessageTemplate.parse('Digest {{newDigestShort}}');
      check(() => sut.render(nativeUpgrade))
          .throws<TemplateException>()
          .has('message', (e) => e.message)
          .contains('newDigestShort');
    });

    test('throws for sections of missing values', () {
      final sut = MessageTemplate.parse(
        '{{#newDigestShort}}x{{/newDigestShort}}',
      );
      check(() => sut.render(nativeUpgrade)).throws<TemplateException>();
    });

    test('converts from and to json', () {
      final sut = MessageTemplate.fromJson('v{{newVersion}}');
      check(sut.toJson()).equals('v{{newVersion}}');
      check(sut).equals(MessageTemplate.parse('v{{newVersion}}'));
    });
  });
}
