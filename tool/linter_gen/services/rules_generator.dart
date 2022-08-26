import 'package:freezed_annotation/freezed_annotation.dart';

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
    required AnalysisOptionsRef baseOptions,
    AnalysisOptionsRef? relativeTo,
    List<AnalysisOptionsRef> mergeOptions = const [],
    AnalysisOptionsRef? customOptions,
  }) async {
    final knownRules = await knownRulesLoader.loadKnownRules();

    final relativeToDir = relativeTo != null
        ? rulesCollector.analysisOptionsLoader.findDirectory(relativeTo)
        : null;
    final baseRules = await rulesCollector.collectRulesRecursively(
      baseOptions,
      relativeTo: relativeToDir,
    );
    final mergeRules = await Stream.fromIterable(mergeOptions)
        .asyncMap(rulesCollector.collectRulesRecursively)
        .toList();
    final customRules = customOptions != null
        ? await rulesCollector.collectRulesRecursively(customOptions)
        : null;

    final appliedRules = _mergeRules(
      baseRules,
      mergeOptions,
      mergeRules,
      customRules,
      knownRules,
    );

    return AnalysisOptions(
      include: baseOptions,
      analyzer: const AnalysisOptionsAnalyzer(
        strongMode: AnalysisOptionsStrongMode(
          implicitCasts: false,
          implicitDynamic: false,
        ),
      ),
      linter: AnalysisOptionsLinter(
        rules: appliedRules,
      ),
    );
  }

  Map<String, dynamic> _mergeRules(
    Map<String, bool> baseRules,
    List<AnalysisOptionsRef> mergeOptions,
    List<Map<String, bool>> mergeRules,
    Map<String, bool>? customRules,
    Set<String> knownRules,
  ) {
    // only mark positive rules as processed, so merge rules can apply
    final processedRules = baseRules.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    final appliedRules = <String, dynamic>{};

    for (var i = 0; i < mergeRules.length; i++) {
      final ruleSet = mergeRules[i];
      final ruleSetOrigin = mergeOptions[i];
      appliedRules['# rules from $ruleSetOrigin'] = null;
      for (final rule in ruleSet.entries) {
        // only apply positive rules that are neither in base nor already merged
        if (rule.value && processedRules.add(rule.key)) {
          appliedRules[rule.key] = rule.value;
        }
      }
    }

    // now mark all base rules as processed, so only different rules are applied
    processedRules.addAll(baseRules.keys);

    if (customRules != null) {
      appliedRules['# custom rules'] = null;
      for (final rule in customRules.entries) {
        if (processedRules.add(rule.key)) {
          // keep rules that are not in base or merged
          appliedRules[rule.key] = rule.value;
        } else {
          // only keep custom entries that are different
          final currentRuleValue =
              (appliedRules[rule.key] as bool?) ?? baseRules[rule.key] ?? false;
          if (rule.value != currentRuleValue) {
            appliedRules[rule.key] = '${rule.value} # overwritten';
          }
        }
      }
    }

    final newRules = knownRules.difference(processedRules);
    appliedRules['# new rules'] = null;
    for (final rule in newRules) {
      appliedRules[rule] = false;
    }
    return appliedRules;
  }
}
