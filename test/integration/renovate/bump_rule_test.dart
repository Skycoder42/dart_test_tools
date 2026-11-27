@TestOn('dart-vm')
library;

import 'package:dart_test_tools/src/auto_export/yaml_serializable.dart';
import 'package:dart_test_tools/src/pub/models/renovate_config.dart';
import 'package:dart_test_tools/src/renovate/models/bump_level.dart';
import 'package:dart_test_tools/src/renovate/models/bump_rule.dart';
import 'package:dart_test_tools/src/renovate/models/message_template.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

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

  group('$BumpLevel', () {
    test('is ordered by bump size', () {
      expect(BumpLevel.values, [
        BumpLevel.build,
        BumpLevel.patch,
        BumpLevel.minor,
        BumpLevel.breaking,
        BumpLevel.major,
      ]);
    });

    test('maxOf returns the biggest level', () {
      expect(
        BumpLevel.maxOf([BumpLevel.patch, BumpLevel.breaking, BumpLevel.minor]),
        BumpLevel.breaking,
      );
      expect(
        BumpLevel.maxOf([BumpLevel.major, BumpLevel.breaking]),
        BumpLevel.major,
      );
      expect(BumpLevel.maxOf([BumpLevel.build]), BumpLevel.build);
    });

    test('maxOf ignores null and returns null for no levels', () {
      expect(BumpLevel.maxOf([null, BumpLevel.build, null]), BumpLevel.build);
      expect(BumpLevel.maxOf([null]), isNull);
      expect(BumpLevel.maxOf([]), isNull);
    });
  });

  group('$MessageTemplate', () {
    test('renders text without placeholders as is', () {
      final sut = MessageTemplate.parse(r'Updated ${native} $binaries {x}');
      expect(sut.render(nativeUpgrade), r'Updated ${native} $binaries {x}');
    });

    test('renders raw values of placeholders', () {
      final sut = MessageTemplate.parse(
        'Updated {{depName}} from {{currentValue}} to {{ newValue }}',
      );
      expect(
        sut.render(nativeUpgrade),
        'Updated native-lib from 1.0.21+202610010000 to 1.0.22+202611181006',
      );
    });

    test('escapes values as HTML', () {
      final sut = MessageTemplate.parse('{{packageName}}');
      expect(
        sut.render(nativeUpgrade.copyWith(packageName: 'https://a.b/<c>&"d"')),
        'https:&#x2F;&#x2F;a.b&#x2F;&lt;c&gt;&amp;&quot;d&quot;',
      );
    });

    test('inserts raw values with triple mustaches and ampersands', () {
      final sut = MessageTemplate.parse('{{{packageName}}} {{&packageName}}');
      expect(
        sut.render(nativeUpgrade.copyWith(packageName: 'https://a.b/<c>&"d"')),
        'https://a.b/<c>&"d" https://a.b/<c>&"d"',
      );
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

      expect(
        sut.render(upgrade),
        'm|dn|pf|dt|cv|nv|ut|cver|nver|cd|nd|nds|pn|ds|rt',
      );
    });

    test('supports sections of present values', () {
      final sut = MessageTemplate.parse(
        'Updated{{#newVersion}} to {{newVersion}}{{/newVersion}}',
      );
      expect(sut.render(nativeUpgrade), 'Updated to 1.0.22');
    });

    test('rejects unknown placeholders with a list of valid ones', () {
      expect(
        () => MessageTemplate.parse('Version {{version}}'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('version'), contains('newVersion')),
          ),
        ),
      );
    });

    test('rejects unknown placeholders in sections', () {
      expect(
        () =>
            MessageTemplate.parse('{{#newVersion}}{{version}}{{/newVersion}}'),
        throwsFormatException,
      );
      expect(
        () => MessageTemplate.parse('{{#version}}x{{/version}}'),
        throwsFormatException,
      );
    });

    test('rejects placeholders with the wrong case', () {
      expect(
        () => MessageTemplate.parse('{{newversion}}'),
        throwsFormatException,
      );
    });

    test('rejects invalid templates', () {
      expect(
        () => MessageTemplate.parse('Version {{newVersion'),
        throwsFormatException,
      );
      expect(
        () => MessageTemplate.parse('{{#newVersion}}x'),
        throwsFormatException,
      );
      expect(
        () => MessageTemplate.parse('{{> partial}}'),
        throwsFormatException,
      );
    });

    test('rejects empty and multi line messages', () {
      expect(() => MessageTemplate.parse(''), throwsFormatException);
      expect(() => MessageTemplate.parse('  '), throwsFormatException);
      expect(() => MessageTemplate.parse('a\nb'), throwsFormatException);
      expect(() => MessageTemplate.parse('a\r\nb'), throwsFormatException);
    });

    test('throws for missing values', () {
      final sut = MessageTemplate.parse('Digest {{newDigestShort}}');
      expect(
        () => sut.render(nativeUpgrade),
        throwsA(
          isA<TemplateException>().having(
            (e) => e.message,
            'message',
            contains('newDigestShort'),
          ),
        ),
      );
    });

    test('throws for sections of missing values', () {
      final sut = MessageTemplate.parse(
        '{{#newDigestShort}}x{{/newDigestShort}}',
      );
      expect(
        () => sut.render(nativeUpgrade),
        throwsA(isA<TemplateException>()),
      );
    });

    test('converts from and to json', () {
      final sut = MessageTemplate.fromJson('v{{newVersion}}');
      expect(sut.toJson(), 'v{{newVersion}}');
      expect(sut, MessageTemplate.parse('v{{newVersion}}'));
    });
  });

  group('$BumpRule', () {
    BumpRule parse(String yaml) => BumpRule.fromJson(loadYaml(yaml) as YamlMap);

    test('parses single values and defaults', () {
      final sut = parse('''
manager: regex
name: native-lib
message: Updated to {{newVersion}}
''');

      expect(sut.manager, ['regex']);
      expect(sut.name, ['native-lib']);
      expect(sut.updateTypes, isEmpty);
      expect(sut.bump, BumpLevel.patch);
      expect(sut.message, MessageTemplate.parse('Updated to {{newVersion}}'));
    });

    test('parses lists and all keys', () {
      final sut = parse('''
manager: [regex, npm]
name: [a, b]
update_types: [major, digest, pinDigest]
bump: breaking
message: Updated
''');

      expect(sut.manager, ['regex', 'npm']);
      expect(sut.name, ['a', 'b']);
      expect(sut.updateTypes, [
        RenovateUpdateType.major,
        RenovateUpdateType.digest,
        RenovateUpdateType.pinDigest,
      ]);
      expect(sut.bump, BumpLevel.breaking);
    });

    test('parses all bump levels', () {
      for (final level in BumpLevel.values) {
        final sut = parse('''
manager: regex
name: a
bump: ${level.name}
message: m
''');
        expect(sut.bump, level);
      }
    });

    for (final (description, yaml) in [
      ('missing manager', 'name: a\nmessage: m'),
      ('missing name', 'manager: regex\nmessage: m'),
      ('missing message', 'manager: regex\nname: a'),
      ('unknown key', 'manager: regex\nname: a\nmessage: m\nbumb: patch'),
      ('unknown bump level', 'manager: regex\nname: a\nmessage: m\nbump: huge'),
      (
        'unknown update type',
        'manager: regex\nname: a\nmessage: m\nupdate_types: majr',
      ),
      (
        'unknown placeholder',
        'manager: regex\nname: a\nmessage: "{{version}}"',
      ),
    ]) {
      test('rejects $description', () {
        expect(() => parse(yaml.replaceAll(r'\n', '\n')), throwsA(anything));
      });
    }

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
        expect(rule().matches(nativeUpgrade), isTrue);
        expect(rule(manager: ['npm', 'regex']).matches(nativeUpgrade), isTrue);
        expect(rule(name: ['x', 'native-lib']).matches(nativeUpgrade), isTrue);
      });

      test('does not match other managers or names', () {
        expect(rule(manager: ['npm']).matches(nativeUpgrade), isFalse);
        expect(rule(manager: ['custom.regex']).matches(nativeUpgrade), isFalse);
        expect(rule(name: ['native']).matches(nativeUpgrade), isFalse);
        expect(rule(name: ['Native-Lib']).matches(nativeUpgrade), isFalse);
      });

      test('matches update types if given', () {
        expect(
          rule(updateTypes: [RenovateUpdateType.patch]).matches(nativeUpgrade),
          isTrue,
        );
        expect(
          rule(
            updateTypes: [RenovateUpdateType.minor, RenovateUpdateType.digest],
          ).matches(nativeUpgrade),
          isFalse,
        );
      });

      test('matches a missing update type only without update_types', () {
        final upgrade = nativeUpgrade.copyWith(updateType: null);
        expect(rule().matches(upgrade), isTrue);
        expect(
          rule(updateTypes: RenovateUpdateType.values).matches(upgrade),
          isFalse,
        );
      });
    });
  });

  group('$RenovateConfig', () {
    test('has no bump rules by default', () {
      final sut = RenovateConfig.fromYaml(
        loadYaml('pre_build_command: echo') as YamlMap,
      );
      expect(sut.bumpRules, isEmpty);
    });

    test('parses bump rules', () {
      final sut = RenovateConfig.fromYaml(
        loadYaml('''
pre_build_extra_managers: regex
bump_rules:
  - manager: regex
    name: native-lib
    update_types: [major, minor, patch]
    message: Updated native binaries to {{newVersion}}
  - manager: regex
    name: native-lib
    update_types: digest
    bump: build
    message: Rebuilt native binaries ({{newDigestShort}})
''') as YamlMap,
      );

      expect(sut.bumpRules, hasLength(2));
      expect(sut.bumpRules[0].bump, BumpLevel.patch);
      expect(sut.bumpRules[1].updateTypes, [RenovateUpdateType.digest]);
      expect(sut.bumpRules[1].bump, BumpLevel.build);
    });

    test('rejects invalid bump rules', () {
      expect(
        () => RenovateConfig.fromYaml(
          loadYaml('''
bump_rules:
  - manager: regex
    name: native-lib
    bump: huge
    message: m
''') as YamlMap,
        ),
        throwsA(anything),
      );
    });
  });
}
