import 'dart:io';

import 'package:yaml_writer/yaml_writer.dart';

import 'linter_gen/models/analysis_options_ref.dart';
import 'linter_gen/services/analysis_options_loader.dart';
import 'linter_gen/services/analysis_options_writer.dart';
import 'linter_gen/services/known_rules_loader.dart';
import 'linter_gen/services/rules_collector.dart';
import 'linter_gen/services/rules_generator.dart';

Future<void> main() async {
  final loader = AnalysisOptionsLoader();
  final writer = AnalysisOptionsWriter(yamlWriter: YamlWriter());
  final generator = RulesGenerator(
    knownRulesLoader: KnownRulesLoader(
      analysisOptionsLoader: loader,
      analysisOptionsWriter: writer,
    ),
    rulesCollector: RulesCollector(analysisOptionsLoader: loader),
  );

  await _writeStrictOptions(generator, writer);
  await _writePackageOptions(generator, writer);
  await _writeSelfOptions(generator, writer);
}

Future<void> _writeStrictOptions(
  RulesGenerator generator,
  AnalysisOptionsWriter writer,
) async {
  const strictOptionsRef = AnalysisOptionsRef.local('lib/strict.yaml');
  stdout.writeln('Generating $strictOptionsRef');
  final normalOptions = await generator.generateRules(
    baseOptions: const [
      AnalysisOptionsRef.package(
        packageName: 'lints',
        path: 'recommended.yaml',
      ),
      AnalysisOptionsRef.package(
        packageName: 'flutter_lints',
        path: 'flutter.yaml',
      ),
      AnalysisOptionsRef.package(packageName: 'lint', path: 'strict.yaml'),
    ],
    customOptions: strictOptionsRef,
    withAnalyzerRules: true,
  );
  await writer.saveAnalysisOptions(strictOptionsRef, normalOptions);
}

Future<void> _writePackageOptions(
  RulesGenerator generator,
  AnalysisOptionsWriter writer,
) async {
  const packageOptionsRef = AnalysisOptionsRef.local('lib/package.yaml');
  stdout.writeln('Generating $packageOptionsRef');
  final packageOptions = await generator.generateRules(
    baseOptions: const [
      AnalysisOptionsRef.package(packageName: 'lint', path: 'package.yaml'),
      AnalysisOptionsRef.local('strict.yaml'),
    ],
    customOptions: packageOptionsRef,
    relativeTo: packageOptionsRef,
  );
  await writer.saveAnalysisOptions(packageOptionsRef, packageOptions);
}

Future<void> _writeSelfOptions(
  RulesGenerator generator,
  AnalysisOptionsWriter writer,
) async {
  const selfOptionsRef = AnalysisOptionsRef.local('analysis_options.yaml');
  stdout.writeln('Generating $selfOptionsRef');
  final normalOptions = await generator.generateRules(
    baseOptions: const [AnalysisOptionsRef.local('lib/package.yaml')],
    customOptions: selfOptionsRef,
  );
  await writer.saveAnalysisOptions(selfOptionsRef, normalOptions);
}
