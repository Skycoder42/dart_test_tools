import '../../common/builders/sdk_job_builder.dart';
import '../../dart/builders/dart_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/strategy.dart';
import '../steps/compile_builder.dart';

class _CompileJobMatrix implements ICompileMatrix {
  @override
  final Expression host;
  @override
  final Expression target;

  String get hostName => host.value.split('.').last;
  String get targetName => target.value.split('.').last;

  const _CompileJobMatrix({
    required this.host,
    required this.target,
  });
}

class CompileJobBuilder extends SdkJobBuilder with DartSdkJobBuilderMixin {
  static const _matrix = _CompileJobMatrix(
    host: Expression('matrix.host'),
    target: Expression('matrix.target'),
  );

  @override
  JobId get id => const JobId('compile');

  final Expression hosts;
  final Expression targets;
  @override
  final Expression dartSdkVersion;
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;

  const CompileJobBuilder({
    required this.hosts,
    required this.targets,
    required this.dartSdkVersion,
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
  });

  @override
  Job build() => Job(
        name: 'Create compiled artifacts',
        strategy: Strategy(
          failFast: false,
          matrix: Matrix.expression(_matixExpression),
        ),
        runsOn: _matrix.host.toString(),
        steps: [
          ...buildSetupSdkSteps(),
          ...CompileBuilder(
            repository: repository,
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            matrix: _matrix,
            pubTool: pubTool,
            runTool: runTool,
          ).build()
        ],
      );

  Expression get _matrixJsonExpression =>
      const Expression.literal('{{"host":{0},"target":{1}}}');

  Expression get _matrixFormatExpression => Expression(
        "format(${_matrixJsonExpression.value}, ${hosts.value}, ${targets.value})",
      );

  Expression get _matixExpression =>
      Expression('fromJson(${_matrixFormatExpression.value})');
}
