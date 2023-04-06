import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class PublishDebBuilder implements StepBuilder {
  final Expression releaseTag;

  const PublishDebBuilder({
    required this.releaseTag,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Upload debian package to release',
          uses: Tools.softpropsActionGhRelease,
          withArgs: <String, dynamic>{
            'tag_name': releaseTag.toString(),
            'files': 'deb/*.deb',
          },
        ),
      ];
}
