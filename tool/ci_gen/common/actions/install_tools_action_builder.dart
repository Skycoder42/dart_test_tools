import '../../types/action.dart';
import '../../types/action_runs.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/input.dart';
import '../../types/step.dart';
import '../api/action_builder.dart';
import '../api/workflow_input.dart';
import '../contexts.dart';
import '../globals.dart';
import '../tools.dart';

class InstallToolsActionBuilder implements ActionBuilder {
  static const _actionName = 'install-tools';
  static const _withDartTestToolsInput = WorkflowInput(
    name: 'withDartTestTools',
    input: Input.action(
      required: false,
      defaultValue: 'false',
      description: 'Also install dart_test_tools as global dart tool.',
    ),
  );

  const InstallToolsActionBuilder();

  static Step step({
    StepId? id,
    String? name,
    Expression? ifExpression,
    bool? continueOnError,
    required bool withDartTestTools,
  }) => Step.uses(
    id: id,
    name: name ?? 'Install tools',
    ifExpression: ifExpression,
    uses: 'Skycoder42/dart_test_tools/.github/actions/$_actionName@main',
    continueOnError: continueOnError,
    withArgs: {_withDartTestToolsInput.name: withDartTestTools.toString()},
  );

  @override
  String get name => _actionName;

  @override
  Action build() {
    final inputContext = WorkflowInputContext();
    final withDartTestTools = inputContext(_withDartTestToolsInput);

    const setupDartInstallId = StepId('setup-dart-install');
    final dartVersionOutput = setupDartInstallId.output('dart-version');

    return Action(
      name: 'Install tools',
      description: 'Installs required operating system tools',
      inputs: inputContext.createInputs(),
      runs: ActionsRuns.composite([
        Step.run(
          id: setupDartInstallId,
          name: 'Setup dart install path',
          shell: 'pwsh',
          run:
              '''
\$ErrorActionPreference = "Stop"
\$dataHomePath = Join-Path \$env:RUNNER_TOOL_CACHE "dart"
Add-Content -Path \$Env:GITHUB_ENV -Value "DART_DATA_HOME=\$dataHomePath"
Add-Content -Path \$Env:GITHUB_PATH -Value (Join-Path \$dataHomePath "install" "bin")
${dartVersionOutput.pwshSetter('Get-Content (Join-Path (Split-Path (Split-Path (Get-Command dart).Source)) "version")', isCommand: true)}
''',
        ),
        Step.uses(
          name: 'Cache dart install tools',
          uses: Tools.actionsCache,
          withArgs: {
            'key': 'dart_tools-${Runner.os}-${dartVersionOutput.expression}',
            'path': '${Runner.toolCache}/dart/install',
          },
        ),
        Step.run(
          name: 'Install scoop',
          ifExpression: Runner.os.eq(const Expression.literal('Windows')),
          shell: 'pwsh',
          run: r'''
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
Join-Path (Resolve-Path ~).Path "scoop\shims" >> $Env:GITHUB_PATH
''',
        ),
        Step.run(
          name: 'Install yq (Windows)',
          ifExpression: Runner.os.eq(const Expression.literal('Windows')),
          run: 'scoop install yq',
          shell: 'pwsh',
        ),
        Step.run(
          name: 'Install coreutils (macOS)',
          ifExpression: Runner.os.eq(const Expression.literal('macOS')),
          run: r'''
brew install coreutils
echo "$(brew --prefix)/opt/coreutils/libexec/gnubin" >> $GITHUB_PATH
''',
          shell: 'bash',
        ),
        Step.run(
          name: 'Install dart_test_tools',
          ifExpression: withDartTestTools.eq(const Expression.literal('true')),
          run: 'dart install dart_test_tools ^$dartTestToolsVersion',
          shell: 'bash',
        ),
      ]),
    );
  }
}
