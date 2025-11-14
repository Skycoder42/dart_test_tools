import 'package:meta/meta.dart';

import '../models/analysis_options.dart';
import '../models/analysis_options_ref.dart';
import 'known_rules_loader.dart';
import 'rules_collector.dart';

class RulesGenerator {
  @internal
  final KnownRulesLoader knownRulesLoader;
  @internal
  final RulesCollector rulesCollector;

  RulesGenerator({
    required this.knownRulesLoader,
    required this.rulesCollector,
  });

  Future<AnalysisOptions> generateRules({
    required List<AnalysisOptionsRef> baseOptions,
    AnalysisOptionsRef? relativeTo,
    AnalysisOptionsRef? customOptions,
    bool withAnalyzerRules = false,
  }) async {
    final newRules = await knownRulesLoader.loadNewRules();

    final relativeToDir = relativeTo != null
        ? rulesCollector.analysisOptionsLoader.findDirectory(relativeTo)
        : null;
    final baseRules = await rulesCollector.collectRules(
      baseOptions,
      relativeTo: relativeToDir,
    );
    final customRules = await rulesCollector.collectRules([
      ?customOptions,
    ], recursive: false);

    final appliedRules = _mergeRules(baseRules, customRules, newRules);

    return AnalysisOptions(
      include: baseOptions.length == 1
          ? ListOrValue.value(baseOptions.single)
          : ListOrValue.list(baseOptions),
      analyzer: AnalysisOptionsAnalyzer(
        plugins: const ['custom_lint'],
        language: withAnalyzerRules
            ? const {
                'strict-casts': true,
                'strict-inference': true,
                'strict-raw-types': true,
              }
            : null,
        errors: withAnalyzerRules
            ? const {'included_file_warning': DiagnosticLevel.ignore}
            : null,
      ),
      linter: AnalysisOptionsLinter(rules: appliedRules),
    );
  }

  Map<String, dynamic> _mergeRules(
    Map<String, bool> baseRules,
    Map<String, bool> customRules,
    Set<String> newRules,
  ) {
    // mark base rules as processed, so merge rules can apply
    final processedRules = baseRules.keys.toSet();
    final appliedRules = <String, dynamic>{};

    if (customRules.isNotEmpty) {
      appliedRules['# custom rules'] = null;
      for (final MapEntry(:key, :value) in customRules.entries) {
        if (appliedRules.containsKey(key)) {
          throw Exception('Cannot apply same custom rule twice: $key');
        }

        if (processedRules.add(key)) {
          // keep rules that are not in base
          appliedRules[key] = value;
        } else {
          // only keep custom entries that are different
          final currentRuleValue = baseRules[key] ?? false;
          if (value != currentRuleValue) {
            appliedRules[key] = '$value # overwritten';
          }
        }
      }
    }

    final actualNewRules = newRules.difference(processedRules);
    appliedRules['# new rules'] = null;
    for (final rule in actualNewRules) {
      appliedRules[rule] = true;
    }
    return appliedRules;
  }
}
