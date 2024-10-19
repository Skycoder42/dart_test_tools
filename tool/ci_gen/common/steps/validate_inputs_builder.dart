import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class ValidateInputsBuilder implements StepBuilder {
  final Map<String, Expression> inputs;

  const ValidateInputsBuilder(this.inputs);

  @override
  Iterable<Step> build() => [
        for (final MapEntry(key: name, value: input) in inputs.entries)
          Step.run(
            name: '[Validate Inputs] Ensure $name is set',
            run: '''
if [[ '$input' == '' ]]; then
  echo '::error::Platform is enabled, but required input $name is not set'
  exit 1
fi
''',
            shell: 'bash',
          ),
      ];
}
