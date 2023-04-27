import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_test_tools/src/custom_lint/lints/fixes/remove_directive.dart';
import 'package:dart_test_tools/src/lint/common/context_root_extensions.dart';

class NoSelfPackageImports extends DartLintRule {
  static const _code = LintCode(
    name: 'no_self_package_imports',
    problemMessage: 'Libraries in lib/src, test or tool should not '
        'import package library files from lib.',
    correctionMessage: 'Import the library from the src folder instead.',
    errorSeverity: ErrorSeverity.INFO,
  );

  const NoSelfPackageImports() : super(code: _code);

  @override
  List<String> get filesToAnalyze => [
        'lib/src/**.dart',
        'test/**.dart',
        'tool/**.dart',
      ];

  @override
  Future<void> run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) async {
    final resolveUnitResult = await resolver.getResolvedUnitResult();
    final contextRoot = resolveUnitResult.session.analysisContext.contextRoot;

    context.registry.addNamespaceDirective((node) {
      if (!_directiveIsValid(contextRoot, node)) {
        reporter.reportErrorForNode(_code, node.uri);
      }

      for (final configuration in node.configurations) {
        if (!_configurationIsValid(contextRoot, configuration)) {
          reporter.reportErrorForNode(_code, configuration.uri);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [
        RemoveDirective(),
      ];

  bool _directiveIsValid(
    ContextRoot contextRoot,
    NamespaceDirective directive,
  ) {
    final importUri = _directiveUri(directive);
    if (importUri is! DirectiveUriWithSource) {
      return true;
    }

    if (_directiveSourceIsValid(contextRoot, importUri)) {
      return true;
    }

    return false;
  }

  bool _configurationIsValid(
    ContextRoot contextRoot,
    Configuration configuration,
  ) {
    final resolvedUri = configuration.resolvedUri;
    if (resolvedUri is! DirectiveUriWithSource) {
      return true;
    }

    if (_directiveSourceIsValid(contextRoot, resolvedUri)) {
      return true;
    }

    return false;
  }

  bool _directiveSourceIsValid(
    ContextRoot contextRoot,
    DirectiveUriWithSource directiveUri,
  ) {
    final source = directiveUri.source.fullName;

    // accept package imports of different packages
    if (!contextRoot.lib.contains(source)) {
      return true;
    }

    // accept package imports that import from "src"
    if (contextRoot.src.contains(source)) {
      return true;
    }

    return false;
  }

  DirectiveUri? _directiveUri(NamespaceDirective directive) {
    if (directive is ImportDirective) {
      return directive.element?.uri;
    } else if (directive is ExportDirective) {
      return directive.element?.uri;
    } else {
      return null;
    }
  }
}
