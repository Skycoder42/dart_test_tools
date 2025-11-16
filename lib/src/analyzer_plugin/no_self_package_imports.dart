import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

@internal
class NoSelfPackageImports extends AnalysisRule {
  static const _code = LintCode(
    'no_self_package_imports',
    'Libraries in lib/src, test or tool should not '
        'import package library files from lib.',
    correctionMessage: 'Import the library from the src folder instead.',
  );

  final _logger = Logger('$NoSelfPackageImports');

  NoSelfPackageImports()
    : super(name: _code.name, description: _code.problemMessage);

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!_shouldScan(context)) {
      return;
    }

    _logger.fine('Scanning ${context.definingUnit.file}:');
    final visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }

  bool _shouldScan(RuleContext context) {
    final root = context.package?.root;
    if (root == null) {
      return false;
    }

    final isInLibSrc = root
        .getChildAssumingFolder('lib')
        .getChildAssumingFolder('src')
        .contains(context.definingUnit.file.path);
    final isInTest = context.isInTestDirectory;
    final isInTool = root
        .getChildAssumingFolder('tool')
        .contains(context.definingUnit.file.path);
    return isInLibSrc || isInTest || isInTool;
  }

  // @override
  // void run(
  //   CustomLintResolver resolver,
  //   DiagnosticReporter reporter,
  //   CustomLintContext context,
  // ) {
  //   context.registry.addNamespaceDirective((node) {
  //     final contextRoot = _import(
  //       node,
  //     )?.libraryFragment.element.session.analysisContext.contextRoot;
  //     if (contextRoot == null) {
  //       print('WARNING: Unable to resolve context root for ${resolver.path}');
  //       return;
  //     }

  //     if (!_directiveIsValid(contextRoot, node)) {
  //       reporter.atNode(node.uri, _code);
  //     }

  //     for (final configuration in node.configurations) {
  //       if (!_configurationIsValid(contextRoot, configuration)) {
  //         reporter.atNode(configuration.uri, _code);
  //       }
  //     }
  //   });
  // }

  // @override
  // List<Fix> getFixes() => [RemoveDirective()];

  // bool _configurationIsValid(
  //   ContextRoot contextRoot,
  //   Configuration configuration,
  // ) {
  //   final resolvedUri = configuration.resolvedUri;
  //   if (resolvedUri is! DirectiveUriWithSource) {
  //     return true;
  //   }

  //   if (_directiveSourceIsValid(contextRoot, resolvedUri)) {
  //     return true;
  //   }

  //   return false;
  // }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoSelfPackageImports _rule;
  final RuleContext _context;

  const _Visitor(this._rule, this._context);

  @override
  void visitImportDirective(ImportDirective node) =>
      _scanDirective(node, node.libraryImport?.uri);

  @override
  void visitExportDirective(ExportDirective node) =>
      _scanDirective(node, node.libraryExport?.uri);

  void _scanDirective(NamespaceDirective node, DirectiveUri? uri) {
    if (!_directiveIsValid(uri)) {
      _rule.reportAtNode(node);
    }

    for (final configuration in node.configurations) {
      if (!_directiveIsValid(configuration.resolvedUri)) {
        _rule.reportAtNode(node);
      }
    }
  }

  bool _directiveIsValid(DirectiveUri? uri) {
    if (uri is! DirectiveUriWithSource) {
      return true;
    }

    // only scan import of the analyzed package
    final belongsToPackage = _context.package?.contains(uri.source) ?? false;
    if (!belongsToPackage) {
      return true;
    }

    // ignore imports from lib/src
    final srcDir = _context.package?.root
        .getChildAssumingFolder('lib')
        .getChildAssumingFolder('src');
    if (srcDir?.contains(uri.source.fullName) ?? false) {
      _rule._logger.finest('${uri.relativeUriString}: OK');
      return true;
    }

    _rule._logger.finest('${uri.relativeUriString}: FAIL');
    return false;
  }
}
