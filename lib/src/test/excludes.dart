class ExcludeConfig {
  final List<String> patterns;

  const ExcludeConfig(this.patterns);

  factory ExcludeConfig.fromAnalysisOptionsYaml(
    Map<dynamic, dynamic> analysisOptionsYaml,
  ) {
    final analyzerYaml =
        analysisOptionsYaml['analyzer'] as Map<dynamic, dynamic>;
    final excludeYaml = analyzerYaml['exclude'] as Iterable<dynamic>;
    return ExcludeConfig(excludeYaml.cast<String>().toList());
  }
}
