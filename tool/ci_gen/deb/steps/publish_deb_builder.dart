import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class PublishDebBuilder implements StepBuilder {
  final Expression tagPrefix;
  final Expression version;

  const PublishDebBuilder({
    required this.tagPrefix,
    required this.version,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Upload debian package to release',
          uses: Tools.softpropsActionGhRelease,
          withArgs: <String, dynamic>{
            'tag_name': '$tagPrefix$version',
            'files': 'deb/*.deb',
          },
        ),
      ];
}
