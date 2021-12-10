import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/input.dart';
import '../api/workflow_input.dart';

mixin PlatformsBuilderMixin {
  @protected
  List<String> get supportedPlatforms;

  @protected
  late final platformsInput = _platformsInputBuilder(supportedPlatforms);

  @protected
  Iterable<WorkflowInput> get platformsInputs => [platformsInput];

  @protected
  String shouldRunExpression(String platform) =>
      'contains(fromJSON(${platformsInput.expression}), $platform)';

  final _platformsInputBuilder = WorkflowInputBuilder(
    name: 'platforms',
    builder: (List<String> defaultPlatforms) => Input.json(
      required: false,
      defaultValue: defaultPlatforms,
      description: '''
A JSON-Formatted list of platforms that unit and integration tests should be run on.
By default, all platforms are active. The available platforms are:
${defaultPlatforms.map((p) => '- $p').join('\n')}
''',
    ),
  );
}
