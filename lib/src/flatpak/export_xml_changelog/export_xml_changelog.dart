import 'dart:io';

import 'package:change/change.dart';
import 'package:collection/collection.dart';
import 'package:markdown/markdown.dart';
import 'package:xml/xml.dart';

class ExportXmlChangelog {
  const ExportXmlChangelog();

  Future<void> call({
    required File outFile,
    bool isMetadataXml = true,
  }) async {
    final changelogFile = File('CHANGELOG.md');
    final changelog = parseChangelog(await changelogFile.readAsString());

    final XmlDocument document;
    if (isMetadataXml) {
      document = XmlDocument.parse(await outFile.readAsString());
      final builder = XmlBuilder();
      _buildReleases(builder, changelog);
      document.getElement('component')!.children.add(builder.buildFragment());
    } else {
      final builder = XmlBuilder()
        ..processing('xml', 'version="1.0" encoding="UTF-8"');
      _buildReleases(builder, changelog);
      document = builder.buildDocument();
    }
    await outFile.writeAsString(document.toXmlString(pretty: true));
  }

  void _buildReleases(XmlBuilder builder, Changelog changelog) {
    builder.element(
      'releases',
      nest: () {
        for (final release in changelog.history().toList().reversed) {
          _buildRelease(builder, release);
        }
      },
    );
  }

  void _buildRelease(XmlBuilder builder, Release release) {
    builder.element(
      'release',
      nest: () {
        builder
          ..attribute('version', release.version)
          ..attribute('date', release.date.toIso8601String().substring(0, 10))
          ..attribute(
            'type',
            release.version.isPreRelease ? 'development' : 'stable',
          )
          ..element(
            'description',
            nest: () => _buildDescription(builder, release.changes()),
          );

        if (release.link.isNotEmpty) {
          builder.element(
            'url',
            nest: () {
              builder.text(release.link);
            },
          );
        }
      },
    );
  }

  void _buildDescription(XmlBuilder builder, Iterable<Change> allChanges) {
    final changeMap = allChanges.groupListsBy((element) => element.type);
    for (final MapEntry(key: type, value: changes) in changeMap.entries) {
      builder
        ..element(
          'h3',
          nest: () {
            builder.text(type);
          },
        )
        ..element(
          'ul',
          nest: () {
            for (final change in changes) {
              final visitor = _DescriptionVisitor()
                ..visitAll(change.description);
              builder.xml(visitor.toXml());
            }
          },
        );
    }
  }
}

class _DescriptionVisitor extends NodeVisitor {
  XmlElement _currentElement;

  _DescriptionVisitor() : _currentElement = XmlElement.tag('li');

  String toXml() => _currentElement.toXmlString();

  void visitAll(Iterable<Node> nodes) {
    for (final node in nodes) {
      node.accept(this);
    }
  }

  @override
  bool visitElementBefore(Element element) {
    final newElement = XmlElement.tag(
      element.tag,
      attributes: element.attributes.entries
          .map((e) => XmlAttribute(XmlName.fromString(e.key), e.value)),
    );
    _currentElement.children.add(newElement);
    _currentElement = newElement;
    return true;
  }

  @override
  void visitElementAfter(Element element) {
    _currentElement = _currentElement.parentElement!;
  }

  @override
  void visitText(Text text) {
    _currentElement.children.add(XmlText(text.text));
  }
}
