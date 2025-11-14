import 'dart:io';

import 'package:meta/meta.dart';

import '../models/analysis_options.dart';
import '../models/analysis_options_ref.dart';
import 'analysis_options_loader.dart';

class RulesCollector {
  @internal
  final AnalysisOptionsLoader analysisOptionsLoader;

  RulesCollector({required this.analysisOptionsLoader});

  Future<Map<String, bool>> collectRules(
    List<AnalysisOptionsRef> analysisOptionsRefs, {
    Directory? relativeTo,
    bool recursive = true,
  }) async {
    final rules = <String, bool>{};

    for (final analysisOptionsRef in analysisOptionsRefs) {
      final analysisOptions = await analysisOptionsLoader.load(
        analysisOptionsRef,
        relativeTo: relativeTo,
      );

      if (analysisOptions.include case final include? when recursive) {
        rules.addAll(
          await collectRules(
            include,
            relativeTo: analysisOptionsLoader.findDirectory(analysisOptionsRef),
          ),
        );
      }

      if (analysisOptionsRef is AnalysisOptionsPackageRef) {
        _validateNoNegativeRules(analysisOptionsRef, analysisOptions);
      }

      rules.addAll(analysisOptions.linter?.ruleMap ?? const {});
    }

    return rules;
  }

  void _validateNoNegativeRules(
    AnalysisOptionsRef analysisOptionsRef,
    AnalysisOptions analysisOptions,
  ) {
    final deactivatedRules =
        analysisOptions.linter?.ruleMap.entries
            .where((e) => !e.value)
            .map((e) => e.key)
            .toSet() ??
        const {};
    if (deactivatedRules.isNotEmpty) {
      throw Exception(
        'Cannot add $analysisOptionsRef because it as negative rules: '
        '${deactivatedRules.join(', ')}',
      );
    }
  }
}
