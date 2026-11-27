import 'package:dart_test_tools/src/pub/models/pub/deps/dependencies.dart';
import 'package:dart_test_tools/src/pub/models/pub/outdated/outdated_info.dart';
import 'package:dart_test_tools/src/pub/models/pub/workspace/workspaces.dart';
import 'package:dart_test_tools/src/pub/models/renovate_config.dart';
import 'package:dart_test_tools/src/pub/pub_wrapper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

@GenerateNiceMocks([MockSpec<PubWrapper>(), MockSpec<PubWrapperFactory>()])
export 'mocks.mocks.dart';

void provideMockDummies() {
  provideDummy(const Workspaces(packages: []));
  provideDummy(const OutdatedInfo(packages: []));
  provideDummy(const Dependencies(root: 'dummy', packages: [], sdks: []));
  provideDummy(const RenovateConfig());
  provideDummy(Pubspec('dummy'));
}
