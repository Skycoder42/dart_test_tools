import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:meta/meta.dart';

@internal
class NoSelfPackageImports extends AnalysisRule {
  static const _code = LintCode(
    'no_self_package_imports',
    'Libraries in lib/src, test or tool should not '
        'import package library files from lib.',
    correctionMessage: 'Import the library from the src folder instead.',
  );

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
    final hasIntegrationFolder = context.definingUnit.file
        .toUri()
        .pathSegments
        .contains('integration');

    return isInLibSrc || (isInTest && !hasIntegrationFolder) || isInTool;
  }
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
    if (!_directiveIsAllowed(uri)) {
      _rule.reportAtNode(node);
    }

    for (final configuration in node.configurations) {
      if (!_directiveIsAllowed(configuration.resolvedUri)) {
        _rule.reportAtNode(node);
      }
    }
  }

  bool _directiveIsAllowed(DirectiveUri? uri) {
    if (uri is! DirectiveUriWithSource) {
      return true;
    }

    // only scan imports that belong to the analyzed package
    final belongsToPackage = _context.package?.contains(uri.source) ?? false;
    if (!belongsToPackage) {
      return true;
    }

    // disallowed imports are all from lib
    final libDir = _context.package?.root.getChildAssumingFolder('lib');
    if (!(libDir?.contains(uri.source.fullName) ?? false)) {
      return true;
    }

    // ... excluding lib/src
    final srcDir = libDir?.getChildAssumingFolder('src');
    if (srcDir?.contains(uri.source.fullName) ?? false) {
      return true;
    }

    // ... excluding lib/gen
    final genDir = libDir?.getChildAssumingFolder('gen');
    if (genDir?.contains(uri.source.fullName) ?? false) {
      return true;
    }

    // so, anything remaining in lib is not allowed
    return false;
  }
}
