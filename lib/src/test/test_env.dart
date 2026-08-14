import 'package:dotenv/dotenv.dart';

abstract class TestEnv {
  static const defaultPath = '.env';

  new _();

  static Future<Map<String, String>> load([String path = defaultPath]) async {
    final env = DotEnv()..load([path]);
    // ignore: invalid_use_of_visible_for_testing_member to keep api for now
    return env.map;
  }
}
