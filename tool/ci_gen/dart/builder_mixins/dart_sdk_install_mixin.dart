import '../../common/builder_mixins/project_setup_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

mixin DartSdkInstallMixin on ProjectSetupBuilderMixin {
  @override
  Step createInstallSdkStep() => Step.uses(
        name: 'Install Dart-SDK '
            '(${Expression.create('inputs.dartSdkVersion')})',
        uses: 'dart-lang/setup-dart@v1.3',
        withArgs: {
          'sdk': Expression.create('inputs.dartSdkVersion'),
        },
      );
}
