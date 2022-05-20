import 'package:dotenv/dotenv.dart';

abstract class TestEnv {
  static const defaultPath = '.env';

  TestEnv._();

  static Future<Map<String, String>> load([String path = defaultPath]) async {
    final env = DotEnv()..load([path]);
    return env.map;
  }
}
