import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_test_tools/src/custom_lint/lints/freezed_classes_must_be_sealed.dart';

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
        final builder = reporter.createChangeBuilder(
          message: 'Add sealed keyword to class definition.',
          priority: 0,
        );

        builder.addDartFileEdit((builder) {
          builder.addInsertion(node.classKeyword.offset, (builder) {
            builder.write('sealed ');
          });
        });
      }
    });
  }
}
