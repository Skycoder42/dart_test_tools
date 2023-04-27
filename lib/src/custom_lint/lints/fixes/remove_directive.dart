import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RemoveDirective extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addNamespaceDirective((node) {
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Remove the ${_directiveKind(node)}',
        priority: 0,
      );
      changeBuilder.addDartFileEdit(
        (builder) => builder.addDeletion(node.sourceRange),
      );
    });
  }

  String _directiveKind(NamespaceDirective directive) {
    if (directive is ImportDirective) {
      return 'import';
    } else if (directive is ExportDirective) {
      return 'export';
    } else {
      return 'directive';
    }
  }
}
