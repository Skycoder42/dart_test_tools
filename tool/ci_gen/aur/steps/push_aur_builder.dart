import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class PushAurBuilder implements StepBuilder {
  const PushAurBuilder();

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Stage package files',
          run: r'''
set -e
git add $(cat .files) .SRCINFO
git status --short
''',
          workingDirectory: 'aur',
        ),
        const Step.run(
          name: 'Create update commit',
          run: r'git commit -m "Update $(yq ".name" ../src/pubspec.yaml) '
              r'to version $(yq ".version" ../src/pubspec.yaml)"',
          workingDirectory: 'aur',
        ),
        const Step.run(
          name: 'Push update to AUR',
          run: 'git push',
          workingDirectory: 'aur',
        ),
        const Step.run(
          name: 'Clean up SSH key',
          ifExpression: Expression('always()'),
          run: r'shred -fzvu "$RUNNER_TEMP/ssh-key"',
        ),
      ];
}
