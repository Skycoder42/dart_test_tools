import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';

@internal
class RemoveDirective extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addNamespaceDirective((node) {
      reporter
          .createChangeBuilder(
            message: 'Remove the ${_directiveKind(node)}',
            priority: 0,
          )
          .addDartFileEdit((builder) => builder.addDeletion(node.sourceRange));
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
