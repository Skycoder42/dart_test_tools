import 'package:meta/meta.dart';
import 'package:mustache_template/mustache_template.dart';

import 'renovate_upgrade.dart';

@internal
@immutable
final class const MessageTemplate._(
  final String source,
  final Template _template,
) {
  static final placeholders = <String, String? Function(RenovateUpgrade)>{
    'manager': (u) => u.manager,
    'depName': (u) => u.depName,
    'packageFile': (u) => u.packageFile,
    'depType': (u) => u.depType,
    'currentValue': (u) => u.currentValue,
    'newValue': (u) => u.newValue,
    'updateType': (u) => u.updateType,
    'currentVersion': (u) => u.currentVersion,
    'newVersion': (u) => u.newVersion,
    'currentDigest': (u) => u.currentDigest,
    'newDigest': (u) => u.newDigest,
    'newDigestShort': (u) => u.newDigestShort,
    'packageName': (u) => u.packageName,
    'datasource': (u) => u.datasource,
    'releaseTimestamp': (u) => u.releaseTimestamp,
  };

  factory parse(String source) {
    if (source.trim().isEmpty) {
      throw const FormatException('The message must not be empty');
    }
    final newline = source.indexOf(RegExp('[\r\n]'));
    if (newline != -1) {
      throw FormatException(
        'The message must be a single line',
        source,
        newline,
      );
    }

    try {
      // strict mode fails for every name that is not a placeholder
      final template = Template(source)
        ..renderString({for (final name in placeholders.keys) name: name});
      return MessageTemplate._(source, template);
    } on TemplateException catch (e) {
      throw FormatException(
        'Invalid message template: ${e.message} Valid placeholders are: '
        '${placeholders.keys.join(', ')}',
        source,
        e.offset,
      );
    }
  }

  factory fromJson(String json) => MessageTemplate.parse(json);

  String toJson() => source;

  String render(RenovateUpgrade upgrade) => _template.renderString({
    for (final MapEntry(key: name, value: valueOf) in placeholders.entries)
      name: ?valueOf(upgrade),
  });

  @override
  bool operator ==(Object other) =>
      other is MessageTemplate && other.source == source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => source;
}
