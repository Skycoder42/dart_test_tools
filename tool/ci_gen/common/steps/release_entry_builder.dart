import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class ReleaseEntryBuilder implements StepBuilder {
  final Expression tag;
  final Expression name;
  final Expression body;
  final Expression? ref;
  final Expression? versionUpdate;
  final String? files;
  final bool bodyAsFile;

  const ReleaseEntryBuilder({
    required this.tag,
    required this.name,
    required this.body,
    this.ref,
    this.versionUpdate,
    this.files,
    this.bodyAsFile = false,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Create Release',
          ifExpression: versionUpdate?.eq(const Expression.literal('true')),
          uses: Tools.softpropsActionGhRelease,
          withArgs: <String, dynamic>{
            'tag_name': tag.toString(),
            'name': name.toString(),
            if (bodyAsFile)
              'body_path': body.toString()
            else
              'body': body.toString(),
            if (files != null) 'files': files,
            if (ref != null) 'target_commitish': ref.toString(),
          },
        ),
      ];
}
