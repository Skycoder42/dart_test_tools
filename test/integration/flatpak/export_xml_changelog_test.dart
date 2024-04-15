import 'dart:io';

import 'package:dart_test_tools/src/flatpak/export_xml_changelog/export_xml_changelog.dart';
import 'package:dart_test_tools/src/tools/io.dart';
import 'package:test/test.dart';

void main() {
  group('$ExportXmlChangelog', () {
    late Directory testDir;

    const sut = ExportXmlChangelog();

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      Directory.current = testDir;
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test('generates changelog XML from MD', () async {
      await testDir.subFile('CHANGELOG.md').writeAsString(_testChangelogMdFull);

      final outFile = testDir.subFile('releases.xml');
      await sut(outFile: outFile, isMetadataXml: false);

      print(outFile.path);
      expect(outFile.existsSync(), isTrue);
      expect(outFile.readAsString(), completion(_testChangelogXml));
    });

    test('adds changelog to metainfo.xml', () async {
      await testDir
          .subFile('CHANGELOG.md')
          .writeAsString(_testChangelogMdMinimal);
      final outFile = testDir.subFile('metainfo.xml');
      await outFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<component>
  <id>test-id</id>
</component>
''');

      await sut(outFile: outFile);

      expect(outFile.existsSync(), isTrue);
      expect(outFile.readAsString(), completion(_testMetainfoXml));
    });
  });
}

const _testChangelogMdFull = '''
# Changelog
This is the preamble. It is ignored.

## [1.2.3] - 2024-10-10
### Added
- simple 1
- simple 2
- simple 3

### Changed
- Complex nested lists
  - Element a
  - Element b
    1. Element b1
    2. Element b2
       - Element b2a
  - Element c
    - Element ca
    - Element cb

## [1.2.0-dev] - 2024-06-25
### Fixed
- Some _text_ with **highlighted** elements ~~and~~ some `<b>code</b>`
- and some multiline code
  ```dart
  const variable = 42;
  ```

## 1.1.39 - 2024-01-11
### Removed
- Should <be/> [escaped]
- Also here is a [link](https://example.com)
- And a ![picture](https://example.com)

[1.2.3]: https://example.com/stable-release
[1.2.0-dev]: https://example.com/dev-release
''';

const _testChangelogMdMinimal = '''
# Changelog
This is the preamble. It is ignored.

## 1.0.0 - 2024-01-01
### Added
- added
''';

const _testChangelogXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<releases>
  <release version="1.2.3" date="2024-10-10" type="stable">
    <description>
      <h3>Added</h3>
      <ul>
        <li>simple 1</li>
        <li>simple 2</li>
        <li>simple 3</li>
      </ul>
      <h3>Changed</h3>
      <ul>
        <li>
          Complex nested lists
          <ul>
            <li>Element a</li>
            <li>
              Element b
              <ol>
                <li>Element b1</li>
                <li>
                  Element b2
                  <ul>
                    <li>Element b2a</li>
                  </ul>
                </li>
              </ol>
            </li>
            <li>
              Element c
              <ul>
                <li>Element ca</li>
                <li>Element cb</li>
              </ul>
            </li>
          </ul>
        </li>
      </ul>
    </description>
    <url>https://example.com/stable-release</url>
  </release>
  <release version="1.2.0-dev" date="2024-06-25" type="development">
    <description>
      <h3>Fixed</h3>
      <ul>
        <li>
          Some
          <em>text</em>
          with
          <strong>highlighted</strong>
          elements ~~and~~ some
          <code>&lt;b>code&lt;/b></code>
        </li>
        <li>
          and some multiline code
          <pre>
            <code class="language-dart">const variable = 42;</code>
          </pre>
        </li>
      </ul>
    </description>
    <url>https://example.com/dev-release</url>
  </release>
  <release version="1.1.39" date="2024-01-11" type="stable">
    <description>
      <h3>Removed</h3>
      <ul>
        <li>Should &lt;be/> [escaped]</li>
        <li>
          Also here is a
          <a href="https://example.com">link</a>
        </li>
        <li>
          And a
          <img src="https://example.com" alt="picture"/>
        </li>
      </ul>
    </description>
  </release>
</releases>''';

const _testMetainfoXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<component>
  <id>test-id</id>
  <releases>
    <release version="1.0.0" date="2024-01-01" type="stable">
      <description>
        <h3>Added</h3>
        <ul>
          <li>added</li>
        </ul>
      </description>
    </release>
  </releases>
</component>''';
