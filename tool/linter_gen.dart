import 'package:yaml_writer/yaml_writer.dart';

import 'linter_gen/models/analysis_options_ref.dart';
import 'linter_gen/services/analysis_options_loader.dart';
import 'linter_gen/services/analysis_options_writer.dart';
import 'linter_gen/services/known_rules_loader.dart';
import 'linter_gen/services/rules_collector.dart';
import 'linter_gen/services/rules_generator.dart';

Future<void> main() async {
  final loader = AnalysisOptionsLoader();
  final writer = AnalysisOptionsWriter(
    yamlWriter: YAMLWriter(),
  );
  final generator = RulesGenerator(
    knownRulesLoader: KnownRulesLoader(
      analysisOptionsLoader: loader,
      analysisOptionsWriter: writer,
    ),
    rulesCollector: RulesCollector(
      analysisOptionsLoader: loader,
    ),
  );

  await _writeNormalOptions(generator, writer);
  await _writePackageOptions(generator, writer);
}

Future<void> _writeNormalOptions(
  RulesGenerator generator,
  AnalysisOptionsWriter writer,
) async {
  const normalOptionsRef = AnalysisOptionsRef.local(
    'lib/analysis_options.yaml',
  );
  final normalOptions = await generator.generateRules(
    baseOptions: const AnalysisOptionsRef.package(
      packageName: 'lint',
      path: 'analysis_options.yaml',
    ),
    mergeOptions: const [
      AnalysisOptionsRef.package(
        packageName: 'lints',
        path: 'recommended.yaml',
      ),
      AnalysisOptionsRef.package(
        packageName: 'flutter_lints',
        path: 'flutter.yaml',
      ),
    ],
    customOptions: normalOptionsRef,
  );
  await writer.saveAnalysisOptions(normalOptionsRef, normalOptions);
}

Future<void> _writePackageOptions(
  RulesGenerator generator,
  AnalysisOptionsWriter writer,
) async {
  const packageOptionsRef = AnalysisOptionsRef.local(
    'lib/analysis_options_package.yaml',
  );
  final packageOptions = await generator.generateRules(
    baseOptions: const AnalysisOptionsRef.local(
      'analysis_options.yaml',
    ),
    relativeTo: packageOptionsRef,
    mergeOptions: const [
      AnalysisOptionsRef.package(
        packageName: 'lint',
        path: 'analysis_options_package.yaml',
      )
    ],
    customOptions: packageOptionsRef,
  );
  await writer.saveAnalysisOptions(packageOptionsRef, packageOptions);
}