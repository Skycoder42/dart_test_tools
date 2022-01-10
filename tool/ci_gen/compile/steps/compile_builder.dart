import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

abstract class ICompileMatrix {
  Expression get target;
  Expression get host;
}

class CompileBuilder implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final ICompileMatrix matrix;
  final String pubTool;
  final String runTool;

  CompileBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.matrix,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Compile ${matrix.target}',
          run: "dart compile exe 'bin/${matrix.target}.dart'",
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Upload compiled ${matrix.target}.exe',
          uses: 'actions/upload-artifact@v2',
          withArgs: {
            'name': '${matrix.target}-${matrix.host}.exe',
            'path': '$workingDirectory/bin/${matrix.target}.exe',
          },
        ),
      ];
}
