import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart';

import '../models/analysis_options.dart';

class KnownRulesLoader {
  final rulesPageUri = Uri.https(
    'dart-lang.github.io',
    '/linter/lints/options/options.html',
  );

  Future<Set<String>> loadKnownRules() async {
    final rulesPageResponse = await get(rulesPageUri);
    if (rulesPageResponse.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to load $rulesPageUri '
        'with status code ${rulesPageResponse.statusCode}',
      );
    }

    final rulesDom = html.parse(
      rulesPageResponse.body,
      sourceUrl: rulesPageUri.toString(),
    );
    final sourceCode = rulesDom.getElementsByTagName('code').single.text;
    final rules = checkedYamlDecode(
      sourceCode,
      AnalysisOptions.fromYaml,
      sourceUrl: rulesPageUri,
    );
    return rules.linter?.ruleMap.keys.toSet() ?? const {};
  }
}
