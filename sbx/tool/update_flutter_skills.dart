// Regenerates the bundled agent-skills list of the Flutter sbx kit.
//
// Reads the pinned commits of dart-lang/skills and flutter/agent-plugins from
// sbx/flutter/flutter.yaml, lists the dart-* and flutter-* skills at exactly
// those commits and rewrites the `skills` arg and the agent-skill@1
// capabilities to match. Run from the repository root:
//
//   dart run sbx/tool/update_flutter_skills.dart [--file <path>]
//
// The commits are the input and are never changed by this tool.
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dart_test_tools/src/tools/github.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const _dartSkillsUrl = 'https://github.com/dart-lang/skills.git';
const _flutterSkillsUrl = 'https://github.com/flutter/agent-plugins.git';
const _capabilitiesKey = 'capabilities';
const _skillType = 'com.docker.sandbox/agent-skill@1';
const _skillPathPrefix = '/opt/flutter-skills/';
final _unorderedEquals = const UnorderedIterableEquality<String>().equals;

Future<void> main(List<String> args) => Github.runZoned(() async {
  final parser = ArgParser()
    ..addOption(
      'file',
      abbr: 'f',
      valueHelp: 'path',
      defaultsTo: 'sbx/flutter/flutter.yaml',
      help: 'The kit descriptor to update.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);
    if (options['help'] as bool) {
      stdout
        ..writeln('Usage: dart run sbx/tool/update_flutter_skills.dart')
        ..writeln(parser.usage);
      return;
    }

    final file = File(options['file'] as String);
    final editor = YamlEditor(await file.readAsString());

    final dartRef = _ref(editor, 'dartSkillsRef');
    final flutterRef = _ref(editor, 'flutterSkillsRef');
    final skills = await _discoverSkills(dartRef, flutterRef).toList()
      ..sort(); // only relevant if actually updated

    _updateSkillsArg(editor, skills);
    _updateSkillEntries(editor, skills);

    if (editor.edits.isEmpty) {
      Github.logInfo('${file.path} is up to date (${skills.length} skills).');
      return;
    }

    await file.writeAsString(editor.toString());
    Github.logNotice('Updated ${file.path} (${skills.length} skills).');
  } on ArgParserException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln(parser.usage);
    exitCode = 64;
  }
});

String _ref(YamlEditor editor, String key) {
  final ref = (editor.parseAt(['args', key, 'default']) as YamlScalar?)?.value;
  if (ref is! String || !RegExp(r'^[0-9a-f]{40}$').hasMatch(ref)) {
    throw Exception('args.$key.default is not a commit SHA: $ref');
  }
  return ref;
}

Stream<String> _discoverSkills(String dartRef, String flutterRef) async* {
  final tmp = await Directory.systemTemp.createTemp();
  try {
    final dartRepo = await _fetch(tmp, 'dart-skills', _dartSkillsUrl, dartRef);
    yield* _listSkills(dartRepo, 'dart-');

    final flutterRepo = await _fetch(
      tmp,
      'flutter-skills',
      _flutterSkillsUrl,
      flutterRef,
    );
    yield* _listSkills(flutterRepo, 'flutter-');
  } finally {
    await tmp.delete(recursive: true);
  }
}

Future<Directory> _fetch(
  Directory tmp,
  String name,
  String url,
  String sha,
) async {
  final dir = Directory.fromUri(tmp.uri.resolve(name));
  Github.logInfo('Fetching $url@$sha');
  await Github.exec('git', ['init', '-q', dir.path]);
  await Github.exec('git', [
    'fetch',
    '-q',
    '--depth',
    '1',
    url,
    sha,
  ], workingDirectory: dir);
  await Github.exec('git', const [
    'checkout',
    '-q',
    'FETCH_HEAD',
  ], workingDirectory: dir);
  final head = await Github.execLines(
    'git',
    const ['rev-parse', 'HEAD'],
    workingDirectory: dir,
  ).map((l) => l.trim()).where((l) => l.isNotEmpty).firstOrNull;
  if (head != sha) {
    throw Exception('Fetched $head from $url, expected $sha.');
  }
  return dir;
}

Stream<String> _listSkills(Directory repo, String prefix) async* {
  final skillsDir = Directory('${repo.path}/skills');
  if (!skillsDir.existsSync()) {
    throw Exception('${skillsDir.path} does not exist.');
  }

  await for (final entity in skillsDir.list(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entity is! Directory || !name.startsWith(prefix)) {
      continue;
    }

    yield name;
  }
}

void _updateSkillsArg(YamlEditor editor, List<String> skills) {
  const skillsArg = ['args', 'skills', 'default'];
  final node = editor.parseAt(skillsArg);
  if (node case YamlScalar(:final String value)) {
    final currentSkills = LineSplitter.split(value)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    if (_unorderedEquals(currentSkills, skills)) {
      Github.logDebug(
        'args.skills.default is up to date (${skills.length} skills).',
      );
      return;
    }

    Github.logInfo('Updating args.skills.default (${skills.length} skills).');
    editor.update(
      skillsArg,
      YamlScalar.wrap(skills.join('\n'), style: .LITERAL),
    );
    return;
  }

  throw Exception(
    'args.skills.default must be a string '
    'but was ${node.runtimeType} (${node.value.runtimeType}).',
  );
}

void _updateSkillEntries(YamlEditor editor, List<String> skills) {
  final indicesToRemove = (editor.parseAt([_capabilitiesKey]) as YamlList)
      .cast<YamlMap>()
      .indexed
      .where((r) => r.$2['type'] == _skillType)
      .map((r) => (r.$1, r.$2['config'] as YamlMap))
      .map((r) => (r.$1, r.$2['path'] as String))
      .where((r) => r.$2.startsWith(_skillPathPrefix))
      .map((r) => (r.$1, r.$2.substring(_skillPathPrefix.length)))
      .toList();

  if (_unorderedEquals(indicesToRemove.map((r) => r.$2), skills)) {
    Github.logDebug(
      'agent-skill@1 capabilities are up to date (${skills.length} skills).',
    );
    return;
  }

  indicesToRemove.sort((a, b) => a.$1.compareTo(b.$1));
  for (final (index, _) in indicesToRemove.reversed) {
    editor.remove([_capabilitiesKey, index]);
  }

  for (final skill in skills) {
    editor.appendToList(
      [_capabilitiesKey],
      {
        'type': _skillType,
        'optional': true,
        'config': {'path': '$_skillPathPrefix$skill'},
      },
    );
  }

  Github.logInfo(
    'Updated agent-skill@1 capabilities (${skills.length} skills).',
  );
}
