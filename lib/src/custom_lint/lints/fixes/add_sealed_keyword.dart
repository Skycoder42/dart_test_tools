import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../freezed_classes_must_be_sealed.dart';

class FreezedClassesMustBeSealedFix extends DartFix {
  FreezedClassesMustBeSealedFix();

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((node) {
      if (node.isUnsealedFreezed) {
        reporter
            .createChangeBuilder(
              message: 'Add sealed keyword to class definition.',
              priority: 0,
            )
            .addDartFileEdit((builder) {
              builder.addInsertion(node.classKeyword.offset, (builder) {
                builder.write('sealed ');
              });
            });
      }
    });
  }
}
