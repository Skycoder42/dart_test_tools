// This is the entrypoint of our custom linter
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_test_tools/src/custom_lint/lints/src_library_not_exported.dart';

import 'lints/no_self_package_imports.dart';

PluginBase createPlugin() => _CustomLintPlugin();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class _CustomLintPlugin extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const NoSelfPackageImports(),
        const SrcLibraryNotExported(),
      ];
}
