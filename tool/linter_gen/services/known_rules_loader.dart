import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart';

import '../models/analysis_options.dart';
import '../models/analysis_options_ref.dart';
import 'analysis_options_loader.dart';
import 'analysis_options_writer.dart';

class KnownRulesLoader {
  final AnalysisOptionsLoader analysisOptionsLoader;
  final AnalysisOptionsWriter analysisOptionsWriter;

  final _rulesPageUri = Uri.https('dart.dev', '/tools/linter-rules/all');

  KnownRulesLoader({
    required this.analysisOptionsLoader,
    required this.analysisOptionsWriter,
  });

  Future<Set<String>> loadNewRules() async {
    const knownRulesCacheFile = AnalysisOptionsRef.local(
      'tool/linter_gen/known_rules.yaml',
    );

    final previousKnownOptions = await analysisOptionsLoader.load(
      knownRulesCacheFile,
    );
    final newKnownOptions = await _loadKnownRules();

    await analysisOptionsWriter.saveAnalysisOptions(
      knownRulesCacheFile,
      newKnownOptions,
    );

    final oldRules =
        previousKnownOptions.linter?.ruleMap.keys.toSet() ?? const {};
    final newRules = newKnownOptions.linter?.ruleMap.keys.toSet() ?? const {};
    return newRules.difference(oldRules);
  }

  Future<AnalysisOptions> _loadKnownRules() async {
    final rulesPageResponse = await get(_rulesPageUri);
    if (rulesPageResponse.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to load $_rulesPageUri '
        'with status code ${rulesPageResponse.statusCode}',
      );
    }

    final rulesDom = html.parse(
      rulesPageResponse.body,
      sourceUrl: _rulesPageUri.toString(),
    );
    final sourceCode = rulesDom.querySelectorAll('pre.shiki').single.text;
    return checkedYamlDecode(
      sourceCode,
      AnalysisOptions.fromYaml,
      sourceUrl: _rulesPageUri,
    );
  }
}
