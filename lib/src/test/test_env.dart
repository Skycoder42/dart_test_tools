import 'package:dotenv/dotenv.dart' as dotenv;

abstract class TestEnv {
  static const defaultPath = '.env';

  TestEnv._();

  static Future<Map<String, String>> load([String path = defaultPath]) async {
    dotenv.load(path);
    return dotenv.env;
  }
}
