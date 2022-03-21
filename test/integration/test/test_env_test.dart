// ignore: test_library_import
import 'package:dart_test_tools/test.dart';
import 'package:test/test.dart';

void main() {
  test('loads correct env vars from .env file', () async {
    final env = await TestEnv.load();

    expect(env, containsPair('TEST_KEY', 'test-value'));
  });
}
