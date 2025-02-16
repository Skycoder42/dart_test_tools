import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/analysis_options_ref.dart';
import 'analysis_options_loader.dart';

class RulesCollector {
  @internal
  final AnalysisOptionsLoader analysisOptionsLoader;

  RulesCollector({required this.analysisOptionsLoader});

  Future<Map<String, bool>> collectRulesRecursively(
    AnalysisOptionsRef analysisOptionsRef, {
    Directory? relativeTo,
  }) async {
    final rules = <String, bool>{};

    final analysisOptions = await analysisOptionsLoader.load(
      analysisOptionsRef,
      relativeTo: relativeTo,
    );

    if (analysisOptions.include != null) {
      rules.addAll(
        await collectRulesRecursively(
          analysisOptions.include!,
          relativeTo: analysisOptionsLoader.findDirectory(analysisOptionsRef),
        ),
      );
    }

    rules.addAll(analysisOptions.linter?.ruleMap ?? const {});

    return rules;
  }
}
