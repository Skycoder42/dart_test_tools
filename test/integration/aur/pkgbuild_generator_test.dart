import 'dart:io';

import 'package:dart_test_tools/src/aur/pkgbuild_generator.dart';
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

  Future<void> _createSources(bool minimal) async {
    final writer = YAMLWriter();
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
        if (!minimal) 'epoch': 1,
        if (!minimal) 'license': 'MIT',
        if (!minimal)
          'depends': const [
            'dependency-a',
            'dependency-b',
            'dependency-c',
          ],
        if (!minimal)
          'install': const [
            {
              'source': 'config/config.json',
              'target': '/etc/config.json',
            },
            {
              'source': 'data/database.db',
              'target': r'/usr/share/$pkgname/core.db',
              'permissions': 600,
            },
          ],
      },
    });

    await File.fromUri(srcDir.uri.resolve('pubspec.yaml'))
        .writeAsString(pubspecYaml);

    if (!minimal) {
      await File.fromUri(srcDir.uri.resolve('CHANGELOG.md'))
          .writeAsString('# The Changelog');
      await File.fromUri(srcDir.uri.resolve('LICENSE.txt'))
          .writeAsString('THE LICENSE');
    }
  }

  test('generates minimal PKGBUILD file', () async {
    await _createSources(true);

    await sut.generatePkgbuild(sourceDirectory: srcDir, aurDirectory: aurDir);

    final aurFiles = aurDir.listSync();
    expect(aurFiles, hasLength(1));
    expect(aurFiles, contains(hasBaseName('PKGBUILD')));

    final pkgBuildContent = await File.fromUri(
      aurDir.uri.resolve('PKGBUILD'),
    ).readAsString();

    expect(pkgBuildContent, _minimalPkgbuild);
  });

  test('generates full PKGBUILD file', () async {
    await _createSources(false);

    await sut.generatePkgbuild(sourceDirectory: srcDir, aurDirectory: aurDir);

    final aurFiles = aurDir.listSync();
    expect(aurFiles, hasLength(2));
    expect(aurFiles, contains(hasBaseName('PKGBUILD')));
    expect(aurFiles, contains(hasBaseName('CHANGELOG.md')));

    final pkgBuildContent = await File.fromUri(
      aurDir.uri.resolve('PKGBUILD'),
    ).readAsString();

    expect(pkgBuildContent, _fullPkgbuild);

    final changelogContent = await File.fromUri(
      aurDir.uri.resolve('CHANGELOG.md'),
    ).readAsString();

    expect(changelogContent, '# The Changelog');
  });
}

Matcher hasBaseName(String name) =>
    predicate<File>((f) => basename(f.path) == name);

const _minimalPkgbuild = r'''
# Maintainer: Maintainer <maintainer@maintain.org>
pkgname='test_package'
# pkgdesc=
pkgver='1.2.3_dev+5'
pkgrel=1
# epoch=
arch=('x86_64' 'i686' 'armv7h' 'aarch64')
url='https://example.com/home'
license=('custom')
depends=()
makedepends=('dart')
_pkgdir='test_package-1.2.3-dev+5'
source=("$_pkgdir.tar.gz::https://example.com/home/archive/refs/tags/v1.2.3-dev+5.tar.gz")
b2sums=('PLACEHOLDER')
# changelog=

prepare() {
  cd "$_pkgdir"
  dart pub get
}

build() {
  cd "$_pkgdir"
  dart compile exe -o 'bin/exe_1' -S 'bin/exe_1.symbols' 'bin/exe_1.dart'
}

check() {
  cd "$_pkgdir"
  dart analyze --no-fatal-warnings
  dart test
}

package() {
  cd "$_pkgdir"
  install -D -m755 'bin/exe_1' "$pkgdir/usr/bin/"'exe_1'
}

''';

const _fullPkgbuild = r'''
# Maintainer: Maintainer <maintainer@maintain.org>
pkgname='custom_package'
pkgdesc='This is a test package.'
pkgver='1.2.3_dev+5'
pkgrel=3
epoch=1
arch=('x86_64' 'i686' 'armv7h' 'aarch64')
url='https://example.com/home'
license=('MIT')
depends=('dependency-a' 'dependency-b' 'dependency-c')
makedepends=('dart>=2.17.0' 'dart<3.0.0')
_pkgdir='test_package-1.2.3-dev+5'
source=("$_pkgdir.tar.gz::https://example.com/home/git/archive/refs/tags/v1.2.3-dev+5.tar.gz")
b2sums=('PLACEHOLDER')
changelog='CHANGELOG.md'

prepare() {
  cd "$_pkgdir"
  dart pub get
}

build() {
  cd "$_pkgdir"
  dart run build_runner build --delete-conflicting-outputs --release
  dart compile exe -o 'bin/exe_1' -S 'bin/exe_1.symbols' 'bin/exe_1.dart'
  dart compile exe -o 'bin/exe-two' -S 'bin/exe-two.symbols' 'bin/exe_2.dart'
}

check() {
  cd "$_pkgdir"
  dart analyze --no-fatal-warnings
  dart test
}

package() {
  cd "$_pkgdir"
  install -D -m755 'bin/exe_1' "$pkgdir/usr/bin/"'exe_1'
  install -D -m755 'bin/exe-two' "$pkgdir/usr/bin/"'exe-two'
  install -D -m644 'config/config.json' "$pkgdir/etc/config.json"
  install -D -m600 'data/database.db' "$pkgdir/usr/share/$pkgname/core.db"
  install -D -m644 'LICENSE.txt' "$pkgdir/usr/share/licenses/$pkgname/"'LICENSE.txt'
}

''';
