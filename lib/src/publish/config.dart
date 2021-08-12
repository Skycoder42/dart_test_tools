import '../common/config.dart';

class PublishConfig {
  static const key = 'publish';

  static const defaultExcludePathConfig = PathConfig();
  static const defaultRootIgnore = '.gitignore';

  static const _exlcudeKey = 'exclude';
  static const _rootIgnoreKey = 'rootIgnore';

  final PathConfig exclude;
  final String rootIgnore;

  const PublishConfig({
    this.exclude = defaultExcludePathConfig,
    this.rootIgnore = defaultRootIgnore,
  });

  factory PublishConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return PublishConfig(
      exclude: yaml.containsKey(_exlcudeKey)
          ? PathConfig.fromYaml(yaml[_exlcudeKey])
          : defaultExcludePathConfig,
      rootIgnore: yaml.containsKey(_rootIgnoreKey)
          ? yaml[_rootIgnoreKey] as String
          : defaultRootIgnore,
    );
  }
}
