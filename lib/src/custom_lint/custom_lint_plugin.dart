// This is the entrypoint of our custom linter
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'lints/freezed_classes_must_be_sealed.dart';
import 'lints/no_self_package_imports.dart';
import 'lints/src_library_not_exported.dart';

PluginBase createPlugin() => _CustomLintPlugin();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class _CustomLintPlugin extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const NoSelfPackageImports(),
        const SrcLibraryNotExported(),
        const FreezedClassesMustBeSealed(),
      ];
}
