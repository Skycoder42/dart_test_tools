@TestOn('dart-vm')
library pkgbuild_generator_test;

import 'dart:io';

// ignore: test_library_import
import 'package:dart_test_tools/aur.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml_writer/yaml_writer.dart';

void main() {
  late Directory testDir;
  late Directory srcDir;
  late Directory aurDir;

  late PkgBuildGenerator sut;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp();

    srcDir = await Directory.fromUri(testDir.uri.resolve('src')).create();
    aurDir = await Directory.fromUri(testDir.uri.resolve('aur')).create();

    sut = const PkgBuildGenerator();
  });

  tearDown(() async {
    await testDir.delete(recursive: true);
  });

  // ignore: avoid_positional_boolean_parameters
  Future<void> createSources(bool minimal) async {
    final writer = YamlWriter();
    final pubspecYaml = writer.write({
      'name': 'test_package',
      if (!minimal) 'description': 'This is a test package.',
      'version': '1.2.3-dev+5',
      'homepage': 'https://example.com/home',
      if (!minimal) 'repository': 'https://example.com/home/git/',
      'environment': {
        if (!minimal) 'sdk': '>=2.17.0 <3.0.0',
      },
      'executables': {
        'exe_1': null,
        if (!minimal) 'exe-two': 'exe_2',
      },
      'dev_dependencies': {
        if (!minimal) 'build_runner': '^2.2.0',
      },
      'aur': {
        'maintainer': 'Maintainer <maintainer@maintain.org>',
        if (!minimal) 'pkgname': 'custom_package',
        if (!minimal) 'pkgrel': 3,
        if (!minimal) 'tagPrefix': 'my-app/v',
        if (!minimal) 'epoch': 1,
        if (!minimal) 'license': 'MIT',
        if (!minimal)
          'depends': const [
            'dependency-a',
            'dependency-b',
            'dependency-c',
          ],
        if (!minimal) 'sourcesDir': r'test-package-sources-$pkgver/my_app',
        if (!minimal) 'binariesArchivePrefix': 'my-app',
        if (!minimal)
          'extraSources': const [
            {
              'name': 'extra-source.tar.gz',
              'url': 'https://example.com/extra/source.tar.gz',
            }
          ],
        if (!minimal) 'install': 'custom_package.install',
        if (!minimal)
          'files': const [
            {
              'source': 'config/config.json',
              'target': '/etc/config.json',
            },
            {
              'source': 'data/database.db',
              'target': r'/usr/share/$pkgname/core.db',
              'permissions': 600,
            },
            {
              'source': 'doc',
              'target': '/usr/doc',
              'recursive': true,
            },
            {
              'source': 'data/base-data',
              'target': r'/usr/share/$pkgname/base',
              'permissions': 755,
              'recursive': true,
            },
          ],
        if (!minimal) 'backup': const ['etc/config.json'],
        if (!minimal)
          'makedeb': {
            'depends': const [
              'dependency-x',
              'dependency-y',
              'dependency-z',
            ],
            'files': const [
              {
                'source': 'config/deb.json',
                'target': '/etc/config.json',
              },
              {
                'source': 'data/deb-data',
                'target': r'/usr/share/$pkgname/base',
                'permissions': 755,
                'recursive': true,
              },
            ],
            'backup': const ['/etc/config.json'],
          },
      },
    });

    await File.fromUri(srcDir.uri.resolve('pubspec.yaml'))
        .writeAsString(pubspecYaml);

    if (!minimal) {
      await File.fromUri(srcDir.uri.resolve('CHANGELOG.md'))
          .writeAsString('# The Changelog');
      await File.fromUri(srcDir.uri.resolve('LICENSE.txt'))
          .writeAsString('THE LICENSE');
      await File.fromUri(srcDir.uri.resolve('custom_package.install'))
          .writeAsString('install');
    }
  }

  group('aur', () {
    test('generates minimal PKGBUILD file', () async {
      await createSources(true);

      await expectLater(
        () =>
            sut.generatePkgbuild(sourceDirectory: srcDir, aurDirectory: aurDir),
        prints('PKGBUILD\n'),
      );

      final aurFiles = aurDir.listSync();
      expect(aurFiles, hasLength(1));
      expect(aurFiles, contains(hasBaseName('PKGBUILD')));

      final pkgBuildContent = await File.fromUri(
        aurDir.uri.resolve('PKGBUILD'),
      ).readAsString();

      expect(pkgBuildContent, _minimalPkgbuild);
    });

    test('generates full PKGBUILD file', () async {
      await createSources(false);

      await expectLater(
        () =>
            sut.generatePkgbuild(sourceDirectory: srcDir, aurDirectory: aurDir),
        prints('PKGBUILD\ncustom_package.install\nCHANGELOG.md\n'),
      );

      final aurFiles = aurDir.listSync();
      expect(aurFiles, hasLength(3));
      expect(aurFiles, contains(hasBaseName('PKGBUILD')));
      expect(aurFiles, contains(hasBaseName('CHANGELOG.md')));
      expect(aurFiles, contains(hasBaseName('custom_package.install')));

      final pkgBuildContent = await File.fromUri(
        aurDir.uri.resolve('PKGBUILD'),
      ).readAsString();

      expect(pkgBuildContent, _fullPkgbuild);

      final changelogContent = await File.fromUri(
        aurDir.uri.resolve('CHANGELOG.md'),
      ).readAsString();

      expect(changelogContent, '# The Changelog');

      final installContent = await File.fromUri(
        aurDir.uri.resolve('custom_package.install'),
      ).readAsString();

      expect(installContent, 'install');
    });
  });

  group('deb', () {
    test('generates minimal PKGBUILD file', () async {
      await createSources(true);

      await expectLater(
        () => sut.generatePkgbuild(
          sourceDirectory: srcDir,
          aurDirectory: aurDir,
          makedebMode: true,
        ),
        prints('PKGBUILD\n'),
      );

      final aurFiles = aurDir.listSync();
      expect(aurFiles, hasLength(1));
      expect(aurFiles, contains(hasBaseName('PKGBUILD')));

      final pkgBuildContent = await File.fromUri(
        aurDir.uri.resolve('PKGBUILD'),
      ).readAsString();

      expect(pkgBuildContent, _minimalDebPkgbuild);
    });

    test('generates full PKGBUILD file', () async {
      await createSources(false);

      await expectLater(
        () => sut.generatePkgbuild(
          sourceDirectory: srcDir,
          aurDirectory: aurDir,
          makedebMode: true,
        ),
        prints('PKGBUILD\ncustom_package.install\nCHANGELOG.md\n'),
      );

      final aurFiles = aurDir.listSync();
      expect(aurFiles, hasLength(3));
      expect(aurFiles, contains(hasBaseName('PKGBUILD')));
      expect(aurFiles, contains(hasBaseName('CHANGELOG.md')));
      expect(aurFiles, contains(hasBaseName('custom_package.install')));

      final pkgBuildContent = await File.fromUri(
        aurDir.uri.resolve('PKGBUILD'),
      ).readAsString();

      expect(pkgBuildContent, _fullDebPkgbuild);

      final changelogContent = await File.fromUri(
        aurDir.uri.resolve('CHANGELOG.md'),
      ).readAsString();

      expect(changelogContent, '# The Changelog');

      final installContent = await File.fromUri(
        aurDir.uri.resolve('custom_package.install'),
      ).readAsString();

      expect(installContent, 'install');
    });
  });
}

Matcher hasBaseName(String name) =>
    predicate<File>((f) => basename(f.path) == name);

const _minimalPkgbuild = r'''
# Maintainer: Maintainer <maintainer@maintain.org>
pkgbase='test_package'
pkgname=('test_package' 'test_package-debug')
pkgver='1.2.3_dev+5'
pkgrel=1
arch=('x86_64')
url='https://example.com/home'
license=('custom')
depends=()
source=("sources.tar.gz::https://example.com/home/archive/refs/tags/v1.2.3-dev+5.tar.gz"
        "bin.tar.xz::https://example.com/home/releases/download/v1.2.3-dev+5/binaries-linux.tar.xz"
        "debug.tar.xz::https://example.com/home/releases/download/v1.2.3-dev+5/binaries-linux-debug-symbols.tar.xz")
b2sums=('PLACEHOLDER'
        'PLACEHOLDER'
        'PLACEHOLDER')
options=('!strip')
_pkgdir="$pkgbase-$pkgver"

package_test_package() {
  install -D -m755 'exe_1' "$pkgdir/usr/bin/"'exe_1'
  cd "$_pkgdir"
}

package_test_package-debug() {
  install -D -m644 'exe_1.sym' "$pkgdir/usr/lib/debug/usr/bin/"'exe_1'.sym
  cd "$_pkgdir"
  find . -exec install -D -m644 "{}" "$pkgdir/usr/src/debug/$pkgbase/{}" \;
}

''';

const _fullPkgbuild = r'''
# Maintainer: Maintainer <maintainer@maintain.org>
pkgbase='custom_package'
pkgname=('custom_package' 'custom_package-debug')
pkgdesc='This is a test package.'
pkgver='1.2.3_dev+5'
pkgrel=3
epoch=1
arch=('x86_64')
url='https://example.com/home'
license=('MIT')
depends=('dependency-a' 'dependency-b' 'dependency-c')
source=("sources.tar.gz::https://example.com/home/git/archive/refs/tags/my-app%2Fv1.2.3-dev+5.tar.gz"
        "bin.tar.xz::https://example.com/home/git/releases/download/my-app%2Fv1.2.3-dev+5/my-app-linux.tar.xz"
        "debug.tar.xz::https://example.com/home/git/releases/download/my-app%2Fv1.2.3-dev+5/my-app-linux-debug-symbols.tar.xz"
        "extra-source.tar.gz::https://example.com/extra/source.tar.gz")
b2sums=('PLACEHOLDER'
        'PLACEHOLDER'
        'PLACEHOLDER'
        'PLACEHOLDER')
install='custom_package.install'
changelog='CHANGELOG.md'
backup=('etc/config.json')
options=('!strip')
_pkgdir="test-package-sources-$pkgver/my_app"

package_custom_package() {
  install -D -m755 'bin/exe_1' "$pkgdir/usr/bin/"'exe_1'
  install -D -m755 'bin/exe-two' "$pkgdir/usr/bin/"'exe-two'
  cd "$_pkgdir"
  install -D -m644 'config/config.json' "$pkgdir/etc/config.json"
  install -D -m600 'data/database.db' "$pkgdir/usr/share/$pkgname/core.db"
  pushd 'doc'
  find . -type f -exec install -D -m644 "{}" "$pkgdir/usr/doc/{}" \;
  popd
  pushd 'data/base-data'
  find . -type f -exec install -D -m755 "{}" "$pkgdir/usr/share/$pkgname/base/{}" \;
  popd
  install -D -m644 'LICENSE.txt' "$pkgdir/usr/share/licenses/$pkgname/"'LICENSE.txt'
}

package_custom_package-debug() {
  install -D -m644 'debug/exe_1.sym' "$pkgdir/usr/lib/debug/usr/bin/"'exe_1'.sym
  install -D -m644 'debug/exe-two.sym' "$pkgdir/usr/lib/debug/usr/bin/"'exe-two'.sym
  cd "$_pkgdir"
  find . -exec install -D -m644 "{}" "$pkgdir/usr/src/debug/$pkgbase/{}" \;
}

''';

const _minimalDebPkgbuild = r'''
# Maintainer: Maintainer <maintainer@maintain.org>
pkgbase='test_package'
pkgname=('test_package' 'test_package-debug')
pkgver='1.2.3_dev+5'
pkgrel=1
arch=('amd64')
url='https://example.com/home'
license=('custom')
depends=()
source=("sources.tar.gz::https://example.com/home/archive/refs/tags/v1.2.3-dev+5.tar.gz"
        "bin.tar.xz::https://example.com/home/releases/download/v1.2.3-dev+5/binaries-linux.tar.xz"
        "debug.tar.xz::https://example.com/home/releases/download/v1.2.3-dev+5/binaries-linux-debug-symbols.tar.xz")
b2sums=('PLACEHOLDER'
        'PLACEHOLDER'
        'PLACEHOLDER')
options=('!strip')
extensions=('zipman')
_pkgdir="$pkgbase-$pkgver"

package_test_package() {
  install -D -m755 'exe_1' "$pkgdir/usr/bin/"'exe_1'
  cd "$_pkgdir"
}

package_test_package-debug() {
  install -D -m644 'exe_1.sym' "$pkgdir/usr/lib/debug/usr/bin/"'exe_1'.sym
  cd "$_pkgdir"
  find . -exec install -D -m644 "{}" "$pkgdir/usr/src/debug/$pkgbase/{}" \;
}

''';

const _fullDebPkgbuild = r'''
# Maintainer: Maintainer <maintainer@maintain.org>
pkgbase='custom_package'
pkgname=('custom_package' 'custom_package-debug')
pkgdesc='This is a test package.'
pkgver='1.2.3_dev+5'
pkgrel=3
epoch=1
arch=('amd64')
url='https://example.com/home'
license=('MIT')
depends=('dependency-x' 'dependency-y' 'dependency-z')
source=("sources.tar.gz::https://example.com/home/git/archive/refs/tags/my-app%2Fv1.2.3-dev+5.tar.gz"
        "bin.tar.xz::https://example.com/home/git/releases/download/my-app%2Fv1.2.3-dev+5/my-app-linux.tar.xz"
        "debug.tar.xz::https://example.com/home/git/releases/download/my-app%2Fv1.2.3-dev+5/my-app-linux-debug-symbols.tar.xz"
        "extra-source.tar.gz::https://example.com/extra/source.tar.gz")
b2sums=('PLACEHOLDER'
        'PLACEHOLDER'
        'PLACEHOLDER'
        'PLACEHOLDER')
install='custom_package.install'
changelog='CHANGELOG.md'
backup=('/etc/config.json')
options=('!strip')
extensions=('zipman')
_pkgdir="test-package-sources-$pkgver/my_app"

package_custom_package() {
  install -D -m755 'bin/exe_1' "$pkgdir/usr/bin/"'exe_1'
  install -D -m755 'bin/exe-two' "$pkgdir/usr/bin/"'exe-two'
  cd "$_pkgdir"
  install -D -m644 'config/deb.json' "$pkgdir/etc/config.json"
  pushd 'data/deb-data'
  find . -type f -exec install -D -m755 "{}" "$pkgdir/usr/share/$pkgname/base/{}" \;
  popd
  install -D -m644 'LICENSE.txt' "$pkgdir/usr/share/licenses/$pkgname/"'LICENSE.txt'
}

package_custom_package-debug() {
  install -D -m644 'debug/exe_1.sym' "$pkgdir/usr/lib/debug/usr/bin/"'exe_1'.sym
  install -D -m644 'debug/exe-two.sym' "$pkgdir/usr/lib/debug/usr/bin/"'exe-two'.sym
  cd "$_pkgdir"
  find . -exec install -D -m644 "{}" "$pkgdir/usr/src/debug/$pkgbase/{}" \;
}

''';
