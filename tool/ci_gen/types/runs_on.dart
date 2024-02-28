enum RunsOn {
  ubuntuLatest('ubuntu-latest'),
  macosLatest('macos-latest'),
  macos13('macos-13'),
  windowsLatest('windows-latest');

  final String id;

  const RunsOn(this.id);
}
