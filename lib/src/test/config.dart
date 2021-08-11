class PathConfig {
  static const unit = PathConfig(['test/unit']);
  static const integration = PathConfig(['test/integration']);

  final List<String> paths;

  const PathConfig(this.paths);

  factory PathConfig.fromYaml(dynamic yaml) {
    if (yaml is Iterable<dynamic>) {
      return PathConfig(yaml.cast<String>().toList());
    } else {
      return PathConfig([yaml as String]);
    }
  }
}

class TestConfig {
  static const key = 'test';

  static const _unitKey = 'unit';
  static const _integrationKey = 'integration';

  final PathConfig unit;
  final PathConfig integration;

  const TestConfig({
    this.unit = PathConfig.unit,
    this.integration = PathConfig.integration,
  });

  factory TestConfig.fromYaml(Map<dynamic, dynamic> yaml) => TestConfig(
        unit: yaml.containsKey(_unitKey)
            ? PathConfig.fromYaml(yaml[_unitKey])
            : PathConfig.unit,
        integration: yaml.containsKey(_integrationKey)
            ? PathConfig.fromYaml(yaml[_integrationKey])
            : PathConfig.integration,
      );
}
