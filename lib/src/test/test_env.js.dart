import 'package:test/test.dart';

abstract class TestEnv {
  static const defaultPath = '.env';

  static const _vmCode = '''
import 'dart:io';

import 'package:dart_test_tools/src/test/test_env.dart';
import 'package:stream_channel/stream_channel.dart';

Future<void> hybridMain(StreamChannel channel, Object? message) async {
  final env = await TestEnv.load(
    message is String ? message : TestEnv.defaultPath,
  );
  channel.sink.add(env);
}
''';

  TestEnv._();

  static Future<Map<String, String>> load([String path = defaultPath]) async {
    final channel = spawnHybridCode(
      _vmCode,
      message: path,
    );
    final dynamic env = await channel.stream.first;
    return env is Map ? Map.from(env) : const {};
  }
}
