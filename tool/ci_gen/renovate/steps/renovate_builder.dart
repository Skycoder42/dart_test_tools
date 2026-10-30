import '../../common/actions/install_tools_action_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/tools.dart';
import '../../types/env.dart';
import '../../types/step.dart';

base mixin RenovateConfig on JobConfig {
  late final flutterCompat = inputContext(WorkflowInputs.flutterCompat);
}

class const RenovateBuilder({required final RenovateConfig config})
    implements StepBuilder {
  static const _repositoryPath = 'repo';
  static const _toolsPath = 'dart_test_tools';
  // tool/renovate/package.json and its lockfile pin the Renovate version (and
  // the node version via engines). This repository's own Renovate updates them.
  static const _renovateDir = 'tool/renovate';
  static const _renovatePath = '$_toolsPath/$_renovateDir';
  static const _cachePath = '/tmp/renovate/cache/renovate/repository';
  static const _cacheKeyPrefix = 'renovate-cache-';

  // The identity behind GITHUB_TOKEN (41898282 is the user id of
  // github-actions[bot]). Renovate commits with the token anyway, but only
  // keeps updating branches whose last commit author matches its git author.
  static const _gitAuthor =
      'github-actions[bot] '
      '<41898282+github-actions[bot]@users.noreply.github.com>';

  static final _configPath = '${Runner.temp}/renovate-config.json';
  static final _cacheKey =
      '$_cacheKeyPrefix${Github.runId}-${Github.runAttempt}';

  @override
  Iterable<Step> build() sync* {
    yield* _setup();
    yield* _writeConfig();
    yield* _runRenovate();
  }

  Iterable<Step> _setup() sync* {
    yield InstallToolsActionBuilder.step(withDartTestTools: true);
    yield* const CheckoutBuilder(
      repository: .fake('Skycoder42/dart_test_tools'),
      gitRef: .fake('main'),
      path: _toolsPath,
      sparseCheckout: _renovateDir,
    ).build();
    yield Step.uses(
      name: 'Install Node.js',
      uses: Tools.actionsSetupNode,
      withArgs: const <String, dynamic>{
        'node-version-file': '$_renovatePath/package.json',
        'cache': 'npm',
        'cache-dependency-path': '$_renovatePath/package-lock.json',
      },
    );
    yield const Step.run(
      name: 'Install Renovate',
      run: 'npm ci',
      workingDirectory: _renovatePath,
    );
    yield* const CheckoutBuilder(
      path: _repositoryPath,
      persistCredentials: .value(false),
    ).build();
  }

  Iterable<Step> _writeConfig() sync* {
    final flutterCompatOption = Functions.case$([
      (config.flutterCompat, const .value('--flutter-compat')),
    ], const .value('--no-flutter-compat'));
    yield Step.run(
      name: 'Write Renovate global config',
      run:
          'renovate-config '
          "--repository '$_repositoryPath' "
          '$flutterCompatOption '
          "--output '$_configPath'",
    );
  }

  Iterable<Step> _runRenovate() sync* {
    yield Step.uses(
      name: 'Restore Renovate repository cache',
      uses: Tools.actionsCacheRestore,
      withArgs: <String, dynamic>{
        'path': _cachePath,
        'key': _cacheKey,
        'restore-keys': _cacheKeyPrefix,
      },
    );
    yield Step.run(
      name: 'Run Renovate',
      run: 'node_modules/.bin/renovate',
      workingDirectory: _renovatePath,
      env: Env({
        'RENOVATE_TOKEN': Github.token.toString(),
        'RENOVATE_CONFIG_FILE': _configPath,
        'RENOVATE_REPOSITORIES': Github.repository.toString(),
        'RENOVATE_REPOSITORY_CACHE': 'enabled',
        'RENOVATE_REVIEWERS': Github.repositoryOwner.toString(),
        'RENOVATE_GIT_AUTHOR': _gitAuthor,
        'LOG_LEVEL': 'info',
      }),
    );
    yield Step.uses(
      name: 'Save Renovate repository cache',
      ifExpression: Functions.always,
      uses: Tools.actionsCacheSave,
      withArgs: <String, dynamic>{'path': _cachePath, 'key': _cacheKey},
    );
  }
}
