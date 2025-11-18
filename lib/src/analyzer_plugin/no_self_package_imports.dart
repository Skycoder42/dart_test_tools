import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'utils/workspace_pacakge_extensions.dart';

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

    _logger.finer('Scanning file: ${context.definingUnit.file.path}');
    final visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }

  bool _shouldScan(RuleContext context) {
    final package = context.package;
    if (package == null) {
      return false;
    }

    final isInLibSrc = package.libSrc.contains(context.definingUnit.file.path);
    final isInTest = context.isInTestDirectory;
    final isInTool = package.tool.contains(context.definingUnit.file.path);
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
    if (!(_context.package?.lib.contains(uri.source.fullName) ?? false)) {
      _rule._logger.finest('${uri.relativeUriString}: OK');
      return true;
    }

    // ... excluding lib/src
    if (_context.package?.libSrc.contains(uri.source.fullName) ?? false) {
      _rule._logger.finest('${uri.relativeUriString}: OK');
      return true;
    }

    // ... excluding lib/gen
    if (_context.package?.libGen.contains(uri.source.fullName) ?? false) {
      _rule._logger.finest('${uri.relativeUriString}: OK');
      return true;
    }

    // so, anything remaining in lib is not allowed
    _rule._logger.finest('${uri.relativeUriString}: FAIL');
    return false;
  }
}
