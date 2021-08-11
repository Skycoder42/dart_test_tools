import '../common/config.dart';

class TestConfig {
  static const key = 'test';
  static const defaultUnitPathConfig = PathConfig(['test/unit']);
  static const defaultIntegrationPathConfig = PathConfig(['test/integration']);

  static const _unitKey = 'unit';
  static const _integrationKey = 'integration';

  final PathConfig unit;
  final PathConfig integration;

  const TestConfig({
    this.unit = defaultUnitPathConfig,
    this.integration = defaultIntegrationPathConfig,
  });

  factory TestConfig.fromYaml(Map<dynamic, dynamic> yaml) => TestConfig(
        unit: yaml.containsKey(_unitKey)
            ? PathConfig.fromYaml(yaml[_unitKey])
            : defaultUnitPathConfig,
        integration: yaml.containsKey(_integrationKey)
            ? PathConfig.fromYaml(yaml[_integrationKey])
            : defaultIntegrationPathConfig,
      );
}
